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

  /// Parts below this are the Khmer civil-service bank, which has never been
  /// renumbered; everything from here up is the English bank.
  static const _firstEnglishPart = 14;

  late SharedPreferences _prefs;
  bool _ready = false;

  Set<String> _mistakes = {};
  Set<String> _bookmarks = {};
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
      return partId >= _firstEnglishPart ? englishMoved : khmerMoved;
    }

    if (englishMoved) {
      _partStats.removeWhere((partId, _) => partId >= _firstEnglishPart);
      final goal = _prefs.getInt(_kGoalPartId);
      if (goal != null && goal >= _firstEnglishPart) {
        await _prefs.remove(_kGoalPartId);
      }
    }
    _mistakes.removeWhere(isStale);
    _bookmarks.removeWhere(isStale);
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
