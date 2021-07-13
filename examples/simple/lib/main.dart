import 'package:flutter/material.dart';
import 'package:feature_discovery_widget/feature_discovery_widget.dart';

void main() {
  runApp(MyApp());
}

const IncrementFeatureId = "Increment";
const CounterFeatureId = "Counter";
const HomePortal = "HomePortal";
const providerKey = GlobalObjectKey("provider");

class MyApp extends StatelessWidget {
  final bool disableAnimations;

  MyApp({this.disableAnimations: false});

  @override
  Widget build(BuildContext context) {
    return FeatureOverlayConfigProvider(
        key: providerKey,
        enablePulsingAnimation: !disableAnimations,
        child: MaterialApp(
          title: 'Simple Feature Discovery',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: FeatureTourWidget(
            child: MyHomePage(title: 'Simple Feature Discovery Example'),
            featureIds: [IncrementFeatureId, CounterFeatureId],
          ),
        ));
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IndexedFeatureOverlay(
        featureOverlays: {
          FeatureOverlay(
              featureId: IncrementFeatureId,
              title: Text("Increment counter! With a very long title !"),
              description: Text("Tapping it increases the counter. Very Very Very Long Line \nTry to tap"),
              contentLocation: ContentLocation.above,
              overflowMode: OverflowMode.extendBackground,
              tapTarget: Icon(Icons.add)),
        },
        child: Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
            ),
            body: IndexedFeatureOverlay(
                featureOverlays: {
                  FeatureOverlay(
                      featureId: CounterFeatureId,
                      title: Text("This is the counter. Longer Line ! Longer and Longer"),
                      description: Text("It increases indefinetly.\nIt starts at 0."),
                      contentLocation: ContentLocation.below,
                      tapTarget: Icon(Icons.access_alarm))
                },
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'You have pushed the button this many times:',
                      ),
                      FeatureOverlayTarget(
                          featureId: CounterFeatureId,
                          child: Text(
                            '$_counter',
                            style: Theme.of(context).textTheme.headline4,
                          )),
                    ],
                  ),
                )),
            floatingActionButton: FeatureOverlayTarget(
                featureId: IncrementFeatureId,
                child: FloatingActionButton(
                    onPressed: _incrementCounter,
                    tooltip: 'Increment',
                    child: Icon(Icons.add)))));
  }
}
