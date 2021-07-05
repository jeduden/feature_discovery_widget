import 'package:feature_discovery_widget/src/feature_overlay_config.dart';
import 'package:flutter/material.dart';

class FeatureTourWidget extends StatefulWidget
{
  Widget child;
  final Iterable<String> features;

  FeatureTourWidget({
    Key? key,
    required this.child,
    required this.features,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return FeatureTourState();
  }
}

class FeatureTourState extends State<FeatureTourWidget>
{
  Iterator<String>? featuresIterator;

  @override
  void initState() {
    featuresIterator = widget.features.iterator;
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return FeatureOverlayConfig(
      activeFeature: featuresIterator?.current,
      onDismiss: (_)=>setState(() { featuresIterator = null; }),
      onComplete: (_)=>setState(() { featuresIterator?.moveNext(); }),
      child: widget.child,
    );
  }
}
