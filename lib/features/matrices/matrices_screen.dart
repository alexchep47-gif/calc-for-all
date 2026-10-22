import 'package:flutter/material.dart';
import '../../data/services/math_library.dart';

/// Matrices n×m, plusieurs matrices, fractions, FE/FER, trace, transpose
class MatricesScreen extends StatefulWidget {
  const MatricesScreen({super.key});

  @override
  State<MatricesScreen> createState() => _MatricesScreenState();
}

class _MatricesScreenState extends State<MatricesScreen> {
  int _rows = 2;
  int _cols = 2;
  int _matrixCount = 2;
  late List<List<List<TextEditingController>>> _matrices; // [mat][row][col]
  String _operation = 'addition';
  String _result = '';
  String _steps = '';

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _matrices = List.generate(
      _matrixCount,
      (_) => List.generate(
        _rows,
        (_) => List.generate(_cols, (_) => TextEditingController(text: '0')),
      ),
    );
  }

  @override
  void dispose() {
    for (final m in _matrices) {
      for (final row in m) {
        for (final c in row) {
          c.dispose();
        }
      }
    }
    super.dispose();
  }

  double _parseCell(String raw) {
    final s = raw.trim().replaceAll(',', '.').replaceAll(' ', '');
    if (s.isEmpty) return 0;
    if (s.contains('/')) {
      final parts = s.split('/');
      if (parts.length == 2) {
        final a = double.tryParse(parts[0]) ?? 0;
        final b = double.tryParse(parts[1]) ?? 1;
        if (b == 0) return double.nan;
        return a / b;
      }
    }
    if (s == 'pi' || s == 'π') return MathLibrary.pi;
    return double.tryParse(s) ?? 0;
  }

  List<List<double>> _read(int index) {
    return _matrices[index]
        .map((row) => row.map((c) => _parseCell(c.text)).toList())
        .toList();
  }

  String _fmt(double v) {
    if (v.isNaN) return '?';
    return MathLibrary.format(v);
  }

  String _formatMatrix(List<List<double>> m) {
    return m.map((row) => row.map(_fmt).join('   ')).join('\n');
  }

  void _resize() {
    setState(() {
      for (final m in _matrices) {
        for (final row in m) {
          for (final c in row) {
            c.dispose();
          }
        }
      }
      _initControllers();
      _result = '';
      _steps = '';
    });
  }

  double _trace(List<List<double>> a) {
    final n = math.min(a.length, a.isEmpty ? 0 : a[0].length);
    var t = 0.0;
    for (var i = 0; i < n; i++) {
      t += a[i][i];
    }
    return t;
  }

  List<List<double>> _transpose(List<List<double>> a) {
    if (a.isEmpty) return [];
    final m = a.length;
    final n = a[0].length;
    return List.generate(n, (j) => List.generate(m, (i) => a[i][j]));
  }

  List<List<double>> _ref(List<List<double>> a) {
    final m = a.length;
    final n = a[0].length;
    var row = 0;
    for (var col = 0; col < n && row < m; col++) {
      var pivot = row;
      for (var i = row + 1; i < m; i++) {
        if (a[i][col].abs() > a[pivot][col].abs()) pivot = i;
      }
      if (a[pivot][col].abs() < 1e-12) continue;
      final tmp = a[row];
      a[row] = a[pivot];
      a[pivot] = tmp;
      final div = a[row][col];
      for (var j = 0; j < n; j++) {
        a[row][j] /= div;
      }
      for (var i = row + 1; i < m; i++) {
        final f = a[i][col];
        for (var j = 0; j < n; j++) {
          a[i][j] -= f * a[row][j];
        }
      }
      row++;
    }
    return a;
  }

  List<List<double>> _rref(List<List<double>> a) {
    a = _ref(a.map((r) => List<double>.from(r)).toList());
    final m = a.length;
    final n = a[0].length;
    for (var i = m - 1; i >= 0; i--) {
      var lead = -1;
      for (var j = 0; j < n; j++) {
        if (a[i][j].abs() > 1e-12) {
          lead = j;
          break;
        }
      }
      if (lead < 0) continue;
      for (var k = 0; k < i; k++) {
        final f = a[k][lead];
        for (var j = 0; j < n; j++) {
          a[k][j] -= f * a[i][j];
        }
      }
    }
    return a;
  }

  void _calculate() {
    final mats =
        List.generate(_matrixCount, (i) => _read(i));
    final buffer = StringBuffer();

    try {
      if (_operation == 'addition' || _operation == 'soustraction') {
        final isAdd = _operation == 'addition';
        buffer.writeln(isAdd ? 'Somme de $_matrixCount matrices' : 'Différences successives');
        var R = mats.first.map((r) => List<double>.from(r)).toList();
        for (var k = 1; k < mats.length; k++) {
          for (var i = 0; i < _rows; i++) {
            for (var j = 0; j < _cols; j++) {
              R[i][j] = isAdd ? R[i][j] + mats[k][i][j] : R[i][j] - mats[k][i][j];
            }
          }
        }
        buffer.writeln(_formatMatrix(R));
        setState(() {
          _result = _formatMatrix(R);
          _steps = buffer.toString();
        });
      } else if (_operation == 'multiplication') {
        // Produit successif A1*A2*... (nécessite cols_k = rows_{k+1})
        var R = mats.first.map((r) => List<double>.from(r)).toList();
        for (var k = 1; k < mats.length; k++) {
          final A = R;
          final B = mats[k];
          if (A[0].length != B.length) {
            throw Exception('Dimensions incompatibles pour le produit');
          }
          final m = A.length;
          final n = B[0].length;
          final p = B.length;
          R = List.generate(
              m,
              (i) => List.generate(n, (j) {
                    var s = 0.0;
                    for (var t = 0; t < p; t++) {
                      s += A[i][t] * B[t][j];
                    }
                    return s;
                  }));
        }
        buffer.writeln('Produit de $_matrixCount matrices');
        buffer.writeln(_formatMatrix(R));
        setState(() {
          _result = _formatMatrix(R);
          _steps = buffer.toString();
        });
      } else if (_operation == 'trace') {
        final lines = <String>[];
        for (var i = 0; i < mats.length; i++) {
          final t = _trace(mats[i]);
          lines.add('Tr(A${i + 1}) = ${_fmt(t)}');
        }
        setState(() {
          _result = lines.join('\n');
          _steps = 'Trace = somme des éléments diagonaux';
        });
      } else if (_operation == 'transpose') {
        final lines = <String>[];
        for (var i = 0; i < mats.length; i++) {
          lines.add('A${i + 1}ᵀ =\n${_formatMatrix(_transpose(mats[i]))}');
        }
        setState(() {
          _result = lines.join('\n\n');
          _steps = 'Transposée : aᵢⱼ → aⱼᵢ';
        });
      } else if (_operation == 'fe') {
        final r = _ref(mats.first.map((r) => List<double>.from(r)).toList());
        setState(() {
          _result = _formatMatrix(r);
          _steps = 'Forme échelonnée (FE / REF) de A1';
        });
      } else if (_operation == 'fer') {
        final r =
            _rref(mats.first.map((r) => List<double>.from(r)).toList());
        setState(() {
          _result = _formatMatrix(r);
          _steps = 'Forme échelonnée réduite (FER / RREF) de A1';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Erreur : $e';
        _steps = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matrices')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Lignes'),
                  const SizedBox(width: 6),
                  DropdownButton<int>(
                    value: _rows,
                    items: [1, 2, 3, 4, 5]
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text('$e')))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      _rows = v;
                      _resize();
                    },
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Colonnes'),
                  const SizedBox(width: 6),
                  DropdownButton<int>(
                    value: _cols,
                    items: [1, 2, 3, 4, 5]
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text('$e')))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      _cols = v;
                      _resize();
                    },
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Nb matrices'),
                  const SizedBox(width: 6),
                  DropdownButton<int>(
                    value: _matrixCount,
                    items: [1, 2, 3, 4]
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text('$e')))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      _matrixCount = v;
                      _resize();
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Fractions acceptées (ex: 1/2, -3/4)',
              style: TextStyle(fontSize: 12)),
          ...List.generate(_matrixCount, (mi) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Text('Matrice A${mi + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                ...List.generate(_rows, (i) {
                  return Row(
                    children: List.generate(_cols, (j) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: TextField(
                            controller: _matrices[mi][i][j],
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ],
            );
          }),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: [
              for (final op in [
                ('addition', '+'),
                ('soustraction', '−'),
                ('multiplication', '×'),
                ('trace', 'Tr'),
                ('transpose', 'ᵀ'),
                ('fe', 'FE'),
                ('fer', 'FER'),
              ])
                ChoiceChip(
                  label: Text(op.$2),
                  selected: _operation == op.$1,
                  onSelected: (_) => setState(() => _operation = op.$1),
                ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.calculate),
            label: const Text('Calculer'),
          ),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  _result,
                  style: const TextStyle(
                      fontFamily: 'monospace', fontWeight: FontWeight.w600),
                ),
              ),
            ),
            Text(_steps, style: const TextStyle(fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

// local min helper
int math_min(int a, int b) => a < b ? a : b;
