# Feature Discovery Widget

This package is based on the [feature_discovery package](https://pub.dev/packages/feature_discovery/), however the major changes have been on the interface and the implementation:

- This package does not have any dependency except on Flutter.
- Statemanagement needs to be implemented by the app.
- The application decides where in the widget tree feature overlay's can appear.

Further the following behaviours are being investigated:
- Have a way for the child to be the tap target
- Difference between barrier and background

## Usage

### FeatureOverlayConfigProvider

wrap the application with `FeatureOverlayConfigProvider`

```dart

FeatureOverlayConfigProvider(
    child: MaterialApp(...))

```

The provider also allows to control the animation speed and control the infinite pulse animation.

### IndexedFeatureOverlay and FeatureOverlay

Wrap the child that should be overlayed with the overlays with the `IndexedFeatureOverlay` and list all feature overlays, that should appear in the `featureOverlays` argument. 

```dart
IndexedFeatureOverlay(
        featureOverlays: {
          FeatureOverlay(
              featureId: "TurnOnAC",
              title: Text("This turns on the AC"),
              tapTarget: Icon(Icons.ac_unit)
              )
        },
        child: Scaffold(
            ...
        ))
```

### FeatureOverlayTarget

Wrap the target that a feature overlay should describe with `FeatureOverlayTarget` and specify the same `featureId`

```dart
  FeatureOverlayTarget(
                featureId: "TurnOnAC",
                child: ElevatedButton(...))
```

Please check the docs for further appearance and configuration options.

### Listening for events and change the active feature

#### Plain Flutter

Example implementation, that works without an statemanagement package.

```dart
class FeatureTourWidget extends StatefulWidget {
  final Widget child;
  final List<String> featureIds;

  FeatureTourWidget({
    Key? key,
    required this.child,
    required this.featureIds,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return FeatureTourState();
  }
}

class FeatureTourState extends State<FeatureTourWidget> {
  Iterator<String>? featuresIterator;
  StreamSubscription<FeatureOverlayEvent>? _subscription;

  @override
  void didUpdateWidget(covariant FeatureTourWidget oldWidget) {
    if (!listEquals(oldWidget.featureIds, widget.featureIds)) {
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        featuresIterator = null;
        _ensureActiveInitialized();
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _ensureActiveInitialized();
    });

    final events = FeatureOverlayConfigProvider.eventStreamOf(context);
    
    _subscription?.cancel();
    _subscription = events.listen((event) {
      if(event.state == FeatureOverlayState.closed) {
        if(event.previousState == FeatureOverlayState.completing) { 
          _nextActive();
        }
        else {
          _setActive(null);
        }
      }
    });
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _ensureActiveInitialized() {
    if (featuresIterator == null) {
      featuresIterator = widget.featureIds.iterator;
      _nextActive();
    }
  }

  void _nextActive() {
    if (featuresIterator!.moveNext())
      _setActive(featuresIterator!.current);
    else
      _setActive(null);
  }

  void _setActive(String? active) {
    final notifier = FeatureOverlayConfigProvider.notifierOf(context);
    notifier.notifyActiveFeature(active);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
```

## Status

This package is work in progress and not yet published.

### To-do

1. Transparent tap target.
2. Extend example with a wider range of overlay configurations.
3. Fix text placement issues
4. Publish package.