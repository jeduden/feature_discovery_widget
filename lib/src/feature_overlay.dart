import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';

import 'package:feature_discovery_widget/src/enums.dart';
import 'package:feature_discovery_widget/src/background_content_layout_delegate.dart';
import 'package:feature_discovery_widget/src/content.dart';
import 'package:feature_discovery_widget/src/center_about.dart';
import 'package:feature_discovery_widget/src/feature_overlay_config.dart';

import 'composite_transform_loose.dart';
import 'feature_overlay_event.dart';

/// Configures the contents and appearance of the feature overlay
/// identified with the [featureId].
/// Can only be placed in the [IndexFeatureOverlay.featureOverlays] set.
class FeatureOverlay extends StatefulWidget {
  static const double kDefaultBackgroundOpacity = 0.96;

  /// This id must be unique among all the [FeatureOverlay] widgets.
  final String featureId;

  /// The color of the large circle, where the text sits on.
  /// If null, defaults to [ThemeData.primaryColor].
  final Color? backgroundColor;

  /// The amount blur on the background. defaults to 0
  final double? backgroundBlur;

  /// The opacity of the large circle, where the text sits on.
  /// If null, defaults to 0.96.
  final double backgroundOpacity;

  /// Color of the target, that is the small circle behind the tap target.
  final Color targetColor;

  /// Color for title and text.
  final Color textColor;

  /// This is the first content widget, i.e. it is displayed above [description].
  ///
  /// It is intended for this to contain a [Text] widget, however, you can pass
  /// any [Widget].
  /// The overlay uses a [DefaultTextStyle] for the title, which is a combination
  /// of [TextTheme.headline6] from [Theme] and the [textColor].
  final Widget? title;

  /// This is the second content widget, i.e. it is displayed below [description].
  ///
  /// It is intended for this to contain a [Text] widget, however, you can pass
  /// any [Widget].
  /// The overlay uses a [DefaultTextStyle] for the description, which is a combination
  /// of [TextTheme.bodyText2] from [Theme] and the [textColor].
  final Widget? description;

  /// This is usually an [Icon].
  /// The final tap target will already have a tap listener to finish each step.
  ///
  /// If you want to hit the tap target in integration tests, you should pass a [Key]
  /// to this [Widget] instead of as the [Key] of [FeatureOverlay].
  final Widget tapTarget;

  /// Specifies how the content should be positioned relative to the tap target.
  final ContentLocation contentLocation;

  /// Controls what happens with content that overflows the background's area.
  ///
  /// Defaults to [OverflowMode.ignore].
  ///
  /// Important consideration: if your content is overflowing the inner area, it will catch hit events
  /// and if you do not handle these correctly, the user might not be able to dismiss your feature
  /// overlay by tapping outside of the circle. If you use [OverflowMode.clipContent], the package takes
  /// care of hit testing and allows the user to tap outside the circle even if your content would
  /// appear there without clipping.
  ///
  /// See also:
  ///
  ///  * [OverflowMode], which has explanations for the different modes.
  final OverflowMode overflowMode;

  /// Controls whether the overlay should be dismissed on touching outside or not.
  ///
  /// The default value for [dismissible] will be taking for [FeatureOverlayConfig.dismissableDefault]
  final bool? dismissible;

  /// Color of the screen overlay by default [Colors.transparent]
  final Color? screenOverlayColor;

  /// Called after the feature finished completing state.
  /// It moves to closed state only after this handler returns.
  final Future<void> Function()? onCompleted;

  /// Called before the feature is transitioning to opening state.
  /// The feature will go into opening state when this handler returns
  final Future<void> Function()? onOpening;

  /// Pulse radius when contracted
  final double? pulseBaseRadius;

  /// Size of expansion in addition to contracted radius
  final double? pulseRadiusExpansion;

  /// Tap target base radius
  double? tapTargetBaseRadius;

  /// Tap target expansion during opening
  double? tapTargetOpeningExpansion;

  /// Tap target pulsing expansion when opened
  double? tapTargetOpenedExpansion;

