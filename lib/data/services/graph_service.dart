import 'package:math_expressions/math_expressions.dart';

/// Service pour le tracé de courbes
class GraphService {
  final Parser _parser = Parser();

  /// Évalue une fonction f(x) pour une liste de points
  List<MapEntry<double, double>> evaluateFunction(
    String expression,
    double xMin,
    double xMax,
    int points,
  ) {
    final List<MapEntry<double, double>> result = [];
    try {
      String expr = expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', 'pi')
          .replaceAll('√', 'sqrt');

      Expression exp = _parser.parse(expr);
      final context = ContextModel();

      final step = (xMax - xMin) / (points - 1);
      for (int i = 0; i < points; i++) {
        final x = xMin + i * step;
        context.bindVariable(Variable('x'), Number(x));
        try {
          final y = exp.evaluate(EvaluationType.REAL, context);
          if (y.isFinite) {
            result.add(MapEntry(x, y));
          }
        } catch (_) {
          // Point non défini (ex: division par zéro)
        }
      }
    } catch (_) {
      // Expression invalide
    }
    return result;
  }
}
