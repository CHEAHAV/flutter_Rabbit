import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:rabbit/widgets/celebration_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(resetCelebrationForTesting);

  Future<BuildContext> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('host'))),
    );
    return tester.element(find.text('host'));
  }

  test('the bundled animation is declared, loads and parses', () async {
    final comp = await precacheCelebration();
    expect(comp, isNotNull, reason: '$celebrationLottieAsset failed to load');
    expect(comp!.duration, const Duration(milliseconds: 2500));
  });

  testWidgets('a correct answer shows the trophy animation, then leaves', (
    tester,
  ) async {
    await tester.runAsync(precacheCelebration);
    final context = await pumpHost(tester);

    showCelebrationOverlay(context);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(Lottie), findsOneWidget);
    expect(find.text('ត្រឹមត្រូវ!'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2600));
    expect(find.byType(Lottie), findsNothing);
    expect(find.text('ត្រឹមត្រូវ!'), findsNothing);
  });

  testWidgets('answering again replaces the card instead of stacking', (
    tester,
  ) async {
    await tester.runAsync(precacheCelebration);
    final context = await pumpHost(tester);

    showCelebrationOverlay(context);
    await tester.pump(const Duration(milliseconds: 800));
    showCelebrationOverlay(context);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('ត្រឹមត្រូវ!'), findsOneWidget);

    // The second card runs its full length from when it was shown.
    await tester.pump(const Duration(milliseconds: 2000));
    expect(find.text('ត្រឹមត្រូវ!'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('ត្រឹមត្រូវ!'), findsNothing);
  });

  testWidgets('dismiss removes the card at once', (tester) async {
    await tester.runAsync(precacheCelebration);
    final context = await pumpHost(tester);

    showCelebrationOverlay(context);
    await tester.pump(const Duration(milliseconds: 300));
    dismissCelebrationOverlay();
    await tester.pump();
    expect(find.text('ត្រឹមត្រូវ!'), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('shows a checkmark while the animation is not loaded', (
    tester,
  ) async {
    final context = await pumpHost(tester);

    showCelebrationOverlay(context);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('ត្រឹមត្រូវ!'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    await tester.runAsync(precacheCelebration);
    await tester.pump(const Duration(milliseconds: 2600));
    expect(find.text('ត្រឹមត្រូវ!'), findsNothing);
  });
}
