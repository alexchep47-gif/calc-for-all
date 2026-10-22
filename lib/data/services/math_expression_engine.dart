import 'dart:math' as math;

import 'math_library.dart';

/// Moteur hors-ligne : parse, evalue, derive — s'appuie sur [MathLibrary].
class MathExpressionEngine {
  String normalize(String input) => MathLibrary.normalizeExpression(input);

  double? evaluate(String input, [double x = 0]) {
    try {
      final normalized = normalize(input);
      final root = _Parser(_tokenize(normalized)).parse();
      final value = root.evaluate(x);
      if (value.isNaN) return null;
      if (!value.isFinite) return value;
      return MathLibrary.clean(value);
    } catch (_) {
      return null;
    }
  }

  String? derivative(String input) {
    try {
      final normalized = normalize(input);
      final root = _Parser(_tokenize(normalized)).parse();
      return root.derivative().simplify().format();
    } catch (_) {
      return null;
    }
  }

  /// Domaine de trace raisonnable (log, sqrt, denoms, constantes e/pi).
  ({double xMin, double xMax}) suggestDomain(
    String input, {
    double fallbackMin = -10,
    double fallbackMax = 10,
  }) {
    final expr = normalize(input);

    // log(x - c) ou log(x + c) avec c numerique ou e/pi
    final logXc = RegExp(
      r'log\(\s*x\s*([+-])\s*(e|pi|\d*\.?\d+)\s*\)',
    ).firstMatch(expr);
    if (logXc != null) {
      final sign = logXc.group(1) == '-' ? -1.0 : 1.0;
      final c = _constValue(logXc.group(2)!);
      final bound = -sign * c; // x + sign*c > 0 => x > -sign*c
      // Pour log(x-e): sign=-1, c=e => bound = e
      return (xMin: bound + 0.05, xMax: bound + 12);
    }

    // log(ax+b)
    final logMatch = RegExp(
      r'log\(([-+]?\d*\.?\d*)\*?x([-+]\d*\.?\d+)?\)',
    ).firstMatch(expr);
    if (logMatch != null) {
      final a = _coeff(logMatch.group(1));
      final b = double.tryParse(logMatch.group(2) ?? '0') ?? 0;
      if (a > 0) {
        final bound = -b / a;
        return (xMin: bound + 0.05, xMax: bound + 12);
      }
      if (a < 0) {
        final bound = -b / a;
        return (xMin: bound - 12, xMax: bound - 0.05);
      }
    }
    if (RegExp(r'log\(x\)').hasMatch(expr)) {
      return (xMin: 0.05, xMax: 10);
    }

    final sqrtMatch = RegExp(
      r'sqrt\(([-+]?\d*\.?\d*)\*?x([-+]\d*\.?\d+)?\)',
    ).firstMatch(expr);
    if (sqrtMatch != null) {
      final a = _coeff(sqrtMatch.group(1));
      final b = double.tryParse(sqrtMatch.group(2) ?? '0') ?? 0;
      if (a > 0) {
        final bound = -b / a;
        return (xMin: bound, xMax: bound + 12);
      }
      if (a < 0) {
        final bound = -b / a;
        return (xMin: bound - 12, xMax: bound);
      }
    }

    // Scan numerique : trouver le premier intervalle ou f est definie
    final scan = _scanDomain(expr, -20, 20);
    if (scan != null) return scan;

    return (xMin: fallbackMin, xMax: fallbackMax);
  }

  ({double xMin, double xMax})? _scanDomain(
    String expr,
    double a,
    double b,
  ) {
    final n = 400;
    final step = (b - a) / n;
    double? first;
    double? last;
    for (var i = 0; i <= n; i++) {
      final x = a + i * step;
      final y = evaluate(expr, x);
      if (y != null && y.isFinite && y.abs() < 1e5) {
        first ??= x;
        last = x;
      }
    }
    if (first == null || last == null || last - first < 0.5) return null;
    final margin = (last - first) * 0.05;
    return (xMin: first - margin, xMax: last + margin);
  }

  double _constValue(String s) {
    if (s == 'e') return MathLibrary.e;
    if (s == 'pi') return MathLibrary.pi;
    return double.tryParse(s) ?? 0;
  }

  double _coeff(String? value) {
    if (value == null || value.isEmpty || value == '+') return 1;
    if (value == '-') return -1;
    return double.tryParse(value) ?? 1;
  }

