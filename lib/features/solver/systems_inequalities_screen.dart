import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../data/services/math_library.dart';
import '../../data/services/math_expression_engine.dart';

class SystemsInequalitiesScreen extends StatefulWidget {
  const SystemsInequalitiesScreen({super.key});
  @override
  State<SystemsInequalitiesScreen> createState() =>
      _SystemsInequalitiesScreenState();
}

class _SystemsInequalitiesScreenState extends State<SystemsInequalitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  int _nEq = 2, _nVar = 2;
  late List<List<TextEditingController>> _coeff;
  String _sysResult = '', _sysSteps = '';
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
      (_) => List.generate(_nVar + 1, (_) => TextEditingController(text: '0')),
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

  String _boundLabel(double v) {
    if (v <= -9.5) return '−∞';
    if (v >= 9.5) return '+∞';
    return _fmt(v);
  }

  void _openGraph() {
    final expr = _ineqCtrl.text.trim();
    Navigator.pushNamed(
      context,
      AppRoutes.graph,
      arguments: expr.isEmpty ? null : expr,
    );
  }

  void _solveSystem() {
    final a = List.generate(
      _nEq,
      (i) => List.generate(_nVar + 1, (j) => _parse(_coeff[i][j].text)),
    );
    final steps = StringBuffer()..writeln('Système $_nEq × $_nVar');
    final m = a.map((r) => List<double>.from(r)).toList();
    final rows = _nEq, cols = _nVar;
    var rank = 0;
    for (var col = 0; col < cols && rank < rows; col++) {
      var pivot = rank;
      for (var i = rank + 1; i < rows; i++) {
        if (m[i][col].abs() > m[pivot][col].abs()) pivot = i;
      }
      if (m[pivot][col].abs() < 1e-12) continue;
      final tmp = m[rank];
      m[rank] = m[pivot];
      m[pivot] = tmp;
      final div = m[rank][col];
      for (var j = 0; j <= cols; j++) {
        m[rank][j] /= div;
      }
      for (var i = 0; i < rows; i++) {
        if (i == rank) continue;
        final f = m[i][col];
        for (var j = 0; j <= cols; j++) {
          m[i][j] -= f * m[rank][j];
        }
      }
      rank++;
    }
    for (var i = 0; i < rows; i++) {
      final allZero =
          List.generate(cols, (j) => m[i][j]).every((v) => v.abs() < 1e-12);
      if (allZero && m[i][cols].abs() > 1e-12) {
        setState(() {
          _sysResult = '∅';
          _sysSteps = '${steps}Système incompatible → ∅';
        });
        return;
      }
    }
    if (rank < cols) {
      setState(() {
        _sysResult = 'Infinité de solutions (rang $rank < $cols)';
        _sysSteps = steps.toString();
      });
      return;
    }
    final text = List.generate(cols, (i) => 'x${i + 1} = ${_fmt(m[i][cols])}').join('\n');
    setState(() {
      _sysResult = text;
      _sysSteps = '${steps}Solution :\n$text';
    });
  }

  void _solveIneq() {
    final expr = _ineqCtrl.text.trim();
    final steps = StringBuffer()
      ..writeln('f(x) $_ineqOp 0  avec f(x) = $expr');
    final roots = <double>[];
    double? prevY;
    for (var i = 0; i <= 400; i++) {
      final x = -10 + i * 20 / 400;
      final y = _engine.evaluate(expr, x);
      if (y == null) {
        prevY = null;
        continue;
      }
      if (prevY != null && prevY * y <= 0) roots.add(x);
      prevY = y;
    }
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
        intervals.add(
            ']${_boundLabel(bounds[i])} ; ${_boundLabel(bounds[i + 1])}[');
      }
    }
    setState(() {
      _ineqResult = intervals.isEmpty ? '∅' : intervals.join(' ∪ ');
      _sysSteps = steps.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Systèmes & Inéquations'),
        actions: [
          IconButton(
            tooltip: 'Graphique',
            icon: const Icon(Icons.show_chart),
            onPressed: _openGraph,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Systèmes'), Tab(text: 'Inéquations')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_buildSystemTab(), _buildIneqTab()],
      ),
    );
  }

  Widget _buildSystemTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          const Text('Éq. '),
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
          const SizedBox(width: 12),
          const Text('Inc. '),
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
        ]),
        ...List.generate(_nEq, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              ...List.generate(_nVar, (j) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: TextField(
                      controller: _coeff[i][j],
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'a${i + 1}${j + 1}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                );
              }),
              const Text('='),
              Expanded(
                child: TextField(
                  controller: _coeff[i][_nVar],
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'b',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ]),
          );
        }),
        FilledButton.icon(
          onPressed: _solveSystem,
          icon: const Icon(Icons.calculate),
          label: const Text('Résoudre le système'),
        ),
        if (_sysResult.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(_sysResult,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SelectableText(_sysSteps),
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
            labelText: 'f(x) =',
            border: OutlineInputBorder(),
          ),
        ),
        Wrap(
          spacing: 8,
          children: ['>', '≥', '<', '≤']
              .map((op) => ChoiceChip(
                    label: Text('f $op 0'),
                    selected: _ineqOp == op,
                    onSelected: (_) => setState(() => _ineqOp = op),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _solveIneq,
          icon: const Icon(Icons.functions),
          label: const Text('Résoudre'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _openGraph,
          icon: const Icon(Icons.show_chart),
          label: const Text('Ouvrir dans Graphique'),
        ),
        if (_ineqResult.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('S = $_ineqResult',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SelectableText(_sysSteps),
        ],
      ],
    );
  }
}
