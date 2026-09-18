/// A single multiple-choice question with exactly 4 options.
/// Options are always rendered in the app using the canonical Khmer
/// labels ក / ខ / គ / ឃ regardless of how the source material was formatted.
class Question {
  final int id;
  final int partId;
  final String text;
  final List<String> options;
  final int answerIndex;

  const Question({
    required this.id,
    required this.partId,
    required this.text,
    required this.options,
    required this.answerIndex,
  }) : assert(options.length == 4, 'Every question must have exactly 4 options');

  /// Globally unique key across all parts, used for progress tracking.
  String get uid => '$partId-$id';

  String get correctOptionText => options[answerIndex];

  factory Question.fromJson(Map<String, dynamic> json, int partId) {
    final rawOptions = (json['o'] as List).map((e) => e.toString()).toList();
    return Question(
      id: json['id'] as int,
      partId: partId,
      text: json['q'] as String,
      options: List<String>.from(rawOptions),
      answerIndex: json['a'] as int,
    );
  }
}
