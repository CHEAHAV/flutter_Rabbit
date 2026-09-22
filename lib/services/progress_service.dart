import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exam_result.dart';
import '../models/history_entry.dart';

/// Persists study progress locally on-device: streaks, mistakes notebook,
/// bookmarks, per-part accuracy and exam history. No account/server needed.
class ProgressService {
  ProgressService._();
  static final ProgressService instance = ProgressService._();

  static const _kStreak = 'rabbit.streak';
  static const _kLastStudyDate = 'rabbit.lastStudyDate';
  static const _kMistakes = 'rabbit.mistakes';
  static const _kBookmarks = 'rabbit.bookmarks';
  static const _kHistory = 'rabbit.history';
  static const _kPartStats = 'rabbit.partStats';
  static const _kTotalAnswered = 'rabbit.totalAnswered';
  static const _kTotalCorrect = 'rabbit.totalCorrect';
  static const _kDisplayName = 'rabbit.displayName';
  static const _kGoalPartId = 'rabbit.goalPartId';
  static const _kDarkMode = 'rabbit.darkMode';
  static const _kSoundEnabled = 'rabbit.soundEnabled';
  static const _kSoundVolume = 'rabbit.soundVolume';
  static const _kBankRevision = 'rabbit.bankRevision';
  static const _kAnswered = 'rabbit.answeredQuestions';

  /// Bumped whenever the English bank is re-cut into a different set of parts.
  /// Progress is keyed by part id and by "partId-questionId", so after a re-cut
  /// the stored keys point at questions that are no longer there; [_migrate]
  /// drops them instead of showing the user accuracy for a subject they never
  /// studied.
  ///
  /// 2: the English bank moved from the book's Part A-E lettering (parts 14-24)
  ///    to one part per level (parts 14-26).
  /// 3: the Khmer bank (parts 1-13) was re-checked against QCM.pdf - the
  ///    questions the app was missing were added back in the document's own
  ///    order, so every Khmer question id shifted.
  static const bankRevision = 3;

  /// The English bank, parts 14-26. Parts 1-13 are the Khmer civil-service
  /// bank and 27 up are the Khmer subjects added since; the range is spelled
  /// out because the two banks were renumbered at different revisions, and a
  /// part added later has no old numbering to clean up.
  static const _firstEnglishPart = 14;
  static const _lastEnglishPart = 26;

  static bool _isEnglishPart(int partId) =>
      partId >= _firstEnglishPart && partId <= _lastEnglishPart;

  late SharedPreferences _prefs;
  bool _ready = false;

  Set<String> _mistakes = {};
  Set<String> _bookmarks = {};

  /// Every question the user has already answered, grouped by part id, so a
  /// new session in a part can be built out of the questions that are left.
  /// Grouping is what makes "how many are left in this subject" a map lookup
  /// instead of a scan of the whole set on every tile rebuild.
  final Map<int, Set<String>> _answeredByPart = {};
  List<HistoryEntry> _history = [];
  Map<int, PartStat> _partStats = {};

  /// Forces the next [init] to re-read storage. Tests only: the service is a
  /// singleton, so without this one test's saved settings leak into the next.
  @visibleForTesting
  void resetForTesting() => _ready = false;

  Future<void> init() async {
    if (_ready) return;
    _prefs = await SharedPreferences.getInstance();
    _mistakes = (_prefs.getStringList(_kMistakes) ?? []).toSet();
    _bookmarks = (_prefs.getStringList(_kBookmarks) ?? []).toSet();
    _history = (_prefs.getStringList(_kHistory) ?? [])
        .map(
          (s) => HistoryEntry.fromJson(jsonDecode(s) as Map<String, dynamic>),
        )
        .toList();
    _answeredByPart.clear();
    _indexAnswered(_prefs.getStringList(_kAnswered) ?? const []);
    final statsRaw = _prefs.getString(_kPartStats);
    if (statsRaw != null) {
      final map = jsonDecode(statsRaw) as Map<String, dynamic>;
      _partStats = map.map(
        (k, v) => MapEntry(
          int.parse(k),
          PartStat.fromJson(int.parse(k), v as Map<String, dynamic>),
        ),
      );
    }
    await _migrate();
    _ready = true;
  }

