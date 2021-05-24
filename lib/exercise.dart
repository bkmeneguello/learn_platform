import 'package:flutter/material.dart';
import 'package:flutter_math/flutter_math.dart';

class Exercise extends StatefulWidget {
  Exercise({Key? key, required this.expression}) : super(key: key);

  final String expression;

  @override
  State<StatefulWidget> createState() {
    return _ExerciseState();
  }
}

class _ExerciseState extends State<Exercise> {
  final _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _key,
      child: Container(
        margin: EdgeInsets.only(top: 1, bottom: 1),
        child: Math.tex(
          widget.expression,
          mathStyle: MathStyle.display,
          textScaleFactor: 1.2,
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: Exercise(expression: "1 + 2 ="),
    ),
  ));
}
