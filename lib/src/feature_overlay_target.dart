import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:flutter/material.dart';
import 'feature_overlay_config.dart';

/// Marks the [child] [Widget] witgh a [featureId].
/// The [FeatureOverlay] with the corresponding [featureId] will use that to overlay this [child].
/// 
/// Please make sure that this widget is having all [IndexedFeatureOverlay]s as ancestors, 
/// that contain feature overlays with this feature id.
/// If this is not the case assertions about the paint order can occur:
/// `LeaderLayer anchor must come before FollowerLayer in paint order, but the reverse was true.`
class FeatureOverlayTarget extends StatelessWidget {

  /// FeatureId of the [FeatureOverlay] to be shown
  final String featureId;

  /// Target of the [FeatureOverlay] when shown
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
