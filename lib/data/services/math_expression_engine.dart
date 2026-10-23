import 'dart:math' as math;

import 'math_library.dart';

/// Moteur hors-ligne : parse, évalue, dérive, intègre — [MathLibrary].
class MathExpressionEngine {
  String normalize(String input) => MathLibrary.normalizeExpression(input);

  double? evaluate(String input, [double x = 0]) {
    try {
      final root = _Parser(_tokenize(normalize(input))).parse();
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
      final root = _Parser(_tokenize(normalize(input))).parse();
      return root.derivative().simplify().format();
    } catch (_) {
      return null;
    }
  }

  String? derivativePretty(String input) {
    final raw = derivative(input);
    if (raw == null) return null;
    var result = raw.replaceAll(' * ', '').replaceAll('*', '');
    result = result.replaceAllMapped(RegExp(r'\^\s*([0-9]+)'), (match) {
      const superscripts = '⁰¹²³⁴⁵⁶⁷⁸⁹';
      return match
          .group(1)!
          .split('')
          .map((digit) => superscripts[int.parse(digit)])
          .join();
    });
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
    while (result.startsWith('(') && result.endsWith(')')) {
      result = result.substring(1, result.length - 1).trim();
    }
    return result;
  }

  /// Étapes de dérivation (fonctions composées = règle de la chaîne).
  String derivativeSteps(String input) {
    final e = normalize(input);
    final buf = StringBuffer();
    buf.writeln('Fonction : f(x) = $e');
    buf.writeln();
    buf.writeln('Règles appliquées :');
    buf.writeln('• Somme : (u+v)′ = u′ + v′');
    buf.writeln('• Produit : (uv)′ = u′v + uv′');
    buf.writeln('• Quotient : (u/v)′ = (u′v − uv′)/v²');
    buf.writeln('• Puissance : (uⁿ)′ = n·uⁿ⁻¹·u′');
    buf.writeln('• Chaîne : [g(u(x))]′ = g′(u)·u′');
    buf.writeln();
    final comp =
        RegExp(r'(sin|cos|tan|exp|ln|log|sqrt|asin|acos|atan|sinh|cosh)\((.+)\)')
            .firstMatch(e);
    if (comp != null && comp.group(2) != 'x') {
      buf.writeln('Composition détectée :');
      buf.writeln('  g(t) = ${comp.group(1)}(t)');
      buf.writeln('  u(x) = ${comp.group(2)}');
      buf.writeln('  f′(x) = g′(u)·u′  (règle de la chaîne)');
      buf.writeln();
    }
    final pretty = derivativePretty(input);
    if (pretty != null) {
      buf.writeln('Dérivée : f′(x) = $pretty');
    } else {
      buf.writeln('Dérivée symbolique non disponible.');
    }
    return buf.toString();
  }

  String _superscript(int value) {
    const digits = '⁰¹²³⁴⁵⁶⁷⁸⁹';
    final neg = value < 0;
    final s = value.abs().toString();
    final out = s.split('').map((d) => digits[int.parse(d)]).join();
    return neg ? '⁻$out' : out;
  }

