import 'package:math_expressions/math_expressions.dart';

/// Service de calcul scientifique classique
class CalculatorService {
  final Parser _parser = Parser();
  final ContextModel _context = ContextModel();

  /// Évalue une expression mathématique et retourne le résultat sous forme de String
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

      // Factorielle simple (n!)
      expr = expr.replaceAllMapped(RegExp(r'(\d+)!'), (m) {
        final n = int.parse(m.group(1)!);
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
}
