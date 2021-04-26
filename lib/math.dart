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

Iterable<String> multVert(
    {Random? rnd,
    NumberConstraint? multiplicand,
    NumberConstraint? multiplier}) sync* {
  final _rnd = rnd ?? Random();
  yield* _gen(() {
    final a = NumberConstraint.from(multiplicand).randInt(_rnd).toString();
    final b = NumberConstraint.from(multiplier).randInt(_rnd).toString();
    return '''\\begin{matrix}
    & ${a.padLeft(b.length, _space)} \\\\
    \\times & ${b.padLeft(a.length, _space)} \\\\
    \\hline
    \\end{matrix}''';
  });
}

Iterable<String> addVert(Random rnd,
    {NumberConstraint? augend, NumberConstraint? addend}) sync* {
  yield* _gen(() {
    final a = NumberConstraint.from(augend).randInt(rnd).toString();
    final b = NumberConstraint.from(addend).randInt(rnd).toString();
    return '''\\begin{matrix}
    & ${a.padLeft(b.length, _space)} \\\\
    + & ${b.padLeft(a.length, _space)} \\\\
    \\hline
    \\end{matrix}''';
  });
}

Iterable<String> subVert(
    {Random? rnd,
    NumberConstraint? minuend,
    NumberConstraint? subtrahend}) sync* {
  final _rnd = rnd ?? Random();
  yield* _gen(() {
    final a = NumberConstraint.from(minuend).randInt(_rnd).toString();
    final b = NumberConstraint.from(subtrahend).randInt(_rnd).toString();
    return '''\\begin{matrix}
    & ${a.padLeft(b.length, _space)} \\\\
    - & ${b.padLeft(a.length, _space)} \\\\
    \\hline
    \\end{matrix}''';
  });
}

typedef Iterable<String> MathGenerator(Random rnd);

class X {
  X(this.range, this.generator);
  final RangeValues range;
  final MathGenerator generator;
}

bool p(Random rnd, double v, bool Function() f) =>
    f() ? (v != 0 && rnd.nextInt(1 ~/ v) + 1 == 1) : true;

var x = [
  X(
      RangeValues(1, 1.5),
      (rnd) => multInline(
            rnd,
            multiplicand: NumberConstraint.between(min: 2, max: 10),
            multiplier: NumberConstraint.between(min: 2, max: 10),
            filter: (rnd, multiplicand, multiplier) =>
                p(rnd, 0, () => multiplicand < 4 && multiplier < 4) &&
                //p(rnd, 0, () => [multiplicand, multiplier].contains(1)) &&
                p(rnd, .3, () => multiplicand < 6 || multiplier < 6) &&
                p(rnd, .7, () => multiplicand == multiplier),
          )),
  X(
      RangeValues(1.5, 2),
      (rnd) => addVert(rnd,
          augend: NumberConstraint.between(min: 101, max: 999)
              .copyWith(minDigits: 3),
          addend: NumberConstraint.between(min: 11, max: 99)
              .copyWith(minDigits: 2)))
];
