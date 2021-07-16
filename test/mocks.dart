import 'dart:async';

import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:flutter/widgets.dart';
import 'package:mockito/mockito.dart';

class MockPersistence extends Mock implements FeatureTourPersistence {
  Future<void> setTourFeatureIds(List<String>? tourFeatureIds) {
    return super.noSuchMethod(
        Invocation.method(#setTourFeatureIds, [tourFeatureIds]),
        returnValue: Future.value());
  }

  @override
  Stream<Set<String>> get completedFeaturesStream {
    return super.noSuchMethod(Invocation.getter(#completedFeaturesStream),
        returnValue: StreamController<Set<String>>().stream);
  }

  @override
  Future<void> completeFeature(
      BuildContext? tourContext, String? featureId) async {
    return super.noSuchMethod(
        Invocation.method(#completeFeature, [tourContext, featureId]),
        returnValue: Future.value());
  }

  @override
  Future<void> dismissFeature(
      BuildContext? tourContext, String? featureId) async {
    return super.noSuchMethod(
        Invocation.method(#dismissFeature, [tourContext, featureId]),
        returnValue: Future.value());
  }
}
