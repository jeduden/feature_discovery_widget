import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'widgets.dart';

/*
void main() {
group('OverflowMode', () {
    const icon = Icons.error;
    const featureId = 'feature';

    // Declares what OverflowMode's should allow the button to be tapped.
    const modes = <OverflowMode, bool>{
      OverflowMode.ignore: false,
      OverflowMode.extendBackground: false,
      OverflowMode.wrapBackground: false,
      OverflowMode.clipContent: true,
    };

    for (final modeEntry in modes.entries) {
      testWidgets(modeEntry.key.toString(), (WidgetTester tester) async {
        var triggered = false;

        // The surface size is set to ensure that the minimum overlay background size
        // does not cover the button, but the content does.
        // The values here are somewhat arbitrary, but the main focus is ensuring that
        // the minimum value (3e2 width in this case) is a lot smaller than the maximum value (4e3 height)
        // because the background will use the minimum screen dimension as its radius and the icon needs
        // to be outside of the background area because that would cover the icon for every entry mode.
        //
        // The Container that makes the content of the feature overlay of the test widget has a static
        // height of 9e3, which ensures that the content definitely covers the 4e3 surface size height
        // if OverflowMode.clipContent is not enabled.
        await (TestWidgetsFlutterBinding.ensureInitialized()
                as TestWidgetsFlutterBinding)
            .setSurfaceSize(const Size(3e2, 4e3));

        await tester.pumpWidget(
          OverflowingDescriptionFeature(
            // This will be called when the content does not cover the icon.
            onDismiss: (featureId) {
              triggered = true;
            },
            featureId: featureId,
            icon: icon,
            mode: modeEntry.key,
          ),
        );


        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(icon));
        expect(triggered, modeEntry.value);
      });
    }
  });
}*/