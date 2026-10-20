import 'math_expression_engine.dart';

/// Évalue une courbe sans interrompre le tracé lorsqu'un point est hors domaine.
class GraphService {
  final MathExpressionEngine _engine;

  GraphService({MathExpressionEngine? engine})
      : _engine = engine ?? MathExpressionEngine();

  String normalize(String expression) => _engine.normalize(expression);

  List<MapEntry<double, double>> evaluateFunction(
    String expression,
    double xMin,
    double xMax,
    int points,
  ) {
    if (points < 2 || !xMin.isFinite || !xMax.isFinite || xMax <= xMin)
      return [];
    final result = <MapEntry<double, double>>[];
    final step = (xMax - xMin) / (points - 1);
    for (var i = 0; i < points; i++) {
      final x = xMin + i * step;
      final y = _engine.evaluate(expression, x);
      if (y != null && y.isFinite && y.abs() < 1e8) {
        result.add(MapEntry(x, y));
      }
    }
    return result;
  }
}
