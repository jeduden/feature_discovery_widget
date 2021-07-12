import 'dart:async';

import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'feature_overlay_config.dart';
import 'feature_overlay_event.dart';

class FeatureOverlayConfigProvider extends StatefulWidget {
  final Widget child;

  /// Enables/Disables the pulsing animation
  /// Disable in tests since the pulse animation does not end.
  final bool enablePulsingAnimation;

  /// Duration for overlay open animation.
  final Duration openDuration;

  /// Duration of one period of the target pulse animation.
  final Duration pulseDuration;

  /// Duration for overlay complete animation.
  final Duration completeDuration;

  /// Duration for overlay dismiss animation.
  final Duration dismissDuration;

  const FeatureOverlayConfigProvider(
      {Key? key,
      required this.child,
      this.enablePulsingAnimation = true,
      this.openDuration = const Duration(milliseconds: 250),
      this.pulseDuration = const Duration(milliseconds: 1000),
      this.completeDuration = const Duration(milliseconds: 400),
      this.dismissDuration = const Duration(milliseconds: 250)})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    final state = FeatureOverlayConfigProviderState();
    print("FeatureOverlayConfigProvider.createState => $state");
    return state;
  }

  static FeatureOverlayConfigChangeNotifier notifierOf(BuildContext context) {
    return FeatureOverlayConfigProviderState.of(context);
  }

  static Stream<FeatureOverlayEvent> eventStreamOf(BuildContext context) {
    return FeatureOverlayConfigProviderState.of(context).events;
  }
}

abstract class FeatureOverlayConfigChangeNotifier {
  void notifyActiveFeature(String? featureId);
}

class FeatureOverlayConfigProviderState
    extends State<FeatureOverlayConfigProvider>
    implements FeatureOverlayConfigChangeNotifier {
  String? _activeFeatureId;
  late LayerLink layerLink;

  late StreamController<FeatureOverlayEvent> _eventsController;

  Stream<FeatureOverlayEvent> get events => _eventsController.stream;

  @override
  void initState() {
    layerLink = LayerLink();
    _eventsController = StreamController.broadcast();
    print("FeatureOverlayConfigProviderState.initState $this");
    super.initState();
  }

  @override
  void dispose() {
    _eventsController.close();
    super.dispose();
  }

  @override
  void notifyActiveFeature(String? featureId) {
    setState(() {
      print(
          "FeatureOverlayConfigProviderState.notifyActiveFeature.setState $this _activeFeatureId:$_activeFeatureId");
      _activeFeatureId = featureId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = FeatureOverlayConfig(
      layerLink: layerLink,
      child: widget.child,
      eventsSink: _eventsController.sink,
      activeFeatureId: _activeFeatureId,
      openDuration: widget.openDuration,
      completeDuration: widget.completeDuration,
      dismissDuration: widget.dismissDuration,
      pulseDuration: widget.pulseDuration,
    );
    print(
        "FeatureOverlayConfigProviderState.build $this => $config _activeFeatureId:$_activeFeatureId");
    return config;
  }

  static FeatureOverlayConfigProviderState of(BuildContext context) {
    final state =
        context.findAncestorStateOfType<FeatureOverlayConfigProviderState>();
    assert(state != null,
        "Wasn't able to find FeatureOverlayConfigProvider in the tree.");
    return state!;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty("_activeFeatureId", _activeFeatureId));
  }
}
