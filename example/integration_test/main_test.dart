import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';

// The application under test.
import 'package:example/main.dart' as app;

extension TestWidgetTester on WidgetTester {
  Future<void> tapAndSettle(Finder finder) async {
    await this.tap(finder);
    await pumpAndSettle();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('tap on the floating action button; verify counter',
        (WidgetTester tester) async {
      runApp(app.MyApp(disableAnimations: true,));

      await tester.pumpAndSettle();

      final Finder ac = find.byIcon(Icons.ac_unit);
      await tester.tapAndSettle(ac);

      // Finds the floating action button to tap on.
      final Finder fab = find.byTooltip('Increment');
      // Emulate a tap on the floating action button.
      await tester.tapAndSettle(fab);

      expect(find.text('1'), findsOneWidget);
    });
  });
}