  /// Drops progress that a renumbering of the bank has made meaningless.
  ///
  /// Each side is dropped only when its own ids actually moved: revision 2
  /// re-cut the English parts, revision 3 renumbered the Khmer ones. Part ids
  /// 1-13 never changed, so Khmer part stats stay; so do lifetime totals and
  /// exam history, which record what the user actually answered.
  Future<void> _migrate() async {
    final stored = _prefs.getInt(_kBankRevision) ?? 0;
    if (stored == bankRevision) return;
    final englishMoved = stored < 2;
    final khmerMoved = stored < 3;
    bool isStale(String uid) {
      final partId = int.tryParse(uid.split('-').first);
      if (partId == null) return true;
      if (_isEnglishPart(partId)) return englishMoved;
      return partId <= 13 && khmerMoved;
    }

    if (englishMoved) {
      _partStats.removeWhere((partId, _) => _isEnglishPart(partId));
      final goal = _prefs.getInt(_kGoalPartId);
      if (goal != null && _isEnglishPart(goal)) {
        await _prefs.remove(_kGoalPartId);
      }
    }
    _mistakes.removeWhere(isStale);
    _bookmarks.removeWhere(isStale);
    // The "already answered" memory is keyed the same way, so a renumbering
    // would otherwise hide questions the user has never actually seen.
    for (final set in _answeredByPart.values) {
      set.removeWhere(isStale);
    }
    _answeredByPart.removeWhere((_, set) => set.isEmpty);
    await _saveAnswered();
    await _prefs.setStringList(_kMistakes, _mistakes.toList());
    await _prefs.setStringList(_kBookmarks, _bookmarks.toList());
    await _prefs.setString(
      _kPartStats,
      jsonEncode(_partStats.map((k, v) => MapEntry(k.toString(), v.toJson()))),
    );
    await _prefs.setInt(_kBankRevision, bankRevision);
  }

  // ---- Streak -------------------------------------------------------
  int get streak => _prefs.getInt(_kStreak) ?? 0;

  DateTime? get lastStudyDate {
    final s = _prefs.getString(_kLastStudyDate);
    return s == null ? null : DateTime.tryParse(s);
  }

