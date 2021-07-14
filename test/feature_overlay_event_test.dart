import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("FeatureOverlayEvents", () {
    test("toString", () {
      expect(
          FeatureOverlayEvent(
                  featureId: "myFeature",
                  previousState: FeatureOverlayState.completing,
                  state: FeatureOverlayState.closed)
              .toString(),
          equals(
              "FeatureOverlayEvent(featureId: \"myFeature\", previousState: completing, state: closed)"));
    });

    group("==", () {
      test("same data", () {
        expect(
            FeatureOverlayEvent(
                featureId: "myFeature",
                previousState: FeatureOverlayState.completing,
                state: FeatureOverlayState.closed),
            equals(FeatureOverlayEvent(
                featureId: "myFeature",
                previousState: FeatureOverlayState.completing,
                state: FeatureOverlayState.closed)));
      });

      test("class is different", () {
        expect(
            FeatureOverlayEvent(
                featureId: "myFeature2",
                previousState: FeatureOverlayState.completing,
                state: FeatureOverlayState.closed),
            isNot(equals(["hello"])));
      });
      test("featureId is different", () {
        final a = FeatureOverlayEvent(
                featureId: "myFeature2",
                previousState: FeatureOverlayState.completing,
                state: FeatureOverlayState.closed);
        final b = FeatureOverlayEvent(
                featureId: "myFeature",
                previousState: FeatureOverlayState.completing,
                state: FeatureOverlayState.closed);
        expect(a,isNot(equals(b)));
        expect(a.hashCode,isNot(equals(b.hashCode)));
      });
      test("previousState is different", () {
        final a = FeatureOverlayEvent(
                featureId: "myFeature",
                previousState: FeatureOverlayState.opening,
                state: FeatureOverlayState.closed);
        final b = FeatureOverlayEvent(
                featureId: "myFeature",
                previousState: FeatureOverlayState.completing,
                state: FeatureOverlayState.closed);
        expect(a,isNot(equals(b)));
        expect(a.hashCode,isNot(equals(b.hashCode)));
      });
      test("state is different", () {
        final a = FeatureOverlayEvent(
                featureId: "myFeature",
                previousState: FeatureOverlayState.completing,
                state: FeatureOverlayState.dismissing);
        final b = FeatureOverlayEvent(
                featureId: "myFeature",
                previousState: FeatureOverlayState.completing,
                state: FeatureOverlayState.closed);
        expect(a,isNot(equals(b)));
        expect(a.hashCode,isNot(equals(b.hashCode)));
      });
    });
  });
}
