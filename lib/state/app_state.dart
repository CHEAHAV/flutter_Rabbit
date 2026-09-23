import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/question_repository.dart';
import '../models/exam_part.dart';
import '../models/question.dart';
import '../services/auth_service.dart';
import '../services/progress_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

/// Root application state: bootstraps the question bank + local progress
/// store, and exposes them to the widget tree via Provider.
class AppState extends ChangeNotifier {
  final QuestionRepository repo = QuestionRepository.instance;
  final ProgressService progress = ProgressService.instance;

  /// The private-app gate. See [AuthService]: one allowed account, and a
  /// successful login is remembered for a day.
  final AuthService auth = AuthService.instance;

  bool _booting = true;
  String? _bootError;
  bool _isDarkMode = false;

  bool get booting => _booting;
  String? get bootError => _bootError;

  /// Whether an unexpired login session is on record. `app.dart` watches this
  /// and shows either the login screen or the app itself.
  bool get isSignedIn => auth.isSignedIn;

  /// The user's saved light/dark preference. Defaults to light until the
  /// on-device preference has loaded (see [bootstrap]). `app.dart` watches
  /// this and animates the theme toward it with a [TweenAnimationBuilder]
  /// whenever it changes, so the switch crossfades instead of snapping.
  bool get isDarkMode => _isDarkMode;

  /// Sound effects: master on/off + volume (0.0 - 1.0). The values live in
  /// [SoundService] (which the whole app plays through) and are persisted via
  /// [ProgressService]; AppState just exposes them to the UI.
  final SoundService sound = SoundService.instance;
  bool get soundEnabled => sound.enabled;
  double get soundVolume => sound.volume;

  /// What the speaker icon should show: muted when off *or* slid to zero.
  bool get soundMuted => !sound.audible;

  List<ExamPart> get parts => repo.parts;
  List<ExamPart> get partsWithQuestions =>
      repo.parts.where((p) => p.count > 0).toList();

  /// The subjects of one course, in catalog order (easiest rung first).
  List<ExamPart> partsIn(PartTrack track) =>
      repo.parts.where((p) => p.track == track).toList();

  /// The courses that actually have questions bundled, in the order
  /// [PartTrack] declares them - Khmer syllabuses first, then the English
  /// ones. Course order cannot be taken from the catalog: that has to follow
  /// the part numbering, which is the order the data files were *added*, so
  /// the teacher course would trail the English ones purely because its files
  /// are parts 27-28. A course whose data files are missing simply does not
  /// appear.
  List<PartTrack> get tracks {
    final stocked = repo.parts
        .where((p) => p.count > 0)
        .map((p) => p.track)
        .toSet();
    return PartTrack.values.where(stocked.contains).toList();
  }

  // ---- Unanswered pools -------------------------------------------------
  //
  // Every session that is built from a set of subjects (rather than from an
  // explicit list, the way the mistakes notebook is) draws only on questions
  // the user has not answered yet. These helpers are the one place that rule
  // lives, so the practice list, the exam configurator, the quick mock papers
  // and the quiz screen itself can never disagree about how many questions a
  // subject still has to offer.

  /// The questions of [part] the user has not answered yet.
  List<Question> unansweredIn(ExamPart part) {
    final answered = progress.answeredIn(part.id);
    if (answered.isEmpty) return part.questions;
    return part.questions.where((q) => !answered.contains(q.uid)).toList();
  }

  /// How many questions [part] still has left for a new session.
  ///
  /// Counted from the bank rather than taken from the size of the answered
  /// set, so a stored uid whose question no longer exists cannot make a
  /// subject look emptier than it is.
  int remainingIn(ExamPart part) {
    final answered = progress.answeredIn(part.id);
    if (answered.isEmpty) return part.count;
    var left = 0;
    for (final q in part.questions) {
      if (!answered.contains(q.uid)) left++;
    }
    return left;
  }

