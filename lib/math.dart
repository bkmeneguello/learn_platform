import 'dart:math';

import 'package:flutter/material.dart';

Iterable<T> _gen<T>(T Function() g) sync* {
  while (true) yield g();
}

class NumberConstraint {
  NumberConstraint({max, min, maxDigits, minDigits, zeroPadded = false})
      : this._max = max,
        this._min = min,
        this._maxDigits = maxDigits,
        this._minDigits = minDigits,
        this._zeroPadded = zeroPadded;

  final num? _max;
  final num? _min;
  final int? _maxDigits;
  final int? _minDigits;
  final bool _zeroPadded;

  static NumberConstraint from(NumberConstraint? original) {
    return original ?? NumberConstraint();
  }

  NumberConstraint copyWith(
      {num? max, num? min, int? maxDigits, int? minDigits, bool? zeroPadded}) {
    return NumberConstraint(
      max: max ?? this._max,
      min: min ?? this._min,
      maxDigits: maxDigits ?? this._maxDigits,
      minDigits: minDigits ?? this._minDigits,
      zeroPadded: zeroPadded ?? this._zeroPadded,
    );
  }

  factory NumberConstraint.between({num? min, num? max}) =>
      NumberConstraint(min: min, max: max);

  factory NumberConstraint.natural({num? max}) =>
      NumberConstraint.between(min: 0, max: max);

  int get _maxInt {
    return _max?.toInt() ?? (1 >> 32);
  }

  int get _minInt {
    return _min?.toInt() ?? (1 << 31);
  }

  int randInt(Random rnd) {
    return _gen(() => rnd.nextInt(_maxInt - _minInt) + _minInt)
        .where((n) => _minDigits == null || n.toString().length >= _minDigits!)
        .where((n) => _maxDigits == null || n.toString().length <= _maxDigits!)
        .first;
  }
}

const _space = r'\hphantom{0}';

Iterable<String> multInline(Random rnd,
    {NumberConstraint? multiplicand,
    NumberConstraint? multiplier,
    bool Function(Random rnd, num multiplicand, num multiplier)?
        filter}) sync* {
  yield* _gen(() {
    while (true) {
      final a = NumberConstraint.from(multiplicand).randInt(rnd);
      final b = NumberConstraint.from(multiplier).randInt(rnd);
      if (filter == null || filter(rnd, a, b)) return '$a \\times $b =';
    }
  });
}

Iterable<String> multVert(Random rnd,
    {NumberConstraint? multiplicand,
    NumberConstraint? multiplier,
    bool Function(Random rnd, num multiplicand, num multiplier)?
        filter}) sync* {
  yield* _gen(() {
    while (true) {
      final a = NumberConstraint.from(multiplicand).randInt(rnd);
      final b = NumberConstraint.from(multiplier).randInt(rnd);
      if (filter == null || filter(rnd, a, b))
        return '''\\begin{matrix}
    & ${a.toString().padLeft(b.toString().length, _space)} \\\\
    \\times & ${b.toString().padLeft(a.toString().length, _space)} \\\\
    \\hline
    \\end{matrix}''';
    }
  });
}

Iterable<String> addVert(Random rnd,
    {NumberConstraint? augend,
    NumberConstraint? addend,
    bool Function(Random rnd, num augend, num addend)? filter}) sync* {
  yield* _gen(() {
    while (true) {
      final a = NumberConstraint.from(augend).randInt(rnd);
      final b = NumberConstraint.from(addend).randInt(rnd);
      if (filter == null || filter(rnd, a, b))
        return '''\\begin{matrix}
    & ${a.toString().padLeft(b.toString().length, _space)} \\\\
    + & ${b.toString().padLeft(a.toString().length, _space)} \\\\
    \\hline
    \\end{matrix}''';
    }
  });
}

