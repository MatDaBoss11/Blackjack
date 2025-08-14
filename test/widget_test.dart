import 'package:flutter_test/flutter_test.dart';

import 'package:blackjack/main.dart';

void main() {
  testWidgets('Blackjack app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BlackjackApp());

    // Verify that our blackjack app has the Deal button
    expect(find.text('Deal'), findsOneWidget);
  });
}