  FeatureOverlay({
    Key? key,
    required this.featureId,
    this.backgroundColor,
    this.screenOverlayColor,
    this.targetColor = Colors.white,
    this.textColor = Colors.white,
    this.title,
    this.description,
    required this.tapTarget,
    this.onCompleted,
    this.onOpening,
    this.contentLocation = ContentLocation.trivial,
    this.overflowMode = OverflowMode.ignore,
    this.backgroundOpacity = kDefaultBackgroundOpacity,
    this.backgroundBlur,
    this.dismissible,
    this.pulseBaseRadius,
    this.pulseRadiusExpansion,
    this.tapTargetBaseRadius,
    this.tapTargetOpeningExpansion,
    this.tapTargetOpenedExpansion,
  }) : super(key: key);

  @override
  _FeatureOverlayState createState() {
    final state = _FeatureOverlayState();
    return state;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(StringProperty("featureId", featureId));
  }
}

class _FeatureOverlayState extends State<FeatureOverlay>
    with SingleTickerProviderStateMixin {
  late Size _screenSize;

  late FeatureOverlayState _state;
  String? _activeFeature;
  late AnimationController _animationController;

  FeatureOverlayConfig get config {
    print("_DescribedFeatureOverlayState.config");
    return FeatureOverlayConfig.of(context);
  }

  @override
  void initState() {
    _state = FeatureOverlayState.closed;
    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1))
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener((status) {
            print("AnimationStatus: ${status.toString()}");
            if (status == AnimationStatus.completed)
              advanceState(activeFeature: _activeFeature);
          });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _screenSize = MediaQuery.of(context).size;
    print(
        "_DescribedFeatureOverlayState.didChangeDependencies _activeFeature=$_activeFeature config.activeFeatureId=${config.activeFeatureId}");
    if (_activeFeature != config.activeFeatureId) {
      advanceState(activeFeature: config.activeFeatureId);
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void advanceState(
      {FeatureOverlayState? to, required String? activeFeature}) async {
    setState(() {
      _activeFeature = activeFeature;

      if (_state == to) {
        // dragging to dismiss. we keep getting advance state to dismissing
        // we must not reset + restart the animation controller
        // but actually continue the animation
        assert(_state == FeatureOverlayState.dismissing);
        return;
      }
      _animationController
          .stop(); // we don't want any completion notifications. anymore
      switch (_state) {
        case FeatureOverlayState.onOpening:
          assert(to == null);
          _setOverlayState(FeatureOverlayState.opening);
          _animationController.duration = config.openDuration;
          _animationController.forward(from: 0);
          break;
        case FeatureOverlayState.opening:
          assert(to == null || to == FeatureOverlayState.dismissing);
          if (_activeFeature != widget.featureId) {
            _setOverlayState(FeatureOverlayState.dismissing);
            _animationController.duration = config.dismissDuration;
            _animationController.forward(from: 0);
          } else {
            _setOverlayState(FeatureOverlayState.opened);
            if (config.enablePulsingAnimation) {
              _animationController.duration = config.pulseDuration;
              _animationController.repeat();
            }
          }
          break;
        case FeatureOverlayState.completing:
          assert(to == null);
          _setOverlayState(FeatureOverlayState.onCompleted);
          WidgetsBinding.instance!.addPostFrameCallback((_) async {
            await widget.onCompleted?.call();
            advanceState(activeFeature: null);
          });
          break;
        case FeatureOverlayState.onCompleted:
          assert(to == null);
          _setOverlayState(FeatureOverlayState.closed);
          break;
        case FeatureOverlayState.dismissing:
          assert(to == null);
          _setOverlayState(FeatureOverlayState.closed);
          break;
        case FeatureOverlayState.closed:
          //assert(to == null || to == FeatureOverlayState.closed);
          if (to != null && to != FeatureOverlayState.closed) {
            print(
                "_DescribedFeatureOverlayState: is this a bug: transition from closed -> $to for feature: \"${widget.featureId}\" active feature:\"$_activeFeature\"");
          }
          if (_activeFeature == widget.featureId) {
            _setOverlayState(FeatureOverlayState.onOpening);
            WidgetsBinding.instance!.addPostFrameCallback((_) async {
              await widget.onOpening?.call();
              advanceState(activeFeature: _activeFeature);
            });
          }
          break;
        case FeatureOverlayState.opened:
          if (to == FeatureOverlayState.completing) {
            _animationController.duration = config.completeDuration;
            _setOverlayState(FeatureOverlayState.completing);
          } else {
            assert(to == FeatureOverlayState.dismissing || to == null);
            _animationController.duration = config.dismissDuration;
            _setOverlayState(FeatureOverlayState.dismissing);
          }
          _animationController.forward(from: 0);
          break;
      }

      print("State: ${_state.toString()}");
    });
  }

  void _setOverlayState(FeatureOverlayState nextState) {
    final previousState = _state;
    _state = nextState;
    print("Next State: $nextState");
    config.eventsSink.add(FeatureOverlayEvent(
        state: _state,
        previousState: previousState,
        featureId: widget.featureId));
  }

  void _dismiss() {
    final dismissible = widget.dismissible ??
        FeatureOverlayConfig.of(context).dismissibleDefault;
    if (!dismissible) {
      print("Ignore dismiss.");
      return;
    }

    if (_state != FeatureOverlayState.completing &&
        _state != FeatureOverlayState.onCompleted) {
      // don't dismiss during completing + onCompleted
      advanceState(
          to: FeatureOverlayState.dismissing, activeFeature: _activeFeature);
    }
  }

  void _complete() {
    if (_state != FeatureOverlayState.dismissing) {
      // don't complete anymore when dismissing
      advanceState(
          to: FeatureOverlayState.completing, activeFeature: _activeFeature);
    }
  }

  bool _isCloseToTopOrBottom(Offset position) =>
      position.dy <= 88.0 || (_screenSize.height - position.dy) <= 88.0;

  bool _isOnTopHalfOfScreen(Offset position) =>
      position.dy < (_screenSize.height / 2.0);

  bool _isOnLeftHalfOfScreen(Offset position) =>
      position.dx < (_screenSize.width / 2.0);

  /// The value returned from here will be adjusted in [BackgroundContentLayoutDelegate]
  /// in order to match the transition progress and overlay state.
  double _backgroundRadius(Offset anchor) {
    final isBackgroundCentered = _isCloseToTopOrBottom(anchor);
    final backgroundRadius = min(_screenSize.width, _screenSize.height) *
        (isBackgroundCentered ? 0.7 : 1.0);
    return backgroundRadius;
  }

  Offset? _backgroundPosition(Offset anchor, ContentLocation contentLocation) {
    final width = min(_screenSize.width, _screenSize.height);
    final isBackgroundCentered = _isCloseToTopOrBottom(anchor);

    if (isBackgroundCentered) {
      return anchor;
    } else {
      final startingBackgroundPosition = anchor;

      Offset? endingBackgroundPosition;
      switch (contentLocation) {
        case ContentLocation.above:
          endingBackgroundPosition = Offset(
              anchor.dx -
                  width / 2.0 +
                  (_isOnLeftHalfOfScreen(anchor) ? -20.0 : 20.0),
              anchor.dy - (width / 2.0) + 80.0);
          break;
        case ContentLocation.below:
          endingBackgroundPosition = Offset(
              anchor.dx -
                  width / 2.0 +
                  (_isOnLeftHalfOfScreen(anchor) ? -20.0 : 20.0),
              anchor.dy + (width / 2.0) - 80.0);
          break;
        case ContentLocation.trivial:
          throw ArgumentError.value(contentLocation);
      }

      switch (_state) {
        case FeatureOverlayState.opening:
          final adjustedPercent =
              const Interval(0.0, 0.8, curve: Curves.easeOut)
                  .transform(_animationController.value);
          return Offset.lerp(startingBackgroundPosition,
              endingBackgroundPosition, adjustedPercent);
        case FeatureOverlayState.completing:
          return endingBackgroundPosition;
        case FeatureOverlayState.dismissing:
          return Offset.lerp(endingBackgroundPosition,
              startingBackgroundPosition, _animationController.value);
        case FeatureOverlayState.opened:
          return endingBackgroundPosition;
        case FeatureOverlayState.onCompleted:
        case FeatureOverlayState.onOpening:
        case FeatureOverlayState.closed:
          return startingBackgroundPosition;
      }
    }
  }

  ContentLocation _nonTrivialContentOrientation(Offset anchor) {
    if (widget.contentLocation != ContentLocation.trivial) {
      return widget.contentLocation;
    }

    // Calculates appropriate content location for ContentLocation.trivial.
    if (_isCloseToTopOrBottom(anchor)) {
      return _isOnTopHalfOfScreen(anchor)
          ? ContentLocation.below
          : ContentLocation.above;
    } else {
      return _isOnTopHalfOfScreen(anchor)
          ? ContentLocation.above
          : ContentLocation.below;
    }
  }

  Offset? _contentCenterPosition(Offset anchor) {
    final width = min(_screenSize.width, _screenSize.height);
    final isBackgroundCentered = _isCloseToTopOrBottom(anchor);

    if (isBackgroundCentered) {
      return anchor;
    } else {
      final startingBackgroundPosition = anchor;
      final endingBackgroundPosition = Offset(
          anchor.dx + (_isOnLeftHalfOfScreen(anchor) ? -20.0 : 20.0),
          anchor.dy +
              (_isOnTopHalfOfScreen(anchor)
                  ? -(width / 2) + 40.0
                  : (width / 20.0) - 40.0));

      switch (_state) {
        case FeatureOverlayState.opening:
          final adjustedPercent =
              const Interval(0.0, 0.8, curve: Curves.easeOut)
                  .transform(_animationController.value);
          return Offset.lerp(startingBackgroundPosition,
              endingBackgroundPosition, adjustedPercent);
        case FeatureOverlayState.completing:
          return endingBackgroundPosition;
        case FeatureOverlayState.dismissing:
          return Offset.lerp(endingBackgroundPosition,
              startingBackgroundPosition, _animationController.value);
        case FeatureOverlayState.opened:
          return endingBackgroundPosition;
        case FeatureOverlayState.onCompleted:
        case FeatureOverlayState.onOpening:
        case FeatureOverlayState.closed:
          return startingBackgroundPosition;
      }
    }
  }

  double _contentOffsetMultiplier(ContentLocation orientation) {
    assert(orientation != ContentLocation.trivial);

    if (orientation == ContentLocation.above) return -1;

    return 1;
  }

  Widget _buildOverlay(BuildContext context) {
    final link = FeatureOverlayConfig.of(context).layerLink;
    // Need to move the immediate child of follower to the left top
    // corner to make sure the tap target
    // is fully covered by the child.
    // otherwise a top on the target is not detected,
    // and the background is hit instead.

    final normRadius = _TapTarget.calcNormalRadius(
        baseRadius: widget.tapTargetBaseRadius,
        radiusOpeningExpansion: widget.tapTargetOpeningExpansion);
    final tapTargetRadiusOffset = Offset(normRadius, normRadius) * sqrt(2);

    final anchor = tapTargetRadiusOffset; //tapTargetRadiusOffset;

    // This will be assigned either above or below, i.e. trivial from
    // widget.contentLocation will be converted to above or below.
    final contentLocation = _nonTrivialContentOrientation(anchor);
    assert(contentLocation != ContentLocation.trivial);

    final backgroundCenter = _backgroundPosition(anchor, contentLocation)!;
    final backgroundRadius = _backgroundRadius(anchor);

    final leaderOffset = link.leader?.offset ?? Offset.zero;
    final leaderSize = link.leaderSize ?? Size.zero;
    // This is the offset generated by targetAnchor: Alignment.center and followerAnchor: Alignment.topLeft,
    final leaderCenterOffset = leaderSize.center(leaderOffset);
    // now we need to substract tapTargetRadiusOffset because we specify it in offset:-tapTargetRadiusOffset
    final contentCenterAnchorOffset =
        leaderCenterOffset - tapTargetRadiusOffset;

    final contentOffsetMultiplier = _contentOffsetMultiplier(contentLocation);
    final contentCenterPosition =
        _contentCenterPosition(-contentCenterAnchorOffset)!;

    final contentWidth = min(_screenSize.width, _screenSize.height);

    var dx = contentCenterPosition.dx - contentWidth;
    if (contentCenterAnchorOffset.dx + dx + contentWidth > _screenSize.width) {
      dx = _screenSize.width - contentWidth + contentCenterAnchorOffset.dx;
    } else if (dx + contentCenterAnchorOffset.dx < 0) {
      dx = -contentCenterAnchorOffset.dx;
    }

    final tapTarget = _TapTarget(
      state: _state,
      transitionProgress: _animationController.value,
      anchor: anchor,
      color: widget.targetColor,
      onPressed: _complete,
      child: widget.tapTarget,
      baseRadius: widget.tapTargetBaseRadius,
      radiusOpeningExpansion: widget.tapTargetOpeningExpansion,
      radiusOpenedExpansion: widget.tapTargetOpenedExpansion,
    );

    final contentPosition = Offset(
      dx,
      anchor.dy + contentOffsetMultiplier * tapTarget.maxRadius,
    );

    return Stack(fit: StackFit.expand, clipBehavior: Clip.none, children: [
      _ScreenOverlay(
          color: widget.screenOverlayColor ?? config.screenOverlayColor,
          state: _state,
          transitionProgress: _animationController.value,
          onTap: _dismiss),
      CompositedTransformLooseFollower(
          showWhenUnlinked:
              false, // we really dont want to display anything if our target is gone.
          link: link,
          targetAnchor: Alignment.center,
          followerAnchor: Alignment.topLeft,
          offset: -tapTargetRadiusOffset,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: CustomMultiChildLayout(
                    delegate: BackgroundContentLayoutDelegate(
                      overflowMode: widget.overflowMode,
                      contentPosition: contentPosition,
                      backgroundCenter: backgroundCenter,
                      backgroundRadius: backgroundRadius,
                      anchor: anchor,
                      contentOffsetMultiplier: contentOffsetMultiplier,
                      state: _state,
                      transitionProgress: _animationController.value,
                    ),
                    children: <Widget>[
                      LayoutId(
                        id: BackgroundContentLayout.background,
                        child: _Background(
                            transitionProgress: _animationController.value,
                            color: widget.backgroundColor ??
                                Theme.of(context).primaryColor,
                            defaultBlur: widget.backgroundBlur ?? 0,
                            defaultOpacity: widget.backgroundOpacity,
                            state: _state,
                            overflowMode: widget.overflowMode,
                            onTap: () async {
                              _dismiss();
                            }),
                      ),
                      LayoutId(
                        id: BackgroundContentLayout.content,
                        child: Content(
                          state: _state,
                          transitionProgress: _animationController.value,
                          title: widget.title,
                          description: widget.description,
                          textColor: widget.textColor,
                          overflowMode: widget.overflowMode,
                          backgroundCenter: backgroundCenter,
                          backgroundRadius: backgroundRadius,
                          width: contentWidth,
                        ),
                      ),
                    ],
                  )),
              _Pulse(
                baseRadius: widget.pulseBaseRadius,
                radiusExpansion: widget.pulseRadiusExpansion,
                state: _state,
                transitionProgress: _animationController.value,
                anchor: anchor,
                color: widget.targetColor,
              ),
              tapTarget,
            ],
          ))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    print("_FeatureOverlayState.build $this");
    final config = FeatureOverlayConfig.of(context);
    final key = ValueKey(widget.featureId);
    if (config.activeFeatureId == widget.featureId) {
      return _buildOverlay(context);
    } else {
      return Container(key: key);
    }
  }
}

