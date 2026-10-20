import 'package:math_expressions/math_expressions.dart';

/// Service de calcul scientifique avec support des fractions
class CalculatorService {
  final Parser _parser = Parser();
  final ContextModel _context = ContextModel();

  /// Évalue une expression mathématique
  String evaluate(String expression) {
    try {
      String expr = expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('−', '-')
          .replaceAll('π', 'pi')
          .replaceAll('√', 'sqrt')
          .replaceAll('²', '^2')
          .replaceAll('³', '^3');

      // Factorielle n!
      expr = expr.replaceAllMapped(RegExp(r'(\d+)!'), (m) {
        final n = int.tryParse(m.group(1)!) ?? 0;
        if (n < 0 || n > 20) return '0'; // limite de sécurité
        int fact = 1;
        for (int i = 2; i <= n; i++) fact *= i;
        return fact.toString();
      });

      // Pourcentage
      if (expr.contains('%')) {
        expr = expr.replaceAllMapped(
          RegExp(r'(\d+(?:\.\d+)?)%'),
          (m) => '(${m.group(1)}/100)',
        );
      }

      Expression exp = _parser.parse(expr);
      double result = exp.evaluate(EvaluationType.REAL, _context);

      if (result.isNaN || result.isInfinite) return 'Erreur';

      // Affichage fractionnaire simple pour les résultats « jolis »
      final fraction = _toSimpleFraction(result);
      if (fraction != null) return fraction;

      if (result == result.roundToDouble()) {
        return result.toInt().toString();
      }

      String formatted = result.toStringAsFixed(10);
      formatted = formatted.replaceAll(RegExp(r'0+$'), '');
      formatted = formatted.replaceAll(RegExp(r'\.$'), '');
      return formatted;
    } catch (e) {
      return 'Erreur';
    }
  }

  /// Tente de convertir un double en fraction simple a/b
  String? _toSimpleFraction(double value) {
    if (value == 0) return '0';
    const maxDenom = 100;
    for (int denom = 1; denom <= maxDenom; denom++) {
      final num = (value * denom).round();
      if ((num / denom - value).abs() < 1e-8) {
        if (denom == 1) return num.toString();
        // Simplification
        final g = _gcd(num.abs(), denom);
        final n = num ~/ g;
        final d = denom ~/ g;
        if (d == 1) return n.toString();
        return '$n/$d';
      }
    }
    return null;
  }

  int _gcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a;
  }
}