Iterable<String> subVert(Random rnd,
    {NumberConstraint? minuend,
    NumberConstraint? subtrahend,
    bool Function(Random rnd, num minuend, num subtrahend)? filter}) sync* {
  yield* _gen(() {
    while (true) {
      final a = NumberConstraint.from(minuend).randInt(rnd);
      final b = NumberConstraint.from(subtrahend).randInt(rnd);
      if (filter == null || filter(rnd, a, b))
        return '''\\begin{matrix}
    & ${a.toString().padLeft(b.toString().length, _space)} \\\\
    - & ${b.toString().padLeft(a.toString().length, _space)} \\\\
    \\hline
    \\end{matrix}''';
    }
  });
}

typedef Iterable<String> MathGenerator(Random rnd);

class ExerciseConfig {
  ExerciseConfig(this.label, this.range, this.generator);
  final String label;
  final RangeValues range;
  final MathGenerator generator;

  @override
  String toString() {
    return '$label';
  }
}

bool p(Random rnd, double v, bool Function() f) =>
    f() ? (v != 0 && rnd.nextInt(1 ~/ v) + 1 == 1) : true;

var configs = [
  ExerciseConfig(
      "Soma armada de unidade com unidade",
      RangeValues(1, 1.2),
      (rnd) => addVert(rnd,
          augend: NumberConstraint.between(min: 1, max: 10),
          addend: NumberConstraint.between(min: 0, max: 10))),
  ExerciseConfig(
      "Soma armada de dezena com unidade",
      RangeValues(1.1, 1.4),
      (rnd) => addVert(rnd,
          augend: NumberConstraint.between(min: 10, max: 100),
          addend: NumberConstraint.between(min: 1, max: 10))),
  ExerciseConfig(
      "Soma armada de dezena com dezena",
      RangeValues(1.3, 1.5),
      (rnd) => addVert(rnd,
          augend: NumberConstraint.between(min: 10, max: 100),
          addend: NumberConstraint.between(min: 11, max: 100))),
  ExerciseConfig(
      "Subtração armada de unidade com unidade",
      RangeValues(1.5, 1.7),
      (rnd) => subVert(
            rnd,
            minuend: NumberConstraint.between(min: 6, max: 10),
            subtrahend: NumberConstraint.between(min: 1, max: 8),
            filter: (rnd, minuend, subtrahend) =>
                /* no negatives */ minuend - subtrahend >= 0,
          )),
  ExerciseConfig(
      "Soma armada de centena com dezena",
      RangeValues(1.4, 1.6),
      (rnd) => addVert(rnd,
          augend: NumberConstraint.between(min: 100, max: 1000),
          addend: NumberConstraint.between(min: 11, max: 100))),
  ExerciseConfig(
      "Subtração armada de dezena com unidade",
      RangeValues(1.6, 1.8),
      (rnd) => subVert(
            rnd,
            minuend: NumberConstraint.between(min: 10, max: 100),
            subtrahend: NumberConstraint.between(min: 0, max: 10),
            filter: (rnd, minuend, subtrahend) =>
                p(/* Less p for < 6 */ rnd, .1, () => subtrahend < 6),
          )),
  ExerciseConfig(
      "Soma armada de centena com centena",
      RangeValues(1.5, 1.7),
      (rnd) => addVert(rnd,
          augend: NumberConstraint.between(min: 100, max: 1000),
          addend: NumberConstraint.between(min: 101, max: 1000))),
  ExerciseConfig(
      "Subtração armada de centena com dezena",
      RangeValues(1.7, 1.9),
      (rnd) => subVert(
            rnd,
            minuend: NumberConstraint.between(min: 100, max: 1000),
            subtrahend: NumberConstraint.between(min: 10, max: 100),
            filter: (rnd, minuend, subtrahend) =>
                p(/* Less p for <= 10 */ rnd, .1, () => subtrahend <= 10),
          )),
  ExerciseConfig(
      "Subtração armada de centena com centena",
      RangeValues(1.8, 1.9),
      (rnd) => subVert(
            rnd,
            minuend: NumberConstraint.between(min: 100, max: 1000),
            subtrahend: NumberConstraint.between(min: 100, max: 1000),
            filter: (rnd, minuend, subtrahend) =>
                /* no negatives */ minuend - subtrahend >= 0 &&
                p(/* Less p for <= 10 */ rnd, .1, () => subtrahend <= 10),
          )),
  ExerciseConfig(
      "Multiplicação armada de unidade por unidade com numeros baixos",
      RangeValues(2, 2.2),
      (rnd) => multVert(
            rnd,
            multiplicand: NumberConstraint.between(min: 1, max: 6),
            multiplier: NumberConstraint.between(min: 0, max: 6),
          )),
  ExerciseConfig(
      "Multiplicação armada de unidade por unidade",
      RangeValues(2.1, 2.3),
      (rnd) => multVert(
            rnd,
            multiplicand: NumberConstraint.between(min: 2, max: 10),
            multiplier: NumberConstraint.between(min: 2, max: 10),
            filter: (rnd, multiplicand, multiplier) =>
                p(rnd, 0, () => multiplicand < 4 && multiplier < 4) &&
                p(rnd, .3, () => multiplicand < 6 || multiplier < 6) &&
                p(rnd, .7, () => multiplicand == multiplier),
          )),
  ExerciseConfig(
      "Multiplicação armada de dezena por unidade com numeros baixos",
      RangeValues(2.1, 2.3),
      (rnd) => multVert(
            rnd,
            multiplicand: NumberConstraint.between(min: 11, max: 100),
            multiplier: NumberConstraint.between(min: 2, max: 10),
            filter: (rnd, multiplicand, multiplier) =>
                multiplicand % 10 != 0 &&
                multiplicand % 10 * multiplier < 10 &&
                p(rnd, .1, () => multiplicand % 10 == 1) &&
                p(rnd, .3, () => multiplicand < 50) &&
                p(rnd, .01, () => multiplier < 6),
          )),
  ExerciseConfig(
      "Multiplicação armada de dezena por unidade",
      RangeValues(2.1, 2.3),
      (rnd) => multVert(
            rnd,
            multiplicand: NumberConstraint.between(min: 10, max: 100),
            multiplier: NumberConstraint.between(min: 2, max: 10),
            filter: (rnd, multiplicand, multiplier) =>
                multiplicand % 10 != 0 &&
                multiplicand % 10 * multiplier >= 10 &&
                p(rnd, .1, () => multiplicand % 10 == 1) &&
                p(rnd, .3, () => multiplicand < 50) &&
                p(rnd, .01, () => multiplier < 6),
          )),
  ExerciseConfig(
      "Multiplicação armada de dezena por dezena",
      RangeValues(2.2, 2.5),
      (rnd) => multVert(
            rnd,
            multiplicand: NumberConstraint.between(min: 10, max: 100),
            multiplier: NumberConstraint.between(min: 10, max: 100),
            filter: (rnd, multiplicand, multiplier) =>
                p(rnd, .1, () => multiplier == 10) &&
                p(rnd, .7, () => multiplicand == multiplier),
          )),
  ExerciseConfig(
      "Multiplicação em linha de dezena por unidade com numeros baixos",
      RangeValues(2.4, 2.7),
      (rnd) => multInline(
            rnd,
            multiplicand: NumberConstraint.between(min: 11, max: 100),
            multiplier: NumberConstraint.between(min: 2, max: 10),
            filter: (rnd, multiplicand, multiplier) =>
                multiplicand % 10 != 0 &&
                multiplicand % 10 * multiplier < 10 &&
                p(rnd, .1, () => multiplicand % 10 == 1) &&
                p(rnd, .3, () => multiplicand < 50) &&
                p(rnd, .01, () => multiplier < 6),
          )),
  ExerciseConfig(
      "Multiplicação em linha de dezena por unidade",
      RangeValues(2.4, 2.7),
      (rnd) => multInline(
            rnd,
            multiplicand: NumberConstraint.between(min: 11, max: 100),
            multiplier: NumberConstraint.between(min: 2, max: 10),
            filter: (rnd, multiplicand, multiplier) =>
                multiplicand % 10 != 0 &&
                p(rnd, .1, () => multiplicand % 10 == 1) &&
                p(rnd, .3, () => multiplicand < 50) &&
                p(rnd, .01, () => multiplier < 6),
          )),
];