class _ScreenOverlay extends StatelessWidget {
  final FeatureOverlayState state;
  final double transitionProgress;
  final Color color;
  final FutureOr<void> Function() onTap;

  const _ScreenOverlay({
    Key? key,
    required this.color,
    required this.state,
    required this.transitionProgress,
    required this.onTap,
  }) : super(key: key);

  double get opacity {
    switch (state) {
      case FeatureOverlayState.opening:
        final adjustedPercent = const Interval(0.0, 0.3, curve: Curves.easeOut)
            .transform(transitionProgress);
        return adjustedPercent;

      case FeatureOverlayState.completing:
        final adjustedPercent = const Interval(0.1, 0.6, curve: Curves.easeOut)
            .transform(transitionProgress);

        return (1 - adjustedPercent);
      case FeatureOverlayState.dismissing:
        final adjustedPercent = const Interval(0.2, 1.0, curve: Curves.easeOut)
            .transform(transitionProgress);
        return (1 - adjustedPercent);
      case FeatureOverlayState.opened:
        return 1.0;
      case FeatureOverlayState.onOpening:
      case FeatureOverlayState.onCompleted:
      case FeatureOverlayState.closed:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (state == FeatureOverlayState.closed) {
      return Container();
    }

    return GestureDetector(
      onTap: onTap,
      onPanUpdate: (_) async {
        await onTap();
      },
      child: Opacity(opacity: opacity, child: Container(color: color)),
    );
  }
}

class _Background extends StatelessWidget {
  final FeatureOverlayState state;
  final double transitionProgress;
  final Color color;
  final OverflowMode overflowMode;
  final double defaultOpacity;
  final double defaultBlur;
  final FutureOr<void> Function() onTap;