  List<String> _tokenize(String source) {
    final result = <String>[];
    var i = 0;
    while (i < source.length) {
      final c = source[i];
      if ('0123456789.'.contains(c)) {
        final start = i++;
        while (i < source.length && '0123456789.eE+-'.contains(source[i])) {
          if ((source[i] == '+' || source[i] == '-') &&
              i > start &&
              source[i - 1] != 'e' &&
              source[i - 1] != 'E') {
            break;
          }
          i++;
        }
        result.add(source.substring(start, i));
      } else if (RegExp(r'[a-zA-Z_]').hasMatch(c)) {
        final start = i++;
        while (i < source.length &&
            RegExp(r'[a-zA-Z_0-9]').hasMatch(source[i])) {
          i++;
        }
        result.add(source.substring(start, i));
      } else if ('+-*/^(),'.contains(c)) {
        result.add(c);
        i++;
      } else {
        i++;
      }
    }
    return result;
  }
}

abstract class _Node {
  double evaluate(double x);
  _Node derivative();
  _Node simplify();
  String format();
}

class _Number extends _Node {
  final double value;
  _Number(this.value);
  @override
  double evaluate(double x) => value;
  @override
  _Node derivative() => _Number(0);
  @override
  _Node simplify() => this;
  @override
  String format() => value == value.roundToDouble()
      ? value.toInt().toString()
      : value
          .toStringAsFixed(6)
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
}

class _Variable extends _Node {
  @override
  double evaluate(double x) => x;
  @override
  _Node derivative() => _Number(1);
  @override
  _Node simplify() => this;
  @override
  String format() => 'x';
}

class _Constant extends _Node {
  final String name;
  _Constant(this.name);
  @override
  double evaluate(double x) {
    switch (name) {
      case 'pi':
        return MathLibrary.pi;
      case 'e':
        return MathLibrary.e;
      case 'tau':
        return MathLibrary.tau;
      default:
        return double.nan;
    }
  }

  @override
  _Node derivative() => _Number(0);
  @override
  _Node simplify() => this;
  @override
  String format() => name;
}

class _Unary extends _Node {
  final String op;
  final _Node value;
  _Unary(this.op, this.value);
  @override
  double evaluate(double x) =>
      op == '-' ? -value.evaluate(x) : value.evaluate(x);
  @override
  _Node derivative() => _Unary(op, value.derivative());
  @override
  _Node simplify() => _Unary(op, value.simplify());
  @override
  String format() => '$op(${value.format()})';
}

class _Binary extends _Node {
  final String op;
  final _Node left;
  final _Node right;
  _Binary(this.op, this.left, this.right);

  @override
  double evaluate(double x) {
    final a = left.evaluate(x);
    final b = right.evaluate(x);
    if (a.isNaN || b.isNaN) return double.nan;
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '*':
        return a * b;
      case '/':
        return b == 0 ? double.nan : a / b;
      case '^':
        return MathLibrary.pow(a, b);
    }
    return double.nan;
  }

  @override
  _Node derivative() {
    final u = left, v = right, du = u.derivative(), dv = v.derivative();
    switch (op) {
      case '+':
        return _Binary('+', du, dv);
      case '-':
        return _Binary('-', du, dv);
      case '*':
        return _Binary('+', _Binary('*', du, v), _Binary('*', u, dv));
      case '/':
        return _Binary(
          '/',
          _Binary('-', _Binary('*', du, v), _Binary('*', u, dv)),
          _Binary('^', v, _Number(2)),
        );
      case '^':
        if (v is _Number) {
          return _Binary(
            '*',
            _Binary(
              '*',
              _Number(v.value),
              _Binary('^', u, _Number(v.value - 1)),
            ),
            du,
          );
        }
        return _Binary(
          '*',
          _Binary('^', u, v),
          _Binary(
            '+',
            _Binary('*', dv, _Function('log', u)),
            _Binary('*', v, _Binary('/', du, u)),
          ),
        );
    }
    return _Number(0);
  }

  @override
  _Node simplify() {
    final l = left.simplify(), r = right.simplify();
    if (r is _Number && r.value == 0 && (op == '+' || op == '-')) return l;
    if (l is _Number && l.value == 0 && op == '+') return r;
    if (l is _Number && l.value == 0 && op == '*') return _Number(0);
    if (r is _Number && r.value == 0 && op == '*') return _Number(0);
    if (r is _Number && r.value == 1 && (op == '*' || op == '/')) return l;
    if (l is _Number && l.value == 1 && op == '*') return r;
    return _Binary(op, l, r);
  }

  @override
  String format() => '(${left.format()} $op ${right.format()})';
}

