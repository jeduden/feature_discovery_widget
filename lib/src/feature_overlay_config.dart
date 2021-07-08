import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'feature_overlay_event.dart';

class FeatureOverlayConfig extends InheritedWidget {
  /// Enables/Disables the pulsing animation
  /// Disable in tests since the pulse animation does not end.
  final bool enablePulsingAnimation;

  final EventSink<FeatureOverlayEvent> eventsSink;

  /// Currently active feature id
  final String? activeFeatureId;

  /// Currently active overlay
  final WidgetBuilder? activeOverlayBuilder;

  /// Currently active portal
  final String? activePortalId;

  /// Duration for overlay open animation.
  final Duration openDuration;

  /// Duration of one period of the target pulse animation.
  final Duration pulseDuration;

  /// Duration for overlay complete animation.
  final Duration completeDuration;

  /// Duration for overlay dismiss animation.
  final Duration dismissDuration;

  final LayerLink layerLink;

  FeatureOverlayConfig({
    Key? key,
    required Widget child,
    this.enablePulsingAnimation: true,
    required this.layerLink,
    required this.eventsSink,
    this.activeFeatureId,
    this.activePortalId,
    this.activeOverlayBuilder,
    this.openDuration: const Duration(milliseconds: 500),
    this.pulseDuration: const Duration(milliseconds: 1000),
    this.completeDuration: const Duration(milliseconds: 250),
    this.dismissDuration: const Duration(milliseconds: 250),
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(covariant FeatureOverlayConfig oldWidget) {
    print(
        "FeatureOverlayConfig.updateShouldNotify activeFeatureId:$activeFeatureId oldWidget.activeFeatureId ${oldWidget.activeFeatureId}");
    final result = child != oldWidget.child ||
        enablePulsingAnimation != oldWidget.enablePulsingAnimation ||
        layerLink != oldWidget.layerLink ||
        eventsSink != oldWidget.eventsSink ||
        activeFeatureId != oldWidget.activeFeatureId ||
        activePortalId != oldWidget.activePortalId ||
        activeOverlayBuilder != oldWidget.activeOverlayBuilder ||
        openDuration != oldWidget.openDuration ||
        pulseDuration != oldWidget.pulseDuration ||
        completeDuration != oldWidget.completeDuration ||
        dismissDuration != oldWidget.dismissDuration;
    print("FeatureOverlayConfig.updateShouldNotify returns $result");
    return result;
  }

  static FeatureOverlayConfig of(BuildContext context) {
    final FeatureOverlayConfig? result =
        context.dependOnInheritedWidgetOfExactType<FeatureOverlayConfig>();
    assert(result != null, 'No FeatureOverlayConfig found in context');
    return result!;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty("activeFeatureId", activeFeatureId));
  }
}
