import 'dart:async';

import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:feature_discovery_widget/src/feature_overlay_config_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'feature_overlay_event.dart';

/// Simple feature discovery guided tour using just plain flutter widgets.
/// Does not persist completed feature ids.
/// Best to be reimplemented using the statemanagement package that is used in the application.
/// Expects to have [FeatureOverlayConfigProvider] as an ancestor.
class FeatureTour extends StatefulWidget {
  final Widget child;

  /// List all feature ids in order.
  final List<String> featureIds;

  FeatureTour(
      {Key? key,
      required this.child,
      required this.featureIds})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return FeatureTourState();
  }
}

class FeatureTourState extends State<FeatureTour> {
  StreamSubscription<FeatureOverlayEvent>? _overlayEventsSubscription;
  StreamSubscription<Set<String>>? _completedFeaturesStreamSubscription;
  Set<String>? lastCompletedFeatures;

  @override
  void didUpdateWidget(covariant FeatureTour oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.featureIds, widget.featureIds)) {
      WidgetsBinding.instance?.addPostFrameCallback((_) async {
        final persistence = FeatureOverlayConfigProvider.featureTourPersistenceOf(context);
        persistence.setTourFeatureIds(widget.featureIds);
        _updateActive();
      });
    }
  }

  void _subscribeToCompletedFeaturesStream(context) 
  {
    _completedFeaturesStreamSubscription?.cancel();
    final persistence = FeatureOverlayConfigProvider.featureTourPersistenceOf(context);
    _completedFeaturesStreamSubscription = persistence.completedFeaturesStream.listen((event) {
      lastCompletedFeatures = event;
      _updateActive();
    });
  }

  @override
  void didChangeDependencies() async {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _updateActive();
    });
    
    final persistence = FeatureOverlayConfigProvider.featureTourPersistenceOf(context);
    await persistence.setTourFeatureIds(widget.featureIds);
    
    _subscribeToCompletedFeaturesStream(context);

    final events = FeatureOverlayConfigProvider.eventStreamOf(context);
    _overlayEventsSubscription?.cancel();
    _overlayEventsSubscription = events.listen((event) async {
      if (event.previousState == FeatureOverlayState.opened) {
        if (event.state == FeatureOverlayState.completing) {
          await persistence.completeFeature(context,event.featureId);
        } else {
          await persistence.dismissFeature(context,event.featureId);
        }
      }
    });
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _overlayEventsSubscription?.cancel();
    _completedFeaturesStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _updateActive() async {
    final iter = widget.featureIds.skipWhile((id) => lastCompletedFeatures?.contains(id) ?? false).iterator;

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
