import 'package:flutter_test/flutter_test.dart';
import 'package:ojol_daily/main.dart';

void main() {
  testWidgets('App initializes successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const OjolDailyApp());
    expect(find.text('Ojol Daily'), findsOneWidget);
  });
}
