import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_math/flutter_math.dart';
import 'package:quiver/iterables.dart';

import 'math.dart' as math;

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
    return _MyHomePageState();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  _MyHomePageState();

  Configuration configuration = Configuration(
      levels: RangeValues(1, 1), exercises: 40, columns: 5, space: 2);

  Map<GlobalKey, String> exercises = {};
  int columns = 0;
  double space = 0;
  bool settingsVisible = true;

  @override
  void initState() {
    super.initState();
    _updateConfig(configuration);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SizedBox.expand(
      child: Column(
        children: [
          Visibility(
              visible: settingsVisible,
              child: SizedBox(
                  height: 120,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ConfigurationView(
                        configuration: configuration,
                        onConfigChanged: _updateConfig),
                  ))),
          Expanded(
            child: ExercisesView(
                exercises: exercises,
                columns: columns,
                space: space,
                onToggleSettings: toggleSettings),
          ),
        ],
      ),
    ));
  }

  void toggleSettings() => {
        setState(() {
          settingsVisible ^= true;
        })
      };

  void _updateConfig(Configuration config) {
    Random rnd =
        Random(DateUtils.dateOnly(DateTime.now()).millisecondsSinceEpoch);
    final range = config.levels;
    setState(() {
      final generators = math.x
          .where((element) =>
              (element.range.start >= range.start &&
                  element.range.start <= range.end) ||
              (element.range.end <= range.end &&
                  element.range.end >= range.start))
          .toList();
      try {
        final e = [];
        generators.forEach((gen) {
          final previousLength = e.length;
          final amount = config.exercises / generators.length;
          var retries = 0;
          while (e.length < previousLength + amount) {
            final el = gen.generator(rnd).first;
            if (e.contains(el)) {
              if (++retries > 100) break;
              continue;
            }
            retries = 0;
            e.add(el);
          }
        });
        exercises = e.asMap().map((key, value) => MapEntry(GlobalKey(), value));
      } catch (e) {
        exercises = {};
      }
      columns = config.columns;
      space = config.space;
      configuration = config;
    });
  }
}

Future<WidgetWraper> resolveImage(GlobalKey key) {
  return WidgetWraper.fromKey(key: key, pixelRatio: 1)
      .catchError((_) => resolveImage(key));
}

class ExercisesView extends StatelessWidget {
  const ExercisesView({
    Key? key,
    required this.exercises,
    required this.columns,
    required this.space,
    required this.onToggleSettings,
  }) : super(key: key);

  final Map<GlobalKey<State<StatefulWidget>>, String> exercises;
  final int columns;
  final double space;
  final VoidCallback onToggleSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 0,
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: exercises.entries
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
            maxPageWidth: 800,
            build: _generatePdf,
            actions: [
              PdfPreviewAction(
                  icon: Icon(Icons.settings),
                  onPressed: (context, build, pageFormat) => onToggleSettings())
            ],
          ),
        ),
      ],
    );
  }

  FutureOr<Uint8List> _generatePdf(PdfPageFormat format) async {
    final doc = pw.Document();
    final _exercises = await Future.wait(exercises.keys.map(resolveImage));
    final pageMargin = const pw.EdgeInsets.all(1 * PdfPageFormat.cm)
        .copyWith(top: 2 * PdfPageFormat.cm);
    doc.addPage(pw.MultiPage(
        pageFormat: format,
        margin: pageMargin,
        header: (context) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10 * PdfPageFormat.mm),
            child: pw.Row(children: [
              pw.Text("Início:"),
              pw.SizedBox(width: 2 * PdfPageFormat.mm),
              pw.Text("____:____"),
              pw.SizedBox(width: 5 * PdfPageFormat.mm),
              pw.Text("Fim:"),
              pw.SizedBox(width: 2 * PdfPageFormat.mm),
              pw.Text("____:____"),
              pw.Spacer(flex: 1),
              if (context.pageNumber == 1) ...[
                pw.Text("Data:"),
                pw.SizedBox(width: 2 * PdfPageFormat.mm),
                pw.Text("____/____/________"),
              ]
            ])),
        footer: (context) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [pw.Text(context.pageNumber.toString())]),
        build: (pw.Context context) {
          return [
            pw.Wrap(
                children: List.generate(exercises.length, (index) {
              final img = _exercises[index].buildImage(context);
              return pw.LayoutBuilder(
                  builder: (context, constraints) => pw.Padding(
                      padding:
                          pw.EdgeInsets.only(bottom: space * PdfPageFormat.cm),
                      child: pw.SizedBox(
                          width: constraints!.maxWidth / columns,
                          child: pw.Column(children: [
                            pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Image(pw.ImageProxy(img),
                                      width: img.width / 1.5)
                                ])
                          ]))));
            }))
          ];
        }));
    return doc.save();
  }
}

class Configuration {
  Configuration(
      {required this.levels,
      required this.exercises,
      required this.columns,
      required this.space});
  final RangeValues levels;
  final int exercises;
  final int columns;
  final double space;

  Configuration copyWith(
          {RangeValues? levels, int? exercises, int? columns, double? space}) =>
      Configuration(
          levels: levels ?? this.levels,
          exercises: exercises ?? this.exercises,
          columns: columns ?? this.columns,
          space: space ?? this.space);
}

class ConfigurationView extends StatefulWidget {
  const ConfigurationView({
    Key? key,
    required this.configuration,
    this.onConfigChanged,
  }) : super(key: key);

  final Configuration configuration;
  final ValueChanged<Configuration>? onConfigChanged;

  @override
  _ConfigurationViewState createState() => _ConfigurationViewState();
}

class _ConfigurationViewState extends State<ConfigurationView> {
  RangeValues levels = RangeValues(0, 0);

  void _updateConfig(Configuration config) {
    ValueChanged<Configuration> callback = widget.onConfigChanged ?? (_) {};
    callback(config);
  }

  @override
  void initState() {
    super.initState();
    levels = widget.configuration.levels;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(
        children: [
          Flexible(child: Text("Quantidade:")),
          SizedBox(width: 10),
          Flexible(
            child: SpinBox(
              min: 1,
              max: 500,
              acceleration: 1,
              value: widget.configuration.exercises.toDouble(),
              onChanged: (value) => _updateConfig(
                  widget.configuration.copyWith(exercises: value.toInt())),
            ),
          ),
          SizedBox(width: 30),
          Flexible(child: Text("Colunas:")),
          SizedBox(width: 10),
          Flexible(
            child: SpinBox(
              min: 1,
              value: widget.configuration.columns.toDouble(),
              onChanged: (value) => _updateConfig(
                  widget.configuration.copyWith(columns: value.toInt())),
            ),
          ),
          SizedBox(width: 30),
          Flexible(child: Text("Espaço:")),
          SizedBox(width: 10),
          Flexible(
            child: SpinBox(
              decimals: 2,
              step: .5,
              value: widget.configuration.space,
              onChanged: (value) =>
                  _updateConfig(widget.configuration.copyWith(space: value)),
            ),
          ),
        ],
      ),
      RangeSlider(
        values: levels,
        onChanged: (value) => {
          setState(() {
            levels = value;
          })
        },
        onChangeEnd: (value) =>
            _updateConfig(widget.configuration.copyWith(levels: levels)),
        divisions: 6,
        min: 1,
        max: 4,
        labels: RangeLabels("Min", "Máx"),
      ),
    ]);
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
