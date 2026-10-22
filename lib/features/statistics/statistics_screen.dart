import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/locale_provider.dart';
import '../../data/services/math_library.dart';

/// Statistiques univariées + bivariées (régressions, Mayer, corrélation)
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  /// '1d' = série unique, '2d' = tableau x / y
  String _mode = '2d';
  int _n = 5;
  late List<TextEditingController> _xCtrls;
  late List<TextEditingController> _yCtrls;
  final _seriesCtrl = TextEditingController();
  String _result = '';
  String _steps = '';

  @override
  void initState() {
    super.initState();
    _rebuildTable();
  }

  void _rebuildTable() {
    _xCtrls = List.generate(_n, (i) => TextEditingController(text: '${i + 1}'));
    _yCtrls = List.generate(
        _n, (i) => TextEditingController(text: '${(i + 1) * 2 + (i % 2)}'));
  }

  @override
  void dispose() {
    for (final c in _xCtrls) {
      c.dispose();
    }
    for (final c in _yCtrls) {
      c.dispose();
    }
    _seriesCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) => MathLibrary.format(v);

  double? _parse(String s) {
    final t = s.trim().replaceAll(',', '.').replaceAll(' ', '');
    if (t.isEmpty) return null;
    if (t.contains('/')) {
      final p = t.split('/');
      if (p.length == 2) {
        final a = double.tryParse(p[0]);
        final b = double.tryParse(p[1]);
        if (a != null && b != null && b != 0) return a / b;
      }
    }
    return double.tryParse(t);
  }

  void _resize(int n) {
    setState(() {
      for (final c in _xCtrls) {
        c.dispose();
      }
      for (final c in _yCtrls) {
        c.dispose();
      }
      _n = n.clamp(2, 30);
      _rebuildTable();
      _result = '';
      _steps = '';
    });
  }

  void _calculate1d(LocaleProvider loc) {
    final parts =
        _seriesCtrl.text.trim().split(RegExp(r'[\s,;]+')).where((e) => e.isNotEmpty);
    final values = <double>[];
    for (final p in parts) {
      final v = _parse(p);
      if (v != null) values.add(v);
    }
    if (values.isEmpty) {
      setState(() {
        _result = loc.t('Aucune donnée valide', 'No valid data');
        _steps = '';
      });
      return;
    }
    values.sort();
    final n = values.length;
    final sum = values.reduce((a, b) => a + b);
    final mean = sum / n;
    final median = n.isOdd
        ? values[n ~/ 2]
        : (values[n ~/ 2 - 1] + values[n ~/ 2]) / 2;
    var variance = 0.0;
    for (final v in values) {
      variance += math.pow(v - mean, 2).toDouble();
    }
    variance /= n;
    final std = math.sqrt(variance);
    final buf = StringBuffer();
    buf.writeln(loc.t('Données triées', 'Sorted data') +
        ' : ${values.map(_fmt).join(', ')}');
    buf.writeln('n = $n');
    buf.writeln('${loc.t('Moyenne', 'Mean')} x̄ = ${_fmt(mean)}');
    buf.writeln('${loc.t('Médiane', 'Median')} = ${_fmt(median)}');
    buf.writeln('${loc.t('Variance', 'Variance')} = ${_fmt(variance)}');
    buf.writeln('${loc.t('Écart-type', 'Std. deviation')} σ = ${_fmt(std)}');
    buf.writeln(
        '${loc.t('Min', 'Min')} = ${_fmt(values.first)}  ${loc.t('Max', 'Max')} = ${_fmt(values.last)}');
    setState(() {
      _result =
          '${loc.t('Moyenne', 'Mean')} : ${_fmt(mean)}\n${loc.t('Médiane', 'Median')} : ${_fmt(median)}\nσ = ${_fmt(std)}';
      _steps = buf.toString();
    });
  }

  void _calculate2d(LocaleProvider loc) {
    final xs = <double>[];
    final ys = <double>[];
    for (var i = 0; i < _n; i++) {
      final x = _parse(_xCtrls[i].text);
      final y = _parse(_yCtrls[i].text);
      if (x == null || y == null) continue;
      xs.add(x);
      ys.add(y);
    }
    if (xs.length < 2) {
      setState(() {
        _result = loc.t(
            'Au moins 2 couples (x, y) valides', 'At least 2 valid (x, y) pairs');
        _steps = '';
      });
      return;
    }

    final n = xs.length;
    final sumX = xs.reduce((a, b) => a + b);
    final sumY = ys.reduce((a, b) => a + b);
    final meanX = sumX / n;
    final meanY = sumY / n;

    var sumXX = 0.0, sumYY = 0.0, sumXY = 0.0;
    for (var i = 0; i < n; i++) {
      final dx = xs[i] - meanX;
      final dy = ys[i] - meanY;
      sumXX += dx * dx;
      sumYY += dy * dy;
      sumXY += dx * dy;
    }

    // Covariance & corrélation
    final cov = sumXY / n;
    final varX = sumXX / n;
    final varY = sumYY / n;
    final sx = math.sqrt(varX);
    final sy = math.sqrt(varY);
    final r = (sx > 0 && sy > 0) ? cov / (sx * sy) : double.nan;
    final r2 = r.isFinite ? r * r : double.nan;

    // Moindres carrés : y = a + b x  (régression de y en x)
    final bYx = sumXX.abs() > 1e-15 ? sumXY / sumXX : double.nan;
    final aYx = meanY - bYx * meanX;

    // Régression de x en y : x = c + d y
    final dXy = sumYY.abs() > 1e-15 ? sumXY / sumYY : double.nan;
    final cXy = meanX - dXy * meanY;

    // Méthode de Mayer : deux groupes (première / seconde moitié triée par x)
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

    // Droite médiane approximative (quartiles sur x triés)
    String mayerLine = bMayer.isFinite
        ? 'y = ${_fmt(aMayer)} + ${_fmt(bMayer)}·x'
        : loc.t('non calculable', 'not computable');

    final buf = StringBuffer();
    buf.writeln(loc.t('Effectif', 'Sample size') + ' n = $n');
    buf.writeln();
    buf.writeln('— ${loc.t('Moyennes', 'Means')} —');
    buf.writeln('x̄ = ${_fmt(meanX)}    ȳ = ${_fmt(meanY)}');
    buf.writeln();
    buf.writeln('— ${loc.t('Dispersion', 'Dispersion')} —');
    buf.writeln(
        '${loc.t('Variance', 'Variance')} σ²ₓ = ${_fmt(varX)}    σ²ᵧ = ${_fmt(varY)}');
    buf.writeln(
        '${loc.t('Écarts-types', 'Std. deviations')} σₓ = ${_fmt(sx)}    σᵧ = ${_fmt(sy)}');
    buf.writeln(
        '${loc.t('Covariance', 'Covariance')} cov(x,y) = ${_fmt(cov)}');
    buf.writeln();
    buf.writeln('— ${loc.t('Corrélation', 'Correlation')} —');
    buf.writeln(
        '${loc.t('Coefficient de Pearson', 'Pearson coefficient')} r = ${_fmt(r)}');
    buf.writeln('r² = ${_fmt(r2)}');
    if (r.isFinite) {
      if (r.abs() > 0.8) {
        buf.writeln(loc.t('→ corrélation forte',
            '→ strong correlation'));
      } else if (r.abs() > 0.5) {
        buf.writeln(loc.t('→ corrélation moyenne',
            '→ moderate correlation'));
      } else {
        buf.writeln(loc.t('→ corrélation faible',
            '→ weak correlation'));
      }
    }
    buf.writeln();
    buf.writeln(
        '— ${loc.t('Moindres carrés — régression de y en x', 'Least squares — y on x')} —');
    buf.writeln('y = a + b·x');
    buf.writeln(
        'b = Σ(x−x̄)(y−ȳ) / Σ(x−x̄)² = ${_fmt(bYx)}');
    buf.writeln('a = ȳ − b·x̄ = ${_fmt(aYx)}');
    buf.writeln('⇒ y = ${_fmt(aYx)} + ${_fmt(bYx)}·x');
    buf.writeln();
    buf.writeln(
        '— ${loc.t('Moindres carrés — régression de x en y', 'Least squares — x on y')} —');
    buf.writeln('x = c + d·y');
    buf.writeln('d = ${_fmt(dXy)}    c = ${_fmt(cXy)}');
    buf.writeln('⇒ x = ${_fmt(cXy)} + ${_fmt(dXy)}·y');
    buf.writeln();
    buf.writeln(
        '— ${loc.t('Méthode de Mayer', 'Mayer method')} —');
    buf.writeln(loc.t(
        'Séries ordonnées selon x, deux groupes de moyennes :',
        'Series sorted by x, two groups of means:'));
    buf.writeln(
        'G1 (n=${g1.length}) : (x̄₁,ȳ₁) = (${_fmt(x1)}, ${_fmt(y1)})');
    buf.writeln(
        'G2 (n=${g2.length}) : (x̄₂,ȳ₂) = (${_fmt(x2)}, ${_fmt(y2)})');
    buf.writeln(
        'b = (ȳ₂−ȳ₁)/(x̄₂−x̄₁) = ${_fmt(bMayer)}');
    buf.writeln('a = ȳ₁ − b·x̄₁ = ${_fmt(aMayer)}');
    buf.writeln('⇒ $mayerLine');
    buf.writeln();
    buf.writeln(
        '— ${loc.t('Autres', 'Other')} —');
    if (bYx.isFinite && dXy.isFinite && (bYx * dXy).abs() > 1e-15) {
      // Angle entre droites de régression lié à r
      buf.writeln(loc.t(
          'Produit des pentes b·d = r² (si centrées correctement) ≈ ${_fmt(bYx * dXy)}',
          'Product of slopes b·d ≈ r² ≈ ${_fmt(bYx * dXy)}'));
    }
    buf.writeln(loc.t(
        'Droite des moindres carrés orthogonaux non détaillée ici.',
        'Orthogonal least-squares line not detailed here.'));

    setState(() {
      _result = loc.t(
        'r = ${_fmt(r)}\n'
        'y = ${_fmt(aYx)} + ${_fmt(bYx)}·x  (y en x)\n'
        'x = ${_fmt(cXy)} + ${_fmt(dXy)}·y  (x en y)\n'
        'Mayer : $mayerLine',
        'r = ${_fmt(r)}\n'
        'y = ${_fmt(aYx)} + ${_fmt(bYx)}·x  (y on x)\n'
        'x = ${_fmt(cXy)} + ${_fmt(dXy)}·y  (x on y)\n'
        'Mayer: $mayerLine',
      );
      _steps = buf.toString();
    });
  }

  void _calculate() {
    final loc = context.read<LocaleProvider>();
    if (_mode == '1d') {
      _calculate1d(loc);
    } else {
      _calculate2d(loc);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('Statistiques', 'Statistics')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: '1d',
                label: Text(loc.t('Série simple', 'Single series')),
              ),
              ButtonSegment(
                value: '2d',
                label: Text(loc.t('Tableau x / y', 'x / y table')),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() {
              _mode = s.first;
              _result = '';
              _steps = '';
            }),
          ),
          const SizedBox(height: 16),
          if (_mode == '1d') ...[
            TextField(
              controller: _seriesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: loc.t(
                    'Données (espaces ou virgules)', 'Data (spaces or commas)'),
                hintText: '12 15 18 20 22',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Text(loc.t('Nombre de lignes : ', 'Number of rows: ')),
                DropdownButton<int>(
                  value: _n,
                  items: [2, 3, 4, 5, 6, 8, 10, 12, 15, 20]
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text('$e')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) _resize(v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              loc.t(
                'Tableau à double entrée — fractions acceptées (1/2)',
                'Two-way table — fractions allowed (1/2)',
              ),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text('xᵢ',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Text('yᵢ',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            ...List.generate(_n, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _xCtrls[i],
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: 'x${i + 1}',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _yCtrls[i],
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: 'y${i + 1}',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.calculate),
            label: Text(loc.t('Calculer', 'Compute')),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  _result,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, height: 1.5, fontSize: 15),
                ),
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.t('Détails pas à pas', 'Step-by-step details'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _steps,
                      style: const TextStyle(height: 1.45, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
