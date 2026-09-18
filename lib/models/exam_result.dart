import 'exam_config.dart';
import 'question_attempt.dart';

class PartBreakdown {
  final int partId;
  final int total;
  final int correct;
  PartBreakdown({required this.partId, required this.total, required this.correct});
  double get percent => total == 0 ? 0 : correct / total;
}

class ExamResult {
  final DateTime completedAt;
  final ExamConfig config;
  final List<QuestionAttempt> attempts;
  final Duration timeSpent;

  ExamResult({
    required this.completedAt,
    required this.config,
    required this.attempts,
    required this.timeSpent,
  });

  int get total => attempts.length;
  int get correctCount => attempts.where((a) => a.isCorrect).length;
  int get wrongCount => attempts.where((a) => a.isAnswered && !a.isCorrect).length;
  int get skippedCount => attempts.where((a) => !a.isAnswered).length;

  double get scorePercent => total == 0 ? 0 : (correctCount / total) * 100;

  bool get passed => scorePercent >= 50;

  List<QuestionAttempt> get mistakes =>
      attempts.where((a) => a.isAnswered && !a.isCorrect).toList();

  Map<int, PartBreakdown> get byPart {
    final map = <int, List<QuestionAttempt>>{};
    for (final a in attempts) {
      map.putIfAbsent(a.question.partId, () => []).add(a);
    }
    return map.map((partId, list) => MapEntry(
          partId,
          PartBreakdown(
            partId: partId,
            total: list.length,
            correct: list.where((a) => a.isCorrect).length,
          ),
        ));
  }
}
