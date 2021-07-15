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
  group('Content placement snapshot test', () {
    const screenSize = Size(3e2, 4e3);
    const titleHeight = 100.0;
    const descriptionHeight = 21.0;
    const tapTargetIconHeight = 33.0;
    final builder =
        (String expected, OverflowMode mode, ContentLocation contentLocation, Alignment alignTarget, Rect expectedContentRect) {
      
      testWidgets("$mode - $contentLocation - $alignTarget $expected", (WidgetTester tester) async {
        await (TestWidgetsFlutterBinding.ensureInitialized()
                as TestWidgetsFlutterBinding)
            .setSurfaceSize(screenSize);

        final featureId = "myFeature";
        final key = GlobalKey();
        final featureOverlay = FeatureOverlay(
          key: key,
          featureId: featureId,
          overflowMode: mode,
          contentLocation: contentLocation,
          title: SizedBox(width: 100,height: titleHeight,),
          description: SizedBox(width: 100,height: descriptionHeight,),
          tapTarget: Icon(Icons.ac_unit_sharp,size:tapTargetIconHeight),
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

        final actual = tester.getRect(find.byType(Content));
        expect(actual.left, closeTo(expectedContentRect.left,0.1), reason:"left");
        expect(actual.right, closeTo(expectedContentRect.right,0.1), reason: "right");
        expect(actual.bottom, closeTo(expectedContentRect.bottom,0.1), reason: "bottom");
        expect(actual.top, closeTo(expectedContentRect.top,0.1), reason: "top");
      });
    };
    builder("", OverflowMode.clipContent, ContentLocation.below, Alignment.topCenter,
        
        Rect.fromLTRB(0, 76, 180, 205));
    builder("", OverflowMode.clipContent, ContentLocation.below, Alignment.topLeft,
        
        Rect.fromLTRB(0, 76.0, 180, 205));
    builder("", OverflowMode.clipContent, ContentLocation.below, Alignment.topRight,
        
        Rect.fromLTRB(0, 76, 180, 205));
    builder("", OverflowMode.clipContent, ContentLocation.above, Alignment.bottomCenter,
        
        Rect.fromLTRB(0, 3795, 180, 3924));
    builder("", OverflowMode.clipContent, ContentLocation.above, Alignment.bottomLeft,
        
        Rect.fromLTRB(0, 3795, 180, 3924));
    builder("", OverflowMode.clipContent, ContentLocation.above, Alignment.bottomRight,
        
        Rect.fromLTRB(0, 3795, 180, 3924));

    builder("", OverflowMode.clipContent, ContentLocation.above, Alignment.center,
        
        Rect.fromLTRB(0, 1807, 180, 1936));
    builder("", OverflowMode.clipContent, ContentLocation.above, Alignment.centerLeft,
        
        Rect.fromLTRB(0, 1807, 180, 1936));
    builder("", OverflowMode.clipContent, ContentLocation.above, Alignment.centerRight,
        
        Rect.fromLTRB(0, 1807, 180, 1936));

    builder("", OverflowMode.clipContent, ContentLocation.below, Alignment.center,
        
        Rect.fromLTRB(0, 2064, 180, 2193));
    builder("", OverflowMode.clipContent, ContentLocation.below, Alignment.centerLeft,
        
        Rect.fromLTRB(0, 2064, 180, 2193));
    builder("", OverflowMode.clipContent, ContentLocation.below, Alignment.centerRight,
        
        Rect.fromLTRB(0, 2064, 180, 2193));
  });
}
