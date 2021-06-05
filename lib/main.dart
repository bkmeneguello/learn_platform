import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:rxdart/rxdart.dart';

import 'math.dart' as math;
import 'config.dart';
import 'exercise.dart';

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

  late Configuration configuration;

  final debounce = BehaviorSubject<Configuration>();
  bool settingsVisible = true;

  @override
  void initState() {
    super.initState();
    configuration = Configuration(math.configs, RangeValues(1, 1), 40, 5, 2);
    debounce.debounceTime(Duration(seconds: 1)).listen((configuration) {
      setState(() {
        this.configuration = configuration;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Random rnd =
        Random(DateUtils.dateOnly(DateTime.now()).millisecondsSinceEpoch);
    final generators = configuration.selected();
    print(generators);
    Map<GlobalKey, String> exercises;
    try {
      final deduplicatedExercises = <String>[];
      generators.forEach((gen) {
        final generatorExercises = <String>[];
        final amount = configuration.exercises / generators.length;
        var retries = 0;
        while (generatorExercises.length < amount) {
          final el = gen.generator(rnd).first;
          if (deduplicatedExercises.contains(el) ||
              generatorExercises.contains(el)) {
            if (++retries < 100) continue;
          }
          retries = 0;
          generatorExercises.add(el);
        }
        generatorExercises.shuffle(rnd);
        deduplicatedExercises.addAll(generatorExercises);
      });
      exercises = deduplicatedExercises
          .asMap()
          .map((key, value) => MapEntry(GlobalKey(), value));
    } catch (e) {
      print(e);
      exercises = {};
    }
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
                      onConfigChanged: (value) => debounce.add(value),
                    ),
                  ))),
          Expanded(
            child: ExercisesView(
                exercises: exercises,
                columns: configuration.columns,
                space: configuration.space,
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
