import 'math_expression_engine.dart';
import 'math_library.dart';

/// Evalue une courbe strictement dans son domaine reel.
/// Points hors domaine → ignores ; segments continus separes aux trous/asymptotes.
class GraphService {
  final MathExpressionEngine _engine;

  GraphService({MathExpressionEngine? engine})
      : _engine = engine ?? MathExpressionEngine();

  String normalize(String expression) =>
      MathLibrary.normalizeExpression(expression);

  /// true si y est un point traçable (domaine + pas d'asymptote numerique)
  static bool isPlottable(double? y) {
    if (y == null) return false;
    if (y.isNaN || y.isInfinite) return false;
    if (y.abs() > 1e5) return false; // asymptote verticale
    return true;
  }

  /// Points bruts (x,y) valides uniquement
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
      final y = _safeY(expression, x);
      if (isPlottable(y)) {
        result.add(MapEntry(x, MathLibrary.clean(y!)));
      }
    }
    return result;
  }

  double? _safeY(String expression, double x) {
    try {
      final y = _engine.evaluate(expression, x);
      if (y == null) return null;
      if (y.isNaN || y.isInfinite) return null;
      return y;
    } catch (_) {
      return null;
    }
  }

  /// Segments continus : coupe a chaque trou de domaine ou saut d'asymptote.
  List<List<MapEntry<double, double>>> evaluateSegments(
    String expression,
    double xMin,
    double xMax,
    int points,
  ) {
    if (points < 2 || xMax <= xMin) return [];

    final step = (xMax - xMin) / (points - 1);
    final segments = <List<MapEntry<double, double>>>[];
    var current = <MapEntry<double, double>>[];

    MapEntry<double, double>? prev;

    for (var i = 0; i < points; i++) {
      final x = xMin + i * step;
      final y = _safeY(expression, x);

      if (!isPlottable(y)) {
        // Hors domaine → fermer le segment en cours
        if (current.length >= 2) segments.add(List.of(current));
        current = [];
        prev = null;
        continue;
      }

      final point = MapEntry(x, MathLibrary.clean(y!));

      if (prev != null) {
        final dx = point.key - prev.key;
        final dy = (point.value - prev.value).abs();
        // Trou (points manquants) ou asymptote (saut vertical)
        if (dx > step * 2.2 || dy > 50) {
          if (current.length >= 2) segments.add(List.of(current));
          current = [point];
        } else {
          current.add(point);
        }
      } else {
        current.add(point);
      }
      prev = point;
    }

    if (current.length >= 2) segments.add(current);
    return segments;
  }

  /// Restreint [xMin,xMax] au sous-ensemble ou f est definie au moins un peu.
  ({double xMin, double xMax}) clampToDomain(
    String expression,
    double xMin,
    double xMax, {
    int samples = 400,
  }) {
    final step = (xMax - xMin) / samples;
    double? first;
    double? last;
    for (var i = 0; i <= samples; i++) {
      final x = xMin + i * step;
      final y = _safeY(expression, x);
      if (isPlottable(y)) {
        first ??= x;
        last = x;
      }
    }
    if (first == null || last == null || last - first < step) {
      return (xMin: xMin, xMax: xMax);
    }
    final margin = (last - first) * 0.02;
    return (xMin: first - margin, xMax: last + margin);
  }
}
