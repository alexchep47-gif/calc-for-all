import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/locale_provider.dart';
import '../../data/services/math_library.dart';
import '../../data/services/regression_service.dart';

/// Statistiques : 1D, x/y (régressions détaillées), séries groupées
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _mode = '2d';
  int _n = 5;
  int _nClasses = 4;

  late List<TextEditingController> _xCtrls;
  late List<TextEditingController> _yCtrls;
  late List<TextEditingController> _aCtrls;
  late List<TextEditingController> _bCtrls;
  late List<TextEditingController> _niCtrls;

  final _seriesCtrl = TextEditingController();
  String _result = '';
  String _steps = '';

  @override
  void initState() {
    super.initState();
    _rebuildXy();
    _rebuildGrouped();
  }

  void _rebuildXy() {
    _xCtrls = List.generate(_n, (i) => TextEditingController(text: '${i + 1}'));
    _yCtrls = List.generate(
        _n, (i) => TextEditingController(text: '${(i + 1) * 2}'));
  }

  void _rebuildGrouped() {
    _aCtrls = List.generate(
        _nClasses, (i) => TextEditingController(text: '${i * 10}'));
    _bCtrls = List.generate(
        _nClasses, (i) => TextEditingController(text: '${(i + 1) * 10}'));
    _niCtrls = List.generate(
        _nClasses, (i) => TextEditingController(text: '${5 + i * 2}'));
  }

  @override
  void dispose() {
    for (final c in [..._xCtrls, ..._yCtrls, ..._aCtrls, ..._bCtrls, ..._niCtrls]) {
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

  void _resizeXy(int n) {
    setState(() {
      for (final c in [..._xCtrls, ..._yCtrls]) {
        c.dispose();
      }
      _n = n.clamp(2, 30);
      _rebuildXy();
      _result = '';
      _steps = '';
    });
  }

  void _resizeGrouped(int n) {
    setState(() {
      for (final c in [..._aCtrls, ..._bCtrls, ..._niCtrls]) {
        c.dispose();
      }
      _nClasses = n.clamp(2, 20);
      _rebuildGrouped();
      _result = '';
      _steps = '';
    });
  }

  void _calculate1d(LocaleProvider loc) {
    final parts = _seriesCtrl.text
        .trim()
        .split(RegExp(r'[\s,;]+'))
        .where((e) => e.isNotEmpty);
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
      variance += (v - mean) * (v - mean);
    }
    variance /= n;
    final std = math.sqrt(variance);
    setState(() {
      _result =
          '${loc.t('Moyenne', 'Mean')} : ${_fmt(mean)}\n${loc.t('Médiane', 'Median')} : ${_fmt(median)}\nσ = ${_fmt(std)}';
      _steps =
          'n = $n\nx̄ = ${_fmt(mean)}\nMed = ${_fmt(median)}\nσ² = ${_fmt(variance)}\nσ = ${_fmt(std)}';
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
        _result = loc.t('Au moins 2 couples valides', 'At least 2 valid pairs');
        _steps = '';
      });
      return;
    }
    final out = RegressionService.analyze(xs, ys, french: loc.isFrench);
    setState(() {
      _result = out.summary;
      _steps = out.steps;
    });
  }

  void _calculateGrouped(LocaleProvider loc) {
    final a = <double>[];
    final b = <double>[];
    final ni = <double>[];
    for (var i = 0; i < _nClasses; i++) {
      final ai = _parse(_aCtrls[i].text);
      final bi = _parse(_bCtrls[i].text);
      final n = _parse(_niCtrls[i].text);
      if (ai == null || bi == null || n == null) continue;
      if (bi <= ai || n < 0) continue;
      a.add(ai);
      b.add(bi);
      ni.add(n);
    }
    if (a.length < 2) {
      setState(() {
        _result = loc.t(
            'Au moins 2 classes valides [a ; b[',
            'At least 2 valid classes [a ; b[');
        _steps = '';
      });
      return;
    }
    final k = a.length;
    final c = List<double>.generate(k, (i) => (a[i] + b[i]) / 2);
    final w = List<double>.generate(k, (i) => b[i] - a[i]);
    final N = ni.reduce((x, y) => x + y);
    if (N <= 0) {
      setState(() {
        _result = loc.t('Effectif total nul', 'Total frequency is zero');
        _steps = '';
      });
      return;
    }
    final nici = List<double>.generate(k, (i) => ni[i] * c[i]);
    final nici2 = List<double>.generate(k, (i) => ni[i] * c[i] * c[i]);
    final fi = List<double>.generate(k, (i) => ni[i] / N);
    final dens = List<double>.generate(k, (i) => w[i] > 0 ? ni[i] / w[i] : double.nan);
    final ecc = List<double>.filled(k, 0);
    final ecd = List<double>.filled(k, 0);
    ecc[0] = ni[0];
    for (var i = 1; i < k; i++) {
      ecc[i] = ecc[i - 1] + ni[i];
    }
    ecd[k - 1] = ni[k - 1];
    for (var i = k - 2; i >= 0; i--) {
      ecd[i] = ecd[i + 1] + ni[i];
    }
    final fec = ecc.map((e) => e / N).toList();
    final fcd = ecd.map((e) => e / N).toList();
    final mean = nici.reduce((x, y) => x + y) / N;
    final variance = nici2.reduce((x, y) => x + y) / N - mean * mean;
    final std = math.sqrt(variance.abs());
    final half = N / 2;
    var medIdx = 0;
    for (var i = 0; i < k; i++) {
      if (ecc[i] >= half) {
        medIdx = i;
        break;
      }
    }
    final fPrev = medIdx == 0 ? 0.0 : ecc[medIdx - 1];
    final median = a[medIdx] + ((half - fPrev) / ni[medIdx]) * w[medIdx];
    var modIdx = 0;
    for (var i = 1; i < k; i++) {
      final di = dens[i].isFinite ? dens[i] : ni[i];
      final d0 = dens[modIdx].isFinite ? dens[modIdx] : ni[modIdx];
      if (di > d0) modIdx = i;
    }
    final f1 = modIdx > 0 ? ni[modIdx - 1] : 0.0;
    final f2 = modIdx < k - 1 ? ni[modIdx + 1] : 0.0;
    final fm = ni[modIdx];
    final denom = (fm - f1) + (fm - f2);
    final mode = denom.abs() > 1e-12
        ? a[modIdx] + ((fm - f1) / denom) * w[modIdx]
        : c[modIdx];
    final buf = StringBuffer();
    buf.writeln('N = ${_fmt(N)}');
    for (var i = 0; i < k; i++) {
      buf.writeln(
          '[${_fmt(a[i])} ; ${_fmt(b[i])}[  c=${_fmt(c[i])}  n=${_fmt(ni[i])}  '
          'nc=${_fmt(nici[i])}  nc²=${_fmt(nici2[i])}  ECC=${_fmt(ecc[i])}  FEC=${_fmt(fec[i])}');
    }
    buf.writeln('x̄=${_fmt(mean)}  Med≈${_fmt(median)}  Mode≈${_fmt(mode)}  σ=${_fmt(std)}');
    buf.writeln('G(${_fmt(mean)} ; 0)');
    setState(() {
      _result =
          'x̄=${_fmt(mean)}\nMed≈${_fmt(median)}\nMode≈${_fmt(mode)}\nG(${_fmt(mean)} ; 0)';
      _steps = buf.toString();
    });
  }

  void _calculate() {
    final loc = context.read<LocaleProvider>();
    switch (_mode) {
      case '1d':
        _calculate1d(loc);
        break;
      case '2d':
        _calculate2d(loc);
        break;
      default:
        _calculateGrouped(loc);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(loc.t('Statistiques', 'Statistics'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: '1d', label: Text(loc.t('Série', 'Series'))),
              ButtonSegment(value: '2d', label: Text(loc.t('x / y', 'x / y'))),
              ButtonSegment(
                  value: 'grouped', label: Text(loc.t('Groupées', 'Grouped'))),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() {
              _mode = s.first;
              _result = '';
              _steps = '';
            }),
          ),
          const SizedBox(height: 16),
          if (_mode == '1d')
            TextField(
              controller: _seriesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: loc.t('Données', 'Data'),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            )
          else if (_mode == '2d') ...[
            Row(children: [
              Text(loc.t('Lignes : ', 'Rows: ')),
              DropdownButton<int>(
                value: _n,
                items: [2, 3, 4, 5, 6, 8, 10]
                    .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) _resizeXy(v);
                },
              ),
            ]),
            ...List.generate(_n, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
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
                ]),
              );
            }),
          ] else ...[
            Row(children: [
              Text(loc.t('Classes : ', 'Classes: ')),
              DropdownButton<int>(
                value: _nClasses,
                items: [2, 3, 4, 5, 6, 8, 10]
                    .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) _resizeGrouped(v);
                },
              ),
            ]),
            ...List.generate(_nClasses, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _aCtrls[i],
                      decoration: InputDecoration(
                          isDense: true,
                          labelText: 'a${i + 1}',
                          border: const OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _bCtrls[i],
                      decoration: InputDecoration(
                          isDense: true,
                          labelText: 'b${i + 1}',
                          border: const OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _niCtrls[i],
                      decoration: InputDecoration(
                          isDense: true,
                          labelText: 'n${i + 1}',
                          border: const OutlineInputBorder()),
                    ),
                  ),
                ]),
              );
            }),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.calculate),
            label: Text(loc.t('Calculer', 'Compute')),
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48)),
          ),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(_result,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, height: 1.5, fontSize: 15)),
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.t('Détails', 'Details'),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SelectableText(_steps,
                        style: const TextStyle(height: 1.4, fontSize: 12)),
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
