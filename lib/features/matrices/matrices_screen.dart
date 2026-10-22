import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/services/math_library.dart';

/// Matrices : taille libre, fractions, FER / FE, opérations
class MatricesScreen extends StatefulWidget {
  const MatricesScreen({super.key});

  @override
  State<MatricesScreen> createState() => _MatricesScreenState();
}

class _MatricesScreenState extends State<MatricesScreen> {
  int _rows = 2;
  int _cols = 2;
  int _matrixCount = 1; // 1 ou 2
  late List<List<TextEditingController>> _aControllers;
  late List<List<TextEditingController>> _bControllers;
  String _operation = 'addition';
  String _result = '';
  String _steps = '';

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _aControllers = List.generate(
        _rows, (_) => List.generate(_cols, (_) => TextEditingController(text: '0')));
    _bControllers = List.generate(
        _rows, (_) => List.generate(_cols, (_) => TextEditingController(text: '0')));
  }

  @override
  void dispose() {
    for (final row in _aControllers) {
      for (final c in row) {
        c.dispose();
      }
    }
    for (final row in _bControllers) {
      for (final c in row) {
        c.dispose();
      }
    }
    super.dispose();
  }

  /// Parse "3/4", "-1/2", "2.5", "π/2"
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

  List<List<double>> _readMatrix(List<List<TextEditingController>> ctrls) {
    return ctrls
        .map((row) => row.map((c) => _parseCell(c.text)).toList())
        .toList();
  }

  String _fmt(double v) {
    if (v.isNaN) return '?';
    final f = MathLibrary.toSimpleFraction(v);
    if (f != null) return f;
    return MathLibrary.format(v);
  }

  String _formatMatrix(List<List<double>> m) {
    return m.map((row) => row.map(_fmt).join('   ')).join('\n');
  }

  void _resize(int rows, int cols) {
    setState(() {
      _rows = rows;
      _cols = cols;
      _initControllers();
      _result = '';
      _steps = '';
    });
  }

  void _calculate() {
    final A = _readMatrix(_aControllers);
    final B = _matrixCount > 1 ? _readMatrix(_bControllers) : A;
    final buffer = StringBuffer();

    try {
      if (_operation == 'addition' || _operation == 'soustraction') {
        final isAdd = _operation == 'addition';
        buffer.writeln(isAdd ? 'Opération : A + B' : 'Opération : A − B');
        final R = List.generate(
            _rows,
            (i) => List.generate(_cols, (j) {
                  return isAdd ? A[i][j] + B[i][j] : A[i][j] - B[i][j];
                }));
        buffer.writeln(_formatMatrix(R));
        setState(() {
          _result = _formatMatrix(R);
          _steps = buffer.toString();
        });
      } else if (_operation == 'multiplication') {
        if (_cols != _rows) {
          // produit si B carrée compatible : A (m×n) * B (n×p) — on suppose B même taille
        }
        buffer.writeln('Opération : A × B');
        final R = List.generate(
            _rows,
            (i) => List.generate(_cols, (j) {
                  double sum = 0;
                  for (int k = 0; k < _cols; k++) {
                    sum += A[i][k] * B[k][j];
                  }
                  return sum;
                }));
        buffer.writeln(_formatMatrix(R));
        setState(() {
          _result = _formatMatrix(R);
          _steps = buffer.toString();
        });
      } else if (_operation == 'déterminant') {
        if (_rows != _cols) {
          setState(() {
            _result = 'Le déterminant exige une matrice carrée.';
            _steps = '';
          });
          return;
        }
        final det = _determinant(A);
        buffer.writeln('det(A) = ${_fmt(det)}');
        setState(() {
          _result = 'det(A) = ${_fmt(det)}';
          _steps = buffer.toString();
        });
      } else if (_operation == 'inverse') {
        if (_rows != _cols) {
          setState(() {
            _result = 'L\'inverse exige une matrice carrée.';
            _steps = '';
          });
          return;
        }
        final det = _determinant(A);
        if (det.abs() < 1e-12) {
          setState(() {
            _result = 'Non inversible (det = 0)';
            _steps = 'Le déterminant est nul.';
          });
          return;
        }
        if (_rows == 2) {
          final inv = [
            [A[1][1] / det, -A[0][1] / det],
            [-A[1][0] / det, A[0][0] / det],
          ];
          setState(() {
            _result = _formatMatrix(inv);
            _steps = 'A⁻¹ = (1/det) × comatrice\ndet = ${_fmt(det)}';
          });
        } else {
          final inv = _gaussJordanInverse(A);
          setState(() {
            _result = _formatMatrix(inv);
            _steps = 'Inverse par Gauss-Jordan\ndet = ${_fmt(det)}';
          });
        }
      } else if (_operation == 'fer') {
        // Forme échelonnée réduite (RREF)
        final r = _rref(A.map((r) => List<double>.from(r)).toList());
        buffer.writeln('Forme échelonnée réduite (FER / RREF) :');
        buffer.writeln(_formatMatrix(r));
        setState(() {
          _result = _formatMatrix(r);
          _steps = buffer.toString();
        });
      } else if (_operation == 'fe') {
        // Forme échelonnée (REF)
        final r = _ref(A.map((r) => List<double>.from(r)).toList());
        buffer.writeln('Forme échelonnée (FE / REF) :');
        buffer.writeln(_formatMatrix(r));
        setState(() {
          _result = _formatMatrix(r);
          _steps = buffer.toString();
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Erreur : $e';
        _steps = '';
      });
    }
  }

  double _determinant(List<List<double>> m) {
    final n = m.length;
    if (n == 1) return m[0][0];
    if (n == 2) return m[0][0] * m[1][1] - m[0][1] * m[1][0];
    // Gauss
    final a = m.map((r) => List<double>.from(r)).toList();
    var det = 1.0;
    for (var i = 0; i < n; i++) {
      var pivot = i;
      for (var r = i + 1; r < n; r++) {
        if (a[r][i].abs() > a[pivot][i].abs()) pivot = r;
      }
      if (a[pivot][i].abs() < 1e-12) return 0;
      if (pivot != i) {
        final tmp = a[i];
        a[i] = a[pivot];
        a[pivot] = tmp;
        det = -det;
      }
      det *= a[i][i];
      for (var r = i + 1; r < n; r++) {
        final f = a[r][i] / a[i][i];
        for (var c = i; c < n; c++) {
          a[r][c] -= f * a[i][c];
        }
      }
    }
    return det;
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
    final ref = _ref(a);
    final m = ref.length;
    final n = ref[0].length;
    for (var i = m - 1; i >= 0; i--) {
      var lead = -1;
      for (var j = 0; j < n; j++) {
        if (ref[i][j].abs() > 1e-12) {
          lead = j;
          break;
        }
      }
      if (lead < 0) continue;
      for (var k = 0; k < i; k++) {
        final f = ref[k][lead];
        for (var j = 0; j < n; j++) {
          ref[k][j] -= f * ref[i][j];
        }
      }
    }
    return ref;
  }

  List<List<double>> _gaussJordanInverse(List<List<double>> m) {
    final n = m.length;
    final aug = List.generate(n, (i) {
      return [
        ...m[i],
        ...List.generate(n, (j) => i == j ? 1.0 : 0.0),
      ];
    });
    final r = _rref(aug);
    return List.generate(n, (i) => r[i].sublist(n));
  }

  Widget _matrixInput(String title, List<List<TextEditingController>> ctrls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Fractions acceptées : 1/2, -3/4…',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        ...List.generate(_rows, (i) {
          return Row(
            children: List.generate(_cols, (j) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: TextField(
                    controller: ctrls[i][j],
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '0',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matrices')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Ordre de la matrice', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Lignes'),
              Expanded(
                child: Slider(
                  value: _rows.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '$_rows',
                  onChanged: (v) => _resize(v.round(), _cols),
                ),
              ),
              Text('$_rows'),
            ],
          ),
          Row(
            children: [
              const Text('Colonnes'),
              Expanded(
                child: Slider(
                  value: _cols.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '$_cols',
                  onChanged: (v) => _resize(_rows, v.round()),
                ),
              ),
              Text('$_cols'),
            ],
          ),
          Row(
            children: [
              const Text('Nombre de matrices'),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('1'),
                selected: _matrixCount == 1,
                onSelected: (_) => setState(() => _matrixCount = 1),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('2'),
                selected: _matrixCount == 2,
                onSelected: (_) => setState(() => _matrixCount = 2),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final op in [
                ('addition', 'A+B'),
                ('soustraction', 'A−B'),
                ('multiplication', 'A×B'),
                ('déterminant', 'det'),
                ('inverse', 'A⁻¹'),
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
          Text(
            _operation == 'fe'
                ? 'FE = forme échelonnée (REF)'
                : _operation == 'fer'
                    ? 'FER = forme échelonnée réduite (RREF)'
                    : '',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          _matrixInput('Matrice A ($_rows×$_cols)', _aControllers),
          if (_matrixCount > 1 &&
              (_operation == 'addition' ||
                  _operation == 'soustraction' ||
                  _operation == 'multiplication')) ...[
            const SizedBox(height: 16),
            _matrixInput('Matrice B', _bControllers),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _calculate,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Calculer'),
          ),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Résultat',
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(_result,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 16, height: 1.5),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_steps,
                    style: const TextStyle(height: 1.4, fontSize: 13)),
              ),
            ).animate().fadeIn(delay: 80.ms),
          ],
        ],
      ),
    );
  }
}
