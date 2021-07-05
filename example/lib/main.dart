import 'package:flutter/material.dart';
import 'package:feature_discovery_widget/feature_discovery_widget.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final bool disableAnimations;

  MyApp({
    this.disableAnimations: false
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page', disableAnimations:disableAnimations),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final bool disableAnimations;
  MyHomePage({Key? key, required this.title, required this.disableAnimations}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState(disableAnimations:disableAnimations);
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  final bool disableAnimations;

  _MyHomePageState({required this.disableAnimations});

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final buttonBuilder = (Key key,BuildContext context) {
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
      body: Center(
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
      ),
      floatingActionButton: DescribedFeatureOverlay(
        featureId: "Increment",
        child: buttonBuilder(ValueKey("child"),context),
        tapTarget: Icon(Icons.ac_unit) //buttonBuilder(ValueKey("tap"),context),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
