import 'dart:math' as math;
import 'package:math_expressions/math_expressions.dart';

/// Résultat complet d'une étude de fonction
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

/// Service d'analyse numérique + règles pour l'étude de fonction
class FunctionAnalysisService {
  final Parser _parser = Parser();

  FunctionStudyResult analyze(String expression, {double xMin = -10, double xMax = 10}) {
    final expr = _normalize(expression);
    final points = _sample(expr, xMin, xMax, 300);

    final domain = _estimateDomain(expr, points);
    final period = _detectPeriod(expr);
    final extrema = _findExtrema(points);
    final asymptotes = _findAsymptotes(expr, points, xMin, xMax);
    final variation = _buildVariationTable(points);
    final symmetry = _detectSymmetry(expr, points);
    final explanations = _buildExplanations(expr, domain, period, extrema, asymptotes, symmetry);

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
        .replaceAll('√', 'sqrt');
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
          ctx.bindVariable(Variable('x'), Number(x));
          final y = exp.evaluate(EvaluationType.REAL, ctx);
          if (y is double && y.isFinite) {
            result.add(MapEntry(x, y));
          }
        } catch (_) {}
      }
    } catch (_) {}
    return result;
  }

  String _estimateDomain(String expr, List<MapEntry<double, double>> points) {
    if (expr.contains('sqrt') || expr.contains('ln') || expr.contains('log')) {
      return 'Domaine restreint (racine / log). Vérifier les points de définition.';
    }
    if (expr.contains('/')) {
      return 'ℝ privé des racines du dénominateur (asymptotes verticales possibles)';
    }
    if (points.length > 50) return 'ℝ (ou large intervalle testé)';
    return 'Domaine partiel détecté sur l’intervalle étudié';
  }

  String _detectPeriod(String expr) {
    final lower = expr.toLowerCase();
    if (lower.contains('sin') || lower.contains('cos') || lower.contains('tan')) {
      if (lower.contains('sin(x)') || lower.contains('cos(x)')) return '2π';
      if (lower.contains('tan(x)')) return 'π';
      return 'Périodique (trigonométrique) – période à confirmer selon le coefficient de x';
    }
    return 'Non périodique (ou période non détectée)';
  }

  List<String> _findExtrema(List<MapEntry<double, double>> points) {
    if (points.length < 5) return ['Aucun extremum détecté'];
    final list = <String>[];
    for (int i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1].value;
      final curr = points[i].value;
      final next = points[i + 1].value;
      if (curr > prev && curr > next) {
        list.add('Maximum local ≈ (${points[i].key.toStringAsFixed(2)} ; ${curr.toStringAsFixed(2)})');
      } else if (curr < prev && curr < next) {
        list.add('Minimum local ≈ (${points[i].key.toStringAsFixed(2)} ; ${curr.toStringAsFixed(2)})');
      }
    }
    if (list.isEmpty) return ['Aucun extremum local évident sur l’intervalle'];
    // Limiter à 6 pour la lisibilité
    return list.take(6).toList();
  }

  List<String> _findAsymptotes(String expr, List<MapEntry<double, double>> points, double xMin, double xMax) {
    final list = <String>[];
    if (expr.contains('/')) {
      list.add('Asymptotes verticales possibles aux racines du dénominateur');
    }
    // Comportement aux bornes
    if (points.isNotEmpty) {
      final first = points.first;
      final last = points.last;
      if (first.value.abs() > 50) list.add('Comportement vertical près de x = ${first.key.toStringAsFixed(1)}');
      if (last.value.abs() > 50) list.add('Comportement vertical près de x = ${last.key.toStringAsFixed(1)}');
    }
    if (list.isEmpty) list.add('Pas d’asymptote évidente détectée numériquement');
    return list;
  }

  String _buildVariationTable(List<MapEntry<double, double>> points) {
    if (points.length < 4) return 'Données insuffisantes';
    final buffer = StringBuffer();
    buffer.writeln('x     | f(x) approx | Variation');
    buffer.writeln('------|-------------|----------');
    for (int i = 0; i < points.length; i += (points.length ~/ 8).clamp(1, 50)) {
      final p = points[i];
      final sign = i == 0
          ? '—'
          : (p.value > points[i - 1].value ? '↗' : (p.value < points[i - 1].value ? '↘' : '→'));
      buffer.writeln('${p.key.toStringAsFixed(1).padLeft(5)} | ${p.value.toStringAsFixed(2).padLeft(11)} | $sign');
    }
    return buffer.toString();
  }

  String _detectSymmetry(String expr, List<MapEntry<double, double>> points) {
    final lower = expr.toLowerCase();
    if (lower.contains('x^2') || lower.contains('x²') || RegExp(r'x\^\d*[02468]').hasMatch(lower)) {
      return 'Parité paire possible (f(-x) = f(x)) → axe de symétrie (Oy)';
    }
    if (lower.contains('x^3') || lower.contains('x³') || RegExp(r'x\^\d*[13579]').hasMatch(lower)) {
      return 'Parité impaire possible (f(-x) = -f(x)) → centre de symétrie (origine)';
    }
    // Test numérique simple
    if (points.length > 20) {
      double evenScore = 0, oddScore = 0;
      int count = 0;
      for (final p in points) {
        if (p.key.abs() < 0.1) continue;
        try {
          final mirror = points.firstWhere((e) => (e.key + p.key).abs() < 0.15, orElse: () => p);
          if (mirror.key != p.key) {
            if ((mirror.value - p.value).abs() < 0.5) evenScore++;
            if ((mirror.value + p.value).abs() < 0.5) oddScore++;
            count++;
          }
        } catch (_) {}
      }
      if (count > 5) {
        if (evenScore / count > 0.7) return 'Symétrie axiale probable par rapport à (Oy)';
        if (oddScore / count > 0.7) return 'Symétrie centrale probable par rapport à l’origine';
      }
    }
    return 'Aucune symétrie évidente détectée';
  }

  String _buildExplanations(String expr, String domain, String period, List<String> extrema,
      List<String> asymptotes, String symmetry) {
    final b = StringBuffer();
    b.writeln('=== Comment lire cette étude ===');
    b.writeln();
    b.writeln('1. Domaine de définition');
    b.writeln('   → Ensemble des x pour lesquels f(x) existe.');
    b.writeln('   → Ici : $domain');
    b.writeln();
    b.writeln('2. Périodicité');
    b.writeln('   → Une fonction est périodique de période T si f(x+T) = f(x).');
    b.writeln('   → Ici : $period');
    b.writeln();
    b.writeln('3. Extremums');
    b.writeln('   → Points où la dérivée s’annule (ou changement de sens).');
    b.writeln('   → Méthode : étudier le signe de f′(x).');
    for (final e in extrema) {
      b.writeln('   • $e');
    }
    b.writeln();
    b.writeln('4. Asymptotes');
    b.writeln('   → Droites dont la courbe se rapproche à l’infini.');
    for (final a in asymptotes) {
      b.writeln('   • $a');
    }
    b.writeln();
    b.writeln('5. Symétrie');
    b.writeln('   → $symmetry');
    b.writeln();
    b.writeln('Note : cette analyse est principalement numérique.');
    b.writeln('Pour une étude purement algébrique, calculer f′(x) à la main.');
    return b.toString();
  }
}