  void _touchStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = lastStudyDate;
    if (last == null) {
      _prefs.setInt(_kStreak, 1);
    } else {
      final lastDay = DateTime(last.year, last.month, last.day);
      final diff = today.difference(lastDay).inDays;
      if (diff == 0) {
        // already studied today, no change
      } else if (diff == 1) {
        _prefs.setInt(_kStreak, streak + 1);
      } else {
        _prefs.setInt(_kStreak, 1);
      }
    }
    _prefs.setString(_kLastStudyDate, today.toIso8601String());
  }

  // ---- Profile --------------------------------------------------------
  String get displayName =>
      _prefs.getString(_kDisplayName) ?? 'ត្រៀមប្រឡងចំណេះដឹងទូទៅ';
  Future<void> setDisplayName(String name) =>
      _prefs.setString(_kDisplayName, name);

  int? get goalPartId => _prefs.getInt(_kGoalPartId);
  Future<void> setGoalPartId(int? id) async {
    if (id == null) {
      await _prefs.remove(_kGoalPartId);
    } else {
      await _prefs.setInt(_kGoalPartId, id);
    }
  }

  // ---- Appearance -------------------------------------------------------
  bool get isDarkMode => _prefs.getBool(_kDarkMode) ?? false;
  Future<void> setDarkMode(bool value) => _prefs.setBool(_kDarkMode, value);

  // ---- Sound ------------------------------------------------------------
  bool get soundEnabled => _prefs.getBool(_kSoundEnabled) ?? true;
  Future<void> setSoundEnabled(bool value) =>
      _prefs.setBool(_kSoundEnabled, value);

  double get soundVolume =>
      (_prefs.getDouble(_kSoundVolume) ?? 0.7).clamp(0.0, 1.0).toDouble();
  Future<void> setSoundVolume(double value) =>
      _prefs.setDouble(_kSoundVolume, value);

  // ---- Mistakes notebook ----------------------------------------------
  Set<String> get mistakeUids => _mistakes;

  Future<void> clearMistake(String uid) async {
    _mistakes.remove(uid);
    await _prefs.setStringList(_kMistakes, _mistakes.toList());
  }

  Future<void> clearAllMistakes() async {
    _mistakes.clear();
    await _prefs.setStringList(_kMistakes, []);
  }

  // ---- Bookmarks --------------------------------------------------------
  Set<String> get bookmarkUids => _bookmarks;
  bool isBookmarked(String uid) => _bookmarks.contains(uid);

  Future<void> toggleBookmark(String uid) async {
    if (_bookmarks.contains(uid)) {
      _bookmarks.remove(uid);
    } else {
      _bookmarks.add(uid);
    }
    await _prefs.setStringList(_kBookmarks, _bookmarks.toList());
  }

  // ---- Already-answered memory -----------------------------------------
  //
  // A session must never hand the user a question they have already answered:
  // asking for 50 more questions in a 200-question subject after finishing 50
  // of them has to draw from the 150 that are left, not from all 200 again.
  // Every question the user answers is recorded here the moment they pick an
  // option, so the memory survives quitting a session halfway through, and
  // the pool for the next session is built by subtracting it from the bank.

  static int? _partIdOf(String uid) => int.tryParse(uid.split('-').first);

  void _indexAnswered(Iterable<String> uids) {
    for (final uid in uids) {
      final partId = _partIdOf(uid);
      if (partId == null) continue;
      _answeredByPart.putIfAbsent(partId, () => <String>{}).add(uid);
    }
  }

  Future<void> _saveAnswered() => _prefs.setStringList(
    _kAnswered,
    [for (final set in _answeredByPart.values) ...set],
  );

  /// The uids answered in [partId]. Empty - never null - for a fresh subject.
  Set<String> answeredIn(int partId) =>
      _answeredByPart[partId] ?? const <String>{};

  /// How many questions of [partId] have been answered at least once.
  int answeredCountIn(int partId) => _answeredByPart[partId]?.length ?? 0;

  bool hasAnswered(String uid) {
    final partId = _partIdOf(uid);
    return partId != null && (_answeredByPart[partId]?.contains(uid) ?? false);
  }

  /// Total answered uids across every part - the whole memory, flattened.
  int get answeredQuestionCount =>
      _answeredByPart.values.fold(0, (sum, set) => sum + set.length);

  /// Remembers that these questions have now been answered. Idempotent:
  /// answering the same question again (from the mistakes notebook, say)
  /// changes nothing and writes nothing.
  Future<void> markAnswered(Iterable<String> uids) async {
    var changed = false;
    for (final uid in uids) {
      final partId = _partIdOf(uid);
      if (partId == null) continue;
      if (_answeredByPart.putIfAbsent(partId, () => <String>{}).add(uid)) {
        changed = true;
      }
    }
    if (!changed) return;
    await _saveAnswered();
  }

  /// Forgets the answered questions of [partIds], putting those subjects back
  /// to a full pool. Used when a subject has been exhausted and the user
  /// chooses to go round again. Returns how many uids were forgotten.
  Future<int> resetAnswered(Iterable<int> partIds) async {
    var removed = 0;
    for (final partId in partIds) {
      removed += _answeredByPart.remove(partId)?.length ?? 0;
    }
    if (removed > 0) await _saveAnswered();
    return removed;
  }

  /// Forgets the answered questions of every subject at once. Accuracy,
  /// history and the mistakes notebook are deliberately left alone: this only
  /// reopens the pool, it does not erase what the user has achieved.
  Future<void> resetAllAnswered() async {
    if (_answeredByPart.isEmpty) return;
    _answeredByPart.clear();
    await _saveAnswered();
  }

  // ---- History & stats --------------------------------------------------
  List<HistoryEntry> get history => List.unmodifiable(_history.reversed);
  Map<int, PartStat> get partStats => _partStats;

  int get totalAnswered => _prefs.getInt(_kTotalAnswered) ?? 0;
  int get totalCorrect => _prefs.getInt(_kTotalCorrect) ?? 0;
  double get overallAccuracy =>
      totalAnswered == 0 ? 0 : totalCorrect / totalAnswered;

  PartStat statFor(int partId) =>
      _partStats[partId] ?? PartStat(partId: partId, answered: 0, correct: 0);

  /// Call once when an exam/practice session finishes.
  Future<void> recordResult(ExamResult result) async {
    // Never serve these again: the live marking in the quiz screen has
    // normally done this already, but a session finished by the timer running
    // out can submit answers that were never tapped through this path.
    await markAnswered(
      result.attempts.where((a) => a.isAnswered).map((a) => a.question.uid),
    );

    // mistakes / mastery per question
    for (final a in result.attempts) {
      if (!a.isAnswered) continue;
      if (a.isCorrect) {
        _mistakes.remove(a.question.uid);
      } else {
        _mistakes.add(a.question.uid);
      }
    }
    await _prefs.setStringList(_kMistakes, _mistakes.toList());

    // per-part stats
    result.byPart.forEach((partId, breakdown) {
      final current = statFor(partId);
      _partStats[partId] = current.addResult(
        answeredDelta: breakdown.total,
        correctDelta: breakdown.correct,
      );
    });
    await _prefs.setString(
      _kPartStats,
      jsonEncode(_partStats.map((k, v) => MapEntry(k.toString(), v.toJson()))),
    );

    // totals
    final answeredNow = result.attempts.where((a) => a.isAnswered).length;
    await _prefs.setInt(_kTotalAnswered, totalAnswered + answeredNow);
    await _prefs.setInt(_kTotalCorrect, totalCorrect + result.correctCount);

    // history (cap at 60 entries)
    final entry = HistoryEntry(
      date: result.completedAt,
      mode: result.config.mode,
      total: result.total,
      correct: result.correctCount,
      timeSpentSec: result.timeSpent.inSeconds,
      partIds: result.byPart.keys.toList(),
    );
    _history.add(entry);
    if (_history.length > 60) {
      _history = _history.sublist(_history.length - 60);
    }
    await _prefs.setStringList(
      _kHistory,
      _history.map((e) => jsonEncode(e.toJson())).toList(),
    );

    _touchStreak();
  }

  /// A 0-100 heuristic "exam readiness" score blending accuracy, coverage
  /// breadth across the subjects that have questions, and recent activity.
  double readinessIndex(int totalPartsWithData) {
    if (totalAnswered == 0) return 0;
    final accuracyScore = overallAccuracy.clamp(0, 1) * 65;
    final coveredParts = _partStats.values
        .where((s) => s.answered >= 10)
        .length;
    final coverageScore = totalPartsWithData == 0
        ? 0
        : (coveredParts / totalPartsWithData).clamp(0, 1) * 25;
    final volumeScore = (totalAnswered / 300).clamp(0, 1) * 10;
    return (accuracyScore + coverageScore + volumeScore)
        .clamp(0, 100)
        .toDouble();
  }
}
