import 'dart:async';

import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FeatureTour extends StatefulWidget {
  final Widget child;

  /// List all feature ids in order.
  final List<String> featureIds;

  /// Called after feature has been dismissed
  final void Function(FeatureTourState state, String featureId)? onDismissFeature;

  /// Loads the feature ids from (external) storage and returns them.
  final Future<Set<String>> Function()? loadCompletedFeatures;

  /// Stores the features in (external) storage 
  final Future<void> Function(Set<String>?)? storeCompletedFeatures;

  FeatureTour(
      {Key? key,
      required this.child,
      required this.featureIds,
      this.onDismissFeature,
      this.loadCompletedFeatures,
      this.storeCompletedFeatures,
      })
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return FeatureTourState();
  }

  static FeatureTourState of(BuildContext context) {
    final state =
        context.findAncestorStateOfType<FeatureTourState>();
    assert(state != null,
        "Wasn't able to find FeatureTour in the tree.");
    return state!;
  }
}

class FeatureTourState extends State<FeatureTour> {
  StreamSubscription<FeatureOverlayEvent>? _overlayEventsSubscription;
  late Set<String>? _lastCompletedFeatures;

  @override
  void initState() {
    super.initState();
    _lastCompletedFeatures = {};
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) { 
      _loadCompletedFeatures();
    });
  }

  @override
  void didUpdateWidget(covariant FeatureTour oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.featureIds, widget.featureIds)) {
      WidgetsBinding.instance?.addPostFrameCallback((_) async {
        await resetTour();
      });
    }
  }

  @override
  /// Subscribes to feature overlay events setting up to calls to event handlers.
  void didChangeDependencies() async {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _updateActive();
    });

    final events = FeatureOverlayConfigProvider.eventStreamOf(context);
    _overlayEventsSubscription?.cancel();
    _overlayEventsSubscription = events.listen((event) async {
      print("tour listen: $event");
      /*if (event.previousState == FeatureOverlayState.opened || event.previousState == FeatureOverlayState.opening) {
        if (event.state == FeatureOverlayState.completing) {
          print("tour listen: peristence => completeFeature");
          await _completeFeature(event.featureId);
        } else if(event.state == FeatureOverlayState.dismissing) {
          print("tour listen: peristence => dismissFeature");
          await _dismissFeature(event.featureId);
        }
      }*/
      if (event.state == FeatureOverlayState.closed) {
        if (event.previousState == FeatureOverlayState.completing) {
          print("tour listen: peristence => completeFeature");
          await _completeFeature(event.featureId);
        } else if(event.previousState == FeatureOverlayState.dismissing) {
          print("tour listen: peristence => dismissFeature");
          await _dismissFeature(event.featureId);
        }
      }
    });
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _overlayEventsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _updateActive() async {
    final iter = widget.featureIds.skipWhile((id) => _lastCompletedFeatures?.contains(id) ?? false).iterator;

    if(iter.moveNext()) {
      _setActive(iter.current);
    }
    else {
      _setActive(null);
    }
  }

  void _setActive(String? active) {
    final notifier = FeatureOverlayConfigProvider.notifierOf(context);
    notifier.notifyActiveFeature(active);
  }

  /// Marks feature id complete and calls [storeCompletedFeatures]
  Future<void> _completeFeature(String featureId) async {
    await _updateCompletedFeatures(_lastCompletedFeatures!..add(featureId));
  }

  /// Marks all feature ids complete and calls [storeCompletedFeatures]
  @mustCallSuper
  Future<void> abortTour() async {
    await _updateCompletedFeatures( _lastCompletedFeatures!..addAll(widget.featureIds));
  }

  /// Marks all feature ids as non-complete and calls [storeCompletedFeatures]
  @mustCallSuper
  Future<void> resetTour() async {
    await _updateCompletedFeatures({});
  }

  /// Handles dismiss. 
  /// dismissFeature
  @protected
  Future<void> _dismissFeature(String featureId) async {
    _setActive(null); 
    widget.onDismissFeature?.call(this,featureId);
  }


  /// Loads the features from (external) storage into [lastCompletedFeatures]
  /// by calling [loadCompletedFeatures].
  /// By default resets [lastCompletedFeatures] to the empty set.
  Future<void> _loadCompletedFeatures() async {
    print("load $_lastCompletedFeatures");
    _updateCompletedFeatures(await widget.loadCompletedFeatures?.call(), persist:false);
  }


  
  /// Stores the completed features in (external) _lastCompletedFeatures
  /// storage using [storeCompletedFeatures] if persist is true (default)
  Future<void> _updateCompletedFeatures(Set<String>? featureIds, {bool persist = true}) async {
    _lastCompletedFeatures = featureIds ?? {};
    _updateActive();
    print("storing $_lastCompletedFeatures");
    await widget.storeCompletedFeatures?.call(_lastCompletedFeatures);
  }


  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        StringProperty("features", List.from(widget.featureIds).toString()));
  }
}
