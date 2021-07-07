import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'feature_overlay_config.dart';

class FeatureOverlayConfigProvider extends StatefulWidget {
  final Widget child;
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

   /// Duration for overlay open animation.
  final Duration openDuration;

  /// Duration of one period of the target pulse animation.
  final Duration pulseDuration;

  /// Duration for overlay complete animation.
  final Duration completeDuration;

  /// Duration for overlay dismiss animation.
  final Duration dismissDuration;

  const FeatureOverlayConfigProvider({Key? key, required this.child, 
    this.enablePulsingAnimation = true, this.onOpen, this.onDismiss, this.onComplete, 
    this.openDuration = const Duration(milliseconds: 250), 
    this.pulseDuration = const Duration(milliseconds: 1000), 
    this.completeDuration = const Duration(milliseconds: 400), 
    this.dismissDuration =const Duration(milliseconds: 250)})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    print("FeatureOverlayConfigProvider.createState");
    return FeatureOverlayConfigProviderState();
  }

  static FeatureOverlayConfigChangeNotifier notifierOf(BuildContext context) {
    return FeatureOverlayConfigProviderState.of(context);
  }
}

abstract class FeatureOverlayConfigChangeNotifier {
  void notifyActiveFeature(String? featureId);
}

class FeatureOverlayConfigProviderState 
    extends State<FeatureOverlayConfigProvider> implements FeatureOverlayConfigChangeNotifier {
  String? _activeFeatureId;
  WidgetBuilder? _activeOverlayBuilder;
  String? _activePortalId;
  late LayerLink layerLink;

  @override
  void initState() {
    layerLink = LayerLink();
    super.initState();
  }

  @override
  void notifyActiveFeature(String? featureId) {
    setState(() {
      print("FeatureOverlayConfigProviderState.setState _activeFeatureId:$_activeFeatureId");
      _activeFeatureId = featureId;
    });
  }

  void setActiveOverlayBuilderForPortal(String portalId,WidgetBuilder? overlayBuilder)
  {
    setState(() {
      _activePortalId = portalId;
      _activeOverlayBuilder = overlayBuilder;
    });
  }

  @override
  Widget build(BuildContext context) {
    print("FeatureOverlayConfigProviderState.build _activeFeatureId:$_activeFeatureId");
    return FeatureOverlayConfig(
      layerLink: layerLink,
      child: widget.child,
      activeFeatureId: _activeFeatureId,
      activeOverlayBuilder: _activeOverlayBuilder,
      activePortalId: _activePortalId,
      openDuration: widget.openDuration,
      completeDuration: widget.completeDuration,
      dismissDuration: widget.dismissDuration,
      pulseDuration: widget.pulseDuration,
      onComplete: widget.onComplete,
      onOpen: widget.onOpen,
      onDismiss: widget.onOpen,
    );
  }

  static FeatureOverlayConfigProviderState of(BuildContext context) {
    final state = context.findAncestorStateOfType<FeatureOverlayConfigProviderState>();
    assert(state != null, "Wasn't able to find FeatureOverlayConfigProvider in the tree.");
    return state!;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty("_activeFeatureId", _activeFeatureId));
  }

}
