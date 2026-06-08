import 'package:flutter_test/flutter_test.dart';

import 'package:fajr_alarm/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FajrApp());
    expect(find.text('Fajr Alarm'), findsOneWidget);
  });
}
