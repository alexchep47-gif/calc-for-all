import 'dart:math' as math;

import 'graph_service.dart';
import 'math_expression_engine.dart';

class FunctionStudyResult {
  final String expression;
  final String domain;
  final String derivative;
  final String limits;
  final String period;
  final List<String> extrema;
  final List<String> asymptotes;
  final String variationTable;
  final String symmetry;
  final String explanations;
  final List<MapEntry<double, double>> samplePoints;

  FunctionStudyResult({
    required this.expression,
    required this.domain,
    required this.derivative,
    required this.limits,
    required this.period,
    required this.extrema,
    required this.asymptotes,
    required this.variationTable,
    required this.symmetry,
    required this.explanations,
    required this.samplePoints,
  });
}

class FunctionAnalysisService {
  final MathExpressionEngine _engine;
  final GraphService _graph;
  FunctionAnalysisService({MathExpressionEngine? engine})
      : _engine = engine ?? MathExpressionEngine(),
        _graph = GraphService(engine: engine ?? MathExpressionEngine());

  FunctionStudyResult analyze(
    String expression, {
    double xMin = -10,
    double xMax = 10,
  }) {
    final normalized = _engine.normalize(expression);
    final derivative =
        _engine.derivative(expression) ?? 'Non calculable automatiquement';
    final points = _graph.evaluateFunction(expression, xMin, xMax, 600);
    final domain = _domain(normalized);
    final extrema = _extrema(derivative, points);
    final asymptotes = _asymptotes(normalized, xMin, xMax);
    final limits = _limits(normalized, xMin, xMax, asymptotes);
    final period = _period(normalized);
    final symmetry = _symmetry(normalized);
    final variation = _variation(derivative, points);
    final explanations = _explanations(
      expression,
      domain,
      derivative,
      extrema,
      limits,
      asymptotes,
      period,
      symmetry,
    );
    return FunctionStudyResult(
      expression: expression,
      domain: domain,
      derivative: derivative,
      limits: limits,
      period: period,
      extrema: extrema,
      asymptotes: asymptotes,
      variationTable: variation,
      symmetry: symmetry,
      explanations: explanations,
      samplePoints: points,
    );
  }

  String _domain(String expr) {
    final log = RegExp(r'(?:log)\(([-+]?\d*\.?\d*)\*?x(?:([-+]\d*\.?\d+))?\)')
        .firstMatch(expr);
    if (log != null) {
      final a = _coefficient(log.group(1));
      final b = double.tryParse(log.group(2) ?? '0') ?? 0;
      if (a > 0)
        return 'D = ]${_fmt(-b / a)} ; +∞[ car ${_fmt(a)}x ${b >= 0 ? '+' : '−'} ${_fmt(b.abs())} > 0.';
      if (a < 0)
        return 'D = ]−∞ ; ${_fmt(-b / a)}[ car ${_fmt(a)}x ${b >= 0 ? '+' : '−'} ${_fmt(b.abs())} > 0.';
    }
    if (RegExp(r'log\(x\)').hasMatch(expr)) return 'D = ]0 ; +∞[ car x > 0.';
    final sqrt = RegExp(r'sqrt\(([-+]?\d*\.?\d*)\*?x(?:([-+]\d*\.?\d+))?\)')
        .firstMatch(expr);
    if (sqrt != null) {
      final a = _coefficient(sqrt.group(1));
      final b = double.tryParse(sqrt.group(2) ?? '0') ?? 0;
      return a >= 0
          ? 'D = [${_fmt(-b / a)} ; +∞[ car ${_fmt(a)}x + ${_fmt(b)} ≥ 0.'
          : 'D = ]−∞ ; ${_fmt(-b / a)}] car ${_fmt(a)}x + ${_fmt(b)} ≥ 0.';
    }
    if (expr.contains('/'))
      return 'D = R privé des zéros du dénominateur (à déterminer selon l’expression).';
    return 'D = R (aucune contrainte réelle détectée).';
  }

  double _coefficient(String? value) {
    if (value == null || value.isEmpty || value == '+') return 1;
    if (value == '-') return -1;
    return double.tryParse(value) ?? 1;
  }

