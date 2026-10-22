import 'dart:math' as math;

/// Bibliotheque mathematique hors-ligne (equivalent d'un math.h / cmath).
/// Constantes, fonctions usuelles, nettoyage d'expression, evaluation sure.
class MathLibrary {
  MathLibrary._();

  // ——— Constantes (comme M_PI, M_E en C) ———
  static const double pi = math.pi;
  static const double e = math.e;
  static const double tau = 2 * math.pi;
  static const double ln2 = math.ln2;
  static const double ln10 = math.ln10;
  static const double sqrt2 = math.sqrt2;
  static const double epsilon = 1e-12;

  /// Fonctions reconnues (nom normalise → evaluation)
  static const Set<String> functionNames = {
    'sin',
    'cos',
    'tan',
    'asin',
    'acos',
    'atan',
    'atan2',
    'sinh',
    'cosh',
    'tanh',
    'sqrt',
    'cbrt',
    'abs',
    'exp',
    'ln',
    'log',
    'log10',
    'log2',
    'floor',
    'ceil',
    'round',
    'sign',
    'fact',
    'factorial',
  };

  // ——— Fonctions numeriques ———
  static double sin(double x) => math.sin(x);
  static double cos(double x) => math.cos(x);
  static double tan(double x) => math.tan(x);
  static double asin(double x) => x.abs() <= 1 ? math.asin(x) : double.nan;
  static double acos(double x) => x.abs() <= 1 ? math.acos(x) : double.nan;
  static double atan(double x) => math.atan(x);
  static double atan2(double y, double x) => math.atan2(y, x);

  /// Hyperboliques (implementes a la main : absents de dart:math sur SDK 3.x)
  static double sinh(double x) {
    if (x.abs() < 1e-8) return x;
    if (x > 20) return math.exp(x) / 2;
    if (x < -20) return -math.exp(-x) / 2;
    final e1 = math.exp(x);
    final e2 = math.exp(-x);
    return (e1 - e2) / 2;
  }

  static double cosh(double x) {
    if (x.abs() > 20) return math.exp(x.abs()) / 2;
    final e1 = math.exp(x);
    final e2 = math.exp(-x);
    return (e1 + e2) / 2;
  }

  static double tanh(double x) {
    if (x > 20) return 1;
    if (x < -20) return -1;
    final e2 = math.exp(2 * x);
    return (e2 - 1) / (e2 + 1);
  }

  static double sqrt(double x) => x >= 0 ? math.sqrt(x) : double.nan;
  static double cbrt(double x) =>
      x >= 0 ? math.pow(x, 1 / 3).toDouble() : -math.pow(-x, 1 / 3).toDouble();
  static double abs(double x) => x.abs();
  static double exp(double x) => math.exp(x);
  static double ln(double x) => x > 0 ? math.log(x) : double.nan;
  static double log10(double x) => x > 0 ? math.log(x) / ln10 : double.nan;
  static double log2(double x) => x > 0 ? math.log(x) / ln2 : double.nan;
  static double pow(double a, double b) => math.pow(a, b).toDouble();
  static double floor(double x) => x.floorToDouble();
  static double ceil(double x) => x.ceilToDouble();
  static double round(double x) => x.roundToDouble();
  static double sign(double x) => x.sign;

  static double factorial(double n) {
    if (n < 0 || n != n.roundToDouble() || n > 170) return double.nan;
    var r = 1.0;
    for (var i = 2; i <= n.round(); i++) {
      r *= i;
    }
    return r;
  }

  /// Evalue une fonction unaire par nom
  static double call1(String name, double a) {
    switch (name) {
      case 'sin':
        return sin(a);
      case 'cos':
        return cos(a);
      case 'tan':
        return tan(a);
      case 'asin':
        return asin(a);
      case 'acos':
        return acos(a);
      case 'atan':
        return atan(a);
      case 'sinh':
        return sinh(a);
      case 'cosh':
        return cosh(a);
      case 'tanh':
        return tanh(a);
      case 'sqrt':
        return sqrt(a);
      case 'cbrt':
        return cbrt(a);
      case 'abs':
        return abs(a);
      case 'exp':
        return exp(a);
      case 'ln':
      case 'log':
        return ln(a);
      case 'log10':
        return log10(a);
      case 'log2':
        return log2(a);
      case 'floor':
        return floor(a);
      case 'ceil':
        return ceil(a);
      case 'round':
        return round(a);
      case 'sign':
        return sign(a);
      case 'fact':
      case 'factorial':
        return factorial(a);
      default:
        return double.nan;
    }
  }

