import 'package:flutter/foundation.dart';
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
    print("IndexFeatureOverlayState.initState");
    overlayKey = GlobalKey<OverlayState>();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  static void tryInsertEntry(
      GlobalKey<OverlayState> overlayKey, OverlayEntry entry, int tries) {
    if (tries > 0) {
      if (overlayKey.currentState != null) {
        overlayKey.currentState!.insert(entry);
      } else {
        WidgetsBinding.instance!.addPostFrameCallback((_) {
          tryInsertEntry(overlayKey, entry, tries - 1);
        });
      }
    } else {
      throw Exception("OverlayState wasn't available via global key.");
    }
  }

  get featureOverlayList => widget.featureOverlays.toList();

  get activeIndex => featureOverlayList
      .indexWhere((element) => element.featureId == config?.activeFeatureId);

  @override
  void didChangeDependencies() {
    print("IndexFeatureOverlayState.didChangeDependencies");
    config = FeatureOverlayConfig.of(context);

    print("IndexFeatureOverlayState.didChangeDependencies: activeIndex $activeIndex");

    FeatureOverlay? activeFeatureOverlayFromThis;
    if (activeIndex >= 0) {
      activeFeatureOverlayFromThis = featureOverlayList[activeIndex];
    }
    
    if (activeFeatureOverlayFromThis != currentFeatureOverlay) {
      print("IndexFeatureOverlayState.didChangeDependencies: activeFeatureOverlayFromThis $activeFeatureOverlayFromThis changed");
      if (currentOverlayEntry?.mounted ?? false)
        currentOverlayEntry?.remove();
      if (activeFeatureOverlayFromThis != null) {
        currentFeatureOverlay = activeFeatureOverlayFromThis;
        currentOverlayEntry =
            OverlayEntry(builder: (_) => currentFeatureOverlay!);
        tryInsertEntry(overlayKey, currentOverlayEntry!, 3);
      }
      else {
        currentFeatureOverlay = null;
      }
    }
    else {
      print("IndexFeatureOverlayState.didChangeDependencies: activeFeatureOverlayFromThis $activeFeatureOverlayFromThis did not change.");
     
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    print("IndexFeatureOverlayState.build");
    return Stack(children: <Widget>[
      widget.child,
      Overlay(
        key: overlayKey,
        initialEntries: [],
      )
    ]);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty(
          "featureOverlayList", List.from(featureOverlayList).toString()))
      ..add(StringProperty("activeIndex", activeIndex.toString()));
  }
}
