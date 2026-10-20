import 'dart:math' as math;
import 'package:math_expressions/math_expressions.dart';

class FunctionStudyResult {
  final String expression;
  final String domain;
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
  final Parser _parser = Parser();

  FunctionStudyResult analyze(String expression, {double xMin = -10, double xMax = 10}) {
    final expr = _normalize(expression);

    // Ajuster l'intervalle si log/ln détecté
    var range = _suggestRange(expr, xMin, xMax);
    var points = _sample(expr, range.$1, range.$2, 400);

    // Si trop peu de points, élargir vers la droite
    if (points.length < 20 && (expr.contains('ln') || expr.contains('log'))) {
      range = (range.$1, range.$2 + 20);
      points = _sample(expr, range.$1, range.$2, 400);
    }

    final domain = _estimateDomain(expr, points);
    final period = _detectPeriod(expr);
    final extrema = _findExtrema(points);
    final asymptotes = _findAsymptotes(expr, points, range.$1, range.$2);
    final variation = _buildVariationTable(points);
    final symmetry = _detectSymmetry(expr, points);
    final explanations = _buildExplanations(expression, domain, period, extrema, asymptotes, symmetry);

    return FunctionStudyResult(
      expression: expression,
      domain: domain,
      period: period,
      extrema: extrema,
      asymptotes: asymptotes,
      variationTable: variation,
      symmetry: symmetry,
      explanations: explanations,
      samplePoints: points,
    );
  }

  String _normalize(String e) {
    return e
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll('π', 'pi')
        .replaceAll('√', 'sqrt')
        .replaceAll('²', '^2')
        .replaceAll('³', '^3')
        .replaceAll(' ', '');
  }

  /// Suggère un intervalle adapté (surtout pour ln/log)
  (double, double) _suggestRange(String expr, double xMin, double xMax) {
    final lower = expr.toLowerCase();
    if (lower.contains('ln') || lower.contains('log')) {
      // Chercher pattern ln(ax+b) ou log(ax+b)
      final match = RegExp(r'(?:ln|log)\s*\(\s*([+-]?\d*\.?\d*)\s*\*?\s*x\s*([+-]\s*\d*\.?\d*)?\s*\)').firstMatch(expr);
      if (match != null) {
        final aStr = match.group(1);
        final bStr = match.group(2)?.replaceAll(' ', '') ?? '0';
        final a = (aStr == null || aStr.isEmpty || aStr == '+') ? 1.0 : (aStr == '-' ? -1.0 : double.tryParse(aStr) ?? 1.0);
        final b = double.tryParse(bStr) ?? 0.0;
        // ax + b > 0  =>  x > -b/a  (si a > 0)
        if (a > 0) {
          final bound = -b / a;
          return (bound + 0.01, math.max(xMax, bound + 10));
        } else if (a < 0) {
          final bound = -b / a;
          return (math.min(xMin, bound - 10), bound - 0.01);
        }
      }
      // ln(x) simple
      if (RegExp(r'(?:ln|log)\s*\(\s*x\s*\)').hasMatch(expr)) {
        return (0.01, math.max(xMax, 10));
      }
    }
    return (xMin, xMax);
  }

  List<MapEntry<double, double>> _sample(String expr, double xMin, double xMax, int n) {
    final result = <MapEntry<double, double>>[];
    try {
      final exp = _parser.parse(expr);
      final ctx = ContextModel();
      final step = (xMax - xMin) / (n - 1);
      for (int i = 0; i < n; i++) {
        final x = xMin + i * step;
        try {
          ctx.bindVariableName('x', Number(x));
          final y = exp.evaluate(EvaluationType.REAL, ctx);
          if (y is num && y.isFinite) {
            result.add(MapEntry(x, y.toDouble()));
          }
        } catch (_) {}
      }
    } catch (_) {}
    return result;
  }

  String _estimateDomain(String expr, List<MapEntry<double, double>> points) {
    final lower = expr.toLowerCase();

    // ln(ax+b)
    final lnMatch = RegExp(r'(?:ln|log)\s*\(\s*([+-]?\d*\.?\d*)\s*\*?\s*x\s*([+-]\s*\d*\.?\d*)?\s*\)').firstMatch(expr);
    if (lnMatch != null) {
      final aStr = lnMatch.group(1);
      final bStr = lnMatch.group(2)?.replaceAll(' ', '') ?? '0';
      final a = (aStr == null || aStr.isEmpty || aStr == '+') ? 1.0 : (aStr == '-' ? -1.0 : double.tryParse(aStr) ?? 1.0);
      final b = double.tryParse(bStr) ?? 0.0;
      if (a > 0) {
        final bound = -b / a;
        return 'x > ${bound.toStringAsFixed(2)}   (car  ${a == 1 ? '' : a.toStringAsFixed(0)}x ${b >= 0 ? '+' : ''}${b.toStringAsFixed(2)} > 0)';
      } else if (a < 0) {
        final bound = -b / a;
        return 'x < ${bound.toStringAsFixed(2)}';
      }
    }
    if (RegExp(r'(?:ln|log)\s*\(\s*x\s*\)').hasMatch(lower)) {
      return 'x > 0';
    }
    if (lower.contains('sqrt')) {
      return 'Domaine restreint (expression sous racine ≥ 0)';
    }
    if (expr.contains('/')) {
      return 'R privé des racines du dénominateur';
    }
    if (points.length > 50) return 'R (ou large intervalle testé)';
    return 'Domaine partiel sur l intervalle etudie';
  }

