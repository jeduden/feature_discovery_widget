import 'dart:async';

import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:feature_discovery_widget/src/feature_overlay_config_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'widgets.dart';

void main() {
  group("IndexedFeatureOverlay", () {
    late StreamController<Set<String>> completeFeaturesStreamController;
    StreamSubscription<FeatureOverlayEvent>? eventSubscription;

    setUp(() {
      completeFeaturesStreamController =
          StreamController<Set<String>>.broadcast();
    });
    tearDown(() {
      completeFeaturesStreamController.close();
      eventSubscription?.cancel();
    });

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
     final List<FeatureOverlayEvent> events = List.empty(growable: true);
      providerKey.currentState!.events.listen((event) {
        events.add(event);
      });
      await tester.pump(Duration(milliseconds: 2100));
      await tester.pump(Duration(milliseconds: 1100));
      events.clear();

      // overlay is present
      expect(tester.widget(find.byIcon(Icons.ac_unit)), isNot(equals(null)));

      // dismiss
      await tester.tap(find.byIcon(Icons.access_alarm));
      await tester.pump(Duration(milliseconds: 1100));
      // confirm we got a dismiss event
      expect(
          events,
          orderedEquals([
            FeatureOverlayEvent(
                state: FeatureOverlayState.dismissing,
                previousState: FeatureOverlayState.opened,
                featureId: "myFeature")
          ]));
      events.clear();
      await tester.pumpAndSettle(Duration(milliseconds: 2100));
      expect(
          events,
          orderedEquals([
            FeatureOverlayEvent(
                state: FeatureOverlayState.closed,
                previousState: FeatureOverlayState.dismissing,
                featureId: "myFeature")
          ]));
      await tester.pumpAndSettle(Duration(milliseconds: 2100));

      // to check the overlay is gone from the tree, 
      // we check if the icon of the overlay child
      // cannot be found anymore in the tree.
      expect(tester.widget(find.byIcon(Icons.ac_unit)), equals(null));

      completeFeaturesStreamController.add(<String>{});
      await tester.pumpAndSettle(Duration(milliseconds: 1100));

      // overlay is present after resetting the completed features
      expect(tester.widget(find.byIcon(Icons.ac_unit)), isNot(equals(null)));
    });
  });
}
