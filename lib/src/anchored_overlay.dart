import 'package:flutter/material.dart';

import 'feature_overlay_config.dart';

class AnchoredOverlay extends StatelessWidget {
  final bool? showOverlay;
  final Widget Function(BuildContext)? overlayBuilder;
  final Widget? child;

  const AnchoredOverlay(
      {Key? key, this.showOverlay, this.overlayBuilder, this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => _OverlayBuilder(
          showOverlay: showOverlay,
          overlayBuilder: overlayBuilder,
          child: child,
        ),
      );
}

class _OverlayBuilder extends StatefulWidget {
  final bool? showOverlay;
  final Function(BuildContext context)? overlayBuilder;
  final Widget? child;

  const _OverlayBuilder(
      {Key? key, this.showOverlay = false, this.overlayBuilder, this.child})
      : super(key: key);

  @override
  _OverlayBuilderState createState() => _OverlayBuilderState();
}

class _OverlayBuilderState extends State<_OverlayBuilder> {
  OverlayEntry? overlayEntry;

  @override
  void initState() {
    super.initState();
    if (widget.showOverlay!) showOverlay();
  }

  @override
  void didChangeDependencies()
  {
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(_OverlayBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncWidgetAndOverlay();
  }

  @override
  void reassemble() {
    super.reassemble();
    syncWidgetAndOverlay();
  }

  @override
  void dispose() {
    if (isShowingOverlay()) hideOverlay();
    super.dispose();
  }

  bool isShowingOverlay() => overlayEntry != null;

  void showOverlay() {
    overlayEntry = OverlayEntry(
      builder: widget.overlayBuilder as Widget Function(BuildContext),
    );
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      Overlay.of(context)!.insert(overlayEntry!);
    });
  }

  void hideOverlay() {
    overlayEntry!.remove();
    overlayEntry = null;
  }

  void syncWidgetAndOverlay() {
    if (isShowingOverlay() && !widget.showOverlay!) {
      hideOverlay();
    } else if (!isShowingOverlay() && widget.showOverlay!) {
      showOverlay();
    }
  }

  void buildOverlay() async => overlayEntry?.markNeedsBuild();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      buildOverlay();//everytime this widget is built - we need to rebuild 
      // the overlay. since we only have a builder method
      // the dependency of the child are not applied for the contents of the builder.
      // they are applied to this part of the tree.  
      // we need to call this in a post - since the build is already in progress
      // this means all rebuilds of the overlay are delayed by one frame.
      // :(
    });
    
    final LayerLink layerLink = FeatureOverlayConfig.of(context).layerLink;
    return CompositedTransformTarget(link: layerLink, child: widget.child);
  }
}
