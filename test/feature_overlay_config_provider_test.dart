import 'dart:async';

import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:feature_discovery_widget/src/feature_overlay_config_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'widgets.dart';

class DummyWidget extends StatefulWidget {
  final void Function() onDepsChanged;
  DummyWidget({required Key? key, required this.onDepsChanged})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return DummyState();
  }
}

class DummyState extends State<DummyWidget> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.onDepsChanged();
  }

  @override
  Widget build(BuildContext context) {
    final config = FeatureOverlayConfig.of(context);
    return Text("Config's sink: $config");
  }
}

void main() {
  group("FeatureOverlayConfigProvider", () {
    testWidgets("does not retrigger builds when nothing changes in the config",
        (WidgetTester tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();

      final dummyKey = GlobalKey<DummyState>();
      int onDepsCalls = 0;
      final onDepsChanged = () {
        onDepsCalls++;
      };

      await tester.pumpWidget(MinimalTestWrapper(
          child: Scaffold(
              body: FeatureOverlayConfigProvider(
                  enablePulsingAnimation: false,
                  openDuration: Duration(milliseconds: 0),
                  dismissDuration: Duration(milliseconds: 0),
                  child: DummyWidget(
                    key: dummyKey,
                    onDepsChanged: onDepsChanged,
                  )))));
      final text = find
          .descendant(of: find.byType(DummyWidget), matching: find.byType(Text))
          .evaluate()
          .single
          .widget as Text;
      expect(onDepsCalls, equals(1));
      await tester.pumpWidget(MinimalTestWrapper(
          child: Scaffold(
              body: FeatureOverlayConfigProvider(
                  enablePulsingAnimation: false,
                  openDuration: Duration(milliseconds: 0),
                  dismissDuration: Duration(milliseconds: 0),
                  child: DummyWidget(
                      key: dummyKey, onDepsChanged: onDepsChanged)))));
      expect(onDepsCalls, equals(1),
          reason: "Should still have a single deps call for the state");
    });

    testWidgets("calls onInitState", (WidgetTester tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();

      var initStateCalled = 0;

      await tester.pumpWidget(MinimalTestWrapper(
          child: Scaffold(
              body: FeatureOverlayConfigProvider(
                  onInitState: (FeatureOverlayConfigProviderState _) =>
                      {initStateCalled = initStateCalled + 1},
                  enablePulsingAnimation: false,
                  openDuration: Duration(milliseconds: 0),
                  dismissDuration: Duration(milliseconds: 0),
                  child: Container()))));
      expect(initStateCalled, equals(1));
      await tester.pumpWidget(MinimalTestWrapper(
          child: Scaffold(
              body: FeatureOverlayConfigProvider(
                  onInitState: (FeatureOverlayConfigProviderState _) =>
                      {initStateCalled = initStateCalled + 1},
                  enablePulsingAnimation: false,
                  openDuration: Duration(milliseconds: 0),
                  dismissDuration: Duration(milliseconds: 0),
                  child: Container()))));
      expect(initStateCalled, equals(1),
          reason: "Only be called initially the state initialization");
    });
  });
}
