import 'package:flutter_test/flutter_test.dart';

import 'package:inkstudio/main.dart';

void main() {
  testWidgets('opening page renders and opens the canvas', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const InkApp());

    expect(find.text('InkStudio'), findsOneWidget);
    expect(find.text('Start Drawing'), findsOneWidget);

    await tester.tap(find.text('Start Drawing'));
    await tester.pumpAndSettle();

    expect(find.text('Canvas'), findsOneWidget);
  });
}

