import 'dart:math' as math;

class MathLibrary {
  static const double pi = math.pi;
  static const double e = math.e;

  static final Set<String> functionNames = {
    'sin', 'cos', 'tan', 'asin', 'acos', 'atan',
    'sinh', 'cosh', 'tanh',
    'log', 'ln', 'log10', 'exp', 'sqrt', 'cbrt', 'abs',
  };

  static double call1(String name, double a) {
    switch (name) {
      case 'sin':
        return math.sin(a);
      case 'cos':
        return math.cos(a);
      case 'tan':
        return math.tan(a);
      case 'asin':
        return math.asin(a);
      case 'acos':
        return math.acos(a);
      case 'atan':
        return math.atan(a);
      case 'sinh':
        return math.sinh(a);
      case 'cosh':
        return math.cosh(a);
      case 'tanh':
        return math.tanh(a);
      case 'log':
      case 'ln':
        return ln(a);
      case 'log10':
        return log10(a);
      case 'exp':
        return math.exp(a);
      case 'sqrt':
        return math.sqrt(a);
      case 'cbrt':
        return cbrt(a);
      case 'abs':
        return a.abs();
      default:
        throw ArgumentError('Unsupported unary function: $name');
    }
  }

  static double clean(double v) {
    if (v.isNaN || v.isInfinite) return v;
    final r = v.roundToDouble();
    if ((v - r).abs() < 1e-10) return r;
    return v;
  }

  static String sanitizeForDisplay(String value) {
    if (value.trim().isEmpty) return value;
    var s = value.trim();
    s = s.replaceAll('·', ' ');
    s = s.replaceAll('×', ' ');
    s = s.replaceAll('∗', ' ');
    s = s.replaceAll('*', ' ');
    s = s.replaceAll('÷', '/');
    s = s.replaceAll('^', '');
    s = s.replaceAllMapped(RegExp(r'([A-Za-zπ])\(([^)]*)\)'), (match) => '${match.group(1)}(${match.group(2)})');
    s = s.replaceAllMapped(RegExp(r'([0-9A-Za-zπ])\s+([A-Za-z(π])'), (match) => '${match.group(1)}${match.group(2)}');
    s = s.replaceAllMapped(RegExp(r'([A-Za-zπ0-9])\s+(/)'), (match) => '${match.group(1)}${match.group(2)}');
    s = s.replaceAllMapped(RegExp(r'([A-Za-zπ])\s*([0-9]+)'), (match) => '${match.group(1)}${_superscriptDigits(match.group(2)!)}');
    s = s.replaceAllMapped(RegExp(r'([0-9]+)\s*([A-Za-zπ])'), (match) => '${match.group(1)}${match.group(2)}');
    s = s.replaceAllMapped(RegExp(r'([A-Za-zπ])\s*\(([^)]*)\)'), (match) => '${match.group(1)}(${match.group(2)})');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  static String _superscriptDigits(String digits) {
    const superscripts = '⁰¹²³⁴⁵⁶⁷⁸⁹';
    return digits.split('').map((d) => superscripts[int.parse(d)]).join();
  }

  static double pow(double a, double b) => math.pow(a, b).toDouble();
  static double log10(double x) => math.log(x) / math.ln10;
  static double ln(double x) => math.log(x);

  static double cbrt(double x) {
    if (x == 0) return 0;
    final sign = x < 0 ? -1.0 : 1.0;
    return sign * math.pow(x.abs(), 1 / 3).toDouble();
  }

  static String normalizeExpression(String input) {
    var s = input.trim();
    s = s.replaceAll('×', '*').replaceAll('÷', '/').replaceAll('−', '-');
    s = s.replaceAll('π', 'pi').replaceAll('Π', 'pi');
    s = s.replaceAllMapped(RegExp(r'\bln\s*\('), (_) => 'log(');
    s = s.replaceAllMapped(RegExp(r'\bin\s*\('), (_) => 'log(');
    s = s.replaceAllMapped(RegExp(r'(\d)\s*([a-zA-Z(])'), (m) => '${m[1]}*${m[2]}');
    s = s.replaceAllMapped(RegExp(r'\)\s*(\d)'), (m) => ')*${m[1]}');
    s = s.replaceAllMapped(RegExp(r'\)\s*([a-zA-Z(])'), (m) => ')*${m[1]}');
    s = s.replaceAllMapped(RegExp(r'(\d)\s*pi\b'), (m) => '${m[1]}*pi');
    return s;
  }

  static String format(double v) {
    if (v.isNaN) return 'Math error';
    if (v.isInfinite) return v.isNegative ? '-∞' : '+∞';

    final c = clean(v);
    if (c == 0) return '0';
    if ((c - c.roundToDouble()).abs() < 1e-10) {
      return c.toInt().toString();
    }

    final frac = toSimpleFraction(c);
    if (frac != null) return frac;
    return _trimDecimal(c);
  }

  static String _trimDecimal(double c) {
    var s = c.toStringAsFixed(10);
    s = s.replaceFirst(RegExp(r'\.?0+$'), '');
    return s;
  }

  static String? toSimpleFraction(double value) {
    if (value == 0) return '0';
    const maxDenom = 10000;
    var bestNumerator = value.round();
    var bestDenominator = 1;
    var bestError = (bestNumerator / bestDenominator - value).abs();
    for (var denom = 1; denom <= maxDenom; denom++) {
      final num = (value * denom).round();
      final error = (num / denom - value).abs();
      if (error < bestError) {
        bestNumerator = num;
        bestDenominator = denom;
        bestError = error;
      }
      if (error < 1e-10) {
        final g = _gcd(num.abs(), denom);
        final n = num ~/ g;
        final d = denom ~/ g;
        if (d == 1) return n.toString();
        return '$n/$d';
      }
    }
    if (bestError > 1e-6) return null;
    final g = _gcd(bestNumerator.abs(), bestDenominator);
    final n = bestNumerator ~/ g;
    final d = bestDenominator ~/ g;
    if (d == 1) return n.toString();
    return '$n/$d';
  }

  static String formatArgAsPi(double arg) {
    if (arg.isNaN) return 'Math error';
    var a = arg;
    while (a > math.pi) a -= 2 * math.pi;
    while (a <= -math.pi) a += 2 * math.pi;
    if (a.abs() < 1e-10) return '0';

    final r = a / math.pi;
    final frac = toSimpleFraction(r);
    if (frac == null) return '${format(a)} rad';
    if (frac == '1') return 'π';
    if (frac == '-1') return '−π';
    if (frac.contains('/')) {
      final p = frac.split('/');
      final n = p[0];
      final d = p[1];
      if (n == '1') return 'π/$d';
      if (n == '-1') return '−π/$d';
      return '$nπ/$d';
    }
    if (frac.startsWith('-')) return '−${frac.substring(1)}π';
    return '${frac}π';
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