  const _Background({
    Key? key,
    required this.color,
    required this.state,
    required this.transitionProgress,
    required this.overflowMode,
    required this.defaultOpacity,
    this.defaultBlur = 3,
    required this.onTap,
  }) : super(key: key);

  double get opacity {
    switch (state) {
      case FeatureOverlayState.opening:
        final adjustedPercent = const Interval(0.0, 0.3, curve: Curves.easeOut)
            .transform(transitionProgress);
        return defaultOpacity * adjustedPercent;

      case FeatureOverlayState.completing:
        final adjustedPercent = const Interval(0.1, 0.6, curve: Curves.easeOut)
            .transform(transitionProgress);

        return defaultOpacity * (1 - adjustedPercent);
      case FeatureOverlayState.dismissing:
        final adjustedPercent = const Interval(0.2, 1.0, curve: Curves.easeOut)
            .transform(transitionProgress);
        return defaultOpacity * (1 - adjustedPercent);
      case FeatureOverlayState.opened:
        return defaultOpacity;
      case FeatureOverlayState.onOpening:
      case FeatureOverlayState.onCompleted:
      case FeatureOverlayState.closed:
        return 0;
    }
  }

  double get blur {
    switch (state) {
      case FeatureOverlayState.opening:
        return defaultBlur * transitionProgress;
      case FeatureOverlayState.completing:
        return defaultBlur * (1 - transitionProgress);
      case FeatureOverlayState.dismissing:
        return defaultBlur * (1 - transitionProgress);
      case FeatureOverlayState.opened:
        return defaultBlur;
      case FeatureOverlayState.onOpening:
      case FeatureOverlayState.onCompleted:
      case FeatureOverlayState.closed:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (state == FeatureOverlayState.closed) {
      return Container();
    }

    Widget result = LayoutBuilder(
        builder: (context, constraints) => ClipOval(
              child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: Container(
                    // The size is controlled in BackgroundContentLayoutDelegate.
                    width: constraints.biggest.width,
                    height: constraints.biggest.height,
                    //child: Text("bla", textScaleFactor: 3,),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(opacity)),
                  )),
            ));

    result = GestureDetector(
      onTap: onTap,
      onPanUpdate: (_) async {
        await onTap();
      },
      child: result,
    );

    return result;
  }
}

class _Pulse extends StatelessWidget {
  final FeatureOverlayState state;
  final double transitionProgress;
  final double baseRadius;
  final double radiusExpansion;
  final Offset anchor;
  final Color color;

