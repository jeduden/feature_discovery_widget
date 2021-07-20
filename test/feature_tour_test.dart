import 'dart:async';

import 'package:feature_discovery_widget/src/feature_tour.dart';
import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:feature_discovery_widget/src/feature_overlay_config_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'widgets.dart';

abstract class OnDismissFunction {
  void call(FeatureTourState? state, String? featureId);
}

class OnDismissMock extends Mock implements OnDismissFunction {}

abstract class StoreFunction {
  Future<void> call(Set<String>? featureIds);
}

class StoreMock extends Mock implements StoreFunction {
  @override
  Future<void> call(Set<String>? featureIds) { 
    return super.noSuchMethod(Invocation.method(#call, [featureIds]),returnValue: Future.value());
  }
}

abstract class LoadFunction {
  Future<Set<String>> call();
}

class LoadMock extends Mock implements LoadFunction {
  @override
  Future<Set<String>> call() { 
    return super.noSuchMethod(Invocation.method(#call, []),returnValue: Future.value(Set<String>.identity()));
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  group("FeatureTour with no callbacks", () {
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

  group("FeatureTour - callbacks", () {
    OnDismissMock? onDismissMock;
    StoreMock? storeMock;
    LoadMock? loadMock;

    setUp(() {
      onDismissMock = OnDismissMock();
      storeMock = StoreMock();
      when(storeMock!.call(any)).thenAnswer((_) async => null);
      when(onDismissMock!.call(any,any)).thenReturn(null);
      loadMock = LoadMock();
    });
    
    testWidgets("activates first feature by default when receiving an empty set from storage",
        (WidgetTester tester) async {
      final providerKey = GlobalKey<FeatureOverlayConfigProviderState>();
      
      when(loadMock!.call()).thenAnswer((_) async => Set<String>.identity());
      
      await tester.pumpWidget(Builder(builder: (context) {
        return FeatureOverlayConfigProvider(
            key: providerKey,
            enablePulsingAnimation: false,
            child: FeatureTour(
              loadCompletedFeatures: loadMock!,
              storeCompletedFeatures: storeMock!,
              featureIds: ["a", "b"], child: Container()));
      }));
      await tester.pumpAndSettle();
      expect(providerKey.currentState!.activeFeatureId, equals("a"));
      verifyInOrder([
        loadMock!(),
        storeMock!(Set.identity())
      ]);
    });

    testWidgets("stores completed feature when in closed state and not during completing state.",
        (WidgetTester tester) async {
      final providerKey = GlobalKey<FeatureOverlayConfigProviderState>();
      await tester.pumpWidget(MinimalTestWrapper(
          child: FeatureOverlayConfigProvider(
              key: providerKey,
              enablePulsingAnimation: false,
              child: FeatureTour(
                storeCompletedFeatures: storeMock!,
                featureIds: ["a", "b"], child: Container()))));
      await tester.pumpAndSettle();
      providerKey.currentState!.eventsController.add(FeatureOverlayEvent(
          featureId: "a",
          previousState: FeatureOverlayState.opened,
          state: FeatureOverlayState.completing));
      verifyNever(storeMock!({"a"}));
      providerKey.currentState!.eventsController.add(FeatureOverlayEvent(
          featureId: "a",
          previousState: FeatureOverlayState.completing,
          state: FeatureOverlayState.closed));
      await tester.pumpAndSettle();
      verify(storeMock!({"a"}));
    });

    testWidgets("when aborting tour pushes all feature ids to storage",
        (WidgetTester tester) async {
      final tourKey = GlobalKey<FeatureTourState>();

      await tester.pumpWidget(MinimalTestWrapper(
          child: FeatureOverlayConfigProvider(
              enablePulsingAnimation: false,
              child: FeatureTour(
                key: tourKey,
                storeCompletedFeatures: storeMock!,
                featureIds: ["a", "b"], child: Container()))));
      await tester.pumpAndSettle();
      clearInteractions(storeMock!);
      await tourKey.currentState!.abortTour();
      verify(storeMock!({"a", "b"}));
    });

    testWidgets("when loading all feature ids from storage no feature is active. when calling resetTour first feature becomes active",
        (WidgetTester tester) async {
      final tourKey = GlobalKey<FeatureTourState>();
      final providerKey = GlobalKey<FeatureOverlayConfigProviderState>();

      when(loadMock!.call()).thenAnswer((_) async => {"a","b"});

      await tester.pumpWidget(MinimalTestWrapper(
          child: FeatureOverlayConfigProvider(
              key: providerKey,
              enablePulsingAnimation: false,
              child: FeatureTour(
                key: tourKey,
                storeCompletedFeatures: storeMock!,
                loadCompletedFeatures: loadMock!,
                featureIds: ["a", "b"], child: Container()))));
      await tester.pumpAndSettle();
      expect(providerKey.currentState!.activeFeatureId, equals(null));
      clearInteractions(storeMock!);
      await tourKey.currentState!.resetTour();
      verify(storeMock!({}));
    });

    testWidgets("when featureIds change resets tour  pushes empty set to storage",
        (WidgetTester tester) async {
      await tester.pumpWidget(MinimalTestWrapper(
          child: FeatureOverlayConfigProvider(
              enablePulsingAnimation: false,
              child: FeatureTour(
                storeCompletedFeatures: storeMock!,
                featureIds: ["a", "b"], child: Container()))));
      await tester.pumpAndSettle();

      clearInteractions(storeMock!);

      await tester.pumpWidget(MinimalTestWrapper(
          child: FeatureOverlayConfigProvider(
              enablePulsingAnimation: false,
              child: FeatureTour(
                storeCompletedFeatures: storeMock!,
                featureIds: ["d", "e"], child: Container()))));
      await tester.pumpAndSettle();
      verify(storeMock!(Set.identity()));
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
      testWidgets("calls onDismiss after $event.",
          (WidgetTester tester) async {
        final providerKey = GlobalKey<FeatureOverlayConfigProviderState>();
        final tourStateKey = GlobalKey<FeatureTourState>();
        await tester.pumpWidget(MinimalTestWrapper(
            child: FeatureOverlayConfigProvider(
                key: providerKey,
                enablePulsingAnimation: false,
                openDuration: Duration(milliseconds: 2000),
                child:
                    FeatureTour(
                      key:tourStateKey,
                      onDismissFeature: onDismissMock!,
                      featureIds: ["a", "b"], child: Container()))));
        await tester.pump(Duration(milliseconds: 1000));
        expect(providerKey.currentState!.activeFeatureId, equals("a"));
        providerKey.currentState!.eventsController
          ..add(event)
          ..add(FeatureOverlayEvent(
              featureId: "a",
              state: FeatureOverlayState.dismissing,
              previousState: event.state));
        verifyNever(onDismissMock!.call(any, any));
        providerKey.currentState!.eventsController.add(FeatureOverlayEvent(
              featureId: "a",
              state: FeatureOverlayState.closed,
              previousState: FeatureOverlayState.dismissing));
        await tester.pumpAndSettle();
        verify(onDismissMock!.call(tourStateKey.currentState!, "a"));
      });
    });
  });
}
