import 'dart:async';

import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:feature_discovery_widget/src/feature_overlay_config_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'widgets.dart';

void main() {
  group("IndexedFeatureOverlay", () {
    testWidgets(
        "Reinserts Overlay when displayed overlay, completed overlay and then resetted completion states.",
        (WidgetTester tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();

      final providerKey = GlobalKey<FeatureOverlayConfigProviderState>();

      await tester.pumpWidget(MinimalTestWrapper(
          child: Scaffold(
              body: FeatureOverlayConfigProvider(
                  key: providerKey,
                  enablePulsingAnimation: false,
                  openDuration: Duration(milliseconds: 0),
                  dismissDuration: Duration(milliseconds: 0),
                  child: IndexedFeatureOverlay(
                      featureOverlays: {
                        FeatureOverlay(
                            featureId: "myFeature",
                            tapTarget: Icon(Icons.ac_unit))
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment
                            .spaceBetween, //make sure overlay is far away
                        children: [
                          FeatureOverlayTarget(
                              featureId: "myFeature", child: Container()),
                          IconButton(
                              onPressed: () => null,
                              icon: Icon(Icons.access_alarm)),
                        ],
                      ))))));

      providerKey.currentState!.notifyActiveFeature("myFeature");

      await tester.pump(Duration(milliseconds: 1));

      // overlay is present
      expect(tester.widget(find.byIcon(Icons.ac_unit)), isNot(equals(null)));

      // dismiss
      providerKey.currentState!.notifyActiveFeature(null);

      await tester.pump(Duration(milliseconds: 1));

      // to check the overlay is gone from the tree,
      // we check if the icon of the overlay child
      // cannot be found anymore in the tree.
      expect(tester.elementList(find.byIcon(Icons.ac_unit)), equals([]));

      // we reactive the feature
      providerKey.currentState!.notifyActiveFeature("myFeature");

      await tester.pump(Duration(milliseconds: 1));

      // overlay is present again after resetting the completed features
      expect(tester.widget(find.byIcon(Icons.ac_unit)), isNot(equals(null)));
    });
  });
}
