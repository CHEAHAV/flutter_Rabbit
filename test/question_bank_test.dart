import 'package:flutter_test/flutter_test.dart';
import 'package:rabbit/data/question_repository.dart';
import 'package:rabbit/models/exam_part.dart';
import 'package:rabbit/utils/khmer_numerals.dart';

/// Loads every bundled part through the real repository and checks that the
/// data the app will actually read is well formed. Parts 14-24 are extracted
/// from assets/pdf/grammar.pdf, so this is what keeps a bad extraction from
/// reaching the quiz screen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late final QuestionRepository repo;

  setUpAll(() async {
    repo = QuestionRepository.instance;
    await repo.load();
  });

  test('every part in the catalog loads with questions', () {
    expect(repo.parts.length, ExamPart.catalog.length);
    for (final part in repo.parts) {
      expect(part.count, greaterThan(0), reason: 'part ${part.id} is empty');
    }
  });

  test('every question is well formed', () {
    for (final part in repo.parts) {
      for (final q in part.questions) {
        final where = 'part ${part.id} question ${q.id}';
        expect(q.text.trim(), isNotEmpty, reason: where);
        expect(
          q.options.length,
          anyOf(4, 5),
          reason: '$where has ${q.options.length} options',
        );
        expect(
          q.optionLabels.length,
          greaterThanOrEqualTo(q.options.length),
          reason: '$where has fewer labels than options',
        );
        for (final o in q.options) {
          expect(o.trim(), isNotEmpty, reason: '$where has a blank option');
        }
        expect(q.answerIndex, inInclusiveRange(0, q.options.length - 1),
            reason: '$where points outside its options');
      }
    }
  });

  test('the English parts never repeat an option within a question', () {
    // Scoped to parts 14-24: four questions in the older Khmer parts (5, 6
    // and 8) do print the same option twice, and those files are left as they
    // are.
    for (final part in repo.parts.where((p) => p.id >= 14)) {
      for (final q in part.questions) {
        expect(
          q.options.map((o) => o.toLowerCase()).toSet().length,
          q.options.length,
          reason: 'part ${part.id} question ${q.id} repeats an option',
        );
      }
    }
  });

  test('question uids are unique across the whole bank', () {
    final seen = <String>{};
    for (final part in repo.parts) {
      for (final q in part.questions) {
        expect(seen.add(q.uid), isTrue, reason: 'duplicate uid ${q.uid}');
      }
    }
  });

  test('the Khmer parts keep ក/ខ/គ/ឃ and the English parts use A/B/C/D/E', () {
    for (final part in repo.parts) {
      final expected = part.id >= 14 ? latinOptionLabels : khmerOptionLabels;
      expect(
        part.questions.first.optionLabels,
        same(expected),
        reason: 'part ${part.id} is lettered with the wrong alphabet',
      );
      // Only the English parts were allowed to bring 5-option questions in.
      if (part.id < 14) {
        expect(
          part.questions.every((q) => q.options.length == 4),
          isTrue,
          reason: 'part ${part.id} changed shape',
        );
      }
    }
  });

  test('the English parts carry the expected volume', () {
    // One part per part of grammar.pdf: Book 1 Parts A-E, Book 2 Parts A-E and
    // Book 3. The floors are set a little under what the extractor currently
    // produces, so an extraction that silently loses a test fails here.
    const floors = {
      14: 1500, // Book 1 Part A
      15: 2200, // Book 1 Part B
      16: 1000, // Book 1 Part C
      17: 1800, // Book 1 Part D
      18: 800, // Book 1 Part E
      19: 650, // Book 2 Part A
      20: 350, // Book 2 Part B
      21: 130, // Book 2 Part C
      22: 900, // Book 2 Part D
      23: 450, // Book 2 Part E
      24: 200, // Book 3
    };
    for (final entry in floors.entries) {
      expect(
        repo.partById(entry.key).count,
        greaterThan(entry.value),
        reason: 'part ${entry.key} lost questions',
      );
    }
    final total = floors.keys.fold(0, (s, id) => s + repo.partById(id).count);
    expect(total, greaterThan(10000), reason: 'the English bank shrank');
  });

  test('no English part is big enough to need splitting again', () {
    // The whole point of parts 14-24 is that a book is never loaded as one
    // slab. If a part ever grows past this, the book division has been lost.
    for (final part in repo.parts.where((p) => p.id >= 14)) {
      expect(
        part.count,
        lessThan(3000),
        reason: 'part ${part.id} holds ${part.count} questions',
      );
    }
  });

  test('the catalog and the bundled data files line up', () {
    // part N in the catalog must be assets/data/part_NN.json: an off-by-one
    // here would letter Khmer questions A-E and English ones with Khmer glyphs.
    expect(ExamPart.catalog.length, 24);
    for (var i = 0; i < ExamPart.catalog.length; i++) {
      final isEnglish = i + 1 >= 14;
      expect(
        ExamPart.catalog[i]['labels'] == 'latin',
        isEnglish,
        reason: 'catalog entry ${i + 1} has the wrong label alphabet',
      );
    }
  });
}
