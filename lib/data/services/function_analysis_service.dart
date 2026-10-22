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

    // ——— Points remarquables uniquement ———
    final criticalXs = _findZerosOf(rawDerivative, xMin, xMax);
    final rootXs = _findZerosOf(expression, xMin, xMax);
    final inflectionXs = rawSecondDeriv.startsWith('Non')
        ? <double>[]
        : _findZerosOf(rawSecondDeriv, xMin, xMax);

    final intercepts = _yIntercept(expression);
    final roots = rootXs.map((x) {
      final y = _engine.evaluate(expression, x);
      return 'Racine : (${_fmt(x)} ; ${_fmt(y ?? 0)})  [f(x)=0]';
    }).toList();
    if (roots.isEmpty) {
      roots.add('Aucune racine detectee sur [${_fmt(xMin)} ; ${_fmt(xMax)}].');
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
      extrema.add("Aucun extremum (f'=0) detecte sur l'intervalle.");
    }

    final inflections = <String>[];
    for (final x in inflectionXs) {
      // Eviter de confondre avec extrema
      if (criticalXs.any((c) => (c - x).abs() < 0.05)) continue;
      final y = _engine.evaluate(expression, x);
      if (y == null || !y.isFinite) continue;
      if (!_concavityChanges(rawSecondDeriv, x)) continue;
      inflections.add('Inflexion en (${_fmt(x)} ; ${_fmt(y)})  [f\'\'=0]');
      remarkable.add(MapEntry(x, y));
    }
    if (inflections.isEmpty) {
      inflections.add('Aucun point d\'inflexion detecte.');
    }

    // Bornes interdites / asymptotes
    final asymptotes = _asymptotes(normalized, xMin, xMax);
    final forbidden = _forbiddenXs(normalized);

    final limits = _limitsRemarkable(
      expression,
      xMin,
      xMax,
      forbidden,
      criticalXs,
    );

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

  /// Cherche les zeros numeriques d'une expression sur [xMin, xMax]
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
        if (zeros.isEmpty || (x - zeros.last).abs() > 0.08) {
          zeros.add(x);
        }
      } else if (prevY != null && prevX != null && prevY * y < 0) {
        // Dichotomie
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
        if (zeros.isEmpty || (root - zeros.last).abs() > 0.08) {
          zeros.add(root);
        }
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
      return ['x = 0 hors domaine (pas d\'ordonnee a l\'origine).'];
    }
    return ['Intersection (OY) : (0 ; ${_fmt(y)})  [f(0)]'];
  }

  List<double> _forbiddenXs(String expr) {
    final xs = <double>[];
    final zero = _linearDenomZero(expr);
    if (zero != null) xs.add(zero);
    final lb = _logBound(expr);
    if (lb != null) xs.add(lb.bound);
    final logDenom = RegExp(
      r'/\(?log\(\s*x\s*([+-])\s*(e|pi|\d*\.?\d+)\s*\)\)?',
    ).firstMatch(expr);
    if (logDenom != null) {
      final sign = logDenom.group(1) == '-' ? -1.0 : 1.0;
      final c = _constVal(logDenom.group(2)!);
      xs.add(1 - sign * c);
    }
    return xs;
  }

  /// Tableau epure : bornes + points critiques seulement
  String _variationTableEpure({
    required String expression,
    required String derivative,
    required double xMin,
    required double xMax,
    required List<double> criticalXs,
    required List<double> forbidden,
  }) {
    // Colonnes : -∞ / xMin, critiques tries, +∞ / xMax, sans les interdits
    final keys = <double>{};
    for (final c in criticalXs) {
      if (c > xMin && c < xMax) keys.add(c);
    }
    final sorted = keys.toList()..sort();

    // Construire les labels de colonnes
    final headers = <String>['-∞'];
    final colXs = <double?>[null]; // null = borne gauche
    for (final f in forbidden) {
      if (f > xMin && f < xMax) {
        // On inserera une double barre au moment du rendu
      }
    }
    for (final x in sorted) {
      headers.add(_fmt(x));
      colXs.add(x);
    }
    headers.add('+∞');
    colXs.add(null);

    // Signe de f' entre les points
    final signs = <String>[];
    final variations = <String>[];
    final values = <String>[];

    // Intervalle gauche -> premier critique (ou +∞)
    final allPoints = <double>[xMin, ...sorted, xMax];
    for (var i = 0; i < allPoints.length - 1; i++) {
      final a = allPoints[i];
      final b = allPoints[i + 1];
      // Sauter si une asymptote verticale est entre a et b
      final hole = forbidden.where((f) => f > a && f < b).toList();
      final mid = hole.isEmpty ? (a + b) / 2 : (a + hole.first) / 2;
      final d = _engine.evaluate(derivative, mid);
      String sign;
      String arrow;
      if (d == null || !d.isFinite) {
        sign = '∥';
        arrow = '∥';
      } else if (d.abs() < 1e-7) {
        sign = '0';
        arrow = '→';
      } else if (d > 0) {
        sign = '+';
        arrow = '↗';
      } else {
        sign = '-';
        arrow = '↘';
      }
      signs.add(sign);
      variations.add(arrow);
    }

    // Images aux points critiques + limites aux bornes
    values.add(_limitStr(expression, xMin, left: true));
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

    // Rendu texte type tableau
    final buf = StringBuffer();
    buf.writeln('Tableau de variation (points remarquables uniquement)');
    buf.writeln('');
    buf.writeln('x     | ${headers.join('  |  ')}');
    buf.writeln('------|${List.filled(headers.length, '------').join('|')}');

    // Ligne f'
    final signRow = <String>['f\''];
    for (var i = 0; i < signs.length; i++) {
      signRow.add(signs[i]);
      if (i < sorted.length) signRow.add('0');
    }
    // Ajustement : pattern  f' |  +  | 0 | - | 0 | +
    final signCells = <String>[];
    for (var i = 0; i < signs.length; i++) {
      signCells.add(' ${signs[i]} ');
      if (i < sorted.length) signCells.add(' 0 ');
    }
    buf.writeln("f'    |${signCells.join('|')}");

    // Ligne variation
    final varCells = <String>[];
    for (var i = 0; i < variations.length; i++) {
      varCells.add(' ${variations[i]} ');
      if (i < values.length && i < sorted.length + 1) {
        // valeur au point apres la fleche interpolee autrement
      }
    }
    // Mieux : afficher valeurs aux bornes et critiques
    buf.writeln('f     | ${values.join('  |  ')}');
    buf.writeln('');
    buf.writeln(
        'Lecture : seules les bornes (±∞ / domaine) et les x où f′ = 0');
    buf.writeln('figurent dans le tableau (méthode épurée type sujet).');

    // Version compacte ASCII plus lisible
    buf.writeln('');
    buf.writeln('--- Forme compacte ---');
    final compact = StringBuffer('x : ');
    compact.write('-∞');
    for (final x in sorted) {
      compact.write('   ${_fmt(x)}');
    }
    compact.write('   +∞');
    buf.writeln(compact.toString());

    final frow = StringBuffer('f : ');
    frow.write(values.first);
    for (var i = 0; i < variations.length; i++) {
      frow.write('  ${variations[i]}  ');
      if (i + 1 < values.length) frow.write(values[i + 1]);
    }
    buf.writeln(frow.toString());

    if (forbidden.isNotEmpty) {
      buf.writeln(
          'Valeurs interdites (asymptotes) : ${forbidden.map(_fmt).join(', ')}');
    }

    return buf.toString();
  }

  String _limitStr(String expression, double x, {required bool left}) {
    // Approche de la borne depuis l'interieur
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
        'Limite a gauche (x→${_fmt(xMin)}) : ${_limitStr(expression, xMin, left: true)}');
    lines.add(
        'Limite a droite (x→${_fmt(xMax)}) : ${_limitStr(expression, xMax, left: false)}');
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

  // ——— domaine / asymptotes (existant ameliore) ———

  double? _linearDenomZero(String expr) {
    final patterns = [
      RegExp(r'/\(([-+]?\d*\.?\d*)\*?x([-+]\d*\.?\d+)\)'),
      RegExp(r'/\(x([-+]\d*\.?\d+)\)'),
      RegExp(r'/\(([-+]?\d+)x\)'),
      RegExp(r'/x([-+]\d*\.?\d+)'),
      RegExp(r'/\(([-+]?\d*\.?\d*)\*?x\)'),
    ];
    for (final re in patterns) {
      final m = re.firstMatch(expr);
      if (m == null) continue;
      if (m.groupCount >= 2 && m.group(2) != null) {
        final a = _coefficient(m.group(1));
        final b = double.tryParse(m.group(2)!) ?? 0;
        if (a != 0) return -b / a;
      } else if (m.groupCount >= 1) {
        final g1 = m.group(1);
        if (g1 != null && (g1.startsWith('+') || g1.startsWith('-'))) {
          return -(double.tryParse(g1) ?? 0);
        }
        final a = _coefficient(g1);
        if (a != 0) return 0;
      }
    }
    if (RegExp(r'/x(?![a-z0-9.])').hasMatch(expr) ||
        RegExp(r'/\(x\)').hasMatch(expr)) {
      return 0;
    }
    return null;
  }

  ({double bound, bool greater})? _logBound(String expr) {
    final m = RegExp(
      r'log\(\s*x\s*([+-])\s*(e|pi|\d*\.?\d+)\s*\)',
    ).firstMatch(expr);
    if (m != null) {
      final sign = m.group(1) == '-' ? -1.0 : 1.0;
      final c = _constVal(m.group(2)!);
      return (bound: -sign * c, greater: true);
    }
    final logLin = RegExp(
      r'log\(([-+]?\d*\.?\d*)\*?x([-+]\d*\.?\d+)?\)',
    ).firstMatch(expr);
    if (logLin != null) {
      final a = _coefficient(logLin.group(1));
      final b = double.tryParse(logLin.group(2) ?? '0') ?? 0;
      if (a > 0) return (bound: -b / a, greater: true);
      if (a < 0) return (bound: -b / a, greater: false);
    }
    if (RegExp(r'log\(x\)').hasMatch(expr)) {
      return (bound: 0, greater: true);
    }
    return null;
  }

  double _constVal(String s) {
    if (s == 'e') return MathLibrary.e;
    if (s == 'pi') return MathLibrary.pi;
    return double.tryParse(s) ?? 0;
  }

  String _domain(String expr) {
    final parts = <String>[];
    final lb = _logBound(expr);
    if (lb != null) {
      parts.add(lb.greater ? 'x > ${_fmt(lb.bound)}' : 'x < ${_fmt(lb.bound)}');
    }
    final sqrt = RegExp(
      r'sqrt\(([-+]?\d*\.?\d*)\*?x([-+]\d*\.?\d+)?\)',
    ).firstMatch(expr);
    if (sqrt != null) {
      final a = _coefficient(sqrt.group(1));
      final b = double.tryParse(sqrt.group(2) ?? '0') ?? 0;
      final bound = -b / a;
      if (a > 0) parts.add('x ≥ ${_fmt(bound)}');
      if (a < 0) parts.add('x ≤ ${_fmt(bound)}');
    }
    final zero = _linearDenomZero(expr);
    if (zero != null) parts.add('x ≠ ${_fmt(zero)}');
    final logDenom = RegExp(
      r'/\(?log\(\s*x\s*([+-])\s*(e|pi|\d*\.?\d+)\s*\)\)?',
    ).firstMatch(expr);
    if (logDenom != null) {
      final sign = logDenom.group(1) == '-' ? -1.0 : 1.0;
      final c = _constVal(logDenom.group(2)!);
      parts.add('x ≠ ${_fmt(1 - sign * c)} (ln=0)');
    }
    if (parts.isEmpty) {
      return expr.contains('/')
          ? 'D = ℝ privé des zéros du dénominateur.'
          : 'D = ℝ';
    }
    return 'D : ${parts.join(' ; ')}';
  }

  double _coefficient(String? value) {
    if (value == null || value.isEmpty || value == '+') return 1;
    if (value == '-') return -1;
    return double.tryParse(value) ?? 1;
  }

  List<String> _asymptotes(String expr, double xMin, double xMax) {
    final result = <String>[];
    final lb = _logBound(expr);
    if (lb != null) {
      result.add('Asymptote verticale : x = ${_fmt(lb.bound)}');
    }
    final zero = _linearDenomZero(expr);
    if (zero != null) {
      result.add('Asymptote verticale : x = ${_fmt(zero)}');
    }
    final logDenom = RegExp(
      r'/\(?log\(\s*x\s*([+-])\s*(e|pi|\d*\.?\d+)\s*\)\)?',
    ).firstMatch(expr);
    if (logDenom != null) {
      final sign = logDenom.group(1) == '-' ? -1.0 : 1.0;
      final c = _constVal(logDenom.group(2)!);
      result.add('Asymptote verticale : x = ${_fmt(1 - sign * c)}');
    }
    final right = _engine.evaluate(expr, xMax);
    final left = _engine.evaluate(expr, xMin);
    if (right != null && right.abs() < 0.15) {
      result.add('Asymptote horizontale à droite : y ≈ 0');
    }
    if (left != null && left.abs() < 0.15) {
      result.add('Asymptote horizontale à gauche : y ≈ 0');
    }
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
    if ((value - (MathLibrary.e + 1)).abs() < 0.01) return 'e+1';
    if ((value - math.pi).abs() < 0.01) return 'π';
    if ((value + math.pi).abs() < 0.01) return '-π';
    return MathLibrary.format(value);
  }
}
