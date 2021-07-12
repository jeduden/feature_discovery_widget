import 'package:flutter/material.dart';

import 'feature_overlay.dart';
import 'feature_overlay_config.dart';

class IndexedFeatureOverlay extends StatefulWidget {
  final Set<FeatureOverlay> featureOverlays;
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
      currentOverlayEntry?.remove();
      if (activeFeatureOverlayFromThis != null) {
        currentFeatureOverlay = activeFeatureOverlayFromThis;
        currentOverlayEntry = OverlayEntry(builder: (_) => currentFeatureOverlay!);
        if(overlayKey.currentState == null) {
          WidgetsBinding.instance!.addPostFrameCallback((_) {
            overlayKey.currentState!.insert(currentOverlayEntry!);
          });
        }
        else {
          overlayKey.currentState!.insert(currentOverlayEntry!);
        }
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
