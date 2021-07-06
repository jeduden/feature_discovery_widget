import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:flutter/material.dart';

class TestWrapper extends StatelessWidget {
  /// This will be passed to [Scaffold.body].
  final Widget? child;

  const TestWrapper({
    Key? key,
    this.child,
  }) : super(key: key);

  @override
  Widget build(_) => MaterialApp(
        title: 'FeatureDiscoveryWidget Test',
        home: Scaffold(
          appBar: AppBar(
            title: const Text('TestWidget'),
          ),
          body: child,
        ),
      );
}

@visibleForTesting
class TestIcon extends StatefulWidget {
  final String featureId;
  final bool allowShowingDuplicate;

  const TestIcon({
    Key? key,
    required this.featureId,
    required this.allowShowingDuplicate,
  }) : super(key: key);

  @override
  TestIconState createState() => TestIconState();
}

@visibleForTesting
class TestIconState extends State<TestIcon> {
  @override
  Widget build(BuildContext context) {
    const icon = Icon(Icons.more_horiz);
    return DescribedFeatureOverlay(
      featureId: widget.featureId,
      // It is mandatory to disable the pulsing animation
      // in order to use pumpAndSettle in tests.
      // Otherwise, the tester can never settle as it requires frame sync.
      enablePulsingAnimation: false,
      child: icon,
      tapTarget: icon,
      title: const Text('This is it'),
      description: Text('Test has passed for ${widget.featureId}'),
    );
  }
}

/// This contains the complete tree necessary to pump it to the [WidgetTester]
/// and contains an icon that is covered by the overlay because it is overflowing.
/// If [OverflowMode.clipContent] is used, the tester should be able to trigger dismissal.
///
/// This works properly using [TestWidgetsFlutterBinding.setSurfaceSize] with `Size(3e2, 4e3)`.
@visibleForTesting
class OverflowingDescriptionFeature extends StatelessWidget {
  final String? featureId;
  final IconData? icon;

  final void Function(String)? onDismiss;
  final void Function(String)? onComplete;
  final void Function(String)? onFinishedOpening;
  final void Function(String)? onFinishedClosing;

  final OverflowMode? mode;

  const OverflowingDescriptionFeature({
    Key? key,
    this.featureId,
    this.icon,
    this.mode,
    this.onDismiss,
    this.onComplete,
    this.onFinishedOpening,
    this.onFinishedClosing,
  }) : super(key: key);

  @override
  Widget build(_) => TestWrapper(
        child: Builder(
          builder: (context) {
            return Stack(
              children: <Widget>[
                Align(
                  alignment: Alignment.topCenter,
                  child: DescribedFeatureOverlay(
                    featureId: featureId!,
                    tapTarget: const Icon(Icons.arrow_drop_down_circle),
                    description: Container(
                      width: double.infinity,
                      height: 9e3,
                      color: const Color(0xff000000),
                    ),
                    contentLocation: ContentLocation.below,
                    enablePulsingAnimation: false,
                    overflowMode: mode!,
                    initiallyShown: true,
                    onDismiss: onDismiss,
                    onComplete: onComplete,
                    onFinishedClosing: onFinishedClosing,
                    onFinishedOpening: onFinishedOpening,
                    child: Container(
                      width: 1e2,
                      height: 1e2,
                      color: const Color(0xfffffff),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Icon(icon),
                ),
              ],
            );
          },
        ),
      );
}

/// This widget takes two features with the same [featureId], one having a title of [staticFeatureTitle]
/// and the other having a title of [disposableFeatureTitle] and both having an icon of [featureIcon].
/// and one of them is disposable using [WidgetWithDisposableFeatureState.disposeFeature].
///
/// This allows testing [DescribedFeatureOverlay.allowShowingDuplicate]'s
/// ability to show overlays
@visibleForTesting
class WidgetWithDisposableFeature extends StatefulWidget {
  final String featureId;
  final IconData featureIcon;

  final String staticFeatureTitle, disposableFeatureTitle;

  const WidgetWithDisposableFeature({
    Key? key,
    required this.featureId,
    required this.featureIcon,
    required this.staticFeatureTitle,
    required this.disposableFeatureTitle,
  }) : super(key: key);

  @override
  State createState() => WidgetWithDisposableFeatureState();
}

@visibleForTesting
class WidgetWithDisposableFeatureState
    extends State<WidgetWithDisposableFeature> {
  late bool _showDisposableFeature;

  @override
  void initState() {
    _showDisposableFeature = true;
    super.initState();
  }

  void disposeFeature() {
    setState(() {
      _showDisposableFeature = false;
    });
  }

  @override
  Widget build(_) => TestWrapper(
        child: Column(
          children: <Widget>[
            if (_showDisposableFeature)
              DescribedFeatureOverlay(
                featureId: widget.featureId,
                enablePulsingAnimation: false,
                title: Text(widget.disposableFeatureTitle),
                tapTarget: Icon(widget.featureIcon),
                child: Container(),
              ),
            DescribedFeatureOverlay(
              featureId: widget.featureId,
              enablePulsingAnimation: false,
              title: Text(widget.staticFeatureTitle),
              tapTarget: Icon(widget.featureIcon),
              child: Container(),
            ),
          ],
        ),
      );
}