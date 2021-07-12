

import 'package:flutter/material.dart';
class FeatureOverlayPortal extends StatelessWidget {
  final String portalId;
  final Widget child;

  FeatureOverlayPortal({
    Key? key,
    required this.child,
    required this.portalId
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    final overlay = Overlay(key: GlobalObjectKey(portalId),);
    return Stack(children: [
      child,
      overlay
    ],);
  }
}