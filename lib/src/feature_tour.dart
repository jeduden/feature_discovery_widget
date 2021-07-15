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
  final FeatureTourPersistence persistence;

  FeatureTour(
      {Key? key,
      required this.persistence,
      required this.child,
      required this.featureIds})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return FeatureTourState();
  }
}

class FeatureTourState extends State<FeatureTour> {
  StreamSubscription<FeatureOverlayEvent>? _subscription;

  @override
  void didUpdateWidget(covariant FeatureTour oldWidget) {
    if (!listEquals(oldWidget.featureIds, widget.featureIds)) {
      WidgetsBinding.instance?.addPostFrameCallback((_) async {
        _updateActive();
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _updateActive();
    });

    final events = FeatureOverlayConfigProvider.eventStreamOf(context);

    _subscription?.cancel();
    _subscription = events.listen((event) async {
      if (event.previousState == FeatureOverlayState.opened) {
        if (event.state == FeatureOverlayState.completing) {
          await _completeActive(event.featureId);
        } else {
          await _dismissActive(event.featureId);
        }
      }
    });
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _completeActive(String id) async {
    await widget.persistence.completeFeature(id,widget.featureIds);
    await _updateActive();
  }

  Future<void> _dismissActive(String id) async {
    await widget.persistence.dismissFeature(id,widget.featureIds);
    await _updateActive();
  }

  Future<void> _updateActive() async {
    final completed = await widget.persistence.completedFeatures(widget.featureIds);
    final iter = widget.featureIds.skipWhile((id) => completed.contains(id)).iterator;

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
