// Tests for the sound/volume feature: the service logic (mute, volume curve,
// failure handling), the persisted settings, and - most importantly - that the
// REAL screens trigger the right sound (correct / wrong / buttons / results)
// and respect the on/off + volume controls. A recording fake stands in for the
// audio device so this runs anywhere.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rabbit/models/exam_config.dart';
import 'package:rabbit/models/exam_part.dart';
import 'package:rabbit/models/exam_result.dart';
import 'package:rabbit/models/question_attempt.dart';
import 'package:rabbit/screens/home_shell.dart';
import 'package:rabbit/screens/profile_screen.dart';
import 'package:rabbit/screens/quiz_session_screen.dart';
import 'package:rabbit/screens/result_screen.dart';
import 'package:rabbit/services/progress_service.dart';
import 'package:rabbit/services/sound_service.dart';
import 'package:rabbit/state/app_state.dart';
import 'package:rabbit/theme/app_theme.dart';

class PlayedSound {
  final AppSound sound;
  final double volume;
  PlayedSound(this.sound, this.volume);
  @override
  String toString() => '${sound.name}@${volume.toStringAsFixed(3)}';
}

class FakeBackend implements SoundBackend {
  final List<PlayedSound> played = [];
  bool failInit = false;
  bool failPlay = false;
  bool initialised = false;

  List<AppSound> get sounds => played.map((p) => p.sound).toList();

  @override
  Future<void> init() async {
    if (failInit) throw Exception('no audio device');
    initialised = true;
  }

