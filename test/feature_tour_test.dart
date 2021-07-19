import 'dart:async';

import 'package:feature_discovery_widget/src/feature_tour.dart';
import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:feature_discovery_widget/src/feature_overlay_config_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'widgets.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  group("FeatureTour with no persistance", () {
    testWidgets("activates first feature by default",
        (WidgetTester tester) async {
      final providerKey = GlobalKey<FeatureOverlayConfigProviderState>();
      await tester.pumpWidget(Builder(builder: (context) {
        return FeatureOverlayConfigProvider(
            key: providerKey,
            enablePulsingAnimation: false,
            child: FeatureTour(featureIds: ["a", "b"], child: Container()));
      }));
      await tester.pumpAndSettle();
      expect(providerKey.currentState!.activeFeatureId, equals("a"));
    });

    testWidgets("activate second feature if first is completed",
        (WidgetTester tester) async {
      final providerKey = GlobalKey<FeatureOverlayConfigProviderState>();
      await tester.pumpWidget(MinimalTestWrapper(
          child: FeatureOverlayConfigProvider(
              key: providerKey,
              enablePulsingAnimation: false,
              child: FeatureTour(featureIds: ["a", "b"], child: Container()))));
      await tester.pumpAndSettle();
      providerKey.currentState!.eventsController.add(FeatureOverlayEvent(
          featureId: "a",
          previousState: FeatureOverlayState.opened,
          state: FeatureOverlayState.completing));
      expect(providerKey.currentState!.activeFeatureId, equals("a"),
          reason: "Feature A must still be active during completing state.");
      providerKey.currentState!.eventsController.add(FeatureOverlayEvent(
          featureId: "a",
          previousState: FeatureOverlayState.completing,
          state: FeatureOverlayState.closed));
      await tester.pumpAndSettle();
      expect(providerKey.currentState!.activeFeatureId, equals("b"));
    });

    testWidgets("resets tour if featureIds change",
        (WidgetTester tester) async {
      final providerKey = GlobalKey<FeatureOverlayConfigProviderState>();
      await tester.pumpWidget(MinimalTestWrapper(
          child: FeatureOverlayConfigProvider(
              key: providerKey,
              enablePulsingAnimation: false,
              child: FeatureTour(featureIds: ["a", "b"], child: Container()))));
      await tester.pumpAndSettle();
      await tester.pumpWidget(MinimalTestWrapper(
          child: FeatureOverlayConfigProvider(
              key: providerKey,
              enablePulsingAnimation: false,
              child: FeatureTour(featureIds: ["d", "e"], child: Container()))));
      await tester.pumpAndSettle();
      expect(providerKey.currentState!.activeFeatureId, equals("d"));
    });

    [
      FeatureOverlayEvent(
          featureId: "a",
          previousState: FeatureOverlayState.closed,
          state: FeatureOverlayState.opening),
      FeatureOverlayEvent(
          featureId: "a",
          previousState: FeatureOverlayState.opening,
          state: FeatureOverlayState.opened)
    ].forEach((event) {
      testWidgets("mark feature as dismissed when dismissing after $event.",
          (WidgetTester tester) async {
        final providerKey = GlobalKey<FeatureOverlayConfigProviderState>();
        await tester.pumpWidget(MinimalTestWrapper(
            child: FeatureOverlayConfigProvider(
                key: providerKey,
                enablePulsingAnimation: false,
                openDuration: Duration(milliseconds: 2000),
                child:
                    FeatureTour(featureIds: ["a", "b"], child: Container()))));
        await tester.pump(Duration(milliseconds: 1000));
        expect(providerKey.currentState!.activeFeatureId, equals("a"));
        providerKey.currentState!.eventsController
          ..add(event)
          ..add(FeatureOverlayEvent(
              featureId: "a",
              state: FeatureOverlayState.dismissing,
              previousState: event.state))
          ..add(FeatureOverlayEvent(
              featureId: "a",
              state: FeatureOverlayState.closed,
              previousState: FeatureOverlayState.dismissing));
        await tester.pumpAndSettle();
        expect(providerKey.currentState!.activeFeatureId, equals(null));
      });
    });

    testWidgets(
        "when all features are completed then no feature will be activated",
        (WidgetTester tester) async {
      final providerKey = GlobalKey<FeatureOverlayConfigProviderState>();
      await tester.pumpWidget(MinimalTestWrapper(
          child: FeatureOverlayConfigProvider(
              key: providerKey,
              enablePulsingAnimation: false,
              child: FeatureTour(featureIds: ["a", "b"], child: Container()))));
      await tester.pumpAndSettle();
      providerKey.currentState!.eventsController
        ..add(FeatureOverlayEvent(
            featureId: "a",
            state: FeatureOverlayState.closed,
            previousState: FeatureOverlayState.completing))
        ..add(FeatureOverlayEvent(
            featureId: "b",
            state: FeatureOverlayState.closed,
            previousState: FeatureOverlayState.completing));
      await tester.pumpAndSettle();
      expect(providerKey.currentState!.activeFeatureId, equals(null));
    });
  });

  group("FeatureTour - with persistence", () {
    testWidgets(
        "completed first feature before initialization and moves to first not completed feature",
        (WidgetTester tester) async {
      final providerKey = GlobalKey<FeatureOverlayConfigProviderState>();
      await tester.pumpWidget(Builder(builder: (context) {
        return FeatureOverlayConfigProvider(
            key: providerKey,
            enablePulsingAnimation: false,
            child: FeatureTour(featureIds: ["a", "b"], child: Container()));
      }));
      await tester.pumpAndSettle();

      expect(providerKey.currentState!.activeFeatureId, equals("b"));
    });
  });
}