  const _Pulse({
    Key? key,
    required this.state,
    required this.transitionProgress,
    required this.anchor,
    required this.color,
    double? baseRadius,
    double? radiusExpansion,
  })  : baseRadius = baseRadius ?? 44.0,
        radiusExpansion = radiusExpansion ?? 35.0,
        super(key: key);

  double get radius {
    switch (state) {
      case FeatureOverlayState.opened:
        double expandedPercent;
        if (transitionProgress >= 0.3 && transitionProgress <= 0.8) {
          expandedPercent = (transitionProgress - 0.3) / 0.5;
        } else {
          expandedPercent = 0.0;
        }
        return baseRadius + (radiusExpansion * expandedPercent);
      case FeatureOverlayState.dismissing:
      case FeatureOverlayState.completing:
        return 0; //(44.0 + 35.0) * (1.0 - transitionProgress);
      case FeatureOverlayState.opening:
      case FeatureOverlayState.onCompleted:
      case FeatureOverlayState.onOpening:
      case FeatureOverlayState.closed:
        return 0;
    }
  }

  double get opacity {
    switch (state) {
      case FeatureOverlayState.opened:
        final percentOpaque =
            1 - ((transitionProgress.clamp(0.3, 0.8) - 0.3) / 0.5);
        return (percentOpaque * 0.75).clamp(0, 1);
      case FeatureOverlayState.completing:
      case FeatureOverlayState.dismissing:
        return 0; //((1.0 - transitionProgress) * 0.5).clamp(0.0, 1.0);
      case FeatureOverlayState.opening:
      case FeatureOverlayState.onCompleted:
      case FeatureOverlayState.onOpening:
      case FeatureOverlayState.closed:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) => state == FeatureOverlayState.closed
      ? Container()
      : CenterAbout(
          position: anchor,
          child: Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(opacity),
            ),
          ),
        );
}

