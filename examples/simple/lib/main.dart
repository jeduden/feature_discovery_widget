import 'package:flutter/material.dart';
import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // https://github.com/flutter/flutter/issues/80956#issuecomment-828833524
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

const IncrementFeatureId = "Increment";
const CounterFeatureId = "Counter";
const HomePortal = "HomePortal";
const providerKey = GlobalObjectKey("provider");

class FeatureTourPersistenceWithSharedPreferences
    implements FeatureTourPersistence {
  static const keyId = "completedFeatures";

  final BuildContext context;

  FeatureTourPersistenceWithSharedPreferences(this.context);

  @override
  Future<Set<String>> completedFeatures(List<String> featureIds) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(keyId) ?? []).toSet();
  }

  @override
  Future<void> completeFeature(String featureId,List<String> featureIds) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final newCompletedSet = (await completedFeatures(featureIds))..add(featureId);
    await prefs.setStringList(keyId, newCompletedSet.toList());
  }

  @override
  Future<void> dismissFeature(String featureId,List<String> featureIds) async {
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      showDialog(
          context: context,
          builder: (BuildContext ctx) {
            return AlertDialog(
              title: Text('Abort Tutorial?'),
              actions: [
                TextButton(
                    onPressed: () async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      prefs.setStringList(keyId, featureIds);
                      Navigator.of(context).pop();
                    },
                    child: Text('Yes')),
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // dont do anything to show the overlay again
                    },
                    child: Text('No, show me the info'))
              ],
            );
          });
    });
  }

  static Future<void> clearCompletions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(keyId);
  }
}

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
          home: Builder(builder:(context) => FeatureTour(
            // we need a context that has the material app in the tree
            // hence we cant take directly the context from MyApp.build
            // we don't need to store persistent in a state
            // since all stateful information is passed into the 
            // methods.
            persistence: FeatureTourPersistenceWithSharedPreferences(context),
            child: MyHomePage(title: 'Simple Feature Discovery Example'),
            featureIds: [IncrementFeatureId, CounterFeatureId],
          )),
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
    showDialog(
          context: context,
          builder: (BuildContext ctx) {
            return AlertDialog(
              title: Text('Abort Tutorial?'),
              actions: [
                TextButton(
                    onPressed: () async {
                      
                    },
                    child: Text('Yes')),
                TextButton(
                    onPressed: () {
                      // dont do anything to show the overlay again
                    },
                    child: Text('No, show me the info'))
              ],
            );
          });
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
              description: Text(
                  "Tapping it increases the counter. Very Very Very Long Line \nTry to tap"),
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
                      title: Text(
                          "This is the counter. Longer Line ! Longer and Longer"),
                      description:
                          Text("It increases indefinetly.\nIt starts at 0."),
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
                      TextButton(onPressed: () async {
                        await FeatureTourPersistenceWithSharedPreferences.clearCompletions();
                        FeatureOverlayConfigProvider.notifierOf(context).notifyActiveFeature(null);
                      }, child: Text("Restart tutorial"))
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
