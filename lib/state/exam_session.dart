import 'dart:async';
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

  ExamSession({required this.config, required List<Question> questions})
      : attempts = questions.map((q) => QuestionAttempt(question: q)).toList() {
    remaining = config.timeLimit;
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  QuestionAttempt get current => attempts[currentIndex];
  int get total => attempts.length;
  int get answeredCount => attempts.where((a) => a.isAnswered).length;
  int get flaggedCount => attempts.where((a) => a.flagged).length;
  bool get isLast => currentIndex == total - 1;
  bool get isFirst => currentIndex == 0;

  bool get lowTime =>
      remaining != null && remaining!.inSeconds > 0 && remaining!.inSeconds <= 5 * 60;

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

  void toggleFlag() {
    current.flagged = !current.flagged;
    notifyListeners();
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
