import 'package:flutter/material.dart';
import 'package:flutter_spinbox/material.dart';

import 'math.dart';

class SelectExerciseConfig {
  SelectExerciseConfig(this.selected, this.config);
  final bool selected;
  final ExerciseConfig config;

  SelectExerciseConfig copyWith({bool? selected}) {
    return SelectExerciseConfig(selected ?? this.selected, this.config);
  }

  @override
  String toString() {
    return '[$selected] ${config.label}';
  }
}

class Configuration {
  Configuration(List<ExerciseConfig> configs, this.levels, this.exercises,
      this.columns, this.space)
      : this.configs = configs
            .map((e) => SelectExerciseConfig(inRange(e.range, levels), e))
            .toList();
  final List<SelectExerciseConfig> configs;
  final RangeValues levels;
  final int exercises;
  final int columns;
  final double space;

  Configuration._(
      this.configs, this.levels, this.exercises, this.columns, this.space);

  Configuration copyWith(
      {List<SelectExerciseConfig>? configs,
      RangeValues? levels,
      int? exercises,
      int? columns,
      double? space}) {
    return Configuration._(
        configs ?? this.configs,
        levels ?? this.levels,
        exercises ?? this.exercises,
        columns ?? this.columns,
        space ?? this.space);
  }

  List<ExerciseConfig> selected() {
    return configs.where((e) => e.selected).map((e) => e.config).toList();
  }
}

class ConfigurationView extends StatefulWidget {
  static void _noop(_) {}
  ConfigurationView({
    Key? key,
    required this.configuration,
    this.onConfigChanged = _noop,
  }) : super(key: key);

  final Configuration configuration;
  final ValueChanged<Configuration> onConfigChanged;

  @override
  _ConfigurationViewState createState() => _ConfigurationViewState();
}

class _ConfigurationViewState extends State<ConfigurationView> {
  late RangeValues levels;

  @override
  void initState() {
    super.initState();
    levels = widget.configuration.levels;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(children: [
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
                    onChanged: (value) => widget.onConfigChanged(widget
                        .configuration
                        .copyWith(exercises: value.toInt())),
                  ),
                ),
                SizedBox(width: 30),
                Flexible(child: Text("Colunas:")),
                SizedBox(width: 10),
                Flexible(
                  child: SpinBox(
                    min: 1,
                    value: widget.configuration.columns.toDouble(),
                    onChanged: (value) => widget.onConfigChanged(
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
                    onChanged: (value) => widget.onConfigChanged(
                        widget.configuration.copyWith(space: value)),
                  ),
                ),
              ],
            ),
            RangeSlider(
              values: levels,
              onChanged: (value) {
                setState(() {
                  levels = value;
                });
                widget.onConfigChanged(widget.configuration.copyWith(
                    configs: widget.configuration.configs
                        .map((e) => e.copyWith(
                            selected: inRange(e.config.range, value)))
                        .toList(),
                    levels: value));
              },
              //divisions: 6,
              min: 1,
              max: 4,
              labels: RangeLabels("Min: ${levels.start}", "Máx: ${levels.end}"),
            ),
          ]),
        ),
        SizedBox(
            width: 400,
            child: ListView.builder(
              itemCount: widget.configuration.configs.length,
              itemBuilder: (context, index) {
                return CheckboxListTile(
                  title: Text(widget.configuration.configs[index].config.label),
                  value: widget.configuration.configs[index].selected,
                  onChanged: (value) {
                    final selections = widget.configuration.configs;
                    selections.insert(index,
                        selections.removeAt(index).copyWith(selected: value));
                    widget.onConfigChanged(
                        widget.configuration.copyWith(configs: selections));
                  },
                );
              },
            ))
      ],
    );
  }
}

bool inRange(RangeValues a, RangeValues b) {
  return (a.start >= b.start && a.start <= b.end) ||
      (a.end <= b.end && a.end >= b.start);
}

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: ConfigurationView(
          configuration: Configuration(configs, RangeValues(1, 1), 10, 2, 1)),
    ),
  ));
}
