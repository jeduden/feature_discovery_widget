
import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'composite_transform_loose.dart';
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
  final Set<String> featureIds;

  /// Target of the [FeatureOverlay] when shown
  final Widget child;

  const FeatureOverlayTarget(
      {Key? key, required this.featureIds, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = FeatureOverlayConfig.whenPresentOf(context);
    final wrapperKey = ValueKey("wrap"); // does this improve perf?
    if (featureIds.contains(config?.activeFeatureId ?? null)) {
      return CompositedTransformLooseTarget(
        key: wrapperKey,
        link: config!.layerLink,
        child: child,
      );
    } else {
      return Container(key: wrapperKey, child: child,); 
    }
  }
}
