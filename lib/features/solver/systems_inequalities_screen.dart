import 'package:flutter/material.dart';

import '../../data/services/math_library.dart';
import '../../data/services/math_expression_engine.dart';

/// Systèmes d'équations linéaires + inéquations avec représentation
class SystemsInequalitiesScreen extends StatefulWidget {
  const SystemsInequalitiesScreen({super.key});

  @override
  State<SystemsInequalitiesScreen> createState() =>
      _SystemsInequalitiesScreenState();
}

class _SystemsInequalitiesScreenState extends State<SystemsInequalitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // —— Système ——
  int _nEq = 2;
  int _nVar = 2;
  late List<List<TextEditingController>> _coeff; // [eq][var + constant]
  String _sysResult = '';
  String _sysSteps = '';

  // —— Inéquation ——
  final _ineqCtrl = TextEditingController(text: 'x^2 - 1');
  String _ineqOp = '>';
  String _ineqResult = '';
  final _engine = MathExpressionEngine();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _rebuildCoeff();
  }

  void _rebuildCoeff() {
    _coeff = List.generate(
      _nEq,
      (_) => List.generate(
        _nVar + 1,
        (_) => TextEditingController(text: '0'),
      ),
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final row in _coeff) {
      for (final c in row) {
        c.dispose();
      }
    }
    _ineqCtrl.dispose();
    super.dispose();
  }

  double _parse(String s) {
    final t = s.trim().replaceAll(',', '.').replaceAll(' ', '');
    if (t.contains('/')) {
      final p = t.split('/');
      if (p.length == 2) {
        final a = double.tryParse(p[0]) ?? 0;
        final b = double.tryParse(p[1]) ?? 1;
        return b == 0 ? double.nan : a / b;
      }
    }
    return double.tryParse(t) ?? 0;
  }

  String _fmt(double v) => MathLibrary.format(v);

  void _solveSystem() {
    // Matrice augmentée nEq × (nVar+1)
    final a = List.generate(
      _nEq,
      (i) => List.generate(_nVar + 1, (j) => _parse(_coeff[i][j].text)),
    );
    final steps = StringBuffer();
    steps.writeln('Système $_nEq équation(s), $_nVar inconnue(s)');
    steps.writeln('Matrice augmentée :');
    for (final row in a) {
      steps.writeln(row.map(_fmt).join('  |  '));
    }
    steps.writeln();

    // Gauss-Jordan sur la partie carrée si possible
    final n = _nEq < _nVar ? _nEq : _nVar;
    final m = a.map((r) => List<double>.from(r)).toList();

    for (var col = 0; col < n; col++) {
      var pivot = col;
      for (var r = col + 1; r < m.length; r++) {
        if (m[r][col].abs() > m[pivot][col].abs()) pivot = r;
      }
      if (m[pivot][col].abs() < 1e-12) continue;
      final tmp = m[col];
      m[col] = m[pivot];
      m[pivot] = tmp;
      final div = m[col][col];
      for (var j = 0; j < m[col].length; j++) {
        m[col][j] /= div;
      }
      for (var r = 0; r < m.length; r++) {
        if (r == col) continue;
        final f = m[r][col];
        for (var j = 0; j < m[r].length; j++) {
          m[r][j] -= f * m[col][j];
        }
      }
    }

    steps.writeln('Après Gauss-Jordan :');
    for (final row in m) {
      steps.writeln(row.map(_fmt).join('  |  '));
    }

    final sols = <String>[];
    for (var i = 0; i < n && i < m.length; i++) {
      // Cherche pivot
      var pivotCol = -1;
      for (var j = 0; j < _nVar; j++) {
        if (m[i][j].abs() > 1e-9) {
          pivotCol = j;
          break;
        }
      }
      if (pivotCol >= 0) {
        final name = String.fromCharCode('x'.codeUnitAt(0) + pivotCol);
        sols.add('$name = ${_fmt(m[i].last)}');
      }
    }

    setState(() {
      _sysResult = sols.isEmpty ? 'Aucune solution unique détectée' : sols.join('  ;  ');
      _sysSteps = steps.toString();
    });
  }

  void _solveIneq() {
    final expr = _ineqCtrl.text.trim();
    if (expr.isEmpty) return;
    final steps = StringBuffer();
    steps.writeln('Inéquation : f(x) $_ineqOp 0');
    steps.writeln('avec f(x) = $expr');
    steps.writeln();

    // Cherche racines numériques sur [-10,10]
    final roots = <double>[];
    const n = 400;
    const xMin = -10.0, xMax = 10.0;
    final step = (xMax - xMin) / n;
    double? prevX, prevY;
    for (var i = 0; i <= n; i++) {
      final x = xMin + i * step;
      final y = _engine.evaluate(expr, x);
      if (y == null || !y.isFinite) {
        prevX = null;
        prevY = null;
        continue;
      }
      if (y.abs() < 1e-6) {
        if (roots.isEmpty || (x - roots.last).abs() > 0.1) roots.add(x);
      } else if (prevY != null && prevX != null && prevY * y < 0) {
        var a = prevX, b = x, fa = prevY;
        for (var k = 0; k < 20; k++) {
          final mid = (a + b) / 2;
          final fm = _engine.evaluate(expr, mid);
          if (fm == null) break;
          if (fa * fm <= 0) {
            b = mid;
          } else {
            a = mid;
            fa = fm;
          }
        }
        final r = (a + b) / 2;
        if (roots.isEmpty || (r - roots.last).abs() > 0.1) roots.add(r);
      }
      prevX = x;
      prevY = y;
    }

    steps.writeln(
        'Racines de f (f=0) : ${roots.isEmpty ? 'aucune sur [-10;10]' : roots.map(_fmt).join(', ')}');

    // Intervalles de vérité
    final bounds = [-10.0, ...roots, 10.0];
    final intervals = <String>[];
    for (var i = 0; i < bounds.length - 1; i++) {
      final mid = (bounds[i] + bounds[i + 1]) / 2;
      final y = _engine.evaluate(expr, mid);
      if (y == null) continue;
      final ok = switch (_ineqOp) {
        '>' => y > 0,
        '≥' => y >= 0,
        '<' => y < 0,
        '≤' => y <= 0,
        _ => false,
      };
      if (ok) {
        intervals.add(']${_fmt(bounds[i])} ; ${_fmt(bounds[i + 1])}[');
      }
    }

    steps.writeln('Solution (approx. sur [-10;10]) :');
    if (intervals.isEmpty) {
      steps.writeln('∅');
    } else {
      steps.writeln(intervals.join(' ∪ '));
    }
    steps.writeln();
    steps.writeln('Représentation : sur la droite réelle, hachurer ces intervalles.');
    steps.writeln('Les racines ${roots.map(_fmt).join(', ')} sont ');
    steps.writeln(_ineqOp.contains('=') ? 'incluses (plein).' : 'exclues (creux).');

    setState(() {
      _ineqResult = intervals.isEmpty ? '∅' : intervals.join(' ∪ ');
      _sysSteps = steps.toString(); // reuse steps display for ineq too via result area
    });
    _sysSteps = steps.toString();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Systèmes & Inéquations'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Systèmes'),
            Tab(text: 'Inéquations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildSystemTab(),
          _buildIneqTab(),
        ],
      ),
    );
  }

  Widget _buildSystemTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Text('Équations :'),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: _nEq,
              items: [1, 2, 3, 4, 5]
                  .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _nEq = v;
                  _rebuildCoeff();
                });
              },
            ),
            const SizedBox(width: 16),
            const Text('Inconnues :'),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: _nVar,
              items: [1, 2, 3, 4, 5]
                  .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _nVar = v;
                  _rebuildCoeff();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Coefficients (fractions acceptées : 1/2, -3/4). Dernière colonne = constante.',
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 8),
        ...List.generate(_nEq, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text('E${i + 1}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                ...List.generate(_nVar + 1, (j) {
                  final label = j < _nVar
                      ? String.fromCharCode('x'.codeUnitAt(0) + j)
                      : '=';
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: TextField(
                        controller: _coeff[i][j],
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: label,
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
        FilledButton.icon(
          onPressed: _solveSystem,
          icon: const Icon(Icons.calculate),
          label: const Text('Résoudre le système'),
        ),
        if (_sysResult.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_sysResult,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 8),
          Text(_sysSteps, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ],
      ],
    );
  }

  Widget _buildIneqTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _ineqCtrl,
          decoration: const InputDecoration(
            labelText: 'f(x)  (ex: x^2-1 , 2x+3)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: ['>', '≥', '<', '≤'].map((op) {
            return ChoiceChip(
              label: Text('f(x) $op 0'),
              selected: _ineqOp == op,
              onSelected: (_) => setState(() => _ineqOp = op),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _solveIneq,
          icon: const Icon(Icons.show_chart),
          label: const Text('Résoudre + représentation'),
        ),
        if (_ineqResult.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ensemble solution :',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_ineqResult,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(_sysSteps, style: const TextStyle(fontSize: 13, height: 1.4)),
        ],
      ],
    );
  }
}
