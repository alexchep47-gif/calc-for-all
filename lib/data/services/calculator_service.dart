import 'package:math_expressions/math_expressions.dart';

/// Service de calcul scientifique classique
class CalculatorService {
  final Parser _parser = Parser();
  final ContextModel _context = ContextModel();

  /// Évalue une expression mathématique et retourne le résultat sous forme de String
  String evaluate(String expression) {
    try {
      // Remplacements pour une saisie plus naturelle
      String expr = expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', 'pi')
          .replaceAll('√', 'sqrt')
          .replaceAll('²', '^2')
          .replaceAll('³', '^3');

      // Gestion du pourcentage simple
      if (expr.contains('%')) {
        expr = expr.replaceAllMapped(
          RegExp(r'(\d+(?:\.\d+)?)%'),
          (m) => '(${m.group(1)}/100)',
        );
      }

      Expression exp = _parser.parse(expr);
      double result = exp.evaluate(EvaluationType.REAL, _context);

      // Formatage propre
      if (result == result.roundToDouble()) {
        return result.toInt().toString();
      }
      // Limite à 10 décimales utiles
      String formatted = result.toStringAsFixed(10);
      formatted = formatted.replaceAll(RegExp(r'0+$'), '');
      formatted = formatted.replaceAll(RegExp(r'\.$'), '');
      return formatted;
    } catch (e) {
      return 'Erreur';
    }
  }

  /// Vérifie si l'expression est valide (sans l'évaluer complètement)
  bool isValid(String expression) {
    try {
      String expr = expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', 'pi')
          .replaceAll('√', 'sqrt');
      _parser.parse(expr);
      return true;
    } catch (_) {
      return false;
    }
  }
}
