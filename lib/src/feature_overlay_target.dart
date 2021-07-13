import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'feature_overlay_config.dart';

/// Wrap the [Widget] the feature overlay should focus on with this
/// widget. The provided [featureId] references the feature overlay
/// that will be overlayed of the [child] widget if the feature is active.
/// 
/// Please make sure that this widget is having all [IndexedFeatureOverlay]s as ancestors, 
/// that contain feature overlays with this feature id.
/// If this is not the case assertions about the paint order can occur:
/// `LeaderLayer anchor must come before FollowerLayer in paint order, but the reverse was true.`
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
