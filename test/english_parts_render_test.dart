// Renders the English parts (14-24, one per part of grammar.pdf) through the
// real quiz and review screens at a small phone width, and checks that a
// 5-option question shows all five choices lettered A-E without a layout
// overflow. The rest of the bank is 4-option and Khmer-lettered, so this is
// the case the screens had not seen before the grammar.pdf parts were added.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rabbit/data/question_repository.dart';
import 'package:rabbit/models/exam_config.dart';
import 'package:rabbit/models/exam_result.dart';
import 'package:rabbit/models/question.dart';
import 'package:rabbit/models/question_attempt.dart';
import 'package:rabbit/screens/quiz_session_screen.dart';
import 'package:rabbit/screens/review_screen.dart';
import 'package:rabbit/state/app_state.dart';
import 'package:rabbit/theme/app_theme.dart';
import 'package:rabbit/widgets/option_tile.dart';

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
  tearDownAll(() => FlutterError.onError = originalOnError);
  setUp(_overflowErrors.clear);

  void expectNoOverflow(String where) {
    expect(
      _overflowErrors,
      isEmpty,
      reason: '$where overflowed: '
          '${_overflowErrors.map((e) => e.exceptionAsString()).join('; ')}',
    );
  }

  Future<AppState> boot(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState();
    await tester.runAsync(app.bootstrap);
    return app;
  }

  Future<void> pumpNarrow(
    WidgetTester tester,
    AppState app,
    Widget child,
  ) async {
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
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
  }

  testWidgets('a 5-option English question shows all five A-E choices', (
    tester,
  ) async {
    final app = await boot(tester);
    final question = _firstFiveOption(app.repo);

    await pumpNarrow(
      tester,
      app,
      _OneQuestion(question: question),
    );

    expect(find.byType(OptionTile), findsNWidgets(5));
    for (final letter in ['A', 'B', 'C', 'D', 'E']) {
      expect(find.text(letter), findsOneWidget);
    }
    for (final option in question.options) {
      expect(find.text(option), findsOneWidget);
    }
    expectNoOverflow('5-option question');
  });

  testWidgets('the quiz screen runs an English part end to end', (
    tester,
  ) async {
    final app = await boot(tester);
    final config = ExamConfig(
      mode: ExamMode.practice,
      partIds: const {14, 16, 19, 22, 24},
      questionCount: 12,
      timeLimit: const Duration(minutes: 10),
      instantFeedback: true,
      presetLabel: 'English',
    );

    await pumpNarrow(tester, app, QuizSessionScreen(config: config));
    expectNoOverflow('QuizSessionScreen (English parts)');

    // Answer a few questions, tapping whichever option is on screen.
    for (var i = 0; i < 5; i++) {
      final options = find.byType(OptionTile);
      expect(options, findsWidgets);
      await tester.tap(options.first);
      await tester.pump(const Duration(milliseconds: 400));
      expectNoOverflow('QuizSessionScreen (answered ${i + 1})');
      await tester.tap(find.text('បន្ទាប់ →'));
      await tester.pump(const Duration(milliseconds: 400));
    }
    expectNoOverflow('QuizSessionScreen (after answering)');

    // Unmount to cancel the countdown Timer this screen keeps running.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the review screen lists all five options of an English question',
      (tester) async {
    final app = await boot(tester);
    final question = _firstFiveOption(app.repo);
    final attempt = QuestionAttempt(question: question, selectedIndex: 0);
    final result = ExamResult(
      completedAt: DateTime.now(),
      config: ExamConfig(
        mode: ExamMode.practice,
        partIds: {question.partId},
        questionCount: 1,
        timeLimit: null,
      ),
      attempts: [attempt],
      timeSpent: const Duration(minutes: 1),
    );

    await pumpNarrow(tester, app, ReviewScreen(result: result));

    for (final option in question.options) {
      expect(find.text(option), findsOneWidget);
    }
    expect(find.text('E. '), findsOneWidget);
    expectNoOverflow('ReviewScreen (5 options)');
  });
}

/// The first 5-option question in the English bank. Which part holds one moves
/// with the extraction - Book 1 Part A is all 4-option, Part C nearly all
/// 5-option - so it is searched for rather than named.
Question _firstFiveOption(QuestionRepository repo) {
  for (final part in repo.parts.where((p) => p.id >= 14)) {
    for (final q in part.questions) {
      if (q.options.length == 5) return q;
    }
  }
  throw StateError('the English parts hold no 5-option question');
}

/// Minimal host that renders one question's options exactly as the quiz screen
/// does, without the surrounding session machinery.
class _OneQuestion extends StatelessWidget {
  final Question question;
  const _OneQuestion({required this.question});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(question.text),
        const SizedBox(height: 8),
        for (var i = 0; i < question.options.length; i++)
          OptionTile(
            index: i,
            text: question.options[i],
            state: i == question.answerIndex
                ? OptionState.correct
                : OptionState.neutral,
            labels: question.optionLabels,
          ),
      ],
    );
  }
}
