import 'dart:async';

import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("FeatureOverlayConfig", () {
    final List<FeatureOverlayEvent> events = [];
    late StreamController<FeatureOverlayEvent> eventController;
    late StreamController<FeatureOverlayEvent> eventController2;
    late FeatureOverlayConfig baseConfig;

    setUpAll(() {
      eventController = StreamController<FeatureOverlayEvent>();
      eventController.stream.listen((event) => events.add(event));
      eventController2 = StreamController<FeatureOverlayEvent>();
    });
    tearDownAll(() {
      eventController.close();
      eventController2.close();
    });
    setUp(() {
      events.clear();
      baseConfig = FeatureOverlayConfig(
          enablePulsingAnimation: false,
          layerLink: LayerLink(),
          activeFeatureId: "myFeature",
          eventsSink: eventController.sink,
          child: FeatureOverlay(
              featureId: "myFeature", tapTarget: Icon(Icons.ac_unit)));
    });

    group("updateShouldNotify", () {
      test("all is the same", () {
        expect(
            baseConfig.updateShouldNotify(FeatureOverlayConfig(
              enablePulsingAnimation: baseConfig.enablePulsingAnimation,
              layerLink: baseConfig.layerLink,
              activeFeatureId: baseConfig.activeFeatureId,
              eventsSink: baseConfig.eventsSink,
              child: baseConfig.child,
              openDuration: baseConfig.openDuration,
              dismissDuration: baseConfig.dismissDuration,
              completeDuration: baseConfig.completeDuration,
              pulseDuration: baseConfig.pulseDuration,
            )),
            equals(false));
      });
      test("enablePulsingAnimation is different", () {
        expect(
            baseConfig.updateShouldNotify(FeatureOverlayConfig(
              enablePulsingAnimation: true,
              layerLink: baseConfig.layerLink,
              activeFeatureId: baseConfig.activeFeatureId,
              eventsSink: baseConfig.eventsSink,
              child: baseConfig.child,
              openDuration: baseConfig.openDuration,
              dismissDuration: baseConfig.dismissDuration,
              completeDuration: baseConfig.completeDuration,
              pulseDuration: baseConfig.pulseDuration,
            )),
            equals(true));
      });
      test("layerLink is different", () {
        expect(
            baseConfig.updateShouldNotify(FeatureOverlayConfig(
              enablePulsingAnimation: baseConfig.enablePulsingAnimation,
              layerLink: LayerLink(),
              activeFeatureId: baseConfig.activeFeatureId,
              eventsSink: baseConfig.eventsSink,
              child: baseConfig.child,
              openDuration: baseConfig.openDuration,
              dismissDuration: baseConfig.dismissDuration,
              completeDuration: baseConfig.completeDuration,
              pulseDuration: baseConfig.pulseDuration,
            )),
            equals(true));
      });
      test("activeFeatureId is different", () {
        expect(
            baseConfig.updateShouldNotify(FeatureOverlayConfig(
              enablePulsingAnimation: baseConfig.enablePulsingAnimation,
              layerLink: baseConfig.layerLink,
              activeFeatureId: "different",
              eventsSink: baseConfig.eventsSink,
              child: baseConfig.child,
              openDuration: baseConfig.openDuration,
              dismissDuration: baseConfig.dismissDuration,
              completeDuration: baseConfig.completeDuration,
              pulseDuration: baseConfig.pulseDuration,
            )),
            equals(true));
      });
      test("eventsSink is different", () {
        expect(
            baseConfig.updateShouldNotify(FeatureOverlayConfig(
              enablePulsingAnimation: baseConfig.enablePulsingAnimation,
              layerLink: baseConfig.layerLink,
              activeFeatureId: baseConfig.activeFeatureId,
              eventsSink: eventController2.sink,
              child: baseConfig.child,
              openDuration: baseConfig.openDuration,
              dismissDuration: baseConfig.dismissDuration,
              completeDuration: baseConfig.completeDuration,
              pulseDuration: baseConfig.pulseDuration,
            )),
            equals(true));
      });
     
      test("child is different", () {
        expect(
            baseConfig.updateShouldNotify(FeatureOverlayConfig(
              enablePulsingAnimation: baseConfig.enablePulsingAnimation,
              layerLink: baseConfig.layerLink,
              activeFeatureId: baseConfig.activeFeatureId,
              eventsSink: baseConfig.eventsSink,
              child: Container(),
              openDuration: baseConfig.openDuration,
              dismissDuration: baseConfig.dismissDuration,
              completeDuration: baseConfig.completeDuration,
              pulseDuration: baseConfig.pulseDuration,
            )),
            equals(true));
      });

      test("openDuration is diffetent", () {
        expect(
            baseConfig.updateShouldNotify(FeatureOverlayConfig(
              enablePulsingAnimation: baseConfig.enablePulsingAnimation,
              layerLink: baseConfig.layerLink,
              activeFeatureId: baseConfig.activeFeatureId,
              eventsSink: baseConfig.eventsSink,
              child: baseConfig.child,
              openDuration: Duration(milliseconds: 10000000),
              dismissDuration: baseConfig.dismissDuration,
              completeDuration: baseConfig.completeDuration,
              pulseDuration: baseConfig.pulseDuration,
            )),
            equals(true));
      });
      test("dismissDuration is different", () {
        expect(
            baseConfig.updateShouldNotify(FeatureOverlayConfig(
              enablePulsingAnimation: baseConfig.enablePulsingAnimation,
              layerLink: baseConfig.layerLink,
              activeFeatureId: baseConfig.activeFeatureId,
              eventsSink: baseConfig.eventsSink,
              child: baseConfig.child,
              openDuration: baseConfig.openDuration,
              dismissDuration: Duration(milliseconds: 10000000),
              completeDuration: baseConfig.completeDuration,
              pulseDuration: baseConfig.pulseDuration,
            )),
            equals(true));
      });
      test("completeDuration is different", () {
        expect(
            baseConfig.updateShouldNotify(FeatureOverlayConfig(
              enablePulsingAnimation: baseConfig.enablePulsingAnimation,
              layerLink: baseConfig.layerLink,
              activeFeatureId: baseConfig.activeFeatureId,
              eventsSink: baseConfig.eventsSink,
              child: baseConfig.child,
              openDuration: baseConfig.openDuration,
              dismissDuration: baseConfig.dismissDuration,
              completeDuration: Duration(milliseconds: 10000000),
              pulseDuration: baseConfig.pulseDuration,
            )),
            equals(true));
      });
      test("pulseDuration is different", () {
        expect(
            baseConfig.updateShouldNotify(FeatureOverlayConfig(
              enablePulsingAnimation: baseConfig.enablePulsingAnimation,
              layerLink: baseConfig.layerLink,
              activeFeatureId: baseConfig.activeFeatureId,
              eventsSink: baseConfig.eventsSink,
              child: baseConfig.child,
              openDuration: baseConfig.openDuration,
              dismissDuration: baseConfig.dismissDuration,
              completeDuration: baseConfig.completeDuration,
              pulseDuration: Duration(milliseconds: 10000000),
            )),
            equals(true));
      });
    });
  });
}
