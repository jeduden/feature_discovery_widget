import 'dart:async';

import 'package:flutter/material.dart';

class FeatureTourConfig extends InheritedWidget {
  /// Enables/Disables the pulsing animation
  /// Disable in tests since the pulse animation does not end.
  final bool enablePulsingAnimation;

  /// Called after the opening animation finished
  /// Receives the featureId.
  final FutureOr<void> Function(String)? onOpen;

  /// Called whenever the user taps outside the overlay area and dismiss animation is finished
  /// Receives the featureId.
  final FutureOr<void> Function(String)? onDismiss;

  /// Called when the tap target is tapped and completion animation is finished
  /// Receives the featureId.
  final FutureOr<void> Function(String)? onComplete;

  /// Currently active feature
  final String? activeFeature;

  /// Duration for overlay open animation.
  final Duration openDuration;

  /// Duration for one period of the target pulse animation.
  final Duration pulseDuration;

  /// Duration for overlay complete animation.
  final Duration completeDuration;

  /// Duration for overlay dismiss animation.
  final Duration dismissDuration;

  const FeatureTourConfig({
      Key? key,
      required Widget child,
      this.enablePulsingAnimation : true,
      this.onOpen,
      this.onDismiss,
      this.onComplete,
      this.activeFeature,
      this.openDuration : const Duration(milliseconds: 500),
      this.pulseDuration : const Duration(milliseconds: 1000),
      this.completeDuration : const Duration(milliseconds: 250),
      this.dismissDuration : const Duration(milliseconds: 250),
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }

  static FeatureTourConfig of(BuildContext context) {
    final FeatureTourConfig? result = context.dependOnInheritedWidgetOfExactType<FeatureTourConfig>();
    assert(result != null, 'No FeatureTourConfig found in context');
    return result!;
  }
}