  /// Intégration symbolique : usuelles, changement de variable, parties.
  ({String? primitive, String method, String steps}) integrateSymbolic(
      String input) {
    final e = normalize(input);
    final steps = StringBuffer();
    steps.writeln('Intégrande : ∫ $e dx');
    steps.writeln();

    if (e == 'x' || e == '(x)') {
      steps.writeln('∫ x dx = x²/2 + C');
      return (
        primitive: 'x²/2 + C',
        method: 'primitive usuelle',
        steps: steps.toString(),
      );
    }
    if (e == '1' || e == '1.0') {
      return (primitive: 'x + C', method: 'primitive usuelle', steps: '∫ 1 dx = x + C');
    }
    if (e == '1/x' || e == '(1/x)') {
      steps.writeln('∫ dx/x = ln|x| + C');
      return (
        primitive: 'ln|x| + C',
        method: 'primitive usuelle',
        steps: steps.toString(),
      );
    }

    final power = RegExp(r'^x\^([-+]?\d+)$').firstMatch(e);
    if (power != null) {
      final n = int.parse(power.group(1)!);
      if (n == -1) {
        return (
          primitive: 'ln|x| + C',
          method: 'primitive usuelle',
          steps: '∫ x⁻¹ dx = ln|x| + C',
        );
      }
      steps.writeln('∫ xⁿ dx = xⁿ⁺¹/(n+1) + C');
      return (
        primitive: 'x${_superscript(n + 1)}/${n + 1} + C',
        method: 'primitive usuelle',
        steps: steps.toString(),
      );
    }

    final coeffPower =
        RegExp(r'^([-+]?\d*\.?\d+)\*x\^([-+]?\d+)$').firstMatch(e);
    if (coeffPower != null) {
      final coefficient = double.parse(coeffPower.group(1)!);
      final n = int.parse(coeffPower.group(2)!);
      if (n == -1) {
        return (
          primitive: '${MathLibrary.format(coefficient)} ln|x| + C',
          method: 'primitive usuelle',
          steps: '∫ k/x dx = k ln|x| + C',
        );
      }
      final next = n + 1;
      return (
        primitive:
            '${MathLibrary.format(coefficient / next)}x${_superscript(next)} + C',
        method: 'primitive usuelle',
        steps: '∫ k·xⁿ dx = k·xⁿ⁺¹/(n+1) + C',
      );
    }

    // Changement de variable : sin/cos/exp/tan(ax+b)
    final linTrig = RegExp(
      r'^(sin|cos|exp|tan)\(\s*([-+]?\d*\.?\d*)\s*\*?\s*x\s*([-+]\s*\d*\.?\d+)?\s*\)$',
    ).firstMatch(e);
    if (linTrig != null) {
      final fn = linTrig.group(1)!;
      final aStr = linTrig.group(2)!;
      final a = aStr.isEmpty || aStr == '+'
          ? 1.0
          : (aStr == '-' ? -1.0 : double.parse(aStr));
      final bStr = (linTrig.group(3) ?? '0').replaceAll(' ', '');
      final b = double.tryParse(bStr) ?? 0.0;
      final inner = b.abs() < 1e-12
          ? (a == 1 ? 'x' : '${MathLibrary.format(a)}x')
          : '${MathLibrary.format(a)}x${b >= 0 ? '+' : ''}${MathLibrary.format(b)}';
      steps.writeln('Changement de variable :');
      steps.writeln('  u = $inner');
      steps.writeln('  du = ${MathLibrary.format(a)} dx');
      String prim;
      switch (fn) {
        case 'sin':
          prim = a == 1
              ? '−cos($inner) + C'
              : '−cos($inner)/${MathLibrary.format(a)} + C';
          break;
        case 'cos':
          prim = a == 1
              ? 'sin($inner) + C'
              : 'sin($inner)/${MathLibrary.format(a)} + C';
          break;
        case 'exp':
          prim = a == 1
              ? 'exp($inner) + C'
              : 'exp($inner)/${MathLibrary.format(a)} + C';
          break;
        default:
          prim = a == 1
              ? '−ln|cos($inner)| + C'
              : '−ln|cos($inner)|/${MathLibrary.format(a)} + C';
      }
      steps.writeln('Résultat : $prim');
      return (
        primitive: prim,
        method: 'changement de variable',
        steps: steps.toString(),
      );
    }

    // 1/(ax+b)
    final invLin = RegExp(
      r'^1/\(\s*([-+]?\d*\.?\d*)\s*\*?\s*x\s*([-+]\s*\d*\.?\d+)?\s*\)$',
    ).firstMatch(e);
    if (invLin != null) {
      final aStr = invLin.group(1)!;
      final a = aStr.isEmpty || aStr == '+'
          ? 1.0
          : (aStr == '-' ? -1.0 : double.parse(aStr));
      final bStr = (invLin.group(2) ?? '0').replaceAll(' ', '');
      final b = double.tryParse(bStr) ?? 0.0;
      final inner = b.abs() < 1e-12
          ? (a == 1 ? 'x' : '${MathLibrary.format(a)}x')
          : '${MathLibrary.format(a)}x${b >= 0 ? '+' : ''}${MathLibrary.format(b)}';
      steps.writeln('Changement de variable : u = $inner');
      final prim = a == 1
          ? 'ln|$inner| + C'
          : 'ln|$inner|/${MathLibrary.format(a)} + C';
      return (
        primitive: prim,
        method: 'changement de variable',
        steps: steps.toString(),
      );
    }

    // (ax+b)^n
    final powLin = RegExp(
      r'^\(\s*([-+]?\d*\.?\d*)\s*\*?\s*x\s*([-+]\s*\d*\.?\d+)?\s*\)\^([-+]?\d+)$',
    ).firstMatch(e);
    if (powLin != null) {
      final aStr = powLin.group(1)!;
      final a = aStr.isEmpty || aStr == '+'
          ? 1.0
          : (aStr == '-' ? -1.0 : double.parse(aStr));
      final bStr = (powLin.group(2) ?? '0').replaceAll(' ', '');
      final b = double.tryParse(bStr) ?? 0.0;
      final n = int.parse(powLin.group(3)!);
      final inner = b.abs() < 1e-12
          ? (a == 1 ? 'x' : '${MathLibrary.format(a)}x')
          : '${MathLibrary.format(a)}x${b >= 0 ? '+' : ''}${MathLibrary.format(b)}';
      steps.writeln('Changement de variable : u = $inner');
      if (n == -1) {
        final prim = a == 1
            ? 'ln|$inner| + C'
            : 'ln|$inner|/${MathLibrary.format(a)} + C';
        return (
          primitive: prim,
          method: 'changement de variable',
          steps: steps.toString(),
        );
      }
      final next = n + 1;
      final coeff = 1 / (a * next);
      final prim =
          '${MathLibrary.format(coeff)}($inner)${_superscript(next)} + C';
      return (
        primitive: prim,
        method: 'changement de variable',
        steps: steps.toString(),
      );
    }

    // Intégration par parties
    if (e == 'ln(x)' || e == 'log(x)') {
      steps.writeln('Intégration par parties :');
      steps.writeln('  u = ln(x), du = dx/x');
      steps.writeln('  dv = dx, v = x');
      steps.writeln('  ∫ = x ln(x) − ∫ 1 dx = x ln(x) − x + C');
      return (
        primitive: 'x·ln(x) − x + C',
        method: 'intégration par parties',
        steps: steps.toString(),
      );
    }
    if (e == 'x*ln(x)' || e == 'x*log(x)') {
      steps.writeln('Intégration par parties :');
      steps.writeln('  u = ln(x), dv = x dx');
      steps.writeln('  ∫ = (x²/2)ln(x) − x²/4 + C');
      return (
        primitive: '(x²/2)·ln(x) − x²/4 + C',
        method: 'intégration par parties',
        steps: steps.toString(),
      );
    }
    final xTrig = RegExp(r'^x\*(sin|cos|exp)\(x\)$').firstMatch(e);
    if (xTrig != null) {
      final fn = xTrig.group(1)!;
      steps.writeln('Intégration par parties : u = x, dv = $fn(x) dx');
      if (fn == 'sin') {
        steps.writeln('∫ = −x cos(x) + sin(x) + C');
        return (
          primitive: '−x·cos(x) + sin(x) + C',
          method: 'intégration par parties',
          steps: steps.toString(),
        );
      }
      if (fn == 'cos') {
        steps.writeln('∫ = x sin(x) + cos(x) + C');
        return (
          primitive: 'x·sin(x) + cos(x) + C',
          method: 'intégration par parties',
          steps: steps.toString(),
        );
      }
      steps.writeln('∫ = x exp(x) − exp(x) + C');
      return (
        primitive: 'x·exp(x) − exp(x) + C',
        method: 'intégration par parties',
        steps: steps.toString(),
      );
    }

    final trig = RegExp(r'^(sin|cos|exp|tan)\(x\)$').firstMatch(e);
    if (trig != null) {
      switch (trig.group(1)) {
        case 'sin':
          return (
            primitive: '−cos(x) + C',
            method: 'primitive usuelle',
            steps: '∫ sin(x) dx = −cos(x) + C',
          );
        case 'cos':
          return (
            primitive: 'sin(x) + C',
            method: 'primitive usuelle',
            steps: '∫ cos(x) dx = sin(x) + C',
          );
        case 'exp':
          return (
            primitive: 'exp(x) + C',
            method: 'primitive usuelle',
            steps: '∫ exp(x) dx = exp(x) + C',
          );
        case 'tan':
          return (
            primitive: '−ln|cos(x)| + C',
            method: 'primitive usuelle',
            steps: '∫ tan(x) dx = −ln|cos(x)| + C',
          );
      }
    }

    steps.writeln('Aucune primitive symbolique pour cette forme.');
    steps.writeln(
        'Essayez : sin(ax+b), x·sin(x), ln(x), 1/(ax+b), (ax+b)^n…');
    return (primitive: null, method: 'non trouvée', steps: steps.toString());
  }

