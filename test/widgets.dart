import 'package:flutter/material.dart';


class MinimalTestWrapper extends StatelessWidget {

  final Size screenSize;
  final Widget child;

  MinimalTestWrapper({Key? key, 
    this.screenSize = Size.zero,
    required this.child}) : super(key: key);

  @override
  Widget build(_) {
    return MediaQuery(
            data: new MediaQueryData(size: screenSize),
            child: Directionality(
                textDirection: TextDirection.ltr,
                child: child));
  }
}