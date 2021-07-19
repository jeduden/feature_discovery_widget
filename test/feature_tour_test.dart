import 'dart:async';

import 'package:feature_discovery_widget/src/feature_tour.dart';
import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:feature_discovery_widget/src/feature_overlay_config_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {

  late StreamController<Set<String>> completeFeaturesStreamController;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  tearDownAll(() {});
  setUp(() {
    completeFeaturesStreamController =
        StreamController<Set<String>>.broadcast();
  });
  tearDown(() {
    completeFeaturesStreamController.close();
  });

  group("FeatureTour", () {
    testWidgets(
        "completed first feature before initialization and moves to first not completed feature",
        (WidgetTester tester) async {
    
      completeFeaturesStreamController.onListen = () => completeFeaturesStreamController.add(<String>{"a"});  
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

    testWidgets("shows first feature if stream has no result yet",
        (WidgetTester tester) async {
      final providerKey = GlobalKey<FeatureOverlayConfigProviderState>();
      when(mockPersistence.setTourFeatureIds(any))
          .thenAnswer((_) async => Future.value());
      await tester.pumpWidget(MinimalTestWrapper(
          child: FeatureOverlayConfigProvider(
              key: providerKey,
              enablePulsingAnimation: false,
              persistenceBuilder: () => mockPersistence,
              child: FeatureTour(featureIds: ["a", "b"], child: Container()))));
      await tester.pumpAndSettle();
      verifyInOrder([
        mockPersistence.setTourFeatureIds(["a", "b"].toList()),
        mockPersistence.completedFeaturesStream]);
      expect(providerKey.currentState!.activeFeatureId, equals("a"));
    });

    testWidgets("calls setTourFeatureIds if featureIds change",
        (WidgetTester tester) async {
      final providerKey = GlobalKey<FeatureOverlayConfigProviderState>();
      when(mockPersistence.setTourFeatureIds(any))
          .thenAnswer((_) async => Future.value());
      await tester.pumpWidget(MinimalTestWrapper(
          child: FeatureOverlayConfigProvider(
              key: providerKey,
              enablePulsingAnimation: false,
              persistenceBuilder: () => mockPersistence,
              child: FeatureTour(featureIds: ["a", "b"], child: Container()))));
      await tester.pumpAndSettle();
      await tester.pumpWidget(MinimalTestWrapper(
          child: FeatureOverlayConfigProvider(
              key: providerKey,
              enablePulsingAnimation: false,
              persistenceBuilder: () => mockPersistence,
              child: FeatureTour(featureIds: ["d", "e"], child: Container()))));
      verifyInOrder([
        mockPersistence.setTourFeatureIds(["a", "b"].toList()),
        mockPersistence.setTourFeatureIds(["d", "e"].toList())]);
    });

    testWidgets("moves to next not completed feature on completion",
        (WidgetTester tester) async {
      when(mockPersistence.setTourFeatureIds(any))
          .thenAnswer((_) async => Future.value());
      when(mockPersistence.completeFeature(any, any))
          .thenAnswer((_) async => Future.value());
      final providerKey = GlobalKey<FeatureOverlayConfigProviderState>();
      await tester.pumpWidget(MinimalTestWrapper(
          child: FeatureOverlayConfigProvider(
              key: providerKey,
              enablePulsingAnimation: false,
              persistenceBuilder: () => mockPersistence,
              child: FeatureTour(featureIds: ["a", "b"], child: Container()))));
      await tester.pumpAndSettle();
      verifyInOrder([
        mockPersistence.setTourFeatureIds(["a", "b"].toList()),
        mockPersistence.completedFeaturesStream]);
      expect(providerKey.currentState!.activeFeatureId, equals("a"));
      verifyNever(mockPersistence.completeFeature(any, "a"));
      providerKey.currentState!.eventsController.sink.add(FeatureOverlayEvent(
          featureId: "a",
          state: FeatureOverlayState.completing,
          previousState: FeatureOverlayState.opened));
      await tester.pumpAndSettle();
      verify(mockPersistence.completeFeature(any, "a")).called(1);
    });

    testWidgets(
        "mark feature as dismissed not when dismissed. call complete features again",
        (WidgetTester tester) async {
      when(mockPersistence.setTourFeatureIds(any))
          .thenAnswer((_) async => Future.value());
      when(mockPersistence.completeFeature(any, any))
          .thenAnswer((_) async => Future.value());
      when(mockPersistence.dismissFeature(any, any))
          .thenAnswer((_) async => Future.value());

      final providerKey = GlobalKey<FeatureOverlayConfigProviderState>();
      await tester.pumpWidget(MinimalTestWrapper(
          child: FeatureOverlayConfigProvider(
              key: providerKey,
              enablePulsingAnimation: false,
              persistenceBuilder: () => mockPersistence,
              child: FeatureTour(featureIds: ["a", "b"], child: Container()))));
      await tester.pumpAndSettle();
      verify(mockPersistence.completedFeaturesStream).called(1);
      expect(providerKey.currentState!.activeFeatureId, equals("a"));
      verifyNever(mockPersistence.completeFeature(any, "a"));
      providerKey.currentState!.eventsController.sink.add(FeatureOverlayEvent(
          featureId: "a",
          state: FeatureOverlayState.dismissing,
          previousState: FeatureOverlayState.opened));
      await tester.pumpAndSettle();
      verifyNever(mockPersistence.completeFeature(any, any));
      verify(mockPersistence.dismissFeature(any, "a"));
    });

     testWidgets(
        "mark feature as dismissed when dismissing during opening.",
        (WidgetTester tester) async {
      when(mockPersistence.setTourFeatureIds(any))
          .thenAnswer((_) async => Future.value());
      when(mockPersistence.completeFeature(any, any))
          .thenAnswer((_) async => Future.value());
      when(mockPersistence.dismissFeature(any, any))
          .thenAnswer((_) async => Future.value());

      final providerKey = GlobalKey<FeatureOverlayConfigProviderState>();
      await tester.pumpWidget(MinimalTestWrapper(
          child: FeatureOverlayConfigProvider(
              key: providerKey,
              enablePulsingAnimation: false,
              openDuration: Duration(milliseconds:2000),
              persistenceBuilder: () => mockPersistence,
              child: FeatureTour(featureIds: ["a", "b"], child: Container()))));
      await tester.pump(Duration(milliseconds: 1000));
      expect(providerKey.currentState!.activeFeatureId, equals("a"));

      providerKey.currentState!.eventsController.add(FeatureOverlayEvent(featureId: "a", 
        state: FeatureOverlayState.dismissing,
      previousState: FeatureOverlayState.opening
      ));
      await tester.pumpAndSettle();
      verify(mockPersistence.dismissFeature(any, "a"));
    });

    testWidgets("when features are completed then no feature will be activated",
        (WidgetTester tester) async {
      final providerKey = GlobalKey<FeatureOverlayConfigProviderState>();
      when(mockPersistence.setTourFeatureIds(any))
          .thenAnswer((_) async => Future.value());
      await tester.pumpWidget(MinimalTestWrapper(
          child: FeatureOverlayConfigProvider(
              key: providerKey,
              enablePulsingAnimation: false,
              persistenceBuilder: () => mockPersistence,
              child: FeatureTour(featureIds: ["a", "b"], child: Container()))));
      await tester.pumpAndSettle();
      expect(providerKey.currentState!.activeFeatureId, equals("a"));
      completeFeaturesStreamController.add({"a"});
      await tester.pumpAndSettle();
      expect(providerKey.currentState!.activeFeatureId, equals("b"));
      completeFeaturesStreamController.add({"a", "b"});
      await tester.pumpAndSettle();
      expect(providerKey.currentState!.activeFeatureId, equals(null));
    });
  });
}
