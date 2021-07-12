import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'feature_overlay_config.dart';

class FeatureOverlayTarget extends StatelessWidget {
  final String featureId;
  final Widget child;

  const FeatureOverlayTarget(
      {Key? key, required this.featureId, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = FeatureOverlayConfig.of(context);
    final wrapperKey = ValueKey("wrap"); // does this improve perf?
    if (config.activeFeatureId == featureId) {
      return CompositedTransformTarget(
        key: wrapperKey,
        link: config.layerLink,
        child: child,
      );
    } else {
      return Container(key: wrapperKey, child: child,); 
    }
  }
}
