import 'dart:async';
import 'dart:math';

import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:feature_discovery_widget/src/indexed_feature_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final List<FeatureOverlayEvent> events = [];
  final eventController = StreamController<FeatureOverlayEvent>();

  setUpAll(() {
    eventController.stream.listen((event) => events.add(event));
  });
  tearDownAll(() {
    eventController.close();
  });
  setUp(() {
    events.clear();
  });
  group('Content placement', () {
    const screenSize = Size(3e2, 4e3);
    final builder =
        (OverflowMode mode, Alignment alignTarget, Rect expectedBackgroudRect) {
      
      testWidgets("$mode - $alignTarget", (WidgetTester tester) async {
        await (TestWidgetsFlutterBinding.ensureInitialized()
                as TestWidgetsFlutterBinding)
            .setSurfaceSize(screenSize);

        final featureId = "myFeature";
        final key = GlobalKey();
        final featureOverlay = FeatureOverlay(
          key: key,
          featureId: featureId,
          overflowMode: mode,
          tapTarget: Icon(Icons.ac_unit_sharp),
        );
        await tester.pumpWidget(MediaQuery(
            data: new MediaQueryData(size: screenSize),
            child: Directionality(
                textDirection: TextDirection.ltr,
                child: FeatureOverlayConfig(
                  enablePulsingAnimation: false,
                  layerLink: LayerLink(),
                  activeFeatureId: featureId,
                  eventsSink: eventController.sink,
                  openDuration: Duration(milliseconds: 10),
                  child: IndexedFeatureOverlay(
                      featureOverlays: {
                        featureOverlay,
                      },
                      child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          child: Align(
                            alignment: alignTarget,
                            child: FeatureOverlayTarget(
                                featureId: featureId,
                                child: Icon(Icons.ac_unit)),
                          ))),
                ))));
        await tester.pumpAndSettle(Duration(milliseconds: 11));

        final foundOverlay = find.byKey(key);

        final dynamic renderObject = tester.renderObject(find.byType(
          Overlay,
        ));
        final dynamic renderObject2 = tester.renderObject(find.byKey(
          key,
        ));

        expect(featureOverlay, equals(tester.widget(foundOverlay)));
        expect(tester.getRect(foundOverlay), expectedBackgroudRect);
      });
    };
    builder(OverflowMode.clipContent, Alignment.bottomCenter,
        Rect.fromLTRB(0, 0, screenSize.width, screenSize.height));
  });
}
