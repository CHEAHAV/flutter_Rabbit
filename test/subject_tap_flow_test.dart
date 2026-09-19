// Covers the one-tap subject flow: the practice list has no on/off switches,
// and tapping a single subject drops straight into that subject's questions.
// The exam configuration screen still multi-selects, but by tapping the row
// rather than flipping a switch.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rabbit/models/exam_config.dart';
import 'package:rabbit/models/exam_part.dart';
import 'package:rabbit/screens/exam_config_screen.dart';
import 'package:rabbit/screens/practice_screen.dart';
import 'package:rabbit/screens/quiz_session_screen.dart';
import 'package:rabbit/state/app_state.dart';
import 'package:rabbit/state/exam_session.dart';
import 'package:rabbit/theme/app_theme.dart';
import 'package:rabbit/widgets/option_tile.dart';
import 'package:rabbit/widgets/subject_tile.dart';

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

  /// Scrolls [tile] into view and taps it.
  Future<void> tapTile(WidgetTester tester, Finder tile) async {
    await tester.scrollUntilVisible(tile, 120, maxScrolls: 60);
    await tester.tap(tile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Finder tileFor(ExamPart part) => find.ancestor(
    of: find.text(part.titleKm),
    matching: find.byType(SubjectTile),
  );

  /// Unmounts the tree so the quiz screen's 1-second countdown Timer stops.
  Future<void> closeQuiz(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
  }

  testWidgets('the practice list has no on/off switches', (tester) async {
    final app = await boot(tester);
    await pump(tester, app, const Scaffold(body: PracticeScreen()));

    expect(find.byType(SubjectTile), findsWidgets);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('tapping one subject goes straight into its questions', (
    tester,
  ) async {
    final app = await boot(tester);
    final part = app.partsWithQuestions.first;
    await pump(tester, app, const Scaffold(body: PracticeScreen()));

    expect(find.byType(QuizSessionScreen), findsNothing);
    await tapTile(tester, tileFor(part));

    expect(find.byType(QuizSessionScreen), findsOneWidget);
    final config = tester
        .widget<QuizSessionScreen>(find.byType(QuizSessionScreen))
        .config;
    expect(config.mode, ExamMode.practice);
    expect(config.partIds, {part.id}, reason: 'only the tapped subject');
    expect(config.instantFeedback, isTrue);

    // Questions are on screen and every one of them belongs to that subject.
    expect(find.byType(OptionTile), findsWidgets);
    final session = Provider.of<ExamSession>(
      tester.element(find.byType(OptionTile).first),
      listen: false,
    );
    expect(session.total, 20, reason: 'the default session size');
    expect(
      session.attempts.every((a) => a.question.partId == part.id),
      isTrue,
      reason: 'no question leaked in from another subject',
    );

    await closeQuiz(tester);
  });

  testWidgets('the chosen question count applies to the tapped subject', (
    tester,
  ) async {
    final app = await boot(tester);
    final part = app.partsWithQuestions.first;
    await pump(tester, app, const Scaffold(body: PracticeScreen()));

    await tester.tap(find.widgetWithText(ChoiceChip, '១០'));
    await tester.pump(const Duration(milliseconds: 200));
    await tapTile(tester, tileFor(part));

    final session = Provider.of<ExamSession>(
      tester.element(find.byType(OptionTile).first),
      listen: false,
    );
    expect(session.total, 10);

    await closeQuiz(tester);
  });

  testWidgets('a subject with no questions stays locked', (tester) async {
    final app = await boot(tester);
    final empty = app.parts.where((p) => p.count == 0).toList();
    if (empty.isEmpty) return; // every part is populated — nothing to lock.

    await pump(tester, app, const Scaffold(body: PracticeScreen()));
    final tile = tileFor(empty.first);
    await tester.scrollUntilVisible(tile, 120, maxScrolls: 60);
    await tester.tap(tile);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(QuizSessionScreen), findsNothing);
  });

  testWidgets('exam config selects subjects by tapping the row, not a switch', (
    tester,
  ) async {
    final app = await boot(tester);
    await pump(tester, app, const ExamConfigScreen(mode: ExamMode.mock));

    // The condition toggles below still use switches; the subject rows must not.
    expect(
      find.descendant(
        of: find.byType(SubjectTile),
        matching: find.byType(Switch),
      ),
      findsNothing,
    );

    final part = app.partsWithQuestions.first;
    final tile = tileFor(part);
    await tester.scrollUntilVisible(tile, 120, maxScrolls: 60);

    bool isSelected() => tester.widget<SubjectTile>(tile).selected;
    expect(isSelected(), isTrue, reason: 'everything starts selected');

    await tester.tap(tile);
    await tester.pump(const Duration(milliseconds: 250));
    expect(isSelected(), isFalse, reason: 'one tap removes it');

    await tester.tap(tile);
    await tester.pump(const Duration(milliseconds: 250));
    expect(isSelected(), isTrue, reason: 'tapping again puts it back');
  });
}
