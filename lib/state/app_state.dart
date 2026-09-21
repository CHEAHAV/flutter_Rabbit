import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/question_repository.dart';
import '../models/exam_part.dart';
import '../services/progress_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

/// Root application state: bootstraps the question bank + local progress
/// store, and exposes them to the widget tree via Provider.
class AppState extends ChangeNotifier {
  final QuestionRepository repo = QuestionRepository.instance;
  final ProgressService progress = ProgressService.instance;

  bool _booting = true;
  String? _bootError;
  bool _isDarkMode = false;

  bool get booting => _booting;
  String? get bootError => _bootError;

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

  /// The courses that actually have questions bundled, in catalog order. The
  /// subject browser is built from this rather than from [PartTrack.values],
  /// so a course whose data files are missing simply does not appear.
  List<PartTrack> get tracks {
    final seen = <PartTrack>[];
    for (final p in repo.parts) {
      if (p.count > 0 && !seen.contains(p.track)) seen.add(p.track);
    }
    return seen;
  }

  Future<void> bootstrap() async {
    try {
      await Future.wait([repo.load(), progress.init()]);
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

  void refresh() => notifyListeners();
}
