import 'math_expression_engine.dart';
import 'math_library.dart';

/// Evalue une courbe sans planter hors domaine.
/// Decoupe en segments continus (pas de trait vertical absurde aux asymptotes).
class GraphService {
  final MathExpressionEngine _engine;

  GraphService({MathExpressionEngine? engine})
      : _engine = engine ?? MathExpressionEngine();

  String normalize(String expression) =>
      MathLibrary.normalizeExpression(expression);

  /// Points bruts (x,y) valides
  List<MapEntry<double, double>> evaluateFunction(
    String expression,
    double xMin,
    double xMax,
    int points,
  ) {
    if (points < 2 || !xMin.isFinite || !xMax.isFinite || xMax <= xMin) {
      return [];
    }
    final result = <MapEntry<double, double>>[];
    final step = (xMax - xMin) / (points - 1);
    for (var i = 0; i < points; i++) {
      final x = xMin + i * step;
      final y = _engine.evaluate(expression, x);
      if (y != null && y.isFinite && y.abs() < 1e6) {
        result.add(MapEntry(x, MathLibrary.clean(y)));
      }
    }
    return result;
  }

  /// Segments continus : coupe quand l'ecart en x ou y est trop grand
  List<List<MapEntry<double, double>>> evaluateSegments(
    String expression,
    double xMin,
    double xMax,
    int points,
  ) {
    final raw = evaluateFunction(expression, xMin, xMax, points);
    if (raw.isEmpty) return [];
    final step = (xMax - xMin) / (points - 1);
    final segments = <List<MapEntry<double, double>>>[];
    var current = <MapEntry<double, double>>[raw.first];
    for (var i = 1; i < raw.length; i++) {
      final prev = raw[i - 1];
      final p = raw[i];
      final dx = p.key - prev.key;
      final dy = (p.value - prev.value).abs();
      // Trou (hors domaine) ou saut d'asymptote
      if (dx > step * 2.5 || dy > 80) {
        if (current.length >= 2) segments.add(current);
        current = [p];
      } else {
        current.add(p);
      }
    }
    if (current.length >= 2) segments.add(current);
    return segments;
  }
}
