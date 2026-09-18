// Regression test: pumps every screen at a small phone width (320x640,
// smaller than an iPhone SE) with real, worst-case-length Khmer content
// and fails if Flutter reports a RenderFlex/layout overflow anywhere.
//
// This is the automated stand-in for "does any page overflow on a small
// screen" — much more reliable than eyeballing a simulator.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rabbit/data/question_repository.dart';
import 'package:rabbit/models/exam_config.dart';
import 'package:rabbit/models/exam_result.dart';
import 'package:rabbit/models/question_attempt.dart';
import 'package:rabbit/services/progress_service.dart';
import 'package:rabbit/state/app_state.dart';
import 'package:rabbit/theme/app_theme.dart';
import 'package:rabbit/screens/exam_config_screen.dart';
import 'package:rabbit/screens/home_shell.dart';
import 'package:rabbit/screens/mock_screen.dart';
import 'package:rabbit/screens/notebook_screen.dart';
import 'package:rabbit/screens/practice_screen.dart';
import 'package:rabbit/screens/profile_screen.dart';
import 'package:rabbit/screens/quiz_session_screen.dart';
import 'package:rabbit/screens/result_screen.dart';
import 'package:rabbit/screens/review_screen.dart';
import 'package:rabbit/screens/splash_screen.dart';

