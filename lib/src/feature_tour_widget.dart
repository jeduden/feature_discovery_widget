import 'package:feature_discovery_widget/src/feature_tour_config.dart';
import 'package:flutter/material.dart';

class FeatureTourWidget extends StatefulWidget
{
  Widget child;
  final Iterable<String> features;
  final bool enablePulsingAnimation;

  FeatureTourWidget({
    Key? key,
    required this.child,
    required this.features,
    this.enablePulsingAnimation = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return FeatureTourState();
  }
}

class FeatureTourState extends State<FeatureTourWidget>
{
  late Iterator<String> featuresIterator;
  String? active;

  @override
  void initState() {
    featuresIterator = widget.features.iterator;
    _nextActive();
    super.initState();
  }

  void _nextActive()
  {
    if(featuresIterator.moveNext())
      active = featuresIterator.current;
    else
      active = null;
  }
  
  @override
  Widget build(BuildContext context) {
    return FeatureTourConfig(
      enablePulsingAnimation: widget.enablePulsingAnimation,
      activeFeature: active,
      onDismiss: (_)=>setState(() { active = null; }),
      onComplete: (_)=>setState(() { _nextActive(); }),
      child: widget.child,
    );
  }
}
