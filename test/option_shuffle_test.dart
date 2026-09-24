import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rabbit/data/question_repository.dart';
import 'package:rabbit/models/exam_config.dart';
import 'package:rabbit/models/question.dart';
import 'package:rabbit/state/exam_session.dart';

/// Options are dealt in a new random order every session, so the correct
/// answer is never where it was last time. These tests run the shuffle over
/// the whole bundled bank and check that it never changes which answer is
/// right - only where it sits.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late final List<Question> bank;

  setUpAll(() async {
    final repo = QuestionRepository.instance;
    await repo.load();
    bank = [for (final p in repo.parts) ...p.questions];
  });

  test('shuffling never changes which answer is correct', () {
    for (var seed = 0; seed < 5; seed++) {
      final rng = Random(seed);
      for (final q in bank) {
        final s = q.withShuffledOptions(rng);
        final where = 'question ${q.uid} (seed $seed)';
        expect(s.uid, q.uid, reason: where);
        expect(s.text, q.text, reason: where);
        expect(s.correctOptionText, q.correctOptionText, reason: where);
        expect(
          [...s.options]..sort(),
          [...q.options]..sort(),
          reason: '$where lost or duplicated an option',
        );
      }
    }
  });

  test('no option leans on a ក/ខ/គ/ឃ letter the app no longer shows', () {
    // Before loading, 21 questions in the bank had an option like
    // "ចម្លើយ ក និង ខ". Loading puts every one of them into words.
    final letterRef = RegExp(
      r'((ចម្លើយ|ចំណុច).*(?:^|[\s,(]|និង)[កខគឃងច](?=$|[\s,)]))'
      r'|^\s*[កខគឃងច]\s*និង\s*[កខគឃងច]',
    );
    for (final q in bank) {
      for (final o in q.options) {
        expect(letterRef.hasMatch(o), isFalse, reason: '${q.uid}: $o');
      }
    }

    String option(String uid, int i) =>
        bank.firstWhere((q) => q.uid == uid).options[i];
    // A pair is spelled out...
    expect(option('2-34', 3), 'ពុទ្ធសាសនា និង ព្រហ្មញ្ញសាសនា');
    expect(option('4-58', 3), 'បញ្ញត្តិ និង ប្រតិបត្តិ');
    expect(option('10-18', 2), 'កត្តាខាងក្នុង និង កត្តាខាងក្រៅ');
    // ...and a long "all of the above" becomes the bank's own wording.
    expect(option('4-36', 3), 'ចម្លើយខាងលើត្រឹមត្រូវទាំងអស់');
    expect(option('5-10', 3), 'ចម្លើយខាងលើត្រឹមត្រូវទាំងអស់');
    expect(option('9-100', 2), 'ចម្លើយខាងលើត្រឹមត្រូវទាំងអស់');
    expect(option('9-100', 3), 'ចម្លើយខាងលើមិនត្រឹមត្រូវទាំងអស់');
    // The answer key is untouched: 4-58's answer is still "ក និង ខ".
    final q458 = bank.firstWhere((q) => q.uid == '4-58');
    expect(q458.correctOptionText, 'បញ្ញត្តិ និង ប្រតិបត្តិ');
  });

  test('"all / none of the above" stays in its slot', () {
    const pinned = {
      'ចម្លើយខាងលើត្រឹមត្រូវទាំងអស់',
      'មិនមានចម្លើយណាមួយត្រឹមត្រូវ',
      'គ្មានចម្លើយត្រឹមត្រូវ',
      'ត្រឹមត្រូវទាំងអស់',
      'ខុសទាំងអស់',
    };
    var seen = 0;
    for (final q in bank) {
      for (var i = 0; i < q.options.length; i++) {
        if (!pinned.contains(q.options[i].trim())) continue;
        seen++;
        for (var seed = 0; seed < 10; seed++) {
          final s = q.withShuffledOptions(Random(seed));
          expect(s.options[i], q.options[i], reason: q.uid);
        }
      }
    }
    expect(seen, greaterThan(20));
  });

  test('ordinary options really move, and the answer lands in every slot', () {
    final rng = Random(7);
    var moved = 0;
    var total = 0;
    // When the answer itself is "all of the above" it keeps its slot on
    // purpose; the other options still move around it.
    for (final q in bank.where(
      (q) => q.options.length == 4 && !q.isPinned(q.answerIndex),
    )) {
      final slots = <int>{};
      for (var n = 0; n < 60; n++) {
        slots.add(q.withShuffledOptions(rng).answerIndex);
      }
      total++;
      if (slots.length > 1) moved++;
      if (total == 300) break;
    }
    // Every such answer changes place.
    expect(moved, total);

    final plain = bank.firstWhere(
      (q) =>
          q.options.length == 4 &&
          q.options.toSet().length == 4 &&
          !q.options.any((o) => o.contains('ចម្លើយ') || o.contains('ខាងលើ')),
    );
    final slots = {
      for (var n = 0; n < 200; n++) plain.withShuffledOptions(rng).answerIndex,
    };
    expect(slots, {0, 1, 2, 3});
  });

  test('a session deals shuffled options and marks the right one correct', () {
    final questions = bank.take(40).toList();
    final session = ExamSession(
      config: const ExamConfig(
        mode: ExamMode.practice,
        partIds: {1},
        questionCount: 40,
        timeLimit: null,
      ),
      questions: questions,
      random: Random(3),
    );
    addTearDown(session.dispose);

    var differs = 0;
    for (var i = 0; i < questions.length; i++) {
      final original = questions[i];
      final dealt = session.attempts[i].question;
      expect(dealt.uid, original.uid);
      if (dealt.answerIndex != original.answerIndex) differs++;

      // Picking the option whose text is the correct answer scores, wherever
      // the shuffle put it; any other option does not.
      session.goTo(i);
      final right = dealt.options.indexOf(original.correctOptionText);
      final wrong = right == 0 ? 1 : 0;
      session.selectOption(wrong);
      expect(session.current.isCorrect, isFalse, reason: original.uid);
      session.selectOption(right);
      expect(session.current.isCorrect, isTrue, reason: original.uid);
    }
    expect(differs, greaterThan(0));

    // Paging away and back shows the question in the order it was dealt.
    final firstOrder = session.attempts.first.question.options;
    session.goTo(5);
    session.goTo(0);
    expect(session.current.question.options, firstOrder);
  });
}