final List<FlutterErrorDetails> _overflowErrors = [];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final originalOnError = FlutterError.onError;
  setUpAll(() {
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('overflowed') || message.contains('RenderFlex')) {
        _overflowErrors.add(details);
      }
      originalOnError?.call(details);
    };
  });

  tearDownAll(() {
    FlutterError.onError = originalOnError;
  });

  setUp(() {
    _overflowErrors.clear();
  });

  Future<AppState> buildBootstrappedAppState() async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState();
    await app.bootstrap();
    return app;
  }

  /// Wraps [child] the same way app.dart wires the real app, at a narrow
  /// 320x640 viewport (smaller than an iPhone SE) — the worst case for
  /// horizontal overflow with long Khmer subject titles.
  Future<void> pumpNarrow(WidgetTester tester, AppState app, Widget child) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: app,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: child,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  void expectNoOverflow(String screenName) {
    expect(
      _overflowErrors,
      isEmpty,
      reason: '$screenName overflowed:\n'
          '${_overflowErrors.map((d) => d.exceptionAsString()).join('\n---\n')}',
    );
  }

  testWidgets('Splash screen does not overflow', (tester) async {
    final app = await buildBootstrappedAppState();
    await pumpNarrow(tester, app, const SplashScreen());
    expectNoOverflow('SplashScreen');
  });

  testWidgets('Home shell tabs (Practice/Mock/Notebook/Profile) do not overflow',
      (tester) async {
    final app = await buildBootstrappedAppState();
    await pumpNarrow(tester, app, const HomeShell());
    expectNoOverflow('HomeShell (Practice tab)');

    // Tap through the other 3 bottom-nav tabs.
    for (final label in ['ប្រឡងសាកល្បង', 'សៀវភៅកត់ត្រា', 'គណនី']) {
      await tester.tap(find.text(label));
      await tester.pump(const Duration(milliseconds: 50));
      expectNoOverflow('HomeShell ($label tab)');
    }
  });

  testWidgets('Practice screen standalone does not overflow', (tester) async {
    final app = await buildBootstrappedAppState();
    await pumpNarrow(tester, app, const PracticeScreen());
    expectNoOverflow('PracticeScreen');
  });

  testWidgets('Mock screen with populated history does not overflow', (tester) async {
    final app = await buildBootstrappedAppState();
    // Seed a couple of history entries so _HistoryRow renders.
    final part = app.repo.parts.firstWhere((p) => p.count >= 4);
    final questions = part.questions.take(4).toList();
    final attempts = [
      QuestionAttempt(question: questions[0], selectedIndex: questions[0].answerIndex),
      QuestionAttempt(question: questions[1], selectedIndex: (questions[1].answerIndex + 1) % 4),
      QuestionAttempt(question: questions[2], selectedIndex: null),
      QuestionAttempt(question: questions[3], selectedIndex: questions[3].answerIndex, flagged: true),
    ];
    final result = ExamResult(
      completedAt: DateTime.now(),
      config: ExamConfig(
        mode: ExamMode.mock,
        partIds: {part.id},
        questionCount: 4,
        timeLimit: const Duration(minutes: 40),
        presetLabel: 'ស្តង់ដារផ្លូវការ',
      ),
      attempts: attempts,
      timeSpent: const Duration(hours: 1, minutes: 12, seconds: 34),
    );
    await app.progress.recordResult(result);
    app.refresh();

    await pumpNarrow(tester, app, const MockScreen());
    expectNoOverflow('MockScreen (with history)');
  });

  testWidgets('Notebook screen with mistakes & bookmarks does not overflow', (tester) async {
    final app = await buildBootstrappedAppState();
    // Use the part with the longest title (Science/Tech/Innovation) — the
    // worst case for the subject-name pill badge.
    final longTitlePart =
        app.repo.parts.reduce((a, b) => a.titleKm.length >= b.titleKm.length ? a : b);
    for (final q in longTitlePart.questions.take(3)) {
      await app.progress.toggleBookmark(q.uid);
    }
    final wrongAttempt = QuestionAttempt(
      question: longTitlePart.questions.first,
      selectedIndex: (longTitlePart.questions.first.answerIndex + 1) % 4,
    );
    final result = ExamResult(
      completedAt: DateTime.now(),
      config: ExamConfig(
        mode: ExamMode.practice,
        partIds: {longTitlePart.id},
        questionCount: 1,
        timeLimit: null,
      ),
      attempts: [wrongAttempt],
      timeSpent: const Duration(minutes: 2),
    );
    await app.progress.recordResult(result);
    app.refresh();

    await pumpNarrow(tester, app, const NotebookScreen());
    expectNoOverflow('NotebookScreen (mistakes tab, long subject title)');

    await tester.tap(find.text('បានរក្សាទុក (៣)'));
    await tester.pump(const Duration(milliseconds: 50));
    expectNoOverflow('NotebookScreen (bookmarks tab, long subject title)');
  });

  testWidgets('Profile screen does not overflow', (tester) async {
    final app = await buildBootstrappedAppState();
    await pumpNarrow(tester, app, const ProfileScreen());
    expectNoOverflow('ProfileScreen');
  });

  testWidgets('Exam config screen (practice & mock) does not overflow', (tester) async {
    final app = await buildBootstrappedAppState();
    await pumpNarrow(tester, app, const ExamConfigScreen(mode: ExamMode.practice));
    expectNoOverflow('ExamConfigScreen (practice)');

    await pumpNarrow(tester, app, const ExamConfigScreen(mode: ExamMode.mock));
    expectNoOverflow('ExamConfigScreen (mock)');
  });

  testWidgets('Quiz session screen does not overflow, incl. long subject title header',
      (tester) async {
    final app = await buildBootstrappedAppState();
    // Longest subject title = worst case for the header pill.
    final longTitlePart =
        app.repo.parts.reduce((a, b) => a.titleKm.length >= b.titleKm.length ? a : b);
    final config = ExamConfig(
      mode: ExamMode.practice,
      partIds: {longTitlePart.id},
      questionCount: longTitlePart.count,
      timeLimit: const Duration(hours: 1, minutes: 5),
      instantFeedback: true,
      presetLabel: 'តេស្ត',
    );

    await pumpNarrow(tester, app, QuizSessionScreen(config: config));
    expectNoOverflow('QuizSessionScreen (header, longest subject title)');

    // Answer the current question to exercise the instant-feedback state.
    final optionFinder = find.byIcon(Icons.outlined_flag_rounded);
    if (optionFinder.evaluate().isNotEmpty) {
      await tester.tap(find.text('ចំណាំទុក'));
      await tester.pump(const Duration(milliseconds: 50));
      expectNoOverflow('QuizSessionScreen (flagged)');
    }

    // Open the quick-navigator question grid bottom sheet.
    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await tester.pumpAndSettle();
    expectNoOverflow('QuizSessionScreen (question grid sheet)');

    // Unmount to cancel the internal countdown Timer before the test ends.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Result & review screens do not overflow', (tester) async {
    final app = await buildBootstrappedAppState();
    final parts = app.repo.parts.where((p) => p.count > 0).take(3).toList();
    final attempts = <QuestionAttempt>[];
    for (final part in parts) {
      for (final q in part.questions.take(2)) {
        attempts.add(QuestionAttempt(
          question: q,
          selectedIndex: attempts.length.isEven ? q.answerIndex : (q.answerIndex + 1) % 4,
          flagged: attempts.length.isOdd,
        ));
      }
    }
    final result = ExamResult(
      completedAt: DateTime.now(),
      config: ExamConfig(
        mode: ExamMode.mock,
        partIds: parts.map((p) => p.id).toSet(),
        questionCount: attempts.length,
        timeLimit: const Duration(hours: 2, minutes: 3),
      ),
      attempts: attempts,
      // Long duration to stress-test StatBox / duration formatting.
      timeSpent: const Duration(hours: 1, minutes: 47, seconds: 9),
    );

    await pumpNarrow(tester, app, ResultScreen(result: result));
    expectNoOverflow('ResultScreen');

    await pumpNarrow(tester, app, ReviewScreen(result: result));
    expectNoOverflow('ReviewScreen (all filter)');

    await tester.tap(find.textContaining('ខុស ('));
    await tester.pump(const Duration(milliseconds: 50));
    expectNoOverflow('ReviewScreen (wrong filter)');

    await tester.tap(find.textContaining('ចំណាំ ('));
    await tester.pump(const Duration(milliseconds: 50));
    expectNoOverflow('ReviewScreen (flagged filter)');
  });
}
