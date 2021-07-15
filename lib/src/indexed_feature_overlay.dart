import 'package:flutter/material.dart';

import 'feature_overlay.dart';
import 'feature_overlay_config.dart';

/// The [FeatureOverlay] listed in [featureOverlays] will appear on top of the [child]
/// when the corresponding [FeatureOverlay.featureId] is active.
class IndexedFeatureOverlay extends StatefulWidget {

  /// A set of [FeatureOverlay]
  final Set<FeatureOverlay> featureOverlays;

  /// The overlays will overlay this [child]. 
  final Widget child;

  const IndexedFeatureOverlay(
      {Key? key, required this.featureOverlays, required this.child})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return IndexFeatureOverlayState();
  }
}

class IndexFeatureOverlayState extends State<IndexedFeatureOverlay> {
  late GlobalKey<OverlayState> overlayKey;
  FeatureOverlayConfig? config;
  FeatureOverlay? currentFeatureOverlay;
  OverlayEntry? currentOverlayEntry;

  @override
  void initState() {
    overlayKey = GlobalKey<OverlayState>();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  static void tryInsertEntry(GlobalKey<OverlayState> overlayKey, OverlayEntry entry,int tries) {
    if(tries > 0) {
      if(overlayKey.currentState != null) {
        overlayKey.currentState!.insert(entry);
      }
      else {
        WidgetsBinding.instance!.addPostFrameCallback((_) {
          tryInsertEntry(overlayKey, entry, tries-1);
        });
      }
    }
    else {
      throw Exception("OverlayState wasn't available via global key.");
    }
  }

  @override
  void didChangeDependencies() {
    config = FeatureOverlayConfig.of(context);
    final list =  widget.featureOverlays.toList();
    final activeIndex = list
        .indexWhere((element) => element.featureId == config?.activeFeatureId);
    FeatureOverlay? activeFeatureOverlayFromThis;
    if(activeIndex>=0) {
        activeFeatureOverlayFromThis = list[activeIndex];
    }
    if(activeFeatureOverlayFromThis != currentFeatureOverlay) {
      if(currentOverlayEntry?.mounted??false)
        currentOverlayEntry?.remove();
      else
        currentOverlayEntry = null;
      if (activeFeatureOverlayFromThis != null) {
        currentFeatureOverlay = activeFeatureOverlayFromThis;
        currentOverlayEntry = OverlayEntry(builder: (_) => currentFeatureOverlay!);
        tryInsertEntry(overlayKey, currentOverlayEntry!, 3);
      }
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      widget.child,
      Overlay(
        key: overlayKey,
        initialEntries: [],
      )
    ]);
  }
}
