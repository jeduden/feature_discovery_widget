# Feature Discovery Widget

This package is based on the [feature_discovery package](https://pub.dev/packages/feature_discovery/), however the major changes have been done:

- This package does not have any dependency except Flutter.
- Persistence needs to be implemented by the app. There is a simple FeatureTour widget, which implements a feature tour, but requires an instance of persistence interface. 
- The application decides where in the widget tree feature overlay's can appear.
- Includes changes/fixes regarding layout, animation and painting.

## Usage

### Install

Add to pubspec.yaml:

```yaml
dependencies:
  feature_discovery_widget:
    git: https://github.com/jeduden/feature_discovery_widget.git
```

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

### Feature Tour Persistence Implementation

Example implementation using the [shared_preferences](https://pub.dev/packages/shared_preferences) package.

```dart

class FeatureTourPersistenceWithSharedPreferences implements FeatureTourPersistence {
  static const keyId = "completedFeatures";
    
  @override
  Future<Set<String>> completedFeatures() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(keyId) ?? []).toSet();
  }

  @override
  Future<void> completeFeature(String featureId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final newCompletedSet = completedFeatures()
                        ..add(featureId);
    await prefs.setStringList(keyId, newCompletedSet.toList());
  }

  // Helpful to reset tutorial. but not part of the interface [FeatureTourPersistence]
  Future<void> clearCompletions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(keyId);
  }
}

```

## Status

This package is works for some configurations and is not (yet?) published on pub.dev.

### To-do
   
1. Support other feature discovery designs that work non-icon widgets?
2. Add example with a wider range of configurations.
3. Remove debug statements
4. Figure out / work on better test coverage
5. Publish package?