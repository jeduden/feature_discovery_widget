import 'package:flutter/foundation.dart';

import 'enums.dart';

/// Event describe the state change of the particular feature overlay.
class FeatureOverlayEvent {
  /// Current state of the feature with id [featureId]
  final FeatureOverlayState state;

  /// Previous state of the feature with id [featureId]
  final FeatureOverlayState previousState;

  /// Id of the feature this event is about.
  final String featureId;
  const FeatureOverlayEvent(
      {required this.state,
      required this.previousState,
      required this.featureId});

  @override
  String toString() {
    return "FeatureOverlayEvent(featureId: \"$featureId\", previousState: ${describeEnum(previousState)}, state: ${describeEnum(state)})";
  }

  @override
  bool operator ==(Object other) =>
      other is FeatureOverlayEvent &&
      featureId == other.featureId && 
      state == other.state &&
      previousState == other.previousState;

  @override
  int get hashCode => state.hashCode ^ featureId.hashCode ^ previousState.hashCode;
}
