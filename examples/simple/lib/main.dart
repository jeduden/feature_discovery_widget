import 'dart:async';

import 'package:flutter/material.dart';
import 'package:feature_discovery_widget/feature_discovery_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // https://github.com/flutter/flutter/issues/80956#issuecomment-828833524
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

const keyId = "completedFeatures";

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
          home: Builder(
              builder: (context) => FeatureTour(
                    loadCompletedFeatures: () async {
                      print("Persist: Loading");
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      final set = prefs.getStringList(keyId)?.toSet() ?? {};
                      print("Persist: Loaded: $set");
                      return set;
                    },
                    storeCompletedFeatures: (completedFeatureIds) async {
                      print("Persist: Storing $completedFeatureIds");
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      await prefs.setStringList(
                          keyId, completedFeatureIds?.toList() ?? []);
                    },
                    onDismissFeature: (state, featureId) {
                      WidgetsBinding.instance!.addPostFrameCallback((_) {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Abort Tutorial?'),
                                actions: [
                                  TextButton(
                                      onPressed: () async {
                                        await state.abortTour();
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('Yes')),
                                  TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        // dont do anything to show the overlay again
                                      },
                                      child: Text(
                                          'No, continue with tutorial next time'))
                                ],
                              );
                            });
                      });
                    },
                    // we need a context that has the material app in the tree
                    // hence we cant take directly the context from MyApp.build
                    // we don't need to store persistent in a state
                    // since all stateful information is passed into the
                    // methods.
                    child:
                        MyHomePage(title: 'Simple Feature Discovery Example'),
                    featureIds: [IncrementFeatureId, IncrementFeatureId, CounterFeatureId],
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
                "The appearance of this overlay was delayed by 2 seconds in onOpening.\n"
                "After the completion of this step, a delay of 3 seconds was configured in onCompleted.\n"
                "Tapping it increases the counter. Very Very Very Long Line \nTry to tap"),
            contentLocation: ContentLocation.above,
            overflowMode: OverflowMode.extendBackground,
            tapTarget: Icon(Icons.add),
            onOpening: () {
              // delay appearance of this feature by 2 second
              return Future.delayed(Duration(seconds: 2));
            },
            onCompleted: () {
              // delay appearance of the next feature by 2 second
              return Future.delayed(Duration(seconds: 3));
            },
          ),
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
                    tapTarget: Icon(Icons.access_alarm),
                  ),
                },
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'You have pushed the button this many times:',
                      ),
                      FeatureOverlayTarget(
                          featureIds: {CounterFeatureId},
                          child: Text(
                            '$_counter',
                            style: Theme.of(context).textTheme.headline4,
                          )),
                      TextButton(
                          onPressed: () async {
                            final featureTourState = FeatureTour.of(context);
                            await featureTourState.resetTour();
                          },
                          child: Text("Restart tutorial"))
                    ],
                  ),
                )),
            floatingActionButton: FeatureOverlayTarget(
                featureIds: {IncrementFeatureId},
                child: FloatingActionButton(
                    onPressed: _incrementCounter,
                    tooltip: 'Increment',
                    child: Icon(Icons.add)))));
  }
}
