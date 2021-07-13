import 'enums.dart';
/// Event describe the state change of the particular feature overlay.
class FeatureOverlayEvent {
  /// Current state of the feature with id [featureId]
  final FeatureOverlayState state;

  /// Previous state of the feature with id [featureId]
  final FeatureOverlayState previousState;

  /// Id of the feature this event is about.
  final String featureId;
  const FeatureOverlayEvent({
    required this.state,
    required this.previousState,
    required this.featureId
  });
}
