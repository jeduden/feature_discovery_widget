import 'dart:async';

import 'package:flutter/material.dart';

class FeatureOverlayConfig extends InheritedWidget {
  /// Enables/Disables the pulsing animation
  /// Disable in tests since the pulse animation does not end.
  final bool enablePulsingAnimation;

  /// Called after the opening animation finished
  /// Receives the featureId.
  final FutureOr<void> Function(String)? onFinishedOpening;

  /// Called whenever the user taps outside the overlay area.
  /// Receives the featureId.
  final FutureOr<void> Function(String)? onDismiss;

  /// Called when the tap target is tapped.
  /// Receives the featureId.
  final FutureOr<void> Function(String)? onComplete;

  /// Called after the closing animation finished
  /// Receives the featureId.
  final FutureOr<void> Function(String)? onFinishedClosing;

  /// Curently active feature
  final String? activeFeature;

  /// Duration for overlay open animation.
  final Duration openDuration;

  /// Duration for one period of the target pulse animation.
  final Duration pulseDuration;

  /// Duration for overlay complete animation.
  final Duration completeDuration;

  /// Duration for overlay dismiss animation.
  final Duration dismissDuration;

  const FeatureOverlayConfig({
      Key? key,
      required Widget child,
      this.enablePulsingAnimation : true,
      this.onFinishedOpening,
      this.onDismiss,
      this.onComplete,
      this.onFinishedClosing,
      this.activeFeature,
      this.openDuration : const Duration(milliseconds: 250),
      this.pulseDuration : const Duration(milliseconds: 1000),
      this.completeDuration : const Duration(milliseconds: 250),
      this.dismissDuration : const Duration(milliseconds: 250),
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }

  static FeatureOverlayConfig of(BuildContext context) {
    final FeatureOverlayConfig? result = context.dependOnInheritedWidgetOfExactType<FeatureOverlayConfig>();
    assert(result != null, 'No FeatureOverlayConfig found in context');
    return result!;
  }
}
