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
## Status

This package is work in progress and not yet published.