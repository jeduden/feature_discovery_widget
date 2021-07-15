import 'dart:async';

import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:feature_discovery_widget/src/feature_overlay_config_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'widgets.dart';

class MockPersistence extends Mock implements FeatureTourPersistence {

   @override
   Stream<Set<String>> completedFeaturesStream(List<String>? tourFeatureIds) {
      return super.noSuchMethod(Invocation.method(#completedFeaturesStream, [tourFeatureIds]),
        returnValue: Future.value(StreamController<Set<String>>().stream));
   }
   @override
   Future<void> completeFeature(String? featureId,List<String>? tourFeatureIds) async {
      return super.noSuchMethod(Invocation.method(#completeFeature, [featureId,tourFeatureIds]),
        returnValue: Future.value());
   }
   @override
   Future<void> dismissFeature(String? featureId,List<String>? tourFeatureIds) async {
      return super.noSuchMethod(Invocation.method(#dismissFeature, [featureId,tourFeatureIds]),
        returnValue: Future.value());
   }
}

void main() {
  late MockPersistence mockPersistence;
  late StreamController<Set<String>> completeFeaturesStreamController;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  tearDownAll(() {
  });
  setUp(() {
    completeFeaturesStreamController = StreamController<Set<String>>.broadcast();
    mockPersistence = MockPersistence();
    when(mockPersistence.completedFeaturesStream(any)).thenReturn(completeFeaturesStreamController.stream);
  });
  tearDown(() {
    completeFeaturesStreamController.close();
  });

  group("FeatureTour", () {
    testWidgets(
        "completed first feature before initialization and moves to first not completed feature",
        (WidgetTester tester) async {
      completeFeaturesStreamController.add({"a"});
      final providerKey = GlobalKey<FeatureOverlayConfigProviderState>();
      await tester.pumpWidget(TestWrapper(child: Builder(builder: (context) {
        return FeatureOverlayConfigProvider(
            key: providerKey,
            enablePulsingAnimation: false,
            child: FeatureTour(
              persistence: mockPersistence,
              featureIds: ["a", "b"], child: Container()));
      })));
      await tester.pumpAndSettle();
      expect(providerKey.currentState!.activeFeatureId, equals("b"));
    });

    testWidgets(
        "shows first feature if stream has no result yet",
        (WidgetTester tester) async {
      final providerKey = GlobalKey<FeatureOverlayConfigProviderState>();
      await tester.pumpWidget(TestWrapper(child: Builder(builder: (context) {
        return FeatureOverlayConfigProvider(
            key: providerKey,
            enablePulsingAnimation: false,
            child: FeatureTour(
              persistence: mockPersistence,
              featureIds: ["a", "b"], child: Container()));
      })));
      await tester.pumpAndSettle();
      verify(mockPersistence.completedFeaturesStream(any)).called(1);
      expect(providerKey.currentState!.activeFeatureId, equals("a"));
    });

  testWidgets(
        "moves to next not completed feature on completion",
        (WidgetTester tester) async {

      when(mockPersistence.completeFeature(any,any)).thenAnswer((_) async => Future.value());
      final providerKey = GlobalKey<FeatureOverlayConfigProviderState>();
      await tester.pumpWidget(TestWrapper(child: Builder(builder: (context) {
        return FeatureOverlayConfigProvider(
            key: providerKey,
            enablePulsingAnimation: false,
            child: FeatureTour(
              persistence: mockPersistence,
              featureIds: ["a", "b"], child: Container()));
      })));
      await tester.pumpAndSettle();
      verify(mockPersistence.completedFeaturesStream(any)).called(1);
      expect(providerKey.currentState!.activeFeatureId, equals("a"));
      verifyNever(mockPersistence.completeFeature("a",["a", "b"].toList()));
      providerKey.currentState!.eventsController.sink.add(
        FeatureOverlayEvent(featureId: "a", state: FeatureOverlayState.completing,previousState: FeatureOverlayState.opened));
      await tester.pumpAndSettle();
      verify(mockPersistence.completeFeature("a",["a", "b"].toList())).called(1);
    });

    testWidgets(
        "mark feature as dismissed not when dismissed. call complete features again",
        (WidgetTester tester) async {

      when(mockPersistence.completeFeature(any,any)).thenAnswer((_) async => Future.value());
      when(mockPersistence.dismissFeature(any,any)).thenAnswer((_) async => Future.value());
      
      final providerKey = GlobalKey<FeatureOverlayConfigProviderState>();
      await tester.pumpWidget(TestWrapper(child: Builder(builder: (context) {
        return FeatureOverlayConfigProvider(
            key: providerKey,
            enablePulsingAnimation: false,
            child: FeatureTour(
              persistence: mockPersistence,
              featureIds: ["a", "b"], child: Container()));
      })));
      await tester.pumpAndSettle();
      verify(mockPersistence.completedFeaturesStream(any)).called(1);
      expect(providerKey.currentState!.activeFeatureId, equals("a"));
      verifyNever(mockPersistence.completeFeature("a",["a", "b"].toList()));
      providerKey.currentState!.eventsController.sink.add(
        FeatureOverlayEvent(featureId: "a", state: FeatureOverlayState.dismissing,previousState: FeatureOverlayState.opened));
      await tester.pumpAndSettle();
      verifyNever(mockPersistence.completeFeature(any,any));
      verify(mockPersistence.dismissFeature("a",["a", "b"].toList()));
      verify(mockPersistence.completedFeaturesStream(any)).called(1);
    });

    testWidgets(
        "when features are completed then no feature will be activated",
        (WidgetTester tester) async {
      
      final providerKey = GlobalKey<FeatureOverlayConfigProviderState>();
      await tester.pumpWidget(TestWrapper(child: Builder(builder: (context) {
        return FeatureOverlayConfigProvider(
            key: providerKey,
            enablePulsingAnimation: false,
            child: FeatureTour(
              persistence: mockPersistence,
              featureIds: ["a", "b"], child: Container()));
      })));
      await tester.pumpAndSettle();
      expect(providerKey.currentState!.activeFeatureId, equals("a"));
      completeFeaturesStreamController.add({"a"});
      await tester.pumpAndSettle();
      expect(providerKey.currentState!.activeFeatureId, equals("b"));
      completeFeaturesStreamController.add({"a","b"});
      await tester.pumpAndSettle();
      expect(providerKey.currentState!.activeFeatureId, equals(null));
    });
  });
}