class _TapTarget extends StatelessWidget {
  final FeatureOverlayState state;
  final double transitionProgress;
  final Offset anchor;
  final Widget child;
  final Color color;
  final double baseRadius;
  final double radiusOpeningExpansion;
  final double radiusOpenedExpansion;

  final VoidCallback onPressed;

  static const defaultRadiusOpeningExpansion = 24.0;
  static const defaultBaseRadius = 20.0;

  const _TapTarget({
    Key? key,
    required this.anchor,
    required this.child,
    required this.onPressed,
    required this.color,
    required this.state,
    required this.transitionProgress,
    double? baseRadius,
    double? radiusOpeningExpansion,
    double? radiusOpenedExpansion,
  })  : baseRadius = baseRadius ?? defaultBaseRadius,
        radiusOpeningExpansion =
            radiusOpeningExpansion ?? defaultRadiusOpeningExpansion,
        radiusOpenedExpansion = radiusOpenedExpansion ?? 20.0,
        super(key: key);

  double get opacity {
    switch (state) {
      case FeatureOverlayState.opening:
        return const Interval(0, 0.3, curve: Curves.easeOut)
            .transform(transitionProgress);
      case FeatureOverlayState.completing:
      case FeatureOverlayState.dismissing:
        return 1 -
            const Interval(0.7, 1, curve: Curves.easeOut)
                .transform(transitionProgress);
      case FeatureOverlayState.onCompleted:
      case FeatureOverlayState.onOpening:
      case FeatureOverlayState.closed:
        return 0;
      case FeatureOverlayState.opened:
        return 1;
    }
  }

