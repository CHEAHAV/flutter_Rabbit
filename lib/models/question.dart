import '../utils/khmer_numerals.dart';

/// A single multiple-choice question with 4 options, or 5 for the English
/// parts, whose source book uses an A-E answer key.
///
/// [optionLabels] carries the alphabet the options are lettered with, so the
/// Khmer question bank keeps ក / ខ / គ / ឃ while the English parts keep the
/// A / B / C / D / E of the book they were taken from. It always has at least
/// as many entries as [options].
class Question {
  final int id;
  final int partId;
  final String text;
  final List<String> options;
  final int answerIndex;
  final List<String> optionLabels;

  const Question({
    required this.id,
    required this.partId,
    required this.text,
    required this.options,
    required this.answerIndex,
    this.optionLabels = khmerOptionLabels,
  }) : assert(
         options.length == 4 || options.length == 5,
         'Every question must have 4 or 5 options',
       ),
       assert(
         answerIndex >= 0 && answerIndex < options.length,
         'answerIndex must point at one of the options',
       );

  /// Globally unique key across all parts, used for progress tracking.
  String get uid => '$partId-$id';

  String get correctOptionText => options[answerIndex];

  /// The letter shown next to option [i] - ក/ខ/គ/ឃ or A/B/C/D/E.
  String labelAt(int i) => optionLabels[i];

  factory Question.fromJson(
    Map<String, dynamic> json,
    int partId, {
    List<String> optionLabels = khmerOptionLabels,
  }) {
    final rawOptions = (json['o'] as List).map((e) => e.toString()).toList();
    return Question(
      id: json['id'] as int,
      partId: partId,
      text: json['q'] as String,
      options: List<String>.from(rawOptions),
      answerIndex: json['a'] as int,
      optionLabels: optionLabels,
    );
  }
}
