import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_math/flutter_math.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  //r'\hphantom{0}'
  @override
  State<StatefulWidget> createState() {
    final rnd = Random();
    final exercises = () sync* {
      while (true) {
        final a = rnd.nextInt(998) + 1;
        final b = rnd.nextInt(98) + 1;
        yield '$a \\times $b =';
      }
    }()
        .take(40)
        .toList()
        .asMap()
        .map((key, value) => MapEntry(GlobalKey(), value));
    return _MyHomePageState(exercises);
  }
}

class _MyHomePageState extends State<MyHomePage> {
  _MyHomePageState(this._exercises);

  Map<GlobalKey, String> _exercises;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SizedBox.expand(
      child: Row(
        children: [
          SizedBox(
            width: 0,
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: _exercises.entries
                      .map((e) => Row(
                            children: [
                              Exercise(key: e.key, expression: e.value),
                            ],
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
          Expanded(
            child: PdfPreview(
              build: _generatePdf,
            ),
          ),
        ],
      ),
    ));
  }

  FutureOr<Uint8List> _generatePdf(PdfPageFormat format) async {
    final doc = pw.Document();
    final x = await Future.wait(_exercises.keys
        .map((e) => WidgetWraper.fromKey(key: e, pixelRatio: 1)));
    final pageMargin = const pw.EdgeInsets.all(1 * PdfPageFormat.cm)
        .copyWith(top: 2 * PdfPageFormat.cm);
    doc.addPage(pw.MultiPage(
        pageFormat: format,
        margin: pageMargin,
        build: (pw.Context context) {
          return [
            pw.Wrap(
                children: List.generate(x.length, (index) {
              final img = x[index].buildImage(context);
              return pw.SizedBox(
                  width: (format.width - pageMargin.horizontal) / 4,
                  height: 2.6 * PdfPageFormat.cm,
                  child: pw.Column(children: [
                    pw.Row(children: [
                      pw.Image(pw.ImageProxy(img), width: img.width / 2)
                    ])
                  ]));
            }))
          ];
        }));
    return doc.save();
  }
}

pw.Widget table(x) {
  return pw.Table(
      columnWidths: {0: pw.IntrinsicColumnWidth(), 1: pw.FlexColumnWidth()},
      children: x
          .asMap()
          .entries
          .map((e) => pw.TableRow(children: [
                pw.Padding(
                    padding: pw.EdgeInsets.only(right: 1 * PdfPageFormat.mm),
                    child: pw.Text("${e.key + 1})",
                        style: pw.TextStyle(fontSize: 6))),
                pw.Padding(
                    padding: pw.EdgeInsets.only(top: 0, bottom: 0),
                    child: pw.Image(e.value))
              ]))
          .toList());
}

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
