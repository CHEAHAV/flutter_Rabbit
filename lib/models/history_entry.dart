import 'exam_config.dart';

class HistoryEntry {
  final DateTime date;
  final ExamMode mode;
  final int total;
  final int correct;
  final int timeSpentSec;
  final List<int> partIds;

  HistoryEntry({
    required this.date,
    required this.mode,
    required this.total,
    required this.correct,
    required this.timeSpentSec,
    required this.partIds,
  });

  double get percent => total == 0 ? 0 : correct / total * 100;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'mode': mode.name,
    'total': total,
    'correct': correct,
    'time': timeSpentSec,
    'parts': partIds,
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    date: DateTime.parse(json['date'] as String),
    mode: (json['mode'] as String) == 'mock'
        ? ExamMode.mock
        : ExamMode.practice,
    total: json['total'] as int,
    correct: json['correct'] as int,
    timeSpentSec: json['time'] as int,
    partIds: (json['parts'] as List).map((e) => e as int).toList(),
  );
}

class PartStat {
  final int partId;
  final int answered;
  final int correct;
  const PartStat({
    required this.partId,
    required this.answered,
    required this.correct,
  });
  double get accuracy => answered == 0 ? 0 : correct / answered;

  Map<String, dynamic> toJson() => {'answered': answered, 'correct': correct};

  factory PartStat.fromJson(int partId, Map<String, dynamic> json) => PartStat(
    partId: partId,
    answered: json['answered'] as int,
    correct: json['correct'] as int,
  );

  PartStat addResult({required int answeredDelta, required int correctDelta}) =>
      PartStat(
        partId: partId,
        answered: answered + answeredDelta,
        correct: correct + correctDelta,
      );
}
