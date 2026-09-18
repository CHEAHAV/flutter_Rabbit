import 'dart:convert';

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

  late SharedPreferences _prefs;
  bool _ready = false;

  Set<String> _mistakes = {};
  Set<String> _bookmarks = {};
  List<HistoryEntry> _history = [];
  Map<int, PartStat> _partStats = {};

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
    _ready = true;
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
      _prefs.getString(_kDisplayName) ?? 'សិស្សត្រៀមប្រឡង';
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
  /// breadth across the 13 parts, and recent activity.
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
