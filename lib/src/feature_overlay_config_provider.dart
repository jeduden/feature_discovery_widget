import 'dart:async';

import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'composite_transform_loose.dart';
import 'feature_overlay_config.dart';
import 'feature_overlay_event.dart';

/// Provides [notifyActiveFeature] to change the active active feature.
abstract class FeatureOverlayConfigChangeNotifier {
  /// Change the active feature. Pass [null] to deactive all features.
  void notifyActiveFeature(String? featureId);
}

/// Provides [FeatureOverlayConfig] to the [child],
/// [FeatureOverlayConfigChangeNotifier] with [notifierOf] to modify the currently 
/// active feature overlay,
/// and an event stream of [FeatureOverlayEvent] via [eventStreamOf] to subscribe
/// to all state changes.
class FeatureOverlayConfigProvider extends StatefulWidget {
  /// Widget to receive the [FeatureOverlayConfig]
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

  /// Called during initState of the provider.
  final void Function(FeatureOverlayConfigChangeNotifier notifier)? onInitState;

  /// Initial active feature id
  final String? initialActiveId;

  /// Default value for dismissible
  final bool dismissibleDefault;

  const FeatureOverlayConfigProvider(
      {Key? key,
      required this.child,
      this.onInitState,
      this.initialActiveId,
      this.enablePulsingAnimation = true,
      this.dismissibleDefault = true,
      this.openDuration = const Duration(milliseconds: 250),
      this.pulseDuration = const Duration(milliseconds: 1000),
      this.completeDuration = const Duration(milliseconds: 400),
      this.dismissDuration = const Duration(milliseconds: 250), 
      }): super(key: key);

  @override
  State<StatefulWidget> createState() {
    final state = FeatureOverlayConfigProviderState();
    print("FeatureOverlayConfigProvider.createState => $state");
    return state;
  }

  /// Returns [FeatureOverlayConfigChangeNotifier] to change the active feature
  static FeatureOverlayConfigChangeNotifier notifierOf(BuildContext context) {
    return FeatureOverlayConfigProviderState.of(context);
  }

  /// Returns [Stream<FeatureOverlayEvent>] to subscribe to all [FeatureOverlayEvent] events.
  static Stream<FeatureOverlayEvent> eventStreamOf(BuildContext context) {
    return FeatureOverlayConfigProviderState.of(context).events;
  }
}



class FeatureOverlayConfigProviderState
    extends State<FeatureOverlayConfigProvider>
    implements FeatureOverlayConfigChangeNotifier {

  @visibleForTesting
  String? activeFeatureId;
  late LooseLayerLink layerLink;

  @visibleForTesting
  late StreamController<FeatureOverlayEvent> eventsController;

  Stream<FeatureOverlayEvent> get events => eventsController.stream;
  late EventSink<FeatureOverlayEvent> eventsSink;

  @override
  void initState() {
    layerLink = LooseLayerLink();
    eventsController = StreamController.broadcast();
    eventsSink = eventsController.sink;
    activeFeatureId = widget.initialActiveId;
    widget.onInitState?.call(this);
    print("FeatureOverlayConfigProviderState.initState $this");
    super.initState();
  }

  @override
  void dispose() {
    eventsController.close();
    super.dispose();
  }

  @override
  void notifyActiveFeature(String? featureId) {
    setState(() {
      print(
          "FeatureOverlayConfigProviderState.notifyActiveFeature.setState $this activeFeatureId:$activeFeatureId");
      activeFeatureId = featureId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = FeatureOverlayConfig(
      layerLink: layerLink,
      child: widget.child,
      eventsSink: eventsSink,
      activeFeatureId: activeFeatureId,
      openDuration: widget.openDuration,
      completeDuration: widget.completeDuration,
      dismissDuration: widget.dismissDuration,
      pulseDuration: widget.pulseDuration,
      dismissibleDefault: widget.dismissibleDefault,
    );
    print(
        "FeatureOverlayConfigProviderState.build $this => $config activeFeatureId:$activeFeatureId");
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
    properties.add(StringProperty("activeFeatureId", activeFeatureId));
  }
}
