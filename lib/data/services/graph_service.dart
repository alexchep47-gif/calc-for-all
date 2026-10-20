import 'package:math_expressions/math_expressions.dart';

/// Service pour le tracé de courbes
class GraphService {
  final Parser _parser = Parser();

  /// Normalise l'expression pour math_expressions
  String normalize(String expression) {
    return expression
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll('π', 'pi')
        .replaceAll('√', 'sqrt')
        .replaceAll('²', '^2')
        .replaceAll('³', '^3')
        .replaceAll(' ', '');
  }

  /// Évalue une fonction f(x) pour une liste de points
  List<MapEntry<double, double>> evaluateFunction(
    String expression,
    double xMin,
    double xMax,
    int points,
  ) {
    final List<MapEntry<double, double>> result = [];
    try {
      final expr = normalize(expression);
      final exp = _parser.parse(expr);
      final context = ContextModel();

      final step = (xMax - xMin) / (points - 1);
      for (int i = 0; i < points; i++) {
        final x = xMin + i * step;
        try {
          context.bindVariableName('x', Number(x));
          final y = exp.evaluate(EvaluationType.REAL, context);
          if (y is num && y.isFinite) {
            result.add(MapEntry(x, y.toDouble()));
          }
        } catch (_) {
          // Point non défini
        }
      }
    } catch (_) {
      // Expression invalide
    }
    return result;
  }
}