  String? antiderivativePretty(String input) =>
      integrateSymbolic(input).primitive;

  bool isTrigExpression(String input) {
    final e = normalize(input);
    return RegExp(r'\b(sin|cos|tan)\s*\(').hasMatch(e);
  }

  ({double xMin, double xMax, double yMin, double yMax, bool piLabels})
      suggestWindow(String input) {
    if (isTrigExpression(input)) {
      const twoPi = 2 * math.pi;
      return (xMin: -twoPi, xMax: twoPi, yMin: -2.0, yMax: 2.0, piLabels: true);
    }
    return (xMin: -10.0, xMax: 10.0, yMin: -10.0, yMax: 10.0, piLabels: false);
  }

  List<String> _tokenize(String input) {
    final tokens = <String>[];
    var i = 0;
    while (i < input.length) {
      final c = input[i];
      if (c == ' ') {
        i++;
        continue;
      }
      if ('+-*/^(),'.contains(c)) {
        tokens.add(c);
        i++;
        continue;
      }
      if (RegExp(r'[0-9.]').hasMatch(c)) {
        final start = i;
        i++;
        while (i < input.length && RegExp(r'[0-9.eE]').hasMatch(input[i])) {
          i++;
        }
        tokens.add(input.substring(start, i));
        continue;
      }
      if (RegExp(r'[a-zA-Z]').hasMatch(c)) {
        final start = i;
        i++;
        while (i < input.length && RegExp(r'[a-zA-Z0-9_]').hasMatch(input[i])) {
          i++;
        }
        tokens.add(input.substring(start, i));
        continue;
      }
      i++;
    }
    return tokens;
  }
}