  double get maxRadius => normalRadius + radiusOpenedExpansion;

  double get normalRadius => calcNormalRadius(
      baseRadius: baseRadius, radiusOpeningExpansion: radiusOpeningExpansion);

  static double calcNormalRadius({
    double? baseRadius,
    double? radiusOpeningExpansion,
  }) =>
      (baseRadius ?? defaultBaseRadius) +
      (radiusOpeningExpansion ?? defaultRadiusOpeningExpansion);

  double get radius {
    switch (state) {
      case FeatureOverlayState.onCompleted:
      case FeatureOverlayState.onOpening:
      case FeatureOverlayState.closed:
        return 0;
      case FeatureOverlayState.opening:
        return baseRadius + radiusOpenedExpansion * transitionProgress;
      case FeatureOverlayState.opened:
        double expandedPercent;
        if (transitionProgress < 0.3) {
          expandedPercent = transitionProgress / 0.3;
        } else if (transitionProgress < 0.6) {
          expandedPercent = 1 - ((transitionProgress - 0.3) / 0.3);
        } else {
          expandedPercent = 0;
        }
        return normalRadius + (radiusOpenedExpansion * expandedPercent);
      case FeatureOverlayState.completing:
      case FeatureOverlayState.dismissing:
        return normalRadius * (1 - transitionProgress);
    }
  }

  @override
  Widget build(BuildContext context) => CenterAbout(
        position: anchor,
        child: Container(
          height: 2 * radius,
          width: 2 * radius,
          child: Opacity(
            opacity: opacity,
            child: RawMaterialButton(
                fillColor: color,
                shape: const CircleBorder(),
                child: child,
                onPressed: onPressed),
          ),
        ),
      );
}
