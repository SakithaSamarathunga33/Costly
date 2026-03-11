import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ExpenseTrackerApp());
    // Basic smoke test — app should render without crashing
    expect(find.text('COSTLY'), findsAny);
  });
}
