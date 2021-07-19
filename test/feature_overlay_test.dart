import 'dart:async';

import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'widgets.dart';

void main() {
  group("FeatureOverlay", () {
    final List<FeatureOverlayEvent> events = [];
    final eventController = StreamController<FeatureOverlayEvent>();

    setUpAll(() {
      eventController.stream.listen((event) => events.add(event));
    });
    tearDownAll(() {
      eventController.close();
    });
    setUp(() {
      events.clear();
    });

    testWidgets("Doesnt animate when enablePulsingAnimation is false",
        (WidgetTester tester) async {
      await (TestWidgetsFlutterBinding.ensureInitialized()
              as TestWidgetsFlutterBinding)
          .setSurfaceSize(const Size(3e2, 4e3));

      await tester.pumpWidget(MinimalTestWrapper(
          child: FeatureOverlayConfig(
              enablePulsingAnimation: false,
              layerLink: LayerLink(),
              activeFeatureId: "myFeature",
              eventsSink: eventController.sink,
              child: FeatureOverlay(
                  featureId: "myFeature", tapTarget: Icon(Icons.ac_unit)))));

      await tester.pumpAndSettle(Duration(milliseconds: 1100));
    });

    testWidgets(
        "depending on active id in config it transitions: closed -> opening -> opened -> dismissing -> closed",
        (WidgetTester tester) async {
      const screenSize = const Size(3e2, 4e3);
      await (TestWidgetsFlutterBinding.ensureInitialized()
              as TestWidgetsFlutterBinding)
          .setSurfaceSize(screenSize);
      await tester.pumpWidget(MinimalTestWrapper(
          screenSize: screenSize,
          child: FeatureOverlayConfig(
              enablePulsingAnimation: false,
              layerLink: LayerLink(),
              activeFeatureId: "myFeature",
              eventsSink: eventController.sink,
              openDuration: Duration(milliseconds: 2000),
              child: FeatureOverlay(
                  featureId: "myFeature", tapTarget: Icon(Icons.ac_unit)))));

      await tester.pump(Duration(milliseconds: 1100));
      expect(
          events,
          orderedEquals([
            FeatureOverlayEvent(
                state: FeatureOverlayState.opening,
                previousState: FeatureOverlayState.closed,
                featureId: "myFeature")
          ]));
      events.clear();
      await tester.pump(Duration(milliseconds: 901));
      expect(
          events,
          orderedEquals([
            FeatureOverlayEvent(
                state: FeatureOverlayState.opened,
                previousState: FeatureOverlayState.opening,
                featureId: "myFeature")
          ]));
      events.clear();
      await tester.pumpWidget(MinimalTestWrapper(
          screenSize: screenSize,
          child: FeatureOverlayConfig(
              enablePulsingAnimation: false,
              layerLink: LayerLink(),
              activeFeatureId: null,
              eventsSink: eventController.sink,
              openDuration: Duration(milliseconds: 2000),
              dismissDuration: Duration(milliseconds: 2000),
              completeDuration: Duration(milliseconds: 10),
              child: FeatureOverlay(
                  featureId: "myFeature", tapTarget: Icon(Icons.ac_unit)))));
      await tester.pump(Duration(milliseconds: 1000));
      expect(
          events,
          orderedEquals([
            FeatureOverlayEvent(
                state: FeatureOverlayState.dismissing,
                previousState: FeatureOverlayState.opened,
                featureId: "myFeature")
          ]));
      events.clear();
      await tester.pump(Duration(milliseconds: 1001));
      expect(
          events,
          orderedEquals([
            FeatureOverlayEvent(
                state: FeatureOverlayState.closed,
                previousState: FeatureOverlayState.dismissing,
                featureId: "myFeature")
          ]));
    });
    testWidgets("when hitting tap target: sink is notified.",
        (WidgetTester tester) async {
      const screenSize = const Size(3e2, 4e3);
      await (TestWidgetsFlutterBinding.ensureInitialized()
              as TestWidgetsFlutterBinding)
          .setSurfaceSize(screenSize);

      await tester.pumpWidget(MinimalTestWrapper(
          screenSize: screenSize,
          child: FeatureOverlayConfig(
              enablePulsingAnimation: false,
              layerLink: LayerLink(),
              activeFeatureId: "myFeature",
              eventsSink: eventController.sink,
              child: FeatureOverlay(
                  featureId: "myFeature", tapTarget: Icon(Icons.ac_unit)))));
      await tester.pumpAndSettle();
      events.clear();
      await tester.tap(find.byIcon(Icons.ac_unit));
      expect(
          events,
          orderedEquals([
            FeatureOverlayEvent(
                state: FeatureOverlayState.completing,
                previousState: FeatureOverlayState.opened,
                featureId: "myFeature")
          ]));
    });
  });
}
