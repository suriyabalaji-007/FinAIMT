import 'package:flutter_test/flutter_test.dart';
import 'package:fin_aimt/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('FinAIMT App Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: FinAIMTApp(),
      ),
    );

    // Verify that the dashboard is loaded (Home text should be present)
    expect(find.text('Welcome back,'), findsOneWidget);
  });
}