  String _detectPeriod(String expr) {
    final lower = expr.toLowerCase();
    if (lower.contains('sin') || lower.contains('cos') || lower.contains('tan')) {
      if (lower.contains('sin(x)') || lower.contains('cos(x)')) return '2π';
      if (lower.contains('tan(x)')) return 'π';
      return 'Periodique (trigonometrique)';
    }
    return 'Non periodique';
  }

  List<String> _findExtrema(List<MapEntry<double, double>> points) {
    if (points.length < 5) return ['Aucun extremum detecte sur l intervalle'];
    final list = <String>[];
    for (int i = 2; i < points.length - 2; i++) {
      final prev = points[i - 1].value;
      final curr = points[i].value;
      final next = points[i + 1].value;
      if (curr > prev && curr > next) {
        list.add('Maximum local ≈ (${points[i].key.toStringAsFixed(2)} ; ${curr.toStringAsFixed(2)})');
      } else if (curr < prev && curr < next) {
        list.add('Minimum local ≈ (${points[i].key.toStringAsFixed(2)} ; ${curr.toStringAsFixed(2)})');
      }
    }
    if (list.isEmpty) return ['Aucun extremum local evident (fonction monotone possible)'];
    return list.take(6).toList();
  }

  List<String> _findAsymptotes(String expr, List<MapEntry<double, double>> points, double xMin, double xMax) {
    final list = <String>[];
    final lower = expr.toLowerCase();

    // Asymptote verticale pour ln(ax+b)
    final lnMatch = RegExp(r'(?:ln|log)\s*\(\s*([+-]?\d*\.?\d*)\s*\*?\s*x\s*([+-]\s*\d*\.?\d*)?\s*\)').firstMatch(expr);
    if (lnMatch != null) {
      final aStr = lnMatch.group(1);
      final bStr = lnMatch.group(2)?.replaceAll(' ', '') ?? '0';
      final a = (aStr == null || aStr.isEmpty || aStr == '+') ? 1.0 : (aStr == '-' ? -1.0 : double.tryParse(aStr) ?? 1.0);
      final b = double.tryParse(bStr) ?? 0.0;
      if (a != 0) {
        final bound = -b / a;
        list.add('Asymptote verticale : x = ${bound.toStringAsFixed(2)}');
      }
    }
    if (RegExp(r'(?:ln|log)\s*\(\s*x\s*\)').hasMatch(lower)) {
      list.add('Asymptote verticale : x = 0');
    }

    if (expr.contains('/')) {
      list.add('Asymptotes verticales possibles aux racines du denominateur');
    }

    // Comportement en ±∞
    if (points.length >= 2) {
      final last = points.last;
      if (last.value > 5) {
        list.add('Quand x → +∞, f(x) → +∞ (ou croît fortement)');
      } else if (last.value < -5) {
        list.add('Quand x → +∞, f(x) → −∞');
      }
    }

    if (list.isEmpty) list.add('Pas d asymptote evidente detectee numeriquement');
    return list;
  }

  String _buildVariationTable(List<MapEntry<double, double>> points) {
    if (points.length < 4) return 'Donnees insuffisantes (fonction peu definie sur l intervalle)';
    final buffer = StringBuffer();
    buffer.writeln('x        | f(x) approx | Sens');
    buffer.writeln('---------|-------------|-----');
    final step = (points.length / 10).ceil().clamp(1, 50);
    for (int i = 0; i < points.length; i += step) {
      final p = points[i];
      String sens = '—';
      if (i > 0) {
        final diff = p.value - points[i - 1].value;
        if (diff > 0.001) {
          sens = 'croissante';
        } else if (diff < -0.001) sens = 'decroissante';
        else {
          sens = 'stable';
        }
      }
      buffer.writeln('${p.key.toStringAsFixed(2).padLeft(8)} | ${p.value.toStringAsFixed(3).padLeft(11)} | $sens');
    }
    return buffer.toString();
  }

  String _detectSymmetry(String expr, List<MapEntry<double, double>> points) {
    final lower = expr.toLowerCase();
    if (lower.contains('ln') || lower.contains('log')) {
      return 'Aucune symetrie evidente (fonction logarithme)';
    }
    if (lower.contains('x^2') || lower.contains('x²')) {
      return 'Parite paire possible → axe de symetrie (Oy)';
    }
    if (lower.contains('x^3') || lower.contains('x³')) {
      return 'Parite impaire possible → centre de symetrie (origine)';
    }
    return 'Aucune symetrie evidente detectee';
  }

  String _buildExplanations(String expr, String domain, String period, List<String> extrema,
      List<String> asymptotes, String symmetry) {
    final b = StringBuffer();
    b.writeln('=== Comment lire cette etude ===');
    b.writeln();
    b.writeln('1. Domaine de definition');
    b.writeln('   Ensemble des x pour lesquels f(x) existe.');
    b.writeln('   Ici : $domain');
    b.writeln();
    b.writeln('2. Periodicite');
    b.writeln('   Une fonction est periodique de periode T si f(x+T) = f(x).');
    b.writeln('   Ici : $period');
    b.writeln();
    b.writeln('3. Extremums');
    b.writeln('   Points ou la derivee s annule ou change de signe.');
    for (final e in extrema) {
      b.writeln('   - $e');
    }
    b.writeln();
    b.writeln('4. Asymptotes');
    b.writeln('   Droites dont la courbe se rapproche a l infini.');
    for (final a in asymptotes) {
      b.writeln('   - $a');
    }
    b.writeln();
    b.writeln('5. Symetrie');
    b.writeln('   $symmetry');
    b.writeln();
    b.writeln('Note : analyse principalement numerique.');
    b.writeln('Pour une etude algebrique complete, calculer f (x) a la main.');
    return b.toString();
  }
}
