

import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:flutter/material.dart';

import 'feature_overlay_config.dart';
import 'feature_overlay_config_provider.dart';

class FeatureOverlayPortal extends StatefulWidget {
  final String portalId;
  final Widget child;

  FeatureOverlayPortal({
    Key? key,
    required this.child,
    required this.portalId
  }) : super(key: key);


  @override
  State<StatefulWidget> createState() {
    return FeatureOverlayPortalState();
  }
}

class FeatureOverlayPortalState extends State<FeatureOverlayPortal>
{
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}