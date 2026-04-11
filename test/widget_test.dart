import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/providers/theme_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final themeProvider = ThemeProvider();
    await tester.pumpWidget(ExpenseTrackerApp(themeProvider: themeProvider));
    // Basic smoke test — app should render without crashing
    expect(find.text('COSTLY'), findsAny);
  });
}
