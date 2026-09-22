// A session must never hand back a question the user has already answered.
// Answering 50 of a 200-question subject and coming back has to draw on the
// other 150: not 50 of the same ones, not a reshuffle of all 200.
//
// The rule lives in two places and both are covered here - ProgressService
// remembers what has been answered, and AppState/QuizSessionScreen subtract
// that memory from the bank when they build a pool.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rabbit/models/exam_config.dart';
import 'package:rabbit/models/exam_part.dart';
import 'package:rabbit/screens/quiz_session_screen.dart';
import 'package:rabbit/services/progress_service.dart';
import 'package:rabbit/state/app_state.dart';
import 'package:rabbit/state/exam_session.dart';
import 'package:rabbit/theme/app_theme.dart';
import 'package:rabbit/widgets/option_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppState> boot(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    ProgressService.instance.resetForTesting();
    final app = AppState();
    await tester.runAsync(app.bootstrap);
    return app;
  }

  /// The biggest bundled subject: the more questions it has, the more room
  /// there is to answer a slice of it and check what is left.
  ExamPart biggestPart(AppState app) {
    final parts = app.partsWithQuestions.toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return parts.first;
  }

  ExamConfig configFor(ExamPart part, int count) => ExamConfig(
    mode: ExamMode.practice,
    partIds: {part.id},
    questionCount: count,
    timeLimit: null,
    shuffleQuestions: true,
    instantFeedback: true,
    presetLabel: part.titleKm,
  );

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

  /// The live session behind whatever quiz screen is on show.
  ExamSession sessionOf(WidgetTester tester) => Provider.of<ExamSession>(
    tester.element(find.byType(OptionTile).first),
    listen: false,
  );

  /// Unmounts the tree so the session's one-second countdown Timer stops.
  Future<void> closeQuiz(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
  }

  // ---- The memory itself -------------------------------------------------

  test('answered questions are remembered, grouped by part, and persist', () async {
    SharedPreferences.setMockInitialValues({});
    final progress = ProgressService.instance;
    progress.resetForTesting();
    await progress.init();

    expect(progress.answeredCountIn(3), 0, reason: 'nothing answered yet');

    await progress.markAnswered(['3-1', '3-2', '5-9']);
    expect(progress.answeredIn(3), {'3-1', '3-2'});
    expect(progress.answeredCountIn(3), 2);
    expect(progress.answeredCountIn(5), 1);
    expect(progress.hasAnswered('3-2'), isTrue);
    expect(progress.hasAnswered('3-3'), isFalse);
    expect(progress.answeredQuestionCount, 3);

    // Re-answering one changes nothing: the memory is a set, not a tally.
    await progress.markAnswered(['3-1']);
    expect(progress.answeredCountIn(3), 2);

    // It survives a restart of the app.
    progress.resetForTesting();
    await progress.init();
    expect(progress.answeredIn(3), {'3-1', '3-2'});
    expect(progress.answeredIn(5), {'5-9'});
  });

  test('resetting a part forgets only that part', () async {
    SharedPreferences.setMockInitialValues({});
    final progress = ProgressService.instance;
    progress.resetForTesting();
    await progress.init();
    await progress.markAnswered(['3-1', '3-2', '5-9']);

    final removed = await progress.resetAnswered({3});
    expect(removed, 2);
    expect(progress.answeredCountIn(3), 0, reason: 'part 3 starts over');
    expect(progress.answeredCountIn(5), 1, reason: 'part 5 is untouched');

    await progress.resetAllAnswered();
    expect(progress.answeredQuestionCount, 0);
  });

  // ---- The pool a session is built from ----------------------------------

  testWidgets('a new session never repeats a question already answered', (
    tester,
  ) async {
    final app = await boot(tester);
    final part = biggestPart(app);

    // Stand in for a first sitting: the user has answered 50 of this subject.
    final firstSitting = part.questions.take(50).map((q) => q.uid).toSet();
    await tester.runAsync(() => app.progress.markAnswered(firstSitting));

    expect(
      app.remainingIn(part),
      part.count - 50,
      reason: 'the subject reports what is left, not its raw total',
    );

    // Ask for the whole subject again.
    await pump(
      tester,
      app,
      QuizSessionScreen(config: configFor(part, part.count)),
    );
    final session = sessionOf(tester);

    expect(
      session.total,
      part.count - 50,
      reason: 'the 50 already answered are gone from the pool',
    );
    expect(
      session.attempts.any((a) => firstSitting.contains(a.question.uid)),
      isFalse,
      reason: 'not one of the first 50 came back',
    );
    expect(
      session.attempts.map((a) => a.question.uid).toSet().length,
      session.total,
      reason: 'and the new pool has no duplicates of its own',
    );

    await closeQuiz(tester);
  });

  testWidgets('a session is capped by what is left, never padded out', (
    tester,
  ) async {
    final app = await boot(tester);
    final part = biggestPart(app);

    // Leave only 7 unanswered, then ask for 50.
    final used = part.questions
        .take(part.count - 7)
        .map((q) => q.uid)
        .toSet();
    await tester.runAsync(() => app.progress.markAnswered(used));

    await pump(tester, app, QuizSessionScreen(config: configFor(part, 50)));
    final session = sessionOf(tester);

    expect(session.total, 7, reason: 'a short session beats a repeated one');
    expect(
      session.attempts.any((a) => used.contains(a.question.uid)),
      isFalse,
    );

    await closeQuiz(tester);
  });

  testWidgets('answering is remembered the moment the option is tapped', (
    tester,
  ) async {
    final app = await boot(tester);
    final part = biggestPart(app);

    await pump(tester, app, QuizSessionScreen(config: configFor(part, 5)));
    final session = sessionOf(tester);
    final uid = session.current.question.uid;

    expect(app.progress.hasAnswered(uid), isFalse);
    await tester.tap(find.byType(OptionTile).first);
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      app.progress.hasAnswered(uid),
      isTrue,
      reason: 'walking out of a half-finished session still uses it up',
    );

    await closeQuiz(tester);
  });

  testWidgets('a finished subject offers a restart instead of an empty quiz', (
    tester,
  ) async {
    final app = await boot(tester);
    final part = biggestPart(app);

    await tester.runAsync(
      () => app.progress.markAnswered(part.questions.map((q) => q.uid)),
    );
    expect(app.remainingIn(part), 0);

    await pump(
      tester,
      app,
      QuizSessionScreen(config: configFor(part, part.count)),
    );

    final restart = find.byKey(const ValueKey('restart-exhausted-pool'));
    expect(
      restart,
      findsOneWidget,
      reason: 'the pool is finished, not empty - say so and offer a way on',
    );
    expect(find.byType(OptionTile), findsNothing);

    await tester.tap(restart);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(app.progress.answeredCountIn(part.id), 0);
    expect(find.byType(OptionTile), findsWidgets);
    expect(sessionOf(tester).total, part.count);

    await closeQuiz(tester);
  });

  testWidgets('an explicit question list is served as given', (tester) async {
    final app = await boot(tester);
    final part = biggestPart(app);

    // The mistakes notebook hands the screen questions the user has answered
    // by definition; that path must not be filtered.
    final wrong = part.questions.take(4).toList();
    await tester.runAsync(
      () => app.progress.markAnswered(wrong.map((q) => q.uid)),
    );

    await pump(
      tester,
      app,
      QuizSessionScreen(
        config: configFor(part, wrong.length),
        overrideQuestions: wrong,
      ),
    );

    expect(sessionOf(tester).total, 4);

    await closeQuiz(tester);
  });
}