  /// [remainingIn], summed over several subjects.
  int remainingInParts(Iterable<ExamPart> parts) =>
      parts.fold<int>(0, (sum, p) => sum + remainingIn(p));

  /// Every question of [partIds] the user has not answered yet, in bank order
  /// (the caller shuffles when the session asks for it).
  List<Question> unansweredPool(Set<int> partIds) => [
    for (final part in repo.parts)
      if (partIds.contains(part.id)) ...unansweredIn(part),
  ];

  /// Every question of [partIds], answered or not. Only used to tell "this
  /// selection is empty" apart from "this selection is finished".
  List<Question> fullPool(Set<int> partIds) => [
    for (final part in repo.parts)
      if (partIds.contains(part.id)) ...part.questions,
  ];

  Future<void> bootstrap() async {
    try {
      await Future.wait([repo.load(), progress.init(), auth.init()]);
      _isDarkMode = progress.isDarkMode;
      AppColors.setBlend(_isDarkMode ? 1.0 : 0.0);
      sound.configure(
        enabled: progress.soundEnabled,
        volume: progress.soundVolume,
      );
      // Load audio in the background: it must never delay or fail app start.
      unawaited(sound.init());
    } catch (e) {
      _bootError = e.toString();
    } finally {
      _booting = false;
      notifyListeners();
    }
  }

  /// Switches the app's theme (smoothly, see [isDarkMode]) and persists the
  /// choice on-device.
  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    AppColors.setBlend(value ? 1.0 : 0.0);
    notifyListeners();
    await progress.setDarkMode(value);
  }

  /// Turns all sound effects on/off. Turning on plays a short confirmation
  /// blip (at the current volume) so the user hears that it works; turning
  /// off is silent.
  ///
  /// Turning on while the slider sits at zero restores the default volume,
  /// otherwise "on" would still be silent.
  Future<void> setSoundEnabled(bool value) async {
    final volume = value && sound.volume == 0
        ? SoundService.defaultVolume
        : sound.volume;
    if (sound.enabled == value && volume == sound.volume) return;
    sound.configure(enabled: value, volume: volume);
    notifyListeners();
    if (value) sound.toggle(true);
    await progress.setSoundEnabled(value);
    await progress.setSoundVolume(volume);
  }

  /// Sets the volume. Pass `persist: false` while a slider is being dragged
  /// (updates the live volume + UI without writing to disk on every frame) and
  /// call again with `persist: true` when the drag ends.
  ///
  /// Dragging up from zero switches sound back on, and dragging to zero shows
  /// as muted - like the volume control on a phone.
  Future<void> setSoundVolume(double value, {bool persist = true}) async {
    final v = value.clamp(0.0, 1.0).toDouble();
    final wasEnabled = sound.enabled;
    sound.configure(enabled: v > 0 ? true : wasEnabled, volume: v);
    notifyListeners();
    if (!persist) return;
    await progress.setSoundVolume(v);
    if (sound.enabled != wasEnabled) {
      await progress.setSoundEnabled(sound.enabled);
    }
  }

  // ---- Login ------------------------------------------------------------

  /// Checks the credentials and opens a one-day session when they match.
  /// Returns true on success; the caller shows the error message on false.
  Future<bool> signIn(String username, String password) async {
    final ok = await auth.signIn(username, password);
    if (ok) notifyListeners();
    return ok;
  }

  /// Ends the session now, sending the user back to the login screen.
  Future<void> signOut() async {
    await auth.signOut();
    notifyListeners();
  }

  /// Re-checks the session against the clock. Called when the app returns to
  /// the foreground, so a session left open past its day is closed the moment
  /// the user comes back rather than at the next cold start.
  Future<void> revalidateSession() async {
    final was = auth.isSignedIn;
    await auth.refresh();
    if (was != auth.isSignedIn) notifyListeners();
  }

  void refresh() => notifyListeners();
}
