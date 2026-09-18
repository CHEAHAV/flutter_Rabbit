import 'question.dart';

/// Mutable per-question state during a live exam/practice session.
class QuestionAttempt {
  final Question question;
  int? selectedIndex;
  bool flagged;

  QuestionAttempt({
    required this.question,
    this.selectedIndex,
    this.flagged = false,
  });

  bool get isAnswered => selectedIndex != null;
  bool get isCorrect =>
      selectedIndex != null && selectedIndex == question.answerIndex;
}