  List<String> _extrema(
    String derivative,
    List<MapEntry<double, double>> points,
  ) {
    if (points.length < 3 || derivative.startsWith('Non'))
      return ['Racines de f′ non déterminées automatiquement.'];
    final result = <String>[];
    double? lastRoot;
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      final da = _engine.evaluate(derivative, a.key),
          db = _engine.evaluate(derivative, b.key);
      if (da == null || db == null || !da.isFinite || !db.isFinite) continue;
      if (da == 0 || da * db < 0) {
        final root = da == 0 ? a.key : (a.key + b.key) / 2;
        if (lastRoot != null && (root - lastRoot).abs() < 0.08) continue;
        final kind = da > 0 && db < 0 ? 'Maximum local' : 'Minimum local';
        result.add('$kind : f′(${_fmt(root)}) = 0 (changement de signe).');
        lastRoot = root;
        if (result.length >= 8) break;
      }
    }
    return result.isEmpty
        ? ['Aucune racine de f′ détectée sur l’intervalle étudié.']
        : result;
  }

  List<String> _asymptotes(String expr, double xMin, double xMax) {
    final result = <String>[];
    final log = RegExp(r'(?:log)\(([-+]?\d*\.?\d*)\*?x(?:([-+]\d*\.?\d+))?\)')
        .firstMatch(expr);
    if (log != null)
      result.add(
        'Verticale : x = ${_fmt(-(double.tryParse(log.group(2) ?? '0') ?? 0) / _coefficient(log.group(1)))}.',
      );
    if (RegExp(r'log\(x\)').hasMatch(expr)) result.add('Verticale : x = 0.');
    if (expr.contains('/'))
      result.add('Verticales possibles aux zéros du dénominateur.');
    final right = _engine.evaluate(expr, xMax),
        left = _engine.evaluate(expr, xMin);
    if (right != null && (right - xMax).abs() < 0.2)
      result.add('Oblique possible à droite : y ≈ x.');
    else if (right != null && right.abs() < 0.1)
      result.add('Horizontale à droite : y = 0.');
    if (left != null && left.abs() < 0.1)
      result.add('Horizontale à gauche : y = 0.');
    return result.isEmpty ? ['Aucune asymptote élémentaire détectée.'] : result;
  }

  String _limits(
    String expr,
    double xMin,
    double xMax,
    List<String> asymptotes,
  ) {
    final l = _engine.evaluate(expr, xMin), r = _engine.evaluate(expr, xMax);
    String value(double? v) =>
        v == null ? 'non définie' : (v.abs() > 1e6 ? '±∞' : _fmt(v));
    return 'Limite à gauche de l’intervalle : ${value(l)} ; limite à droite : ${value(r)}.\nLes limites aux bornes interdites sont indiquées par les asymptotes lorsqu’elles existent.';
  }

  String _period(String expr) {
    if (expr.contains('tan(x)')) return 'π (tangente).';
    if (expr.contains('sin(x)') || expr.contains('cos(x)')) return '2π.';
    return 'Non périodique détectée.';
  }

  String _symmetry(String expr) {
    final even = _compare(expr, expr.replaceAll('x', '(-x)'));
    final odd = _compare(expr, '-(${expr.replaceAll('x', '(-x)')})');
    if (even) return 'Paire : axe de symétrie (Oy).';
    if (odd) return 'Impaire : centre de symétrie (O).';
    return 'Aucune parité détectée automatiquement.';
  }

  bool _compare(String a, String b) {
    for (final x in [-3.0, -1.2, 0.7, 2.5]) {
      final av = _engine.evaluate(a, x), bv = _engine.evaluate(b, x);
      if (av == null || bv == null || (av - bv).abs() > 1e-5) return false;
    }
    return true;
  }

  String _variation(String derivative, List<MapEntry<double, double>> points) {
    if (points.length < 2)
      return 'Données insuffisantes pour le tableau de variation.';
    final rows = <String>[
      'x        | signe de f′ | variation',
      '---------|-------------|-----------',
    ];
    final step = math.max(1, (points.length / 10).round());
    for (var i = 0; i < points.length; i += step) {
      final p = points[i];
      final d = _engine.evaluate(derivative, p.key);
      final sign = d == null
          ? 'indéfini'
          : d.abs() < 1e-5
              ? '0'
              : d > 0
                  ? '+'
                  : '−';
      final direction = sign == '+'
          ? 'croissante'
          : sign == '−'
              ? 'décroissante'
              : 'à étudier';
      rows.add('${_fmt(p.key).padLeft(8)} | ${sign.padLeft(11)} | $direction');
    }
    return rows.join('\n');
  }

  String _explanations(
    String expression,
    String domain,
    String derivative,
    List<String> extrema,
    String limits,
    List<String> asymptotes,
    String period,
    String symmetry,
  ) =>
      '''Méthode hors-ligne :
1. Normalisation : les multiplications implicites sont explicitées (par exemple 2x devient 2*x) et ln est traité comme log naturel.
2. Domaine : on impose les contraintes réelles des logarithmes, racines et dénominateurs.
3. Dérivée : application récursive des règles de somme, produit, quotient, puissance et fonctions usuelles.

Fonction : f(x) = $expression
Domaine : $domain
Dérivée : f′(x) = $derivative
Racines de f′ et extremums : ${extrema.join(' ; ')}
Limites : $limits
Asymptotes : ${asymptotes.join(' ; ')}
Variation : le signe de f′ détermine les intervalles croissants et décroissants.
Périodicité : $period
Parité : $symmetry''';

  String _fmt(double value) => value.abs() < 1e-9
      ? '0'
      : value
          .toStringAsFixed(3)
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
}
