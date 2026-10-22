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

  /// Extrait le zero d'un denominateur lineaire ax+b ou (ax+b)
  double? _linearDenomZero(String expr) {
    // Cherche pattern / (ax+b) ou /ax+b
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
        // /x+b form group1 is b, a=1
        final g1 = m.group(1);
        if (g1 != null && (g1.startsWith('+') || g1.startsWith('-'))) {
          final b = double.tryParse(g1) ?? 0;
          return -b;
        }
        final a = _coefficient(g1);
        if (a != 0) return 0; // /ax  => x=0
      }
    }
    if (RegExp(r'/x(?![a-z0-9.])').hasMatch(expr) ||
        RegExp(r'/\(x\)').hasMatch(expr)) {
      return 0;
    }
    return null;
  }

  String _domain(String expr) {
    final log = RegExp(
      r'log\(([-+]?\d*\.?\d*)\*?x([-+]\d*\.?\d+)?\)',
    ).firstMatch(expr);
    if (log != null) {
      final a = _coefficient(log.group(1));
      final b = double.tryParse(log.group(2) ?? '0') ?? 0;
      final bound = -b / a;
      if (a > 0) {
        return 'D = ]${_fmt(bound)} ; +inf[  car ${_fmt(a)}x ${_sign(b)} ${_fmt(b.abs())} > 0.';
      }
      if (a < 0) {
        return 'D = ]-inf ; ${_fmt(bound)}[  car ${_fmt(a)}x ${_sign(b)} ${_fmt(b.abs())} > 0.';
      }
    }
    if (RegExp(r'log\(x\)').hasMatch(expr)) {
      return 'D = ]0 ; +inf[  car x > 0.';
    }

    final sqrt = RegExp(
      r'sqrt\(([-+]?\d*\.?\d*)\*?x([-+]\d*\.?\d+)?\)',
    ).firstMatch(expr);
    if (sqrt != null) {
      final a = _coefficient(sqrt.group(1));
      final b = double.tryParse(sqrt.group(2) ?? '0') ?? 0;
      final bound = -b / a;
      if (a > 0) {
        return 'D = [${_fmt(bound)} ; +inf[  car ${_fmt(a)}x ${_sign(b)} ${_fmt(b.abs())} >= 0.';
      }
      if (a < 0) {
        return 'D = ]-inf ; ${_fmt(bound)}]  car ${_fmt(a)}x ${_sign(b)} ${_fmt(b.abs())} >= 0.';
      }
    }

    final zero = _linearDenomZero(expr);
    if (zero != null) {
      return 'D = ]-inf ; ${_fmt(zero)}[ U ]${_fmt(zero)} ; +inf[  (denominateur nul en x = ${_fmt(zero)}).';
    }
    if (expr.contains('/')) {
      return 'D = R prive des zeros du denominateur.';
    }
    return 'D = R (aucune contrainte reelle detectee).';
  }

  String _sign(double b) => b >= 0 ? '+' : '-';

  double _coefficient(String? value) {
    if (value == null || value.isEmpty || value == '+') return 1;
    if (value == '-') return -1;
    return double.tryParse(value) ?? 1;
  }

  List<String> _extrema(
    String derivative,
    List<MapEntry<double, double>> points,
  ) {
    if (points.length < 3 || derivative.startsWith('Non')) {
      return ["Racines de f' non determinees automatiquement."];
    }
    final result = <String>[];
    double? lastRoot;
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      final da = _engine.evaluate(derivative, a.key);
      final db = _engine.evaluate(derivative, b.key);
      if (da == null || db == null || !da.isFinite || !db.isFinite) continue;
      if (da == 0 || da * db < 0) {
        final root = da == 0 ? a.key : (a.key + b.key) / 2;
        if (lastRoot != null && (root - lastRoot).abs() < 0.08) continue;
        final kind = da > 0 && db < 0 ? 'Maximum local' : 'Minimum local';
        result.add("$kind : f'(${_fmt(root)}) approx 0.");
        lastRoot = root;
        if (result.length >= 8) break;
      }
    }
    return result.isEmpty
        ? ["Aucune racine de f' detectee sur l intervalle etudie."]
        : result;
  }

  List<String> _asymptotes(String expr, double xMin, double xMax) {
    final result = <String>[];
    final log = RegExp(
      r'log\(([-+]?\d*\.?\d*)\*?x([-+]\d*\.?\d+)?\)',
    ).firstMatch(expr);
    if (log != null) {
      final a = _coefficient(log.group(1));
      final b = double.tryParse(log.group(2) ?? '0') ?? 0;
      result.add('Asymptote verticale : x = ${_fmt(-b / a)}.');
    }
    if (RegExp(r'log\(x\)').hasMatch(expr)) {
      result.add('Asymptote verticale : x = 0.');
    }
    final zero = _linearDenomZero(expr);
    if (zero != null) {
      result.add('Asymptote verticale : x = ${_fmt(zero)} (denominateur nul).');
    } else if (expr.contains('/')) {
      result.add('Verticales possibles aux zeros du denominateur.');
    }
    final right = _engine.evaluate(expr, xMax);
    final left = _engine.evaluate(expr, xMin);
    if (right != null && right.abs() < 0.1) {
      result.add('Asymptote horizontale a droite : y = 0.');
    }
    if (left != null && left.abs() < 0.1) {
      result.add('Asymptote horizontale a gauche : y = 0.');
    }
    // Quotient lineaire/lineaire -> asymptote y = a/c
    final quot = RegExp(
      r'\(([-+]?\d*\.?\d*)\*?x([-+]\d*\.?\d+)?\)/\(([-+]?\d*\.?\d*)\*?x([-+]\d*\.?\d+)?\)',
    ).firstMatch(expr);
    if (quot != null) {
      final a = _coefficient(quot.group(1));
      final c = _coefficient(quot.group(3));
      if (c != 0) {
        result.add(
            'Asymptote horizontale : y = ${_fmt(a / c)} (degres egaux).');
      }
    }
    return result.isEmpty
        ? ['Aucune asymptote elementaire detectee.']
        : result;
  }

  String _limits(
    String expr,
    double xMin,
    double xMax,
    List<String> asymptotes,
  ) {
    final l = _engine.evaluate(expr, xMin);
    final r = _engine.evaluate(expr, xMax);
    String value(double? v) {
      if (v == null) return 'non definie';
      if (v.abs() > 1e6) return '+/-inf';
      return _fmt(v);
    }

    return 'Limite pres de la borne gauche (x~${_fmt(xMin)}) : ${value(l)}\n'
        'Limite pres de la borne droite (x~${_fmt(xMax)}) : ${value(r)}\n'
        'Les asymptotes indiquent les comportements aux bornes interdites.';
  }

  String _period(String expr) {
    if (expr.contains('tan(x)')) return 'pi (tangente).';
    if (expr.contains('sin(x)') || expr.contains('cos(x)')) return '2pi.';
    return 'Non periodique detectee.';
  }

  String _symmetry(String expr) {
    final even = _compare(expr, expr.replaceAll('x', '(-x)'));
    final odd = _compare(expr, '-(${expr.replaceAll('x', '(-x)')})');
    if (even) return 'Paire : axe de symetrie (Oy).';
    if (odd) return 'Impaire : centre de symetrie (O).';
    return 'Aucune parite detectee automatiquement.';
  }

  bool _compare(String a, String b) {
    for (final x in [-3.0, -1.2, 0.7, 2.5]) {
      final av = _engine.evaluate(a, x);
      final bv = _engine.evaluate(b, x);
      if (av == null || bv == null || (av - bv).abs() > 1e-5) return false;
    }
    return true;
  }

  String _variation(String derivative, List<MapEntry<double, double>> points) {
    if (points.length < 2) {
      return 'Donnees insuffisantes pour le tableau de variation.';
    }
    final rows = <String>[
      "x        | signe de f' | variation",
      '---------|-------------|-----------',
    ];
    final step = math.max(1, (points.length / 10).round());
    for (var i = 0; i < points.length; i += step) {
      final p = points[i];
      final d = _engine.evaluate(derivative, p.key);
      final sign = d == null
          ? 'indet.'
          : d.abs() < 1e-5
              ? '0'
              : d > 0
                  ? '+'
                  : '-';
      final direction = sign == '+'
          ? 'croissante'
          : sign == '-'
              ? 'decroissante'
              : 'a etudier';
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
      '''Methode hors-ligne :
1. Normalisation : 2x devient 2*x ; ln / In devient log (logarithme naturel).
2. Domaine : contraintes des logarithmes, racines et denominateurs.
3. Derivee : regles de somme, produit, quotient, puissance et fonctions usuelles.

Fonction : f(x) = $expression
Domaine : $domain
Derivee : f'(x) = $derivative
Extremums : ${extrema.join(' ; ')}
Limites : $limits
Asymptotes : ${asymptotes.join(' ; ')}
Variation : le signe de f' determine les intervalles croissants et decroissants.
Periodicite : $period
Parite : $symmetry''';

  String _fmt(double value) {
    if (value.abs() < 1e-9) return '0';
    var s = value.toStringAsFixed(3);
    while (s.endsWith('0')) {
      s = s.substring(0, s.length - 1);
    }
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    return s;
  }
}
