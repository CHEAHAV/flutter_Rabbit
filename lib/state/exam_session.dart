import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/exam_config.dart';
import '../models/exam_result.dart';
import '../models/question.dart';
import '../models/question_attempt.dart';

/// Drives a single live practice/exam run: countdown timer, question
/// navigation, answer selection and flagging. One instance per session.
class ExamSession extends ChangeNotifier {
  final ExamConfig config;
  final List<QuestionAttempt> attempts;
  int currentIndex = 0;
  Duration? remaining;
  Duration elapsed = Duration.zero;
  bool timeExpired = false;
  bool _alertShown = false;
  Timer? _timer;

  /// Every question's options are dealt in a fresh random order when the
  /// session opens (see [Question.withShuffledOptions]), so the correct answer
  /// is not always in the slot it had last time. The order is fixed for the
  /// life of the session: paging back to a question, and the review screen
  /// afterwards, show it exactly as it was answered.
  ExamSession({
    required this.config,
    required List<Question> questions,
    Random? random,
  }) : attempts = _deal(questions, random ?? Random()) {
    remaining = config.timeLimit;
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  static List<QuestionAttempt> _deal(List<Question> questions, Random rng) => [
    for (final q in questions)
      QuestionAttempt(question: q.withShuffledOptions(rng)),
  ];

  QuestionAttempt get current => attempts[currentIndex];
  int get total => attempts.length;
  int get answeredCount => attempts.where((a) => a.isAnswered).length;
  int get flaggedCount => attempts.where((a) => a.flagged).length;
  bool get isLast => currentIndex == total - 1;
  bool get isFirst => currentIndex == 0;

  bool get lowTime =>
      remaining != null &&
      remaining!.inSeconds > 0 &&
      remaining!.inSeconds <= 5 * 60;

  void _tick(Timer t) {
    elapsed += const Duration(seconds: 1);
    if (remaining != null) {
      final next = remaining! - const Duration(seconds: 1);
      remaining = next.isNegative ? Duration.zero : next;
      if (remaining!.inSeconds == 5 * 60 && !_alertShown) {
        _alertShown = true;
        onLowTimeWarning?.call();
      }
      if (remaining!.inSeconds <= 0) {
        timeExpired = true;
        t.cancel();
        onTimeExpired?.call();
      }
    }
    notifyListeners();
  }

  VoidCallback? onTimeExpired;
  VoidCallback? onLowTimeWarning;

  void selectOption(int index) {
    current.selectedIndex = index;
    notifyListeners();
  }

  /// Marks the question [uid] as saved or not saved.
  ///
  /// Addressed by uid rather than by "the current question" on purpose: the
  /// save is written to the notebook first and only then reflected here, and by
  /// the time that write lands - or when an undo fires from a snackbar - the
  /// user may already have moved on to another question.
  ///
  /// The quiz screen drives this from the persisted notebook rather than
  /// flipping the flag on its own, so the save button, the gold squares in the
  /// question grid and the saved list in the notebook can never disagree.
  /// Listeners are notified even when nothing moved, because the button reads
  /// the notebook and it is the rebuild that shows the change.
  void setFlagFor(String uid, bool flagged) {
    for (final a in attempts) {
      if (a.question.uid == uid) a.flagged = flagged;
    }
    notifyListeners();
  }

  /// Marks the attempts whose question [isSaved] says is already in the
  /// notebook. Called once when the session opens, so re-meeting a question
  /// the user saved earlier shows up as saved from the first frame.
  void syncFlags(bool Function(String uid) isSaved) {
    var changed = false;
    for (final a in attempts) {
      final saved = isSaved(a.question.uid);
      if (a.flagged != saved) {
        a.flagged = saved;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void goTo(int index) {
    if (index < 0 || index >= total) return;
    currentIndex = index;
    notifyListeners();
  }

  void next() {
    if (currentIndex < total - 1) {
      currentIndex++;
      notifyListeners();
    }
  }

  void prev() {
    if (currentIndex > 0) {
      currentIndex--;
      notifyListeners();
    }
  }

  ExamResult finish() {
    _timer?.cancel();
    return ExamResult(
      completedAt: DateTime.now(),
      config: config,
      attempts: attempts,
      timeSpent: elapsed,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