class _Function extends _Node {
  final String name;
  final _Node argument;
  _Function(this.name, this.argument);

  @override
  double evaluate(double x) {
    final a = argument.evaluate(x);
    if (a.isNaN) return double.nan;
    return MathLibrary.call1(name, a);
  }

  @override
  _Node derivative() {
    final d = argument.derivative();
    switch (name) {
      case 'log':
      case 'ln':
        return _Binary('/', d, argument);
      case 'sin':
        return _Binary('*', _Function('cos', argument), d);
      case 'cos':
        return _Unary('-', _Binary('*', _Function('sin', argument), d));
      case 'tan':
        return _Binary(
          '/',
          d,
          _Binary('^', _Function('cos', argument), _Number(2)),
        );
      case 'sqrt':
        return _Binary(
          '/',
          d,
          _Binary('*', _Number(2), _Function('sqrt', argument)),
        );
      case 'exp':
        return _Binary('*', _Function('exp', argument), d);
      case 'abs':
        return _Binary(
          '*',
          _Binary('/', argument, _Function('abs', argument)),
          d,
        );
      case 'asin':
        return _Binary(
          '/',
          d,
          _Function(
            'sqrt',
            _Binary('-', _Number(1), _Binary('^', argument, _Number(2))),
          ),
        );
      case 'acos':
        return _Unary(
          '-',
          _Binary(
            '/',
            d,
            _Function(
              'sqrt',
              _Binary('-', _Number(1), _Binary('^', argument, _Number(2))),
            ),
          ),
        );
      case 'atan':
        return _Binary(
          '/',
          d,
          _Binary('+', _Number(1), _Binary('^', argument, _Number(2))),
        );
    }
    return _Number(0);
  }

  @override
  _Node simplify() => _Function(name, argument.simplify());
  @override
  String format() => '$name(${argument.format()})';
}

class _Parser {
  final List<String> tokens;
  int index = 0;
  _Parser(this.tokens);

  _Node parse() {
    if (tokens.isEmpty) throw FormatException('Expression vide');
    final result = _expression();
    if (index != tokens.length) throw FormatException('Expression invalide');
    return result;
  }

  _Node _expression() {
    var n = _term();
    while (index < tokens.length &&
        (tokens[index] == '+' || tokens[index] == '-')) {
      final op = tokens[index++];
      n = _Binary(op, n, _term());
    }
    return n;
  }

  _Node _term() {
    var n = _unary();
    while (index < tokens.length &&
        (tokens[index] == '*' || tokens[index] == '/')) {
      final op = tokens[index++];
      n = _Binary(op, n, _unary());
    }
    return n;
  }

  _Node _unary() {
    if (index < tokens.length &&
        (tokens[index] == '+' || tokens[index] == '-')) {
      return _Unary(tokens[index++], _unary());
    }
    return _power();
  }

  _Node _power() {
    var n = _primary();
    if (index < tokens.length && tokens[index] == '^') {
      index++;
      n = _Binary('^', n, _unary());
    }
    return n;
  }

  _Node _primary() {
    if (index >= tokens.length) throw FormatException('Valeur attendue');
    final t = tokens[index++];
    final number = double.tryParse(t);
    if (number != null) return _Number(number);
    if (t == 'x') return _Variable();
    if (t == 'pi' || t == 'e' || t == 'tau') return _Constant(t);
    if (t == '(') {
      final n = _expression();
      if (index >= tokens.length || tokens[index++] != ')') {
        throw FormatException('Parenthese manquante');
      }
      return n;
    }
    if (MathLibrary.functionNames.contains(t) || t == 'ln' || t == 'in') {
      final name = (t == 'ln' || t == 'in') ? 'log' : t;
      if (index >= tokens.length || tokens[index++] != '(') {
        throw FormatException('Parenthese attendue apres $t');
      }
      final n = _Function(name, _expression());
      if (index >= tokens.length || tokens[index++] != ')') {
        throw FormatException('Parenthese manquante');
      }
      return n;
    }
    throw FormatException('Symbole inconnu : $t');
  }
}
