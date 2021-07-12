import 'dart:async';

import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:feature_discovery_widget/src/feature_overlay_config_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'feature_overlay_event.dart';

class FeatureTourWidget extends StatefulWidget {
  final Widget child;
  final List<String> featureIds;
  final bool enablePulsingAnimation;

  FeatureTourWidget({
    Key? key,
    required this.child,
    required this.featureIds,
    this.enablePulsingAnimation = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return FeatureTourState();
  }
}

class FeatureTourState extends State<FeatureTourWidget> {
  Iterator<String>? featuresIterator;
  StreamSubscription<FeatureOverlayEvent>? _subscription;

  @override
  void didUpdateWidget(covariant FeatureTourWidget oldWidget) {
    if (!listEquals(oldWidget.featureIds, widget.featureIds)) {
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        featuresIterator = null;
        _ensureActiveInitialized();
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _ensureActiveInitialized();
    });

    final events = FeatureOverlayConfigProvider.eventStreamOf(context);
    
    _subscription?.cancel();
    _subscription = events.listen((event) {
      if(event.state == FeatureOverlayState.closed) {
        if(event.previousState == FeatureOverlayState.completing) { 
          _nextActive();
        }
        else {
          _setActive(null);
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

  void _ensureActiveInitialized() {
    if (featuresIterator == null) {
      featuresIterator = widget.featureIds.iterator;
      _nextActive();
    }
  }

  void _nextActive() {
    if (featuresIterator!.moveNext())
      _setActive(featuresIterator!.current);
    else
      _setActive(null);
  }

  void _setActive(String? active) {
    final notifier = FeatureOverlayConfigProvider.notifierOf(context);
    notifier.notifyActiveFeature(active);
  }

  @override
  Widget build(BuildContext context) {
    print("FeatureTourState.build");
    return widget.child;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(StringProperty("features", List.from(widget.featureIds).toString()));
    properties
        .add(StringProperty("current", featuresIterator?.current.toString()));
  }
}
