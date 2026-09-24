import 'dart:math';

import '../utils/khmer_numerals.dart';

/// A single multiple-choice question with 4 options, or up to 6 where the
/// source prints more: the English book uses an A-E answer key, and a few
/// Khmer questions in QCM.pdf run to ង or ច.
///
/// [optionLabels] carries the alphabet the source letters its options with -
/// ក / ខ / គ / ឃ for the Khmer bank, A / B / C / D / E for the English book. The
/// app no longer shows these letters (options are shuffled per session), but
/// the Khmer ones are still how "ចម្លើយ ក និង ខ" is resolved when the question
/// is loaded. It always has at least as many entries as [options].
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
         options.length >= 4 && options.length <= 6,
         'Every question must have between 4 and 6 options',
       ),
       assert(
         answerIndex >= 0 && answerIndex < options.length,
         'answerIndex must point at one of the options',
       );

  /// Globally unique key across all parts, used for progress tracking.
  String get uid => '$partId-$id';

  String get correctOptionText => options[answerIndex];

  /// This question with every option that names other options by letter -
  /// "ចម្លើយ ក និង ខ", "ខ និង គ", "ទាំងអស់ចំណុច (ក ខ និង គ) ខាងលើ" - rewritten to
  /// say what it means in words, so no option depends on a letter.
  ///
  /// The app shows no ក/ខ/គ/ឃ or A-E and shuffles the options every session,
  /// which would leave "ក និង ខ" pointing at nothing. The referenced options
  /// are spelled out instead ("បញ្ញត្តិ និង ប្រតិបត្តិ"). When that would run
  /// long and the option covers every ordinary option printed above it, it
  /// becomes the bank's usual "ចម្លើយខាងលើត្រឹមត្រូវទាំងអស់" (or
  /// "...មិនត្រឹមត្រូវទាំងអស់"), which stays in its slot when shuffled.
  ///
  /// Only the in-memory question changes; the JSON keeps the text of QCM.pdf.
  /// An option whose letters do not resolve to other options is left as is.
  Question withLetterReferencesSpelledOut() {
    final refs = [for (final o in options) _referencesOptionLetters(o)];
    if (!refs.contains(true)) return this;
    final ordinary = [
      for (var i = 0; i < options.length; i++)
        if (!refs[i] && !_isSummaryOption(options[i])) i,
    ];
    final out = List<String>.from(options);
    for (var i = 0; i < options.length; i++) {
      if (!refs[i]) continue;
      final named = <int>{
        for (final m in _letterToken.allMatches(options[i]))
          khmerOptionLabels.indexOf(m.group(1)!),
      }.toList()..sort();
      if (named.isEmpty ||
          named.any((n) => n < 0 || n >= options.length || refs[n])) {
        continue;
      }
      final negative = options[i].contains('មិន');
      final spelled = _joinKhmer([for (final n in named) options[n].trim()]);
      final coversAllAbove =
          named.length == ordinary.length &&
          named.every(ordinary.contains) &&
          ordinary.every((n) => n < i);
      if (coversAllAbove && (negative || spelled.length > _maxSpelledLength)) {
        out[i] = negative
            ? 'ចម្លើយខាងលើមិនត្រឹមត្រូវទាំងអស់'
            : 'ចម្លើយខាងលើត្រឹមត្រូវទាំងអស់';
      } else {
        out[i] = negative ? '$spelled មិនត្រឹមត្រូវ' : spelled;
      }
    }
    return Question(
      id: id,
      partId: partId,
      text: text,
      options: out,
      answerIndex: answerIndex,
      optionLabels: optionLabels,
    );
  }

  /// Past this many characters a spelled-out "ក និង ខ" reads worse than
  /// "ចម្លើយខាងលើត្រឹមត្រូវទាំងអស់", when that says the same thing.
  static const _maxSpelledLength = 70;

  /// "A និង B", or "A, B និង C" for three or more.
  static String _joinKhmer(List<String> parts) => parts.length == 1
      ? parts.single
      : '${parts.sublist(0, parts.length - 1).join(', ')} និង ${parts.last}';

  /// This question with its options in a random order and [answerIndex]
  /// moved to follow the correct option, so the answer is never in a
  /// predictable place.
  ///
  /// An "all/none of the above" option stays in its own slot - it reads
  /// against the options printed before it - and the rest shuffle around it.
  /// The id and part are kept, so [uid] (progress, saved questions) is the
  /// same.
  Question withShuffledOptions(Random rng) {
    final pinned = [for (var i = 0; i < options.length; i++) isPinned(i)];
    final free = [
      for (var i = 0; i < options.length; i++)
        if (!pinned[i]) i,
    ];
    final shuffledFree = List<int>.from(free)..shuffle(rng);
    // order[newSlot] = the original index shown in that slot.
    final order = List<int>.generate(options.length, (i) => i);
    for (var k = 0; k < free.length; k++) {
      order[free[k]] = shuffledFree[k];
    }
    return Question(
      id: id,
      partId: partId,
      text: text,
      options: [for (final i in order) options[i]],
      answerIndex: order.indexOf(answerIndex),
      optionLabels: optionLabels,
    );
  }

  /// Whether option [i] keeps its slot when the options are shuffled - an
  /// "all / none of the above" that only reads right below the others.
  bool isPinned(int i) => _isSummaryOption(options[i]);

  static const _letter = '[កខគឃងច]';

  /// A lone option letter, captured in group 1: not followed by a vowel sign
  /// (so "ចម្លើយខាងលើ" is not read as "ចម្លើយ ខ"), and set off by a space,
  /// comma, bracket or a preceding "និង".
  static final _letterToken = RegExp(
    r'(?:^|[\s,(]|និង)(' + _letter + r')(?=$|[\s,)])',
  );

  /// An option made only of letters joined with "និង", like "ខ និង គ".
  static final _letterList = RegExp(
    r'^\s*' +
        _letter +
        r'(?:\s*(?:,|និង)\s*' +
        _letter +
        r')*\s*និង\s*' +
        _letter +
        r'\s*$',
  );

  /// Whether [option] names other options by letter, as in "ចម្លើយ ក និង ខ"
  /// or "ខ និង គ" - as opposed to content that merely contains a letter, like
  /// "ក, ខ, គ" as the names of civil-service categories.
  static bool _referencesOptionLetters(String option) =>
      ((option.contains('ចម្លើយ') || option.contains('ចំណុច')) &&
          _letterToken.hasMatch(option)) ||
      _letterList.hasMatch(option);

  static final _summary = RegExp(
    r'ខាងលើ'
    r'|^(?:មិនមាន|គ្មាន)ចម្លើយ'
    r'|^ចម្លើយ.*ត្រូវ'
    r'|^(?:ត្រឹមត្រូវ|មិនត្រូវ|មិនត្រឹមត្រូវ|ខុស|ត្រូវ)ទាំងអស់$'
    r'|\b(?:all|none|both|neither) of the above\b',
    caseSensitive: false,
  );

  /// "All of the above", "ចម្លើយខាងលើត្រឹមត្រូវទាំងអស់", "គ្មានចម្លើយត្រឹមត្រូវ"
  /// and the like - options that sum up the others rather than stand alone.
  static bool _isSummaryOption(String option) =>
      _summary.hasMatch(option.trim());

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
