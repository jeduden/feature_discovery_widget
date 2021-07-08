import 'package:flutter/material.dart';
import 'package:feature_discovery_widget/feature_discovery_widget.dart';

void main() {
  runApp(MyApp());
}

const IncrementFeatureId = "Increment";
const HomePortal = "HomePortal";
const providerKey = GlobalObjectKey("provider");

class MyApp extends StatelessWidget {
  final bool disableAnimations;

  MyApp({this.disableAnimations: false});

  @override
  Widget build(BuildContext context) {
    return FeatureOverlayConfigProvider(
        key:providerKey,
        child: MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FeatureTourWidget(
        child: MyHomePage(title: 'Flutter Demo Home Page'),
        featureIds: [IncrementFeatureId],
        enablePulsingAnimation: !disableAnimations,
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
    final buttonBuilder = (Key key, BuildContext context) {
      return FloatingActionButton(
          key: key,
          onPressed: _incrementCounter,
          tooltip: 'Increment',
          child: Icon(Icons.add));
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FeatureOverlayPortal(
          portalId: HomePortal,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'You have pushed the button this many times:',
                ),
                Text(
                  '$_counter',
                  style: Theme.of(context).textTheme.headline4,
                ),
              ],
            ),
          )),
      floatingActionButton: DescribedFeatureOverlay(
          portalId: HomePortal,
          featureId: IncrementFeatureId,
          child: buttonBuilder(ValueKey("child"), context),
          tapTarget:
              Icon(Icons.ac_unit) //buttonBuilder(ValueKey("tap"),context),
          ),
    );
  }
}
