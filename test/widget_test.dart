// Smoke test: the Rabbit app boots to the splash screen without throwing.

import 'package:flutter_test/flutter_test.dart';

import 'package:rabbit/app.dart';

void main() {
  testWidgets('Rabbit app boots and shows splash branding', (WidgetTester tester) async {
    await tester.pumpWidget(const RabbitApp());
    await tester.pump();

    expect(find.text('Rabbit'), findsOneWidget);
  });
}
