// Basic smoke test for Quizistan Academy.
// Verifies the app widget builds without crashing. Firebase/AdMob are
// stub-safe at startup (see main.dart), so no config is needed for this test.

import 'package:flutter_test/flutter_test.dart';

import 'package:quizistan_academy/main.dart';

void main() {
  testWidgets('QuizistanApp builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const QuizistanApp());
    await tester.pump();
    expect(find.byType(QuizistanApp), findsOneWidget);
  });
}
