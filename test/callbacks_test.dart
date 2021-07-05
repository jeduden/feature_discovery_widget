import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'widgets.dart';
import 'package:mockito/mockito.dart';

abstract class Callback {
  void call(String featureId);
}

class MockCallback extends Mock implements Callback {}

void main() {
  final mockOnFinishedOpening = MockCallback();
  final mockOnComplete = MockCallback();
  final mockOnFinishedClosing = MockCallback();
  final mockOnDismiss = MockCallback();

  setUp(() {
    reset(mockOnFinishedOpening);
    reset(mockOnComplete);
    reset(mockOnFinishedClosing);
    reset(mockOnDismiss);
  });
  testWidgets("when completing call order is onFinishedOpening, onComplete, onFinishedClosing ",
      (WidgetTester tester) async {

    await (TestWidgetsFlutterBinding.ensureInitialized()
            as TestWidgetsFlutterBinding)
        .setSurfaceSize(const Size(3e2, 4e3));

    await tester.pumpWidget(
      OverflowingDescriptionFeature(
        onFinishedOpening: mockOnFinishedOpening,
        onFinishedClosing: mockOnFinishedClosing,
        onComplete: mockOnComplete,
        onDismiss: mockOnDismiss,
        featureId: "feature",
        icon: Icons.ac_unit,
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.ac_unit));
    verifyInOrder([
      mockOnFinishedOpening("feature"),
      mockOnComplete("feature"),
      mockOnFinishedClosing("feature")
    ]);
    verifyNever(mockOnDismiss);
  });
}