abstract class _Node {
  double evaluate(double x);
  _Node derivative();
  _Node simplify() => this;
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
  String format() => MathLibrary.format(value);
}

class _Variable extends _Node {
  @override
  double evaluate(double x) => x;
  @override
  _Node derivative() => _Number(1);
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
        return math.pi;
      case 'e':
        return math.e;
      case 'tau':
        return 2 * math.pi;
    }
    return double.nan;
  }

  @override
  _Node derivative() => _Number(0);
  @override
  String format() => name;
}

class _Unary extends _Node {
  final String op;
  final _Node value;
  _Unary(this.op, this.value);
  @override
  double evaluate(double x) {
    final v = value.evaluate(x);
    return op == '-' ? -v : v;
  }

  @override
  _Node derivative() => _Unary(op, value.derivative());
  @override
  _Node simplify() {
    final v = value.simplify();
    if (v is _Number && op == '-') return _Number(-v.value);
    return _Unary(op, v);
  }

  @override
  String format() => '($op${value.format()})';
}

class _Binary extends _Node {
  final String op;
  final _Node left, right;
  _Binary(this.op, this.left, this.right);

  @override
  double evaluate(double x) {
    final a = left.evaluate(x);
    final b = right.evaluate(x);
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
    if (op == '^' && r is _Number) {
      if (r.value == 0) return _Number(1);
      if (r.value == 1) return l;
    }
    if (l is _Number && r is _Number) {
      return _Number(_Binary(op, l, r).evaluate(0));
    }
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

  /// Règle de la chaîne : [g(u)]′ = g′(u)·u′
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
      case 'sec':
        return _Binary(
          '*',
          _Binary('*', _Function('sec', argument), _Function('tan', argument)),
          d,
        );
      case 'csc':
        return _Unary(
          '-',
          _Binary(
            '*',
            _Binary('*', _Function('csc', argument), _Function('cot', argument)),
            d,
          ),
        );
      case 'cot':
        return _Unary(
          '-',
          _Binary('/', d, _Binary('^', _Function('sin', argument), _Number(2))),
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
      case 'sinh':
        return _Binary('*', _Function('cosh', argument), d);
      case 'cosh':
        return _Binary('*', _Function('sinh', argument), d);
      case 'tanh':
        return _Binary(
          '/',
          d,
          _Binary('^', _Function('cosh', argument), _Number(2)),
        );
      case 'log10':
        return _Binary(
          '/',
          d,
          _Binary('*', argument, _Number(math.ln10)),
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

  _Node parse() => _expression();

  _Node _expression() {
    var node = _term();
    while (index < tokens.length &&
        (tokens[index] == '+' || tokens[index] == '-')) {
      final op = tokens[index++];
      node = _Binary(op, node, _term());
    }
    return node;
  }

  _Node _term() {
    var node = _power();
    while (index < tokens.length &&
        (tokens[index] == '*' || tokens[index] == '/')) {
      final op = tokens[index++];
      node = _Binary(op, node, _power());
    }
    return node;
  }

  _Node _power() {
    var node = _unary();
    if (index < tokens.length && tokens[index] == '^') {
      index++;
      node = _Binary('^', node, _unary());
    }
    return node;
  }

  _Node _unary() {
    if (index < tokens.length &&
        (tokens[index] == '+' || tokens[index] == '-')) {
      final op = tokens[index++];
      return _Unary(op, _unary());
    }
    return _primary();
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
        throw FormatException('Parenthèse manquante');
      }
      return n;
    }
    if (MathLibrary.functionNames.contains(t) || t == 'ln' || t == 'in') {
      final name = (t == 'ln' || t == 'in') ? 'log' : t;
      if (index >= tokens.length || tokens[index++] != '(') {
        throw FormatException('Parenthèse attendue après $t');
      }
      final n = _Function(name, _expression());
      if (index >= tokens.length || tokens[index++] != ')') {
        throw FormatException('Parenthèse manquante');
      }
      return n;
    }
    throw FormatException('Symbole inconnu : $t');
  }
}