  @override
  Future<void> play(AppSound sound, double volume) async {
    if (failPlay) throw Exception('playback failed');
    played.add(PlayedSound(sound, volume));
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SoundService', () {
    late FakeBackend backend;
    late SoundService svc;

    setUp(() async {
      backend = FakeBackend();
      svc = SoundService.withBackend(backend);
      await svc.init();
    });

    test('plays a sound at the volume curve x the sound gain', () {
      svc.configure(enabled: true, volume: 0.5);
      svc.answer(correct: true);
      expect(backend.played, hasLength(1));
      expect(backend.played.single.sound, AppSound.correct);
      expect(
        backend.played.single.volume,
        closeTo(SoundService.amplitudeFor(0.5) * AppSound.correct.gain, 1e-9),
      );
    });

    test('maps every helper to the right sound', () {
      svc.configure(enabled: true, volume: 1);
      svc.tap();
      svc.select();
      svc.toggle(true);
      svc.toggle(false);
      svc.answer(correct: true);
      svc.answer(correct: false);
      svc.result(passed: true);
      svc.result(passed: false);
      svc.warning();
      expect(backend.sounds, [
        AppSound.tap,
        AppSound.select,
        AppSound.toggleOn,
        AppSound.toggleOff,
        AppSound.correct,
        AppSound.wrong,
        AppSound.success,
        AppSound.fail,
        AppSound.warning,
      ]);
    });

    test('is completely silent when switched off', () {
      svc.configure(enabled: false, volume: 1);
      svc.tap();
      svc.answer(correct: false);
      expect(backend.played, isEmpty);
    });

    test('is silent when the volume is zero', () {
      svc.configure(enabled: true, volume: 0);
      svc.tap();
      expect(svc.audible, isFalse);
      expect(backend.played, isEmpty);
    });

    test('louder slider => strictly louder output; max is full scale', () {
      double at(double v) {
        backend.played.clear();
        svc.configure(enabled: true, volume: v);
        svc.answer(correct: true); // gain 1.0
        return backend.played.single.volume;
      }

      final levels = [0.1, 0.25, 0.5, 0.75, 1.0].map(at).toList();
      for (var i = 1; i < levels.length; i++) {
        expect(levels[i], greaterThan(levels[i - 1]));
      }
      expect(levels.last, closeTo(1.0, 1e-9));
      for (final s in AppSound.values) {
        backend.played.clear();
        svc.configure(enabled: true, volume: 1);
        svc.play(s);
        expect(backend.played.single.volume, inInclusiveRange(0.0, 1.0));
      }
    });

    test('clamps out-of-range volume', () {
      svc.configure(enabled: true, volume: 7);
      expect(svc.volume, 1.0);
      svc.configure(enabled: true, volume: -3);
      expect(svc.volume, 0.0);
    });

    test('a failing backend can never throw into a button press', () {
      backend.failPlay = true;
      svc.configure(enabled: true, volume: 1);
      expect(() => svc.tap(), returnsNormally);
    });

    test(
      'no audio device: init failure leaves the app silent, not broken',
      () async {
        final broken = FakeBackend()..failInit = true;
        final s = SoundService.withBackend(broken);
        s.configure(enabled: true, volume: 1);
        await s.init(); // must not throw
        expect(s.isReady, isFalse);
        expect(() => s.tap(), returnsNormally);
        expect(broken.played, isEmpty);
      },
    );

    test('nothing plays before the sounds have loaded', () {
      final fake = FakeBackend();
      final fresh = SoundService.withBackend(fake);
      fresh.configure(enabled: true, volume: 1);
      fresh.tap(); // init() never called
      expect(fresh.isReady, isFalse);
      expect(fake.played, isEmpty);
    });

    test('every sound maps to a real WAV file in assets/sounds', () {
      // Guards against a typo in AppSound.file or a missing/renamed asset.
      for (final s in AppSound.values) {
        final f = File('assets/sounds/${s.file}');
        expect(f.existsSync(), isTrue, reason: '${s.file} is missing');
        final bytes = f.readAsBytesSync();
        expect(bytes.length, greaterThan(1000), reason: '${s.file} is empty');
        expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
        expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
      }
    });
  });

  group('settings persistence (AppState)', () {
    late FakeBackend backend;

    Future<AppState> boot(WidgetTester tester) async {
      backend = FakeBackend();
      sfx.useBackendForTesting(backend);
      final app = AppState();
      await tester.runAsync(() async {
        await app.bootstrap();
        await sfx.init();
      });
      return app;
    }

    testWidgets('defaults: on, 70%', (tester) async {
      SharedPreferences.setMockInitialValues({});
      ProgressService.instance.resetForTesting();
      final app = await boot(tester);
      expect(app.soundEnabled, isTrue);
      expect(app.soundVolume, 0.7);
      expect(app.soundMuted, isFalse);
    });

    testWidgets(
      'on/off and volume are written to storage and reloaded at boot',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        ProgressService.instance.resetForTesting();
        var app = await boot(tester);
        await tester.runAsync(() async {
          await app.setSoundVolume(0.35);
          await app.setSoundEnabled(false);
        });

        // "Restart": fresh AppState + fresh prefs singleton reading the store.
        final stored = await tester.runAsync(SharedPreferences.getInstance);
        await tester.runAsync(() => stored!.reload());
        // ProgressService.init() is a no-op once ready, so read via its getters
        // to prove the values were written to disk.
        expect(stored!.getBool('rabbit.soundEnabled'), isFalse);
        expect(stored.getDouble('rabbit.soundVolume'), closeTo(0.35, 1e-9));

        app = await boot(tester);
        expect(app.soundEnabled, isFalse);
        expect(app.soundVolume, closeTo(0.35, 1e-9));
      },
    );

    testWidgets('dragging to zero = muted; dragging up = audible again', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      ProgressService.instance.resetForTesting();
      final app = await boot(tester);
      await tester.runAsync(() => app.setSoundVolume(0.0));
      expect(app.soundMuted, isTrue);
      await tester.runAsync(() => app.setSoundVolume(0.4));
      expect(app.soundMuted, isFalse);
      expect(app.soundEnabled, isTrue);
    });

    testWidgets('turning sound on from zero volume restores an audible level', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      ProgressService.instance.resetForTesting();
      final app = await boot(tester);
      await tester.runAsync(() => app.setSoundVolume(0.0));
      await tester.runAsync(() => app.setSoundEnabled(true));
      expect(app.soundVolume, SoundService.defaultVolume);
      expect(app.soundMuted, isFalse);
    });

    testWidgets('turning on plays a confirmation blip; turning off is silent', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      ProgressService.instance.resetForTesting();
      final app = await boot(tester);
      await tester.runAsync(() => app.setSoundEnabled(false));
      expect(backend.played, isEmpty);
      await tester.runAsync(() => app.setSoundEnabled(true));
      expect(backend.sounds, [AppSound.toggleOn]);
    });
  });

  group('real screens trigger the right sounds', () {
    late FakeBackend backend;
    late AppState app;

    Future<void> pumpApp(WidgetTester tester, Widget child) async {
      SharedPreferences.setMockInitialValues({});
      ProgressService.instance.resetForTesting();
      backend = FakeBackend();
      sfx.useBackendForTesting(backend);
      app = AppState();
      await tester.runAsync(() async {
        await app.bootstrap();
        await sfx.init();
      });
      tester.view.physicalSize = const Size(400, 900);
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
      await tester.pump(const Duration(milliseconds: 50));
    }

    ExamConfig practiceConfig({bool instant = true}) => ExamConfig(
      mode: ExamMode.practice,
      partIds: const {},
      questionCount: 2,
      timeLimit: null,
      shuffleQuestions: false,
      instantFeedback: instant,
    );

    testWidgets('CORRECT answer plays the correct chime', (tester) async {
      SharedPreferences.setMockInitialValues({});
      ProgressService.instance.resetForTesting();
      final part = (await _loadedParts(tester)).first;
      final qs = part.questions.take(2).toList();
      await pumpApp(
        tester,
        QuizSessionScreen(config: practiceConfig(), overrideQuestions: qs),
      );
      await tester.tap(find.text(qs[0].options[qs[0].answerIndex]));
      await tester.pump(const Duration(milliseconds: 100));
      expect(backend.sounds, [AppSound.correct]);
      await tester.pump(const Duration(seconds: 3)); // let celebration finish
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('WRONG answer plays the wrong sound', (tester) async {
      SharedPreferences.setMockInitialValues({});
      ProgressService.instance.resetForTesting();
      final part = (await _loadedParts(tester)).first;
      final qs = part.questions.take(2).toList();
      await pumpApp(
        tester,
        QuizSessionScreen(config: practiceConfig(), overrideQuestions: qs),
      );
      final wrongIndex = (qs[0].answerIndex + 1) % 4;
      await tester.tap(find.text(qs[0].options[wrongIndex]));
      await tester.pump(const Duration(milliseconds: 100));
      expect(backend.sounds, [AppSound.wrong]);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('exam mode (no instant feedback) plays a neutral select tick, '
        'not correct/wrong', (tester) async {
      SharedPreferences.setMockInitialValues({});
      ProgressService.instance.resetForTesting();
      final part = (await _loadedParts(tester)).first;
      final qs = part.questions.take(2).toList();
      await pumpApp(
        tester,
        QuizSessionScreen(
          config: practiceConfig(instant: false),
          overrideQuestions: qs,
        ),
      );
      await tester.tap(find.text(qs[0].options[qs[0].answerIndex]));
      await tester.pump(const Duration(milliseconds: 100));
      expect(backend.sounds, [AppSound.select]);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('next / previous / flag / grid buttons all click', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      ProgressService.instance.resetForTesting();
      final part = (await _loadedParts(tester)).first;
      final qs = part.questions.take(3).toList();
      await pumpApp(
        tester,
        QuizSessionScreen(
          config: practiceConfig(instant: false),
          overrideQuestions: qs,
        ),
      );
      await tester.tap(find.text('បន្ទាប់ →'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('← សំណួរមុន'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('ចំណាំទុក'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byIcon(Icons.grid_view_rounded));
      await tester.pump(const Duration(milliseconds: 400));
      expect(backend.sounds, everyElement(AppSound.tap));
      expect(backend.sounds, hasLength(4));
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('muted => wrong/correct/buttons are all silent', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      ProgressService.instance.resetForTesting();
      final part = (await _loadedParts(tester)).first;
      final qs = part.questions.take(2).toList();
      await pumpApp(
        tester,
        QuizSessionScreen(config: practiceConfig(), overrideQuestions: qs),
      );
      await tester.runAsync(() => app.setSoundEnabled(false));
      await tester.pump();
      await tester.tap(find.text(qs[0].options[(qs[0].answerIndex + 1) % 4]));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('បន្ទាប់ →'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(backend.played, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('in-quiz speaker button mutes and unmutes', (tester) async {
      SharedPreferences.setMockInitialValues({});
      ProgressService.instance.resetForTesting();
      final part = (await _loadedParts(tester)).first;
      final qs = part.questions.take(2).toList();
      await pumpApp(
        tester,
        QuizSessionScreen(config: practiceConfig(), overrideQuestions: qs),
      );
      await tester.tap(find.byIcon(Icons.volume_up_rounded));
      await tester.pump(const Duration(milliseconds: 50));
      expect(app.soundMuted, isTrue);
      expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.volume_off_rounded));
      await tester.pump(const Duration(milliseconds: 50));
      expect(app.soundMuted, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('bottom navigation tabs click', (tester) async {
      await pumpApp(tester, const HomeShell());
      final mockTab = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('ប្រឡងសាកល្បង'),
      );
      await tester.tap(mockTab);
      await tester.pump(const Duration(milliseconds: 100));
      expect(backend.sounds, [AppSound.tap]);
      // Re-tapping the already-selected tab does not spam a click.
      await tester.tap(mockTab);
      await tester.pump(const Duration(milliseconds: 100));
      expect(backend.sounds, [AppSound.tap]);
    });

    ExamResult resultWith({required bool pass}) {
      final part = app.repo.parts.firstWhere((p) => p.count >= 4);
      final qs = part.questions.take(4).toList();
      return ExamResult(
        completedAt: DateTime.now(),
        config: ExamConfig(
          mode: ExamMode.practice,
          partIds: {part.id},
          questionCount: 4,
          timeLimit: null,
        ),
        attempts: [
          for (final q in qs)
            QuestionAttempt(
              question: q,
              selectedIndex: pass ? q.answerIndex : (q.answerIndex + 1) % 4,
            ),
        ],
        timeSpent: const Duration(minutes: 3),
      );
    }

    testWidgets('result screen: pass => success fanfare', (tester) async {
      SharedPreferences.setMockInitialValues({});
      ProgressService.instance.resetForTesting();
      await pumpApp(tester, const SizedBox());
      final r = resultWith(pass: true);
      expect(r.passed, isTrue);
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: app,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: ResultScreen(result: r),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(backend.sounds, [AppSound.success]);
    });

    testWidgets('result screen: fail => encouraging tone', (tester) async {
      SharedPreferences.setMockInitialValues({});
      ProgressService.instance.resetForTesting();
      await pumpApp(tester, const SizedBox());
      final r = resultWith(pass: false);
      expect(r.passed, isFalse);
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: app,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: ResultScreen(result: r),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(backend.sounds, [AppSound.fail]);
    });

    testWidgets('PROFILE: switch turns sound off/on and shows the state', (
      tester,
    ) async {
      await pumpApp(tester, const ProfileScreen());
      expect(find.text('កំពុងបើក — កម្រិត ៧០%'), findsOneWidget);

      // Tap the "Sound" row (toggles off).
      await tester.tap(find.text('សំឡេងកម្មវិធី (Sound)'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(app.soundEnabled, isFalse);
      expect(find.text('បិទ — គ្មានសំឡេង'), findsOneWidget);
      expect(backend.played, isEmpty, reason: 'turning off is silent');

      // Tap again (toggles on) -> blip at the current volume.
      await tester.tap(find.text('សំឡេងកម្មវិធី (Sound)'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(app.soundEnabled, isTrue);
      expect(backend.sounds, [AppSound.toggleOn]);
    });

    testWidgets('PROFILE: slider changes the volume, persists it, and '
        'previews the new level on release', (tester) async {
      await pumpApp(tester, const ProfileScreen());
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);
      expect(tester.widget<Slider>(slider).value, 0.7);

      // Drag the thumb to the far left => volume 0 => muted.
      await tester.drag(slider, const Offset(-600, 0));
      await tester.pump(const Duration(milliseconds: 100));
      expect(app.soundVolume, 0.0);
      expect(app.soundMuted, isTrue);
      expect(find.text('បិទ — គ្មានសំឡេង'), findsOneWidget);
      expect(backend.played, isEmpty, reason: 'silent at zero volume');

      // Drag right => audible again, louder, preview plays on release.
      await tester.drag(slider, const Offset(600, 0));
      await tester.pump(const Duration(milliseconds: 100));
      expect(app.soundVolume, 1.0);
      expect(app.soundMuted, isFalse);
      expect(backend.sounds, [AppSound.select]);
      expect(
        backend.played.single.volume,
        closeTo(AppSound.select.gain, 1e-9),
        reason: 'full volume => full-scale x the select gain',
      );

      final prefs = await tester.runAsync(SharedPreferences.getInstance);
      expect(prefs!.getDouble('rabbit.soundVolume'), 1.0);
    });
  });
}

/// Loads the real question bank (via AppState) to get real questions.
Future<List<ExamPart>> _loadedParts(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  ProgressService.instance.resetForTesting();
  final app = AppState();
  await tester.runAsync(app.bootstrap);
  return app.repo.parts.where((p) => p.count >= 3).toList();
}
