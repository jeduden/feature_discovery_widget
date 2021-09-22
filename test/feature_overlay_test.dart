import 'dart:async';

import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:feature_discovery_widget/src/feature_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'widgets.dart';

abstract class CallbackFunction {
  Future<void> call();
}

class CallbackMock extends Mock implements CallbackFunction {
  @override
  Future<void> call() {
    return super.noSuchMethod(Invocation.method(#call, []),
        returnValue: Future.value());
  }
}

void main() {
  group("FeatureOverlay", () {
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

    testWidgets("Doesnt animate when enablePulsingAnimation is false",
        (WidgetTester tester) async {
      await (TestWidgetsFlutterBinding.ensureInitialized()
              as TestWidgetsFlutterBinding)
          .setSurfaceSize(const Size(3e2, 4e3));

      await tester.pumpWidget(MinimalTestWrapper(
          child: FeatureOverlayConfig(
              enablePulsingAnimation: false,
              layerLink: LooseLayerLink(),
              activeFeatureId: "myFeature",
              eventsSink: eventController.sink,
              child: FeatureOverlay(
                  featureId: "myFeature", tapTarget: Icon(Icons.ac_unit)))));

      await tester.pumpAndSettle(Duration(milliseconds: 1100));
    });

    testWidgets(
        "depending on active id in config it transitions: closed -> onOpening -> opening -> opened -> dismissing -> closed",
        (WidgetTester tester) async {
      const screenSize = const Size(3e2, 4e3);
      await (TestWidgetsFlutterBinding.ensureInitialized()
              as TestWidgetsFlutterBinding)
          .setSurfaceSize(screenSize);
      await tester.pumpWidget(MinimalTestWrapper(
          screenSize: screenSize,
          child: FeatureOverlayConfig(
              enablePulsingAnimation: false,
              layerLink: LooseLayerLink(),
              activeFeatureId: "myFeature",
              eventsSink: eventController.sink,
              openDuration: Duration(milliseconds: 2000),
              child: FeatureOverlay(
                  featureId: "myFeature", tapTarget: Icon(Icons.ac_unit)))));

      await tester.pump(Duration(milliseconds: 1100));
      expect(
          events,
          orderedEquals([
            FeatureOverlayEvent(
                state: FeatureOverlayState.onOpening,
                previousState: FeatureOverlayState.closed,
                featureId: "myFeature"),
            FeatureOverlayEvent(
                state: FeatureOverlayState.opening,
                previousState: FeatureOverlayState.onOpening,
                featureId: "myFeature")
          ]));
      events.clear();
      await tester.pump(Duration(milliseconds: 3000));
      expect(
          events,
          orderedEquals([
            FeatureOverlayEvent(
                state: FeatureOverlayState.opened,
                previousState: FeatureOverlayState.opening,
                featureId: "myFeature")
          ]));
      events.clear();
      await tester.pumpWidget(MinimalTestWrapper(
          screenSize: screenSize,
          child: FeatureOverlayConfig(
              enablePulsingAnimation: false,
              layerLink: LooseLayerLink(),
              activeFeatureId: null,
              eventsSink: eventController.sink,
              openDuration: Duration(milliseconds: 2000),
              dismissDuration: Duration(milliseconds: 2000),
              completeDuration: Duration(milliseconds: 10),
              child: FeatureOverlay(
                  featureId: "myFeature", tapTarget: Icon(Icons.ac_unit)))));
      await tester.pump(Duration(milliseconds: 1000));
      expect(
          events,
          orderedEquals([
            FeatureOverlayEvent(
                state: FeatureOverlayState.dismissing,
                previousState: FeatureOverlayState.opened,
                featureId: "myFeature")
          ]));
      events.clear();
      await tester.pump(Duration(milliseconds: 1001));
      expect(
          events,
          orderedEquals([
            FeatureOverlayEvent(
                state: FeatureOverlayState.closed,
                previousState: FeatureOverlayState.dismissing,
                featureId: "myFeature")
          ]));
    });

    testWidgets(
        "when hitting tap target that doesnt follow, sink not notified.",
        (WidgetTester tester) async {
      const screenSize = const Size(3e2, 4e3);
      await (TestWidgetsFlutterBinding.ensureInitialized()
              as TestWidgetsFlutterBinding)
          .setSurfaceSize(screenSize);

      await tester.pumpWidget(MinimalTestWrapper(
          screenSize: screenSize,
          child: FeatureOverlayConfig(
              enablePulsingAnimation: false,
              layerLink: LooseLayerLink(),
              activeFeatureId: "myFeature",
              eventsSink: eventController.sink,
              child: FeatureOverlay(
                  featureId: "myFeature", tapTarget: Icon(Icons.ac_unit)))));
      await tester.pumpAndSettle();
      events.clear();
      await tester.tap(find.byIcon(Icons.ac_unit));
      expect(
          events,
          orderedEquals([
            FeatureOverlayEvent(
                state: FeatureOverlayState.dismissing,
                previousState: FeatureOverlayState.opened,
                featureId: "myFeature")
          ]));
    });

    testWidgets("when hitting tap target: sink is notified.",
        (WidgetTester tester) async {
      const screenSize = const Size(3e2, 4e3);
      await (TestWidgetsFlutterBinding.ensureInitialized()
              as TestWidgetsFlutterBinding)
          .setSurfaceSize(screenSize);

      await tester.pumpWidget(MinimalTestWrapper(
          screenSize: screenSize,
          child: FeatureOverlayConfig(
              enablePulsingAnimation: false,
              layerLink: LooseLayerLink(),
              activeFeatureId: "myFeature",
              eventsSink: eventController.sink,
              child: Stack(children: [
                FeatureOverlay(
                    featureId: "myFeature", tapTarget: Icon(Icons.ac_unit)),
                FeatureOverlayTarget(
                    featureIds: {"myFeature"}, child: Container())
              ]))));
      await tester.pumpAndSettle();
      events.clear();
      await tester.tap(find.byIcon(Icons.ac_unit));
      expect(
          events,
          orderedEquals([
            FeatureOverlayEvent(
                state: FeatureOverlayState.completing,
                previousState: FeatureOverlayState.opened,
                featureId: "myFeature")
          ]));
    });

    testWidgets(
        "during transitions it calls callbacks: closed -> [onOpening] -> opening -> opened -> completing -> [onCompleted] -> closed",
        (WidgetTester tester) async {
      const screenSize = const Size(3e2, 4e3);
      await (TestWidgetsFlutterBinding.ensureInitialized()
              as TestWidgetsFlutterBinding)
          .setSurfaceSize(screenSize);

      final mockCompleted = CallbackMock();
      when(mockCompleted.call())
          .thenAnswer((realInvocation) => Future.delayed(Duration(seconds: 3)));
      final mockOpening = CallbackMock();
      when(mockOpening.call())
          .thenAnswer((realInvocation) => Future.delayed(Duration(seconds: 3)));

      await tester.pumpWidget(MinimalTestWrapper(
          screenSize: screenSize,
          child: FeatureOverlayConfig(
              enablePulsingAnimation: false,
              layerLink: LooseLayerLink(),
              activeFeatureId: "myFeature",
              eventsSink: eventController.sink,
              openDuration: Duration(milliseconds: 2000),
              completeDuration: Duration(milliseconds: 2000),
              child: Stack(
                children: [
                  FeatureOverlayTarget(
                    child: Container(),
                    featureIds: {"myFeature"},
                  ),
                  FeatureOverlay(
                    featureId: "myFeature",
                    tapTarget: Icon(Icons.ac_unit),
                    onCompleted: mockCompleted,
                    onOpening: mockOpening,
                  )
                ],
              ))));

      await tester.pump(Duration(milliseconds: 100));
      verify(mockOpening.call());
      verifyNever(mockCompleted.call());
      clearInteractions(mockOpening);
      expect(
          events,
          orderedEquals([
            FeatureOverlayEvent(
                state: FeatureOverlayState.onOpening,
                previousState: FeatureOverlayState.closed,
                featureId: "myFeature"),
          ]),
          reason: "Because onOpening is delaying opening transition");
      events.clear();
      await tester.pump(Duration(milliseconds: 1000));
      expect(events, orderedEquals([]),
          reason: "waiting for onOpening to finish");
      events.clear();
      await tester.pump(Duration(milliseconds: 2101));
      expect(
          events,
          orderedEquals([
            FeatureOverlayEvent(
                state: FeatureOverlayState.opening,
                previousState: FeatureOverlayState.onOpening,
                featureId: "myFeature"),
          ]));
      events.clear();
      await tester.pump(Duration(milliseconds: 2001));
      expect(
          events,
          orderedEquals([
            FeatureOverlayEvent(
                state: FeatureOverlayState.opened,
                previousState: FeatureOverlayState.opening,
                featureId: "myFeature")
          ]));
      events.clear();
      await tester.tap(find.byIcon(Icons.ac_unit));
      await tester.pump(Duration(milliseconds: 1001));
      expect(
          events,
          orderedEquals([
            FeatureOverlayEvent(
                state: FeatureOverlayState.completing,
                previousState: FeatureOverlayState.opened,
                featureId: "myFeature")
          ]),
          reason:
              "we find only completing. onCompleted is delaying the transition to closed state");
      events.clear();
      verifyNever(mockCompleted.call());
      verifyNever(mockOpening.call());
      await tester.pump(Duration(milliseconds: 2001));
      verify(mockCompleted.call());
      verifyNever(mockOpening.call());
      expect(
          events,
          orderedEquals([
            FeatureOverlayEvent(
                state: FeatureOverlayState.onCompleted,
                previousState: FeatureOverlayState.completing,
                featureId: "myFeature")
          ]));
      events.clear();
      await tester.pump(Duration(milliseconds: 1001));
      expect(events, orderedEquals([]),
          reason: "waiting for onCompleted to finish");
      await tester.pump(Duration(milliseconds: 2001));
      expect(
          events,
          orderedEquals([
            FeatureOverlayEvent(
                state: FeatureOverlayState.closed,
                previousState: FeatureOverlayState.onCompleted,
                featureId: "myFeature")
          ]));
    });

    const screenSize = const Size(3e2, 4e3);
    final testCompleteDuring = (
        {required Duration waitBeforeFirstTap,
        Duration? waitBeforeSecondTap,
        Future<void> Function()? tap,
        Future<void> Function()? firstTap,
        Future<void> Function()? secondTap,
        required WidgetTester tester,
        bool? dismissable,
        state,
        previousState}) async {
      final overlayStateKey = GlobalKey<FeatureOverlayWidgetState>();

      await (TestWidgetsFlutterBinding.ensureInitialized()
              as TestWidgetsFlutterBinding)
          .setSurfaceSize(screenSize);

      final mockCompleted = CallbackMock();
      when(mockCompleted.call())
          .thenAnswer((realInvocation) => Future.delayed(Duration(seconds: 3)));
      final mockOpening = CallbackMock();
      when(mockOpening.call())
          .thenAnswer((realInvocation) => Future.delayed(Duration(seconds: 3)));

      await tester.pumpWidget(MinimalTestWrapper(
          screenSize: screenSize,
          child: FeatureOverlayConfig(
              enablePulsingAnimation: false,
              layerLink: LooseLayerLink(),
              activeFeatureId: "myFeature",
              eventsSink: eventController.sink,
              openDuration: Duration(milliseconds: 2000),
              completeDuration: Duration(milliseconds: 2000),
              child: Stack(
                children: [
                  FeatureOverlayTarget(
                    child: Container(),
                    featureIds: {"myFeature"},
                  ),
                  FeatureOverlay(
                    dismissible: dismissable,
                    key: overlayStateKey,
                    featureId: "myFeature",
                    tapTarget: Icon(Icons.ac_unit),
                    title: Text("Title"),
                    onCompleted: () =>
                        Future.delayed(Duration(milliseconds: 2000)),
                    onOpening: () =>
                        Future.delayed(Duration(milliseconds: 2000)),
                  )
                ],
              ))));

      await tester.pumpAndSettle(
          waitBeforeFirstTap); // call pumpAndSettle instead of pump to trigger animation controller. the animation controller's tick is only called once per pump?
      print("First tapping $tap");
      await (firstTap ?? tap!)();
      if (waitBeforeSecondTap != null) {
        await tester.pumpAndSettle(waitBeforeSecondTap);
        await tester.pumpAndSettle(Duration(milliseconds: 1));
        print("Second tapping $tap");
        await (secondTap ?? tap!)();
      }
      await tester.pumpAndSettle(Duration(milliseconds: 20000));
      await tester.pumpAndSettle(Duration(
          milliseconds: 20000)); //we need to call this multiple times....
      expect(
          events,
          contains(
            FeatureOverlayEvent(
                state: state,
                previousState: previousState,
                featureId: "myFeature"),
          ));
      return events;
    };

    final Future<void> Function() Function(WidgetTester tester)
        tapTopRightCornerWithTester =
        (tester) => () => tester.tapAt(screenSize.topRight(Offset(-20, 20)));
    final Future<void> Function() Function(WidgetTester tester)
        tapTargetWithTester = (tester) =>
            () => tester.tap(find.byIcon(Icons.ac_unit, skipOffstage: false));

    testWidgets("tap on icon during onOpening should not do anything",
        (WidgetTester tester) async {
      await testCompleteDuring(
          waitBeforeFirstTap: Duration(milliseconds: 1000),
          tester: tester,
          tap: tapTargetWithTester(tester),
          previousState: FeatureOverlayState.opening,
          state: FeatureOverlayState.opened);
    });

    testWidgets(
        "tap on icon complete during opening should not dismiss but complete. ",
        (WidgetTester tester) async {
      await testCompleteDuring(
          waitBeforeFirstTap: Duration(milliseconds: 3000),
          tester: tester,
          tap: tapTargetWithTester(tester),
          previousState: FeatureOverlayState.onCompleted,
          state: FeatureOverlayState.closed);
    },
        skip:
            true); // this test doesnt work. the feature advances to onCompleted state before tap can be executed.
    testWidgets("tap on icon should not do anything during completing",
        (WidgetTester tester) async {
      await testCompleteDuring(
          waitBeforeFirstTap: Duration(milliseconds: 5000),
          waitBeforeSecondTap: Duration(milliseconds: 10),
          tester: tester,
          tap: tapTargetWithTester(tester),
          previousState: FeatureOverlayState.onCompleted,
          state: FeatureOverlayState.closed);
    });
    testWidgets("dismissing should not do anything during completing",
        (WidgetTester tester) async {
      await testCompleteDuring(
          waitBeforeFirstTap: Duration(milliseconds: 5000),
          waitBeforeSecondTap: Duration(milliseconds: 1000),
          tester: tester,
          firstTap: tapTargetWithTester(tester),
          secondTap: tapTopRightCornerWithTester(tester),
          previousState: FeatureOverlayState.onCompleted,
          state: FeatureOverlayState.closed);
    });
    testWidgets("tap on icon  should not do work during onCompleted",
        (WidgetTester tester) async {
      await testCompleteDuring(
          waitBeforeFirstTap: Duration(milliseconds: 5000),
          waitBeforeSecondTap: Duration(milliseconds: 3000),
          tester: tester,
          tap: tapTargetWithTester(tester),
          previousState: FeatureOverlayState.onCompleted,
          state: FeatureOverlayState.closed);
    });
    testWidgets("dismissing during onCompleted should not do work",
        (WidgetTester tester) async {
      await testCompleteDuring(
          waitBeforeFirstTap: Duration(milliseconds: 5000),
          waitBeforeSecondTap: Duration(milliseconds: 3000),
          tester: tester,
          firstTap: tapTargetWithTester(tester),
          secondTap: tapTopRightCornerWithTester(tester),
          previousState: FeatureOverlayState.onCompleted,
          state: FeatureOverlayState.closed);
    });
    testWidgets("dismissing during onOpening SHOUD NOT work",
        (WidgetTester tester) async {
      await testCompleteDuring(
          waitBeforeFirstTap: Duration(milliseconds: 1000),
          tester: tester,
          tap: tapTopRightCornerWithTester(tester),
          previousState: FeatureOverlayState.opening,
          state: FeatureOverlayState.opened);
    });
    testWidgets("dismissing during opening SHOUD work",
        (WidgetTester tester) async {
      await testCompleteDuring(
          waitBeforeFirstTap: Duration(milliseconds: 3000),
          tester: tester,
          tap: tapTopRightCornerWithTester(tester),
          previousState: FeatureOverlayState.dismissing,
          state: FeatureOverlayState.closed);
    });
    testWidgets("dismissing afer opening SHOUD work",
        (WidgetTester tester) async {
      await testCompleteDuring(
          waitBeforeFirstTap: Duration(milliseconds: 5000),
          tester: tester,
          tap: tapTopRightCornerWithTester(tester),
          previousState: FeatureOverlayState.dismissing,
          state: FeatureOverlayState.closed);
    });

    testWidgets(
        "dismissing afer opening SHOUD NOT work if dissmissable is false",
        (WidgetTester tester) async {
      final events = await testCompleteDuring(
          waitBeforeFirstTap: Duration(milliseconds: 5000),
          tester: tester,
          dismissable: false,
          tap: tapTopRightCornerWithTester(tester),
          previousState: FeatureOverlayState.opening,
          state: FeatureOverlayState.opened);
      expect(
          events,
          isNot(contains(
            FeatureOverlayEvent(
                state: FeatureOverlayState.closed,
                previousState: FeatureOverlayState.dismissing,
                featureId: "myFeature"),
          )));
    });
    testWidgets("dismissing during dismissing should not do anything else",
        (WidgetTester tester) async {
      await testCompleteDuring(
          waitBeforeFirstTap: Duration(milliseconds: 3000),
          waitBeforeSecondTap: Duration(milliseconds: 1000),
          tester: tester,
          tap: tapTopRightCornerWithTester(tester),
          previousState: FeatureOverlayState.dismissing,
          state: FeatureOverlayState.closed);
    });
  });
}
