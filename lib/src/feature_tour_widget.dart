import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:feature_discovery_widget/src/feature_overlay_config.dart';
import 'package:feature_discovery_widget/src/feature_overlay_config_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FeatureTourWidget extends StatefulWidget {
  final Widget child;
  final Iterable<String> featureIds;
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

  @override
  void didUpdateWidget(covariant FeatureTourWidget oldWidget) {
    if (oldWidget.featureIds != widget.featureIds) {
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
    super.didChangeDependencies();
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
    return FeatureOverlayConfigProvider(
      enablePulsingAnimation: widget.enablePulsingAnimation,
      onDismiss: (_) => setState(() {
        _setActive(null);
      }),
      onComplete: (_) => setState(() {
        _nextActive();
      }),
      child: widget.child,
    );
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
