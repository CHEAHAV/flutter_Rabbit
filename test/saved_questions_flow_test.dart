// Covers the saved-questions flow end to end: pressing ចំណាំទុក on a question
// in a session puts that question, with its answer, on the notebook's
// បានរក្សាទុក shelf; it stays there across sessions and app restarts; and it
// leaves only when the user unsaves it.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rabbit/models/exam_config.dart';
import 'package:rabbit/models/exam_result.dart';
import 'package:rabbit/models/question.dart';
import 'package:rabbit/models/question_attempt.dart';
import 'package:rabbit/screens/notebook_screen.dart';
import 'package:rabbit/screens/quiz_session_screen.dart';
import 'package:rabbit/screens/review_screen.dart';
import 'package:rabbit/services/progress_service.dart';
import 'package:rabbit/state/app_state.dart';
import 'package:rabbit/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProgressService.instance.resetForTesting();
  });

  Future<AppState> boot(WidgetTester tester) async {
    final app = AppState();
    await tester.runAsync(app.bootstrap);
    return app;
  }

  /// Boots a *second* AppState over the same stored preferences: what a cold
  /// start of the app does. The progress service is a singleton, so it has to
  /// be told to re-read storage - otherwise it just hands back the sets it is
  /// already holding in memory and the test proves nothing.
  Future<AppState> restart(WidgetTester tester) async {
    ProgressService.instance.resetForTesting();
    return boot(tester);
  }

  Future<void> pump(WidgetTester tester, AppState app, Widget home) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: app,
        child: MaterialApp(theme: AppTheme.light(), home: home),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
  }

  /// Unmounts the tree so the quiz screen's 1-second countdown Timer stops.
  Future<void> closeQuiz(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox.shrink());

  /// Lets a tap's write to storage complete and the snackbar settle.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// A one-question practice session over [question].
  Widget quizOver(Question question) => QuizSessionScreen(
    config: ExamConfig(
      mode: ExamMode.practice,
      partIds: {question.partId},
      questionCount: 1,
      timeLimit: null,
      shuffleQuestions: false,
      instantFeedback: true,
    ),
    overrideQuestions: [question],
  );

  Question firstQuestion(AppState app) =>
      app.repo.parts.firstWhere((p) => p.count > 0).questions.first;

  ExamResult resultOver(Question question, int selectedIndex) => ExamResult(
    completedAt: DateTime.now(),
    config: ExamConfig(
      mode: ExamMode.practice,
      partIds: {question.partId},
      questionCount: 1,
      timeLimit: null,
    ),
    attempts: [
      QuestionAttempt(question: question, selectedIndex: selectedIndex),
    ],
    timeSpent: const Duration(minutes: 1),
  );

  const saveLabel = 'ចំណាំទុក';
  const savedLabel = 'បានរក្សាទុក';

  // The two choices the confirmation bar offers. Exact-text finders, so the
  // shorter label cannot match inside the longer one.
  const undoLabel = 'ថយក្រោយ';
  const keepLabel = 'បាទ/ចាស៎';

  /// The confirmation card, as every screen that can save a question shows it:
  /// the right heading and icon for what just happened, and two real buttons -
  /// an outlined ថយក្រោយ beside a filled បាទ/ចាស៎.
  void expectSaveCard({required bool saved}) {
    expect(
      find.text(saved ? 'បានរក្សាទុកសំណួរ' : 'បានដកសំណួរចេញ'),
      findsOneWidget,
    );
    expect(
      find.byIcon(
        saved ? Icons.bookmark_added_rounded : Icons.bookmark_remove_rounded,
      ),
      findsOneWidget,
    );
    expect(find.text(undoLabel), findsOneWidget);
    expect(find.text(keepLabel), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text(undoLabel),
        matching: find.byType(OutlinedButton),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.text(keepLabel),
        matching: find.byType(ElevatedButton),
      ),
      findsOneWidget,
    );
  }

  /// Both choices are on screen. Shorthand for the checks that only care that
  /// the card is up, not which way round it reads.
  void expectBothChoices() {
    expect(find.text(undoLabel), findsOneWidget);
    expect(find.text(keepLabel), findsOneWidget);
  }

  /// Brings the notebook's saved tab into view and opens it.
  Future<void> openSavedTab(WidgetTester tester) async {
    final tab = find.textContaining('$savedLabel (');
    await tester.scrollUntilVisible(tab, 120, maxScrolls: 30);
    await tester.tap(tab);
    await tester.pump();
  }

  /// Opens the page of the saved part [partId] from the notebook's saved tab,
  /// which lists saved questions part by part.
  Future<void> openSavedPart(WidgetTester tester, int partId) async {
    final tile = find.byKey(ValueKey('saved-part-$partId'));
    await tester.scrollUntilVisible(tile, 120, maxScrolls: 30);
    await tester.tap(tile);
    await tester.pumpAndSettle();
  }

  /// Saves the question the quiz screen is showing. Scrolled into view first:
  /// a test that has reached for the quick navigator lower down the page may
  /// have left the button above the fold.
  Future<void> tapSave(WidgetTester tester) async {
    final button = find.text(saveLabel);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await settle(tester);
  }

  /// Jumps to question [number] through the quick navigator.
  ///
  /// Not through the footer's "next" button: the snackbar the save puts up
  /// covers the footer, and a widget test's clock does not retire it.
  Future<void> jumpToQuestion(WidgetTester tester, String number) async {
    final square = find.text(number);
    await tester.ensureVisible(square);
    await tester.tap(square);
    await settle(tester);
  }

  testWidgets('saving in a session puts the question on the saved shelf', (
    tester,
  ) async {
    final app = await boot(tester);
    final question = firstQuestion(app);
    await pump(tester, app, quizOver(question));

    // Before: the button offers to save, and nothing is saved.
    expect(find.text(saveLabel), findsOneWidget);
    expect(app.progress.bookmarkUids, isEmpty);

    await tapSave(tester);

    // The save is on record and the button now says so.
    expect(app.progress.isBookmarked(question.uid), isTrue);
    expect(find.text(savedLabel), findsWidgets);
    expect(find.text(saveLabel), findsNothing);

    // And the confirmation card is up, headed for a save, with both choices.
    expectSaveCard(saved: true);

    await closeQuiz(tester);
  });

  testWidgets('បាទ/ចាស៎ keeps the save and closes the bar', (tester) async {
    final app = await boot(tester);
    final question = firstQuestion(app);
    await pump(tester, app, quizOver(question));

    await tapSave(tester);
    expectBothChoices();

    await tester.tap(find.text(keepLabel));
    await settle(tester);

    // The save stands and the bar is gone, so neither choice is still offered.
    expect(app.progress.isBookmarked(question.uid), isTrue);
    expect(find.text(undoLabel), findsNothing);
    expect(find.text(keepLabel), findsNothing);
    expect(find.text(savedLabel), findsOneWidget);

    await closeQuiz(tester);
  });

  testWidgets('the saved question, with its answer, is in the notebook', (
    tester,
  ) async {
    final app = await boot(tester);
    final question = firstQuestion(app);
    await pump(tester, app, quizOver(question));
    await tapSave(tester);
    await closeQuiz(tester);

    await pump(tester, app, const Scaffold(body: NotebookScreen()));
    await openSavedTab(tester);
    await openSavedPart(tester, question.partId);

    // The card carries the question, every option, and the correct answer.
    expect(find.text(question.text), findsOneWidget);
    for (final option in question.options) {
      expect(find.text(option), findsWidgets);
    }
    expect(find.textContaining(question.correctOptionText), findsWidgets);
  });

  testWidgets('a save survives a restart of the app', (tester) async {
    final first = await boot(tester);
    final question = firstQuestion(first);
    await pump(tester, first, quizOver(question));
    await tapSave(tester);
    await closeQuiz(tester);

    // Cold start over the same on-device store.
    final second = await restart(tester);
    expect(second.progress.isBookmarked(question.uid), isTrue);

    await pump(tester, second, const Scaffold(body: NotebookScreen()));
    await openSavedTab(tester);
    await openSavedPart(tester, question.partId);
    expect(find.text(question.text), findsOneWidget);
  });

  testWidgets('meeting a saved question again shows it as already saved', (
    tester,
  ) async {
    final app = await boot(tester);
    final question = firstQuestion(app);
    await app.progress.setBookmark(question.uid, true);

    await pump(tester, app, quizOver(question));
    expect(find.text(savedLabel), findsOneWidget);
    expect(find.text(saveLabel), findsNothing);
    await closeQuiz(tester);
  });

  testWidgets('pressing the button a second time unsaves it', (tester) async {
    final app = await boot(tester);
    final question = firstQuestion(app);
    await pump(tester, app, quizOver(question));

    await tapSave(tester);
    expect(app.progress.isBookmarked(question.uid), isTrue);

    await tester.tap(find.text(savedLabel).first);
    await settle(tester);
    expect(app.progress.isBookmarked(question.uid), isFalse);
    expect(find.text(saveLabel), findsOneWidget);

    await closeQuiz(tester);

    // And the shelf is empty again after a restart too.
    final second = await restart(tester);
    expect(second.progress.bookmarkUids, isEmpty);
  });

  testWidgets('unsaving from the notebook takes the card off the shelf', (
    tester,
  ) async {
    final app = await boot(tester);
    final question = firstQuestion(app);
    await app.progress.setBookmark(question.uid, true);

    await pump(tester, app, const Scaffold(body: NotebookScreen()));
    await openSavedTab(tester);
    await openSavedPart(tester, question.partId);
    expect(find.text(question.text), findsOneWidget);

    // By tooltip, not by icon: the "practise the saved questions" button sits
    // above the cards, and a bare icon finder would hit that instead.
    final unsave = find.byTooltip('ដកចេញពីបញ្ជីរក្សាទុក');
    await tester.ensureVisible(unsave);
    await tester.tap(unsave);
    await settle(tester);

    expect(app.progress.isBookmarked(question.uid), isFalse);
    expect(find.text(question.text), findsNothing);
    expect(find.text('មិនមានសំណួររក្សាទុកក្នុងផ្នែកនេះទៀតទេ'), findsOneWidget);
    expectSaveCard(saved: false);

    // Back in the notebook, the part has left the shelf with its last question.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('saved-part-${question.partId}')), findsNothing);
    expect(find.text('អ្នកមិនទាន់រក្សាទុកសំណួរណាមួយទេ'), findsOneWidget);
  });

  testWidgets('a save belongs to its own question, not to the cursor', (
    tester,
  ) async {
    final app = await boot(tester);
    final part = app.repo.parts.firstWhere((p) => p.count >= 2);
    final first = part.questions[0];
    final second = part.questions[1];

    await pump(
      tester,
      app,
      QuizSessionScreen(
        config: ExamConfig(
          mode: ExamMode.practice,
          partIds: {part.id},
          questionCount: 2,
          timeLimit: null,
          shuffleQuestions: false,
          instantFeedback: true,
        ),
        overrideQuestions: [first, second],
      ),
    );

    await tapSave(tester);
    expect(app.progress.isBookmarked(first.uid), isTrue);

    // The next question is its own question: still unsaved, and saving it
    // leaves the first one saved.
    await jumpToQuestion(tester, '២');
    expect(find.text(second.text), findsOneWidget);
    expect(find.text(saveLabel), findsOneWidget);
    await tapSave(tester);
    expect(app.progress.bookmarkUids, {first.uid, second.uid});

    // And paging back shows the first one still saved.
    await jumpToQuestion(tester, '១');
    expect(find.text(first.text), findsOneWidget);
    expect(find.text(savedLabel), findsOneWidget);

    await closeQuiz(tester);
  });

  testWidgets('the undo on an accidental unsave puts the question back', (
    tester,
  ) async {
    final app = await boot(tester);
    final question = firstQuestion(app);
    await app.progress.setBookmark(question.uid, true);

    await pump(tester, app, const Scaffold(body: NotebookScreen()));
    await openSavedTab(tester);
    await openSavedPart(tester, question.partId);

    final unsave = find.byTooltip('ដកចេញពីបញ្ជីរក្សាទុក');
    await tester.ensureVisible(unsave);
    await tester.tap(unsave);
    await settle(tester);
    expect(app.progress.isBookmarked(question.uid), isFalse);

    expectBothChoices();
    await tester.tap(find.text(undoLabel));
    await settle(tester);

    expect(app.progress.isBookmarked(question.uid), isTrue);
    expect(find.text(question.text), findsOneWidget);
  });

  testWidgets('បាទ/ចាស៎ lets an unsave stand', (tester) async {
    final app = await boot(tester);
    final question = firstQuestion(app);
    await app.progress.setBookmark(question.uid, true);

    await pump(tester, app, const Scaffold(body: NotebookScreen()));
    await openSavedTab(tester);
    await openSavedPart(tester, question.partId);

    final unsave = find.byTooltip('ដកចេញពីបញ្ជីរក្សាទុក');
    await tester.ensureVisible(unsave);
    await tester.tap(unsave);
    await settle(tester);

    expectBothChoices();
    await tester.tap(find.text(keepLabel));
    await settle(tester);

    expect(app.progress.isBookmarked(question.uid), isFalse);
    expect(find.text(question.text), findsNothing);
    expect(find.text(undoLabel), findsNothing);
  });

  testWidgets('the review screen saves to the same shelf', (tester) async {
    final app = await boot(tester);
    final question = firstQuestion(app);

    await pump(
      tester,
      app,
      ReviewScreen(result: resultOver(question, question.answerIndex)),
    );
    await tester.tap(find.byIcon(Icons.bookmark_border_rounded).first);
    await settle(tester);

    expect(app.progress.isBookmarked(question.uid), isTrue);
    expect(find.byIcon(Icons.bookmark_rounded), findsWidgets);
    expectSaveCard(saved: true);
  });

  testWidgets('answering a saved question never unsaves it', (tester) async {
    final app = await boot(tester);
    final question = firstQuestion(app);
    await app.progress.setBookmark(question.uid, true);

    // Answer it right, then wrong: the mistakes list moves, the shelf does not.
    final wrong = (question.answerIndex + 1) % question.options.length;
    for (final selected in [question.answerIndex, wrong]) {
      await tester.runAsync(
        () => app.progress.recordResult(resultOver(question, selected)),
      );
      expect(app.progress.isBookmarked(question.uid), isTrue);
    }
    expect(app.progress.mistakeUids, contains(question.uid));
  });

  group('the saved shelf is kept part by part', () {
    // The two teacher-course subjects, as in the user's own example.
    const teacherPart = 27; // ក្រមសីលធម៌វិជ្ជាជីវៈគ្រូបង្រៀន
    const ictPart = 28; // ព័ត៌មានវិទ្យា (ICT)

    Finder row(int partId) => find.byKey(ValueKey('saved-part-$partId'));

    /// Saves 3 ICT and 2 teacher-ethics questions, interleaved the way a user
    /// saves across sessions.
    Future<(List<Question>, List<Question>)> saveSome(AppState app) async {
      final ict = app.repo.partById(ictPart).questions.take(3).toList();
      final teacher = app.repo.partById(teacherPart).questions.take(2).toList();
      for (final q in [ict[0], teacher[0], ict[1], teacher[1], ict[2]]) {
        await app.progress.setBookmark(q.uid, true);
      }
      return (ict, teacher);
    }

    testWidgets('each part saved from is one row, with its own count', (
      tester,
    ) async {
      final app = await boot(tester);
      final (ict, teacher) = await saveSome(app);
      await pump(tester, app, const Scaffold(body: NotebookScreen()));
      await openSavedTab(tester);

      expect(find.textContaining('$savedLabel (៥)'), findsOneWidget);
      await tester.scrollUntilVisible(row(ictPart), 120, maxScrolls: 30);
      expect(
        find.descendant(
          of: row(ictPart),
          matching: find.text('ព័ត៌មានវិទ្យា (ICT)'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row(ictPart), matching: find.text('៣')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row(teacherPart), matching: find.text('២')),
        findsOneWidget,
      );
      // Only those two parts: nothing was saved anywhere else.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('saved-part-'),
        ),
        findsNWidgets(2),
      );
      // The questions themselves are not all dumped on the shelf.
      for (final q in [...ict, ...teacher]) {
        expect(find.text(q.text), findsNothing);
      }
      // And no "practise every saved question" button on this tab.
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('a part page holds only the questions saved from that part', (
      tester,
    ) async {
      final app = await boot(tester);
      final (ict, teacher) = await saveSome(app);
      await pump(tester, app, const Scaffold(body: NotebookScreen()));
      await openSavedTab(tester);

      await openSavedPart(tester, ictPart);
      expect(find.text('បានរក្សាទុក ៣ សំណួរ'), findsOneWidget);
      for (final q in ict) {
        await tester.scrollUntilVisible(find.text(q.text), 200, maxScrolls: 40);
        expect(find.text(q.text), findsOneWidget);
      }
      for (final q in teacher) {
        expect(find.text(q.text), findsNothing);
      }

      await tester.pageBack();
      await tester.pumpAndSettle();
      await openSavedPart(tester, teacherPart);
      expect(find.text('បានរក្សាទុក ២ សំណួរ'), findsOneWidget);
      for (final q in teacher) {
        await tester.scrollUntilVisible(find.text(q.text), 200, maxScrolls: 40);
        expect(find.text(q.text), findsOneWidget);
      }
      for (final q in ict) {
        expect(find.text(q.text), findsNothing);
      }
    });

    testWidgets("practising a part runs only that part's saved questions", (
      tester,
    ) async {
      final app = await boot(tester);
      final (ict, _) = await saveSome(app);
      await pump(tester, app, const Scaffold(body: NotebookScreen()));
      await openSavedTab(tester);
      await openSavedPart(tester, ictPart);

      await tester.tap(find.text('ហ្វឹកហាត់សំណួរទាំង ៣'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final quiz = tester.widget<QuizSessionScreen>(
        find.byType(QuizSessionScreen),
      );
      expect(quiz.config.partIds, {ictPart});
      expect(
        quiz.overrideQuestions!.map((q) => q.uid).toSet(),
        ict.map((q) => q.uid).toSet(),
      );
      await closeQuiz(tester);
    });

    testWidgets('unsaving on a part page leaves the other parts alone', (
      tester,
    ) async {
      final app = await boot(tester);
      final (ict, teacher) = await saveSome(app);
      await pump(tester, app, const Scaffold(body: NotebookScreen()));
      await openSavedTab(tester);
      await openSavedPart(tester, teacherPart);

      for (var n = 0; n < teacher.length; n++) {
        final unsave = find.byTooltip('ដកចេញពីបញ្ជីរក្សាទុក').first;
        await tester.ensureVisible(unsave);
        await tester.tap(unsave);
        await settle(tester);
      }
      for (final q in teacher) {
        expect(app.progress.isBookmarked(q.uid), isFalse);
      }
      for (final q in ict) {
        expect(app.progress.isBookmarked(q.uid), isTrue);
      }

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(row(teacherPart), findsNothing);
      expect(row(ictPart), findsOneWidget);
      expect(find.textContaining('$savedLabel (៣)'), findsOneWidget);
    });
  });
}
