import 'dart:math' as math;

import 'math_library.dart';

/// Calculs de régression linéaires détaillés (hors-ligne).
class RegressionService {
  /// Résultat textuel complet pour un nuage (xᵢ, yᵢ).
  static ({String summary, String steps}) analyze(
    List<double> xs,
    List<double> ys, {
    bool french = true,
  }) {
    final n = xs.length;
    assert(n == ys.length && n >= 2);

    String fmt(double v) => MathLibrary.format(v);
    String t(String fr, String en) => french ? fr : en;

    final meanX = xs.reduce((a, b) => a + b) / n;
    final meanY = ys.reduce((a, b) => a + b) / n;
    var sumXX = 0.0, sumYY = 0.0, sumXY = 0.0;
    for (var i = 0; i < n; i++) {
      final dx = xs[i] - meanX;
      final dy = ys[i] - meanY;
      sumXX += dx * dx;
      sumYY += dy * dy;
      sumXY += dx * dy;
    }
    final cov = sumXY / n;
    final varX = sumXX / n;
    final varY = sumYY / n;
    final sx = math.sqrt(varX);
    final sy = math.sqrt(varY);
    final r = (sx > 0 && sy > 0) ? cov / (sx * sy) : double.nan;
    final r2 = r.isFinite ? r * r : double.nan;

    // y = a + b x
    final bYx = sumXX.abs() > 1e-15 ? sumXY / sumXX : double.nan;
    final aYx = meanY - bYx * meanX;

    // x = c + d y
    final dXy = sumYY.abs() > 1e-15 ? sumXY / sumYY : double.nan;
    final cXy = meanX - dXy * meanY;

    // Mayer
    final indices = List.generate(n, (i) => i);
    indices.sort((i, j) => xs[i].compareTo(xs[j]));
    final mid = n ~/ 2;
    final g1 = indices.sublist(0, mid == 0 ? 1 : mid);
    final g2 = indices.sublist(mid);
    double avg(List<int> g, List<double> v) =>
        g.map((i) => v[i]).reduce((a, b) => a + b) / g.length;
    final x1 = avg(g1, xs), y1 = avg(g1, ys);
    final x2 = avg(g2, xs), y2 = avg(g2, ys);
    final bMayer =
        (x2 - x1).abs() > 1e-15 ? (y2 - y1) / (x2 - x1) : double.nan;
    final aMayer = y1 - bMayer * x1;

    // Orthogonal
    double aOrth = double.nan, bOrth = double.nan;
    if (sumXY.abs() < 1e-15) {
      if (sumXX >= sumYY) {
        bOrth = 0;
        aOrth = meanY;
      } else {
        bOrth = double.infinity;
        aOrth = meanX;
      }
    } else {
      final disc = (sumXX - sumYY) * (sumXX - sumYY) + 4 * sumXY * sumXY;
      final sqrtD = math.sqrt(disc);
      bOrth = (sumYY - sumXX + sqrtD) / (2 * sumXY);
      aOrth = meanY - bOrth * meanX;
    }

    final orthLine = bOrth.isInfinite
        ? 'x = ${fmt(meanX)}'
        : 'y = ${fmt(aOrth)} + ${fmt(bOrth)}·x';

    final buf = StringBuffer();
    buf.writeln('${t('Effectif', 'Sample size')} n = $n');
    buf.writeln('${t('Point moyen', 'Mean point')} G(${fmt(meanX)} ; ${fmt(meanY)})');
    buf.writeln();
    buf.writeln('— ${t('Dispersion', 'Dispersion')} —');
    buf.writeln('σ²ₓ = ${fmt(varX)}  σ²ᵧ = ${fmt(varY)}');
    buf.writeln('σₓ = ${fmt(sx)}  σᵧ = ${fmt(sy)}');
    buf.writeln('${t('Covariance', 'Covariance')} = ${fmt(cov)}');
    buf.writeln();
    buf.writeln('— ${t('Corrélation de Pearson', 'Pearson correlation')} —');
    buf.writeln('r = cov/(σₓσᵧ) = ${fmt(r)}');
    buf.writeln('r² = ${fmt(r2)}');
    buf.writeln();
    buf.writeln(
        '— ${t('Moindres carrés — régression de y en x', 'Least squares — y on x')} —');
    buf.writeln('Modèle : y = a + b·x');
    buf.writeln(
        'b = Σ(x−x̄)(y−ȳ)/Σ(x−x̄)² = ${fmt(sumXY)}/${fmt(sumXX)} = ${fmt(bYx)}');
    buf.writeln('a = ȳ − b·x̄ = ${fmt(aYx)}');
    buf.writeln('⇒ y = ${fmt(aYx)} + ${fmt(bYx)}·x');
    buf.writeln();
    buf.writeln(
        '— ${t('Moindres carrés — régression de x en y', 'Least squares — x on y')} —');
    buf.writeln('Modèle : x = c + d·y');
    buf.writeln(
        'd = Σ(x−x̄)(y−ȳ)/Σ(y−ȳ)² = ${fmt(sumXY)}/${fmt(sumYY)} = ${fmt(dXy)}');
    buf.writeln('c = x̄ − d·ȳ = ${fmt(cXy)}');
    buf.writeln('⇒ x = ${fmt(cXy)} + ${fmt(dXy)}·y');
    if (bYx.isFinite && dXy.isFinite) {
      buf.writeln('Produit des pentes b·d = ${fmt(bYx * dXy)} (≈ r²)');
    }
    buf.writeln();
    buf.writeln('— ${t('Méthode de Mayer', 'Mayer method')} —');
    buf.writeln(
        'G1 (n=${g1.length}) : (${fmt(x1)} ; ${fmt(y1)})');
    buf.writeln(
        'G2 (n=${g2.length}) : (${fmt(x2)} ; ${fmt(y2)})');
    buf.writeln('b = (ȳ₂−ȳ₁)/(x̄₂−x̄₁) = ${fmt(bMayer)}');
    buf.writeln('a = ȳ₁ − b·x̄₁ = ${fmt(aMayer)}');
    buf.writeln('⇒ y = ${fmt(aMayer)} + ${fmt(bMayer)}·x');
    buf.writeln();
    buf.writeln(
        '— ${t('Moindres carrés orthogonaux', 'Orthogonal least squares')} —');
    buf.writeln(t(
      'Minimise les distances perpendiculaires (passe par G).',
      'Minimizes perpendicular distances (through G).',
    ));
    if (bOrth.isInfinite) {
      buf.writeln('Droite verticale : x = ${fmt(meanX)}');
    } else {
      buf.writeln(
          'b = [σ²ᵧ−σ²ₓ + √((σ²ₓ−σ²ᵧ)²+4cov²)]/(2cov) = ${fmt(bOrth)}');
      buf.writeln('a = ${fmt(aOrth)}');
      buf.writeln('⇒ y = ${fmt(aOrth)} + ${fmt(bOrth)}·x');
    }

    final summary =
        'G(${fmt(meanX)} ; ${fmt(meanY)})\n'
        'r = ${fmt(r)}\n'
        'y en x : y = ${fmt(aYx)} + ${fmt(bYx)}·x\n'
        'x en y : x = ${fmt(cXy)} + ${fmt(dXy)}·y\n'
        'Mayer : y = ${fmt(aMayer)} + ${fmt(bMayer)}·x\n'
        'Orthogonal : $orthLine';

    return (summary: summary, steps: buf.toString());
  }
}
