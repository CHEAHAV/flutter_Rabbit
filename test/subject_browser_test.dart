// Covers the course/level browser: the bank is no longer one flat list of
// subjects but five courses, and the English courses are ordered by the level
// their questions are graded at.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rabbit/models/exam_config.dart';
import 'package:rabbit/models/exam_part.dart';
import 'package:rabbit/screens/exam_config_screen.dart';
import 'package:rabbit/screens/mock_screen.dart';
import 'package:rabbit/screens/practice_screen.dart';
import 'package:rabbit/screens/quiz_session_screen.dart';
import 'package:rabbit/state/app_state.dart';
import 'package:rabbit/theme/app_theme.dart';
import 'package:rabbit/widgets/level_chip.dart';
import 'package:rabbit/widgets/subject_tile.dart';
import 'package:rabbit/widgets/track_header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppState> boot(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState();
    await tester.runAsync(app.bootstrap);
    return app;
  }

  Future<void> pump(WidgetTester tester, AppState app, Widget child) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: app,
        child: MaterialApp(theme: AppTheme.light(), home: child),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
  }

  /// Drags the page to the bottom, capturing what the browser showed on the
  /// way. Rows scrolled past are disposed, so a single look at the end would
  /// miss most of them.
  Future<({Set<String> subjects, Set<PartTrack> tracks, List<PartTrack> order})>
  browse(WidgetTester tester) async {
    final subjects = <String>{};
    final order = <PartTrack>[];
    void capture() {
      for (final tile in tester.widgetList<SubjectTile>(
        find.byType(SubjectTile),
      )) {
        subjects.add(tile.part.titleKm);
      }
      // Dragging downwards, so headings are met in the order they are laid
      // out: keeping them in a list is what lets a test check that order.
      for (final header in tester.widgetList<TrackHeader>(
        find.byType(TrackHeader),
      )) {
        if (!order.contains(header.track)) order.add(header.track);
      }
    }

    capture();
    for (var i = 0; i < 40; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await tester.pump(const Duration(milliseconds: 40));
      capture();
    }
    return (subjects: subjects, tracks: order.toSet(), order: order);
  }

  /// Brings a chip into view before tapping it - the course switcher sits
  /// below the hero card, off screen on a phone.
  Future<void> tapChip(WidgetTester tester, String label) async {
    // Back to the top first: scrollUntilVisible only ever scrolls forward, so
    // a chip above the current position would never be found.
    for (var i = 0; i < 40; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 400));
      await tester.pump(const Duration(milliseconds: 20));
    }
    final chip = find.widgetWithText(ChoiceChip, label);
    await tester.scrollUntilVisible(chip, 120, maxScrolls: 60);
    await tester.ensureVisible(chip);
    await tester.pump();
    await tester.tap(chip);
    await tester.pump(const Duration(milliseconds: 250));
  }

  testWidgets('the practice browser groups subjects under their course', (
    tester,
  ) async {
    final app = await boot(tester);
    await pump(tester, app, const Scaffold(body: PracticeScreen()));
    final seen = await browse(tester);

    // Every course the bank has questions for got a heading of its own, and
    // every subject that has questions was reachable under one of them.
    expect(seen.tracks, containsAll(app.tracks));
    expect(
      seen.subjects,
      containsAll(app.partsWithQuestions.map((p) => p.titleKm)),
    );
  });

  testWidgets('the Khmer courses are listed before the English ones', (
    tester,
  ) async {
    final app = await boot(tester);
    await pump(tester, app, const Scaffold(body: PracticeScreen()));
    final seen = await browse(tester);

    expect(
      seen.order,
      app.tracks,
      reason: 'the browser shows courses in the order PartTrack declares them',
    );
    expect(
      seen.order.indexOf(PartTrack.teaching),
      lessThan(seen.order.indexOf(PartTrack.grammar)),
      reason: 'the teacher syllabus is a Khmer exam: it belongs above English, '
          'not below it because its data file happens to be part 27',
    );
  });

  testWidgets('a course chip narrows the browser to that course alone', (
    tester,
  ) async {
    final app = await boot(tester);
    await pump(tester, app, const Scaffold(body: PracticeScreen()));

    final grammarTitles = app
        .partsIn(PartTrack.grammar)
        .map((p) => p.titleKm)
        .toSet();
    final khmerTitles = app
        .partsIn(PartTrack.civilService)
        .map((p) => p.titleKm)
        .toSet();

    await tapChip(tester, PartTrack.grammar.titleKm);
    final seen = await browse(tester);

    expect(
      seen.subjects,
      containsAll(grammarTitles),
      reason: 'every grammar level should still be reachable',
    );
    expect(
      seen.subjects.intersection(khmerTitles),
      isEmpty,
      reason: 'the other courses are filtered out',
    );
    expect(
      seen.tracks,
      {PartTrack.grammar},
      reason: 'only the chosen course keeps its heading',
    );

    // And the filter is reversible.
    await tapChip(tester, 'គ្រប់វគ្គសិក្សា');
    final all = await browse(tester);
    expect(all.tracks, containsAll(app.tracks));
  });

  testWidgets('English subjects show their level, Khmer subjects do not', (
    tester,
  ) async {
    final app = await boot(tester);
    await pump(tester, app, const Scaffold(body: PracticeScreen()));

    final grammar = app.partsIn(PartTrack.grammar).first;
    final khmer = app.partsIn(PartTrack.civilService).first;

    Finder chipIn(ExamPart part) => find.descendant(
      of: find.ancestor(
        of: find.text(part.titleKm),
        matching: find.byType(SubjectTile),
      ),
      matching: find.byType(LevelChip),
    );

    await tester.scrollUntilVisible(
      find.text(khmer.titleKm),
      120,
      maxScrolls: 60,
    );
    expect(chipIn(khmer), findsNothing);

    await tester.scrollUntilVisible(
      find.text(grammar.titleKm),
      160,
      maxScrolls: 80,
    );
    expect(chipIn(grammar), findsOneWidget);
    expect(
      tester.widget<LevelChip>(chipIn(grammar)).level,
      PartLevel.elementary,
      reason: 'the grammar course opens on its easiest rung',
    );
  });

  testWidgets('exam config takes a whole course in or out in one tap', (
    tester,
  ) async {
    final app = await boot(tester);
    await pump(tester, app, const ExamConfigScreen(mode: ExamMode.mock));

    final grammarIds = app
        .partsIn(PartTrack.grammar)
        .where((p) => p.count > 0)
        .map((p) => p.id)
        .toSet();
    final khmerIds = app
        .partsIn(PartTrack.civilService)
        .where((p) => p.count > 0)
        .map((p) => p.id)
        .toSet();

    Set<int> selected() => tester
        .widgetList<SubjectTile>(find.byType(SubjectTile))
        .where((t) => t.selected)
        .map((t) => t.part.id)
        .toSet();

    final header = find.ancestor(
      of: find.text(PartTrack.grammar.titleKm),
      matching: find.byType(TrackHeader),
    );
    await tester.scrollUntilVisible(header, 160, maxScrolls: 80);
    await tester.ensureVisible(header);
    await tester.pump();

    // Everything starts selected, so the button reads "remove".
    final button = find.descendant(
      of: header,
      matching: find.byType(TextButton),
    );
    expect(button, findsOneWidget);
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 250));

    final afterRemove = selected();
    expect(
      afterRemove.intersection(grammarIds),
      isEmpty,
      reason: 'the whole grammar course came out',
    );
    expect(
      afterRemove.containsAll(khmerIds.intersection(afterRemove)),
      isTrue,
      reason: 'no other course was touched',
    );
    for (final id in khmerIds) {
      // The Khmer rows are built above the grammar ones, so they are all on
      // screen here and must still be selected.
      final tile = tester
          .widgetList<SubjectTile>(find.byType(SubjectTile))
          .where((t) => t.part.id == id);
      if (tile.isNotEmpty) {
        expect(tile.first.selected, isTrue, reason: 'part $id was collateral');
      }
    }

    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      selected().containsAll(grammarIds),
      isTrue,
      reason: 'tapping again puts the whole course back',
    );
  });

  testWidgets('each quick mock draws only from its own syllabus', (
    tester,
  ) async {
    final app = await boot(tester);
    await pump(tester, app, const Scaffold(body: MockScreen()));

    expect(
      find.widgetWithText(ElevatedButton, 'ចាប់ផ្ដើមប្រឡងសាកល្បង'),
      findsNWidgets(3),
      reason: 'one quick mock per syllabus',
    );

    Future<Set<int>> partsOfMock(String slug) async {
      final button = find.byKey(ValueKey('quick-mock-$slug'));
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final config = tester
          .widget<QuizSessionScreen>(find.byType(QuizSessionScreen))
          .config;
      // Unmount so the quiz screen's countdown Timer stops.
      await tester.pumpWidget(const SizedBox.shrink());
      return config.partIds;
    }

    final khmerIds = app
        .partsIn(PartTrack.civilService)
        .where((p) => p.count > 0)
        .map((p) => p.id)
        .toSet();
    expect(
      await partsOfMock('civil-service'),
      khmerIds,
      reason: 'the official paper is the civil-service syllabus alone',
    );

    await pump(tester, app, const Scaffold(body: MockScreen()));
    final englishIds = {
      for (final track in [
        PartTrack.grammar,
        PartTrack.vocabulary,
        PartTrack.englishSkills,
      ])
        ...app.partsIn(track).where((p) => p.count > 0).map((p) => p.id),
    };
    expect(
      await partsOfMock('english'),
      englishIds,
      reason: 'the English test never reaches into the Khmer bank',
    );

    await pump(tester, app, const Scaffold(body: MockScreen()));
    final teachingIds = app
        .partsIn(PartTrack.teaching)
        .where((p) => p.count > 0)
        .map((p) => p.id)
        .toSet();
    expect(
      await partsOfMock('teaching'),
      teachingIds,
      reason: 'the teacher paper is the teaching syllabus alone',
    );
    expect(
      teachingIds.intersection(khmerIds),
      isEmpty,
      reason: 'teacher ethics is a separate exam from the civil-service one',
    );
  });
}
