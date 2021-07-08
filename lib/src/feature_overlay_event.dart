import 'enums.dart';

class FeatureOverlayEvent {
  final FeatureOverlayState state;
  final FeatureOverlayState previousState;
  final String featureId;
  const FeatureOverlayEvent({
    required this.state,
    required this.previousState,
    required this.featureId
  });
}
