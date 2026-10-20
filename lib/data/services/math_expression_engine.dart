import 'dart:math' as math;

/// Moteur hors-ligne volontairement petit : il couvre les opérateurs et
/// fonctions utilisés par Calc For All sans dépendre d'un service distant.
class MathExpressionEngine {
  static const _functions = {
    'sin',
    'cos',
    'tan',
    'asin',
    'acos',
    'atan',
    'sqrt',
    'abs',
    'log',
    'ln',
    'exp',
    'floor',
    'ceil',
  };

  String normalize(String input) {
    final source = input
        .replaceAll('×', '*')
        .replaceAll('·', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll('π', 'pi')
        .replaceAll('√', 'sqrt')
        .replaceAll('²', '^2')
        .replaceAll('³', '^3')
        .replaceAll(',', '.');
    final tokens = _tokenize(source.replaceAll(' ', '').toLowerCase());
    final out = <String>[];
    for (var i = 0; i < tokens.length; i++) {
      final current = tokens[i];
      if (out.isNotEmpty &&
          _endsValue(out.last) &&
          _startsValue(current) &&
          !(out.last == ')' && current == '(') &&
          !(_isFunction(out.last) && current == '(')) {
        out.add('*');
      }
      out.add(current == 'ln' ? 'log' : current);
    }
    return out.join();
  }

  double? evaluate(String input, double x) {
    try {
      final root = _Parser(_tokenize(normalize(input))).parse();
      final value = root.evaluate(x);
      return value.isFinite ? value : null;
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
              source[i - 1] != 'E') break;
          i++;
        }
        result.add(source.substring(start, i));
      } else if (RegExp(r'[a-zA-Z_]').hasMatch(c)) {
        final start = i++;
        while (i < source.length && RegExp(r'[a-zA-Z_0-9]').hasMatch(source[i]))
          i++;
        result.add(source.substring(start, i));
      } else if ('+-*/^(),'.contains(c)) {
        result.add(c);
        i++;
      } else {
        throw FormatException('Caractère non reconnu : $c');
      }
    }
    return result;
  }

  bool _endsValue(String token) =>
      token == ')' ||
      _isNumber(token) ||
      token == 'x' ||
      token == 'pi' ||
      token == 'e';

  bool _startsValue(String token) =>
      token == '(' ||
      _isNumber(token) ||
      token == 'x' ||
      token == 'pi' ||
      token == 'e' ||
      _isFunction(token);

  bool _isFunction(String token) => _functions.contains(token);
  bool _isNumber(String token) => double.tryParse(token) != null;
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
  double evaluate(double x) => name == 'pi' ? math.pi : math.e;
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
    final a = left.evaluate(x), b = right.evaluate(x);
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
        return math.pow(a, b).toDouble();
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
        if (v is _Number)
          return _Binary(
            '*',
            _Binary(
              '*',
              _Number(v.value),
              _Binary('^', u, _Number(v.value - 1)),
            ),
            du,
          );
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
    switch (name) {
      case 'log':
        return a > 0 ? math.log(a) : double.nan;
      case 'sin':
        return math.sin(a);
      case 'cos':
        return math.cos(a);
      case 'tan':
        return math.tan(a);
      case 'sqrt':
        return a >= 0 ? math.sqrt(a) : double.nan;
      case 'abs':
        return a.abs();
      case 'exp':
        return math.exp(a);
      case 'asin':
        return a.abs() <= 1 ? math.asin(a) : double.nan;
      case 'acos':
        return a.abs() <= 1 ? math.acos(a) : double.nan;
      case 'atan':
        return math.atan(a);
      case 'floor':
        return a.floorToDouble();
      case 'ceil':
        return a.ceilToDouble();
    }
    return double.nan;
  }

  @override
  _Node derivative() {
    final d = argument.derivative();
    switch (name) {
      case 'log':
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
    if (index < tokens.length && (tokens[index] == '+' || tokens[index] == '-'))
      return _Unary(tokens[index++], _unary());
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
    if (t == 'pi' || t == 'e') return _Constant(t);
    if (t == '(') {
      final n = _expression();
      if (index >= tokens.length || tokens[index++] != ')')
        throw FormatException('Parenthèse manquante');
      return n;
    }
    if (MathExpressionEngine._functions.contains(t)) {
      if (index >= tokens.length || tokens[index++] != '(')
        throw FormatException('Parenthèse attendue');
      final n = _Function(t, _expression());
      if (index >= tokens.length || tokens[index++] != ')')
        throw FormatException('Parenthèse manquante');
      return n;
    }
    throw FormatException('Symbole inconnu : $t');
  }
}
