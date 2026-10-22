import 'dart:math' as math;

import 'graph_service.dart';
import 'math_expression_engine.dart';
import 'math_library.dart';

class FunctionStudyResult {
  final String expression;
  final String domain;
  final String derivative;
  final String secondDerivative;
  final String limits;
  final String period;
  final List<String> roots;
  final List<String> intercepts;
  final List<String> extrema;
  final List<String> inflections;
  final List<String> asymptotes;
  final String variationTable;
  final String symmetry;
  final String explanations;
  final List<MapEntry<double, double>> samplePoints;
  final List<MapEntry<double, double>> remarkablePoints;

  FunctionStudyResult({
    required this.expression,
    required this.domain,
    required this.derivative,
    required this.secondDerivative,
    required this.limits,
    required this.period,
    required this.roots,
    required this.intercepts,
    required this.extrema,
    required this.inflections,
    required this.asymptotes,
    required this.variationTable,
    required this.symmetry,
    required this.explanations,
    required this.samplePoints,
    required this.remarkablePoints,
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
    final rawDerivative =
        _engine.derivative(expression) ?? 'Non calculable automatiquement';
    final derivative = rawDerivative.startsWith('Non')
        ? rawDerivative
        : (_engine.derivativePretty(expression) ?? rawDerivative);
    final rawSecondDeriv = rawDerivative.startsWith('Non')
        ? 'Non calculable'
        : (_engine.derivative(rawDerivative) ?? 'Non calculable');
    final secondDeriv = rawSecondDeriv.startsWith('Non')
        ? rawSecondDeriv
        : (_engine.derivativePretty(rawDerivative) ?? rawSecondDeriv);

    final points = _graph.evaluateFunction(expression, xMin, xMax, 800);
    final domain = _domain(normalized);

    final criticalXsRaw = _findZerosOf(rawDerivative, xMin, xMax);
    final criticalXs =
        criticalXsRaw.length > 6 ? criticalXsRaw.sublist(0, 6) : criticalXsRaw;
    final rootXsRaw = _findZerosOf(expression, xMin, xMax);
    final rootXs = rootXsRaw.length > 4 ? rootXsRaw.sublist(0, 4) : rootXsRaw;
    final inflectionXsRaw = rawSecondDeriv.startsWith('Non')
        ? <double>[]
        : _findZerosOf(rawSecondDeriv, xMin, xMax);
    final inflectionXs = inflectionXsRaw.length > 2
        ? inflectionXsRaw.sublist(0, 2)
        : inflectionXsRaw;

    final intercepts = _yIntercept(expression);
    final roots = rootXs.map((x) {
      final y = _engine.evaluate(expression, x);
      return 'Racine : (${_fmt(x)} ; ${_fmt(y ?? 0)})  [f(x)=0]';
    }).toList();
    if (roots.isEmpty) {
      roots.add('Aucune racine détectée sur [${_fmt(xMin)} ; ${_fmt(xMax)}].');
    }

    final extrema = <String>[];
    final remarkable = <MapEntry<double, double>>[];
    for (final x in criticalXs) {
      final y = _engine.evaluate(expression, x);
      if (y == null || !y.isFinite) continue;
      final kind = _classifyExtrema(rawDerivative, x);
      extrema.add('$kind en (${_fmt(x)} ; ${_fmt(y)})  [f\'=0]');
      remarkable.add(MapEntry(x, y));
    }
    if (extrema.isEmpty) {
      extrema.add("Aucun extremum (f'=0) détecté sur l'intervalle.");
    }

    final inflections = <String>[];
    for (final x in inflectionXs) {
      if (criticalXs.any((c) => (c - x).abs() < 0.05)) continue;
      final y = _engine.evaluate(expression, x);
      if (y == null || !y.isFinite) continue;
      if (!_concavityChanges(rawSecondDeriv, x)) continue;
      inflections.add('Inflexion en (${_fmt(x)} ; ${_fmt(y)})  [f\'\'=0]');
      // Pas ajouté aux points rouges pour alléger le graphe
    }
    if (inflections.isEmpty) {
      inflections.add("Aucun point d'inflexion détecté.");
    }

    final asymptotes = _asymptotes(normalized, xMin, xMax);
    final forbidden = _forbiddenXs(normalized);
    final limits = _limitsRemarkable(
        expression, xMin, xMax, forbidden, criticalXs);
    final variation = _variationTableEpure(
      expression: expression,
      derivative: rawDerivative,
      xMin: xMin,
      xMax: xMax,
      criticalXs: criticalXs,
      forbidden: forbidden,
    );
    final period = _period(normalized);
    final symmetry = _symmetry(normalized);

    final explanations = '''Étude par points remarquables (méthode épurée) :

1. Racines : résoudre f(x) = 0
2. Ordonnée à l'origine : f(0) si 0 ∈ D
3. Extrema : résoudre f′(x) = 0 puis étudier le signe de f′
4. Inflexion : résoudre f″(x) = 0 si changement de convexité
5. Tableau de variation : uniquement bornes du domaine + points critiques

Fonction : f(x) = $expression
Domaine : $domain
f'(x) = $derivative
f''(x) = $secondDeriv
''';

    return FunctionStudyResult(
      expression: expression,
      domain: domain,
      derivative: derivative,
      secondDerivative: secondDeriv,
      limits: limits,
      period: period,
      roots: roots,
      intercepts: intercepts,
      extrema: extrema,
      inflections: inflections,
      asymptotes: asymptotes,
      variationTable: variation,
      symmetry: symmetry,
      explanations: explanations,
      samplePoints: points,
      remarkablePoints: remarkable,
    );
  }

  List<double> _findZerosOf(String expr, double xMin, double xMax) {
    if (expr.startsWith('Non')) return [];
    final zeros = <double>[];
    const n = 500;
    final step = (xMax - xMin) / n;
    double? prevX;
    double? prevY;
    for (var i = 0; i <= n; i++) {
      final x = xMin + i * step;
      final y = _engine.evaluate(expr, x);
      if (y == null || !y.isFinite) {
        prevX = null;
        prevY = null;
        continue;
      }
      if (y.abs() < 1e-6) {
        if (zeros.isEmpty || (x - zeros.last).abs() > 0.08) zeros.add(x);
      } else if (prevY != null && prevX != null && prevY * y < 0) {
        var a = prevX, b = x, fa = prevY;
        for (var k = 0; k < 20; k++) {
          final m = (a + b) / 2;
          final fm = _engine.evaluate(expr, m);
          if (fm == null || !fm.isFinite) break;
          if (fa * fm <= 0) {
            b = m;
          } else {
            a = m;
            fa = fm;
          }
        }
        final root = (a + b) / 2;
        if (zeros.isEmpty || (root - zeros.last).abs() > 0.08) zeros.add(root);
      }
      prevX = x;
      prevY = y;
    }
    return zeros;
  }

  String _classifyExtrema(String derivative, double x) {
    final left = _engine.evaluate(derivative, x - 0.05);
    final right = _engine.evaluate(derivative, x + 0.05);
    if (left == null || right == null) return 'Point critique';
    if (left > 0 && right < 0) return 'Maximum local';
    if (left < 0 && right > 0) return 'Minimum local';
    return 'Point critique (palier ou inflexion horizontale)';
  }

  bool _concavityChanges(String secondDeriv, double x) {
    final left = _engine.evaluate(secondDeriv, x - 0.08);
    final right = _engine.evaluate(secondDeriv, x + 0.08);
    if (left == null || right == null) return false;
    return left * right < 0;
  }

  List<String> _yIntercept(String expression) {
    final y = _engine.evaluate(expression, 0);
    if (y == null || !y.isFinite) {
      return ["x = 0 hors domaine (pas d'ordonnée à l'origine)."];
    }
    return ['Intersection (OY) : (0 ; ${_fmt(y)})  [f(0)]'];
  }

  List<double> _forbiddenXs(String expr) {
    final xs = <double>[];
    final zero = _linearDenomZero(expr);
    if (zero != null) xs.add(zero);
    final lb = _logBound(expr);
    if (lb != null) xs.add(lb.bound);
    return xs;
  }

  String _variationTableEpure({
    required String expression,
    required String derivative,
    required double xMin,
    required double xMax,
    required List<double> criticalXs,
    required List<double> forbidden,
  }) {
    final keys = <double>{};
    for (final c in criticalXs) {
      if (c > xMin && c < xMax) keys.add(c);
    }
    final sorted = keys.toList()..sort();
    final headers = <String>['-∞'];
    for (final x in sorted) {
      headers.add(_fmt(x));
    }
    headers.add('+∞');

    final allPoints = <double>[xMin, ...sorted, xMax];
    final signs = <String>[];
    final variations = <String>[];
    for (var i = 0; i < allPoints.length - 1; i++) {
      final a = allPoints[i];
      final b = allPoints[i + 1];
      final hole = forbidden.where((f) => f > a && f < b).toList();
      final mid = hole.isEmpty ? (a + b) / 2 : (a + hole.first) / 2;
      final d = _engine.evaluate(derivative, mid);
      if (d == null || !d.isFinite) {
        signs.add('∥');
        variations.add('∥');
      } else if (d.abs() < 1e-7) {
        signs.add('0');
        variations.add('→');
      } else if (d > 0) {
        signs.add('+');
        variations.add('↗');
      } else {
        signs.add('-');
        variations.add('↘');
      }
    }

    final values = <String>[_limitStr(expression, xMin, left: true)];
    for (final x in sorted) {
      final y = _engine.evaluate(expression, x);
      final kind = _classifyExtrema(derivative, x);
      final tag = kind.startsWith('Max')
          ? 'Max'
          : kind.startsWith('Min')
              ? 'Min'
              : '';
      values.add(y == null ? '?' : '${_fmt(y)}${tag.isEmpty ? '' : ' ($tag)'}');
    }
    values.add(_limitStr(expression, xMax, left: false));

    final buf = StringBuffer();
    buf.writeln('Tableau de variation (points remarquables uniquement)');
    buf.writeln('x     | ${headers.join('  |  ')}');
    buf.writeln('f     | ${values.join('  |  ')}');
    buf.writeln('');
    buf.writeln('Forme compacte :');
    final compact = StringBuffer('x : -∞');
    for (final x in sorted) {
      compact.write('   ${_fmt(x)}');
    }
    compact.write('   +∞');
    buf.writeln(compact.toString());
    final frow = StringBuffer('f : ${values.first}');
    for (var i = 0; i < variations.length; i++) {
      frow.write('  ${variations[i]}  ');
      if (i + 1 < values.length) frow.write(values[i + 1]);
    }
    buf.writeln(frow.toString());
    if (forbidden.isNotEmpty) {
      buf.writeln(
          'Valeurs interdites : ${forbidden.map(_fmt).join(', ')}');
    }
    return buf.toString();
  }

  String _limitStr(String expression, double x, {required bool left}) {
    final eps = left ? 0.01 : -0.01;
    final y = _engine.evaluate(expression, x + eps);
    if (y == null) return '∥';
    if (y.abs() > 1e5) return y > 0 ? '+∞' : '-∞';
    return _fmt(y);
  }

  String _limitsRemarkable(
    String expression,
    double xMin,
    double xMax,
    List<double> forbidden,
    List<double> critical,
  ) {
    final lines = <String>[];
    lines.add(
        'Limite à gauche (x→${_fmt(xMin)}) : ${_limitStr(expression, xMin, left: true)}');
    lines.add(
        'Limite à droite (x→${_fmt(xMax)}) : ${_limitStr(expression, xMax, left: false)}');
    for (final f in forbidden) {
      final yl = _engine.evaluate(expression, f - 0.01);
      final yr = _engine.evaluate(expression, f + 0.01);
      String side(double? v) {
        if (v == null) return 'indet.';
        if (v.abs() > 1e5) return v > 0 ? '+∞' : '-∞';
        return _fmt(v);
      }

      lines.add(
          'En x→${_fmt(f)} (interdit) : gauche ${side(yl)} | droite ${side(yr)}');
    }
    for (final x in critical) {
      final y = _engine.evaluate(expression, x);
      if (y != null) {
        lines.add('f(${_fmt(x)}) = ${_fmt(y)}  (point critique)');
      }
    }
    return lines.join('\n');
  }

  double? _linearDenomZero(String expr) {
    if (RegExp(r'/x(?![a-z0-9.])').hasMatch(expr) ||
        RegExp(r'/\(x\)').hasMatch(expr)) {
      return 0;
    }
    return null;
  }

  ({double bound, bool greater})? _logBound(String expr) {
    if (RegExp(r'log\(x\)|ln\(x\)').hasMatch(expr)) {
      return (bound: 0, greater: true);
    }
    return null;
  }

  String _domain(String expr) {
    final parts = <String>[];
    final lb = _logBound(expr);
    if (lb != null) {
      parts.add(lb.greater ? 'x > ${_fmt(lb.bound)}' : 'x < ${_fmt(lb.bound)}');
    }
    final zero = _linearDenomZero(expr);
    if (zero != null) parts.add('x ≠ ${_fmt(zero)}');
    if (parts.isEmpty) {
      return expr.contains('/')
          ? 'D = ℝ privé des zéros du dénominateur.'
          : 'D = ℝ';
    }
    return 'D : ${parts.join(' ; ')}';
  }

  List<String> _asymptotes(String expr, double xMin, double xMax) {
    final result = <String>[];
    final lb = _logBound(expr);
    if (lb != null) result.add('Asymptote verticale : x = ${_fmt(lb.bound)}');
    final zero = _linearDenomZero(expr);
    if (zero != null) result.add('Asymptote verticale : x = ${_fmt(zero)}');
    return result.isEmpty ? ['Aucune asymptote élémentaire détectée.'] : result;
  }

  String _period(String expr) {
    if (expr.contains('tan(x)')) return 'π (tangente)';
    if (expr.contains('sin(x)') || expr.contains('cos(x)')) return '2π';
    return 'Non périodique détectée';
  }

  String _symmetry(String expr) {
    final even = _compare(expr, expr.replaceAll('x', '(-x)'));
    final odd = _compare(expr, '-(${expr.replaceAll('x', '(-x)')})');
    if (even) return 'Paire : axe de symétrie (Oy)';
    if (odd) return 'Impaire : centre de symétrie (O)';
    return 'Aucune parité détectée';
  }

  bool _compare(String a, String b) {
    for (final x in [-3.0, -1.2, 0.7, 2.5]) {
      final av = _engine.evaluate(a, x);
      final bv = _engine.evaluate(b, x);
      if (av == null || bv == null || (av - bv).abs() > 1e-5) return false;
    }
    return true;
  }

  String _fmt(double value) {
    if (value.abs() < 1e-9) return '0';
    if ((value - MathLibrary.e).abs() < 0.01) return 'e';
    final pi = math.pi;
    final candidates = <MapEntry<double, String>>[
      MapEntry(pi / 6, 'π/6'),
      MapEntry(pi / 4, 'π/4'),
      MapEntry(pi / 3, 'π/3'),
      MapEntry(pi / 2, 'π/2'),
      MapEntry(2 * pi / 3, '2π/3'),
      MapEntry(3 * pi / 4, '3π/4'),
      MapEntry(5 * pi / 6, '5π/6'),
      MapEntry(pi, 'π'),
      MapEntry(7 * pi / 6, '7π/6'),
      MapEntry(5 * pi / 4, '5π/4'),
      MapEntry(4 * pi / 3, '4π/3'),
      MapEntry(3 * pi / 2, '3π/2'),
      MapEntry(5 * pi / 3, '5π/3'),
      MapEntry(7 * pi / 4, '7π/4'),
      MapEntry(11 * pi / 6, '11π/6'),
      MapEntry(2 * pi, '2π'),
    ];
    for (final c in candidates) {
      if ((value - c.key).abs() < 0.02) return c.value;
      if ((value + c.key).abs() < 0.02) return '-${c.value}';
    }
    for (var q = 2; q <= 12; q++) {
      for (var p = -24; p <= 24; p++) {
        if (p == 0) continue;
        if ((value - p / q).abs() < 1e-4) return '$p/$q';
      }
    }
    return MathLibrary.format(value);
  }
}
