import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Module Matrices : opérations de base + déterminant + inverse (2x2 et 3x3)
class MatricesScreen extends StatefulWidget {
  const MatricesScreen({super.key});

  @override
  State<MatricesScreen> createState() => _MatricesScreenState();
}

class _MatricesScreenState extends State<MatricesScreen> {
  int _size = 2; // 2x2 ou 3x3
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
    _aControllers = List.generate(_size, (_) => List.generate(_size, (_) => TextEditingController(text: '0')));
    _bControllers = List.generate(_size, (_) => List.generate(_size, (_) => TextEditingController(text: '0')));
  }

  @override
  void dispose() {
    for (final row in _aControllers) {
      for (final c in row) c.dispose();
    }
    for (final row in _bControllers) {
      for (final c in row) c.dispose();
    }
    super.dispose();
  }

  List<List<double>> _readMatrix(List<List<TextEditingController>> ctrls) {
    return ctrls.map((row) => row.map((c) => double.tryParse(c.text.replaceAll(',', '.')) ?? 0.0).toList()).toList();
  }

  void _calculate() {
    final A = _readMatrix(_aControllers);
    final B = _readMatrix(_bControllers);
    final buffer = StringBuffer();

    if (_operation == 'addition' || _operation == 'soustraction') {
      final isAdd = _operation == 'addition';
      buffer.writeln(isAdd ? 'Opération : A + B' : 'Opération : A − B');
      buffer.writeln();
      final R = List.generate(_size, (i) => List.generate(_size, (j) {
            return isAdd ? A[i][j] + B[i][j] : A[i][j] - B[i][j];
          }));
      buffer.writeln('Résultat :');
      buffer.writeln(_formatMatrix(R));
      setState(() {
        _result = _formatMatrix(R);
        _steps = buffer.toString();
      });
    } else if (_operation == 'multiplication') {
      buffer.writeln('Opération : A × B');
      buffer.writeln('Chaque élément (i,j) = somme de A[i][k] × B[k][j]');
      buffer.writeln();
      final R = List.generate(_size, (i) => List.generate(_size, (j) {
            double sum = 0;
            for (int k = 0; k < _size; k++) {
              sum += A[i][k] * B[k][j];
            }
            return sum;
          }));
      buffer.writeln('Résultat :');
      buffer.writeln(_formatMatrix(R));
      setState(() {
        _result = _formatMatrix(R);
        _steps = buffer.toString();
      });
    } else if (_operation == 'déterminant') {
      final det = _determinant(A);
      buffer.writeln('Calcul du déterminant de A');
      if (_size == 2) {
        buffer.writeln('Formule 2×2 : a11·a22 − a12·a21');
        buffer.writeln('${A[0][0]} × ${A[1][1]} − ${A[0][1]} × ${A[1][0]} = $det');
      } else {
        buffer.writeln('Formule de Sarrus / développement (3×3)');
        buffer.writeln('det(A) = $det');
      }
      setState(() {
        _result = 'det(A) = ${det.toStringAsFixed(6)}';
        _steps = buffer.toString();
      });
    } else if (_operation == 'inverse') {
      final det = _determinant(A);
      if (det.abs() < 1e-10) {
        setState(() {
          _result = 'Matrice non inversible (det = 0)';
          _steps = 'Le déterminant est nul → pas d’inverse.';
        });
        return;
      }
      final inv = _inverse(A, det);
      buffer.writeln('Inverse de A');
      buffer.writeln('det(A) = $det');
      buffer.writeln('A⁻¹ = (1/det) × comatrice transposée');
      buffer.writeln();
      buffer.writeln('Résultat :');
      buffer.writeln(_formatMatrix(inv));
      setState(() {
        _result = _formatMatrix(inv);
        _steps = buffer.toString();
      });
    }
  }

  double _determinant(List<List<double>> m) {
    if (_size == 2) {
      return m[0][0] * m[1][1] - m[0][1] * m[1][0];
    }
    // 3x3
    return m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) -
        m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0]) +
        m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]);
  }

  List<List<double>> _inverse(List<List<double>> m, double det) {
    if (_size == 2) {
      return [
        [m[1][1] / det, -m[0][1] / det],
        [-m[1][0] / det, m[0][0] / det],
      ];
    }
    // 3x3 via comatrice
    final c = List.generate(3, (_) => List.filled(3, 0.0));
    c[0][0] = m[1][1] * m[2][2] - m[1][2] * m[2][1];
    c[0][1] = -(m[1][0] * m[2][2] - m[1][2] * m[2][0]);
    c[0][2] = m[1][0] * m[2][1] - m[1][1] * m[2][0];
    c[1][0] = -(m[0][1] * m[2][2] - m[0][2] * m[2][1]);
    c[1][1] = m[0][0] * m[2][2] - m[0][2] * m[2][0];
    c[1][2] = -(m[0][0] * m[2][1] - m[0][1] * m[2][0]);
    c[2][0] = m[0][1] * m[1][2] - m[0][2] * m[1][1];
    c[2][1] = -(m[0][0] * m[1][2] - m[0][2] * m[1][0]);
    c[2][2] = m[0][0] * m[1][1] - m[0][1] * m[1][0];

    // Transposée / det
    return List.generate(3, (i) => List.generate(3, (j) => c[j][i] / det));
  }

  String _formatMatrix(List<List<double>> m) {
    return m.map((row) => row.map((v) => v.toStringAsFixed(4)).join('  ')).join('\n');
  }

  Widget _matrixInput(String title, List<List<TextEditingController>> ctrls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...List.generate(_size, (i) {
          return Row(
            children: List.generate(_size, (j) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: TextField(
                    controller: ctrls[i][j],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
          Row(
            children: [
              const Text('Taille : '),
              ChoiceChip(
                label: const Text('2×2'),
                selected: _size == 2,
                onSelected: (_) {
                  setState(() {
                    _size = 2;
                    _initControllers();
                  });
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('3×3'),
                selected: _size == 3,
                onSelected: (_) {
                  setState(() {
                    _size = 3;
                    _initControllers();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'addition', label: Text('A+B')),
              ButtonSegment(value: 'soustraction', label: Text('A−B')),
              ButtonSegment(value: 'multiplication', label: Text('A×B')),
              ButtonSegment(value: 'déterminant', label: Text('det')),
              ButtonSegment(value: 'inverse', label: Text('A⁻¹')),
            ],
            selected: {_operation},
            onSelectionChanged: (s) => setState(() => _operation = s.first),
          ),
          const SizedBox(height: 20),
          _matrixInput('Matrice A', _aControllers),
          if (_operation == 'addition' || _operation == 'soustraction' || _operation == 'multiplication') ...[
            const SizedBox(height: 16),
            _matrixInput('Matrice B', _bControllers),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _calculate,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Calculer'),
          ),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Résultat', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(_result, style: const TextStyle(fontFamily: 'monospace', fontSize: 16, height: 1.5), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_steps, style: const TextStyle(height: 1.4, fontSize: 13)),
              ),
            ).animate().fadeIn(delay: 80.ms),
          ],
        ],
      ),
    );
  }
}
