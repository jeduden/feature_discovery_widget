import 'package:flutter/material.dart';

class CenterAbout extends StatelessWidget {
  final Offset? position;
  final Widget? child;

  const CenterAbout({Key? key, this.position, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) => Positioned(
        top: position!.dy,
        left: position!.dx,
        child: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: child,
        ),
      );
}