  /// Nettoyage d'une expression utilisateur (clavier, symboles, π…)
  static String normalizeExpression(String input) {
    var s = input
        .replaceAll('×', '*')
        .replaceAll('·', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll('–', '-')
        .replaceAll('π', 'pi')
        .replaceAll('Π', 'pi')
        .replaceAll('√', 'sqrt')
        .replaceAll('²', '^2')
        .replaceAll('³', '^3')
        .replaceAll(',', '.')
        .replaceAll(' ', '')
        .replaceAll('{', '(')
        .replaceAll('}', ')')
        .replaceAll('[', '(')
        .replaceAll(']', ')');

    s = s
        .replaceAll(RegExp(r'\bIn\b'), 'ln')
        .replaceAll(RegExp(r'\bIN\b'), 'ln')
        .replaceAll(RegExp(r'\bLn\b'), 'ln');

    s = s.toLowerCase();

    s = s.replaceAllMapped(RegExp(r'(\d+(?:\.\d+)?)!'), (m) {
      return 'fact(${m.group(1)})';
    });

    s = s.replaceAllMapped(RegExp(r'(\d+(?:\.\d+)?)%'), (m) {
      return '(${m.group(1)}/100)';
    });

    s = _insertImplicitMultiplication(s);
    return s;
  }

  static String _insertImplicitMultiplication(String source) {
    final tokens = _tokenize(source);
    final out = <String>[];
    for (var i = 0; i < tokens.length; i++) {
      final current = tokens[i];
      if (out.isNotEmpty &&
          _endsValue(out.last) &&
          _startsValue(current) &&
          !(out.last == ')' && current == '(') &&
          !(functionNames.contains(out.last) && current == '(')) {
        if (!functionNames.contains(out.last)) {
          out.add('*');
        }
      }
      out.add(current);
    }
    return out.join();
  }

  static List<String> _tokenize(String source) {
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
        while (
            i < source.length && RegExp(r'[a-zA-Z_0-9]').hasMatch(source[i])) {
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

  static bool _endsValue(String token) =>
      token == ')' ||
      double.tryParse(token) != null ||
      token == 'x' ||
      token == 'pi' ||
      token == 'e' ||
      token == 'tau';

  static bool _startsValue(String token) =>
      token == '(' ||
      double.tryParse(token) != null ||
      token == 'x' ||
      token == 'pi' ||
      token == 'e' ||
      token == 'tau' ||
      functionNames.contains(token);

  /// Arrondi propre : cos(pi) → -1, sin(pi) → 0
  static double clean(double v) {
    if (v.isNaN || v.isInfinite) return v;
    if (v.abs() < epsilon) return 0;
    final r = v.roundToDouble();
    if ((v - r).abs() < 1e-10) return r;
    return v;
  }

  static String format(double v) {
    if (v.isNaN) return 'Indefini';
    if (v.isInfinite) return v.isNegative ? '-∞' : '+∞';
    final c = clean(v);
    if (c == c.roundToDouble() && c.abs() < 1e15) {
      return c.toInt().toString();
    }
    final frac = toSimpleFraction(c);
    if (frac != null) return frac;
    var s = c.toStringAsFixed(12);
    s = s.replaceAll(RegExp(r'0+$'), '');
    s = s.replaceAll(RegExp(r'\.$'), '');
    return s;
  }

  static String? toSimpleFraction(double value) {
    if (value == 0) return '0';
    const maxDenom = 10000;
    for (var denom = 1; denom <= maxDenom; denom++) {
      final num = (value * denom).round();
      if ((num / denom - value).abs() < 1e-10) {
        final g = _gcd(num.abs(), denom);
        final n = num ~/ g;
        final d = denom ~/ g;
        if (d == 1) return n.toString();
        return '$n/$d';
      }
    }
    return null;
  }

  static int _gcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a == 0 ? 1 : a;
  }
}
