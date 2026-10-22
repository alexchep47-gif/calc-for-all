import 'dart:math' as math;

import 'graph_service.dart';
import 'math_expression_engine.dart';
import 'math_library.dart';

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
          final b = double.tryParse(g1) ?? 0;
          return -b;
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

  /// Bound pour log(x ± c) avec c = e, pi ou nombre
  ({double bound, bool greater})? _logBound(String expr) {
    final m = RegExp(
      r'log\(\s*x\s*([+-])\s*(e|pi|\d*\.?\d+)\s*\)',
    ).firstMatch(expr);
    if (m != null) {
      final sign = m.group(1) == '-' ? -1.0 : 1.0;
      final c = _constVal(m.group(2)!);
      // x + sign*c > 0 => x > -sign*c
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
      if (lb.greater) {
        parts.add('x > ${_fmt(lb.bound)} (argument du log > 0)');
      } else {
        parts.add('x < ${_fmt(lb.bound)} (argument du log > 0)');
      }
    }

    final sqrt = RegExp(
      r'sqrt\(([-+]?\d*\.?\d*)\*?x([-+]\d*\.?\d+)?\)',
    ).firstMatch(expr);
    if (sqrt != null) {
      final a = _coefficient(sqrt.group(1));
      final b = double.tryParse(sqrt.group(2) ?? '0') ?? 0;
      final bound = -b / a;
      if (a > 0) {
        parts.add('x >= ${_fmt(bound)} (racine)');
      } else if (a < 0) {
        parts.add('x <= ${_fmt(bound)} (racine)');
      }
    }

    final zero = _linearDenomZero(expr);
    if (zero != null) {
      parts.add('x != ${_fmt(zero)} (denominateur lineaire nul)');
    }

    // Denom = log(...) : log != 0 => argument != 1
    final logDenom = RegExp(
      r'/\(?log\(\s*x\s*([+-])\s*(e|pi|\d*\.?\d+)\s*\)\)?',
    ).firstMatch(expr);
    if (logDenom != null) {
      final sign = logDenom.group(1) == '-' ? -1.0 : 1.0;
      final c = _constVal(logDenom.group(2)!);
      // log(x+sign*c)=0 => x+sign*c=1 => x = 1 - sign*c
      final hole = 1 - sign * c;
      parts.add('x != ${_fmt(hole)} (log = 0 => denominateur nul)');
    }

    if (parts.isEmpty) {
      if (expr.contains('/')) {
        return 'D = R prive des zeros du denominateur.';
      }
      return 'D = R (aucune contrainte reelle detectee).';
    }
    return 'D : ${parts.join(' ; ')}.';
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
    final lb = _logBound(expr);
    if (lb != null) {
      result.add('Asymptote verticale : x = ${_fmt(lb.bound)} (bord du log).');
    }
    final zero = _linearDenomZero(expr);
    if (zero != null) {
      result.add('Asymptote verticale : x = ${_fmt(zero)} (denominateur nul).');
    }
    final logDenom = RegExp(
      r'/\(?log\(\s*x\s*([+-])\s*(e|pi|\d*\.?\d+)\s*\)\)?',
    ).firstMatch(expr);
    if (logDenom != null) {
      final sign = logDenom.group(1) == '-' ? -1.0 : 1.0;
      final c = _constVal(logDenom.group(2)!);
      final hole = 1 - sign * c;
      result.add(
          'Asymptote verticale : x = ${_fmt(hole)} (ln = 0, denominateur nul).');
    }
    if (result.isEmpty && expr.contains('/')) {
      result.add('Verticales possibles aux zeros du denominateur.');
    }
    final right = _engine.evaluate(expr, xMax);
    final left = _engine.evaluate(expr, xMin);
    if (right != null && right.abs() < 0.15) {
      result.add('Asymptote horizontale a droite : y ≈ 0.');
    }
    if (left != null && left.abs() < 0.15) {
      result.add('Asymptote horizontale a gauche : y ≈ 0.');
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
      '''Methode hors-ligne (MathLibrary) :
1. Normalisation : 2x → 2*x ; ln/In → log ; π → pi ; e reconnu.
2. Domaine : log, racines, denominateurs (y compris ln = 0).
3. Derivee symbolique : somme, produit, quotient, puissance, fonctions usuelles.

Fonction : f(x) = $expression
Domaine : $domain
Derivee : f'(x) = $derivative
Extremums : ${extrema.join(' ; ')}
Limites : $limits
Asymptotes : ${asymptotes.join(' ; ')}
Variation : signe de f'
Periodicite : $period
Parite : $symmetry''';

  String _fmt(double value) {
    if (value.abs() < 1e-9) return '0';
    // Afficher e si proche
    if ((value - MathLibrary.e).abs() < 0.01) return 'e';
    if ((value - (MathLibrary.e + 1)).abs() < 0.01) return 'e+1';
    var s = value.toStringAsFixed(3);
    while (s.endsWith('0')) {
      s = s.substring(0, s.length - 1);
    }
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    return s;
  }
}
