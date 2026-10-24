import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../data/services/math_library.dart';

/// Solveur d'équations polynomiales de degré n
class SolverScreen extends StatefulWidget {
  const SolverScreen({super.key});

  @override
  State<SolverScreen> createState() => _SolverScreenState();
}

class _SolverScreenState extends State<SolverScreen> {
  int _degree = 2;
  final List<TextEditingController> _controllers = [];
  String _result = '';
  String _steps = '';

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    for (final c in _controllers) {
      c.dispose();
    }
    _controllers.clear();
    for (int i = 0; i <= _degree; i++) {
      _controllers.add(TextEditingController(text: i == 0 ? '1' : '0'));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<double> _getCoefficients() {
    return _controllers.map((c) {
      return double.tryParse(c.text.replaceAll(',', '.')) ?? 0.0;
    }).toList();
  }

  void _solve() {
    final coeffs = _getCoefficients();
    if (coeffs.every((c) => c == 0)) {
      setState(() {
        _result = 'Polynôme nul';
        _steps = 'Tous les coefficients sont nuls.';
      });
      return;
    }

    int realDegree = 0;
    for (int i = 0; i < coeffs.length; i++) {
      if (coeffs[i].abs() > 1e-12) {
        realDegree = _degree - i;
        break;
      }
    }

    final buffer = StringBuffer();
    buffer.writeln('Équation : ${_formatPolynomial(coeffs)} = 0');
    buffer.writeln('Degré détecté : $realDegree');
    buffer.writeln();

    if (realDegree == 0) {
      setState(() {
        _result = coeffs.last == 0 ? 'Identité (toujours vrai)' : 'Aucune solution';
        _steps = buffer.toString();
      });
      return;
    }

    if (realDegree == 1) {
      final a = coeffs[coeffs.length - 2];
      final b = coeffs.last;
      final x = -b / a;
      buffer.writeln('Forme : ax + b = 0');
      buffer.writeln('a = $a , b = $b');
      buffer.writeln('Solution exacte : x = -b / a = ${MathLibrary.format(x)}');
      setState(() {
        _result = 'x = ${MathLibrary.format(x)}';
        _steps = buffer.toString();
      });
      return;
    }

    if (realDegree == 2) {
      final a = coeffs[coeffs.length - 3];
      final b = coeffs[coeffs.length - 2];
      final c = coeffs.last;
      final delta = b * b - 4 * a * c;

      buffer.writeln('Forme : ax² + bx + c = 0');
      buffer.writeln('a = $a , b = $b , c = $c');
      buffer.writeln('Discriminant Δ = b² − 4ac = $delta');
      buffer.writeln();

      if (delta > 0) {
        final x1 = (-b + math.sqrt(delta)) / (2 * a);
        final x2 = (-b - math.sqrt(delta)) / (2 * a);
        buffer.writeln('Δ > 0 → deux solutions réelles distinctes');
        buffer.writeln('x₁ = (-b + √Δ) / 2a = ${MathLibrary.format(x1)}');
        buffer.writeln('x₂ = (-b − √Δ) / 2a = ${MathLibrary.format(x2)}');
        setState(() {
          _result = 'x₁ = ${MathLibrary.format(x1)}\nx₂ = ${MathLibrary.format(x2)}';
          _steps = buffer.toString();
        });
      } else if (delta.abs() < 1e-10) {
        final x = -b / (2 * a);
        buffer.writeln('Δ = 0 → une solution double');
        buffer.writeln('x = -b / 2a = ${MathLibrary.format(x)}');
        setState(() {
          _result = 'x = ${MathLibrary.format(x)} (double)';
          _steps = buffer.toString();
        });
      } else {
        buffer.writeln('Δ < 0 → pas de solution réelle');
        buffer.writeln('Solutions complexes possibles');
        setState(() {
          _result = 'Pas de solution réelle (Δ < 0)';
          _steps = buffer.toString();
        });
      }
      return;
    }

    buffer.writeln('Degré ≥ 3 : utilisation d’une méthode numérique');
    buffer.writeln('(Newton-Raphson avec plusieurs points de départ)');
    buffer.writeln('Les solutions sont approchées.');
    buffer.writeln();

    final roots = _findRootsNumerically(coeffs);
    if (roots.isEmpty) {
      buffer.writeln('Aucune racine réelle trouvée dans l’intervalle exploré.');
      setState(() {
        _result = 'Aucune racine réelle évidente';
        _steps = buffer.toString();
      });
      return;
    }

    buffer.writeln('Racines réelles approchées trouvées :');
    for (int i = 0; i < roots.length; i++) {
      buffer.writeln('  x${i + 1} = ${MathLibrary.format(roots[i])}');
    }

    setState(() {
      _result = roots.map((r) => 'x = ${MathLibrary.format(r)}').join('\n');
      _steps = buffer.toString();
    });
  }

  double _evalPoly(List<double> coeffs, double x) {
    double result = 0;
    for (final c in coeffs) {
      result = result * x + c;
    }
    return result;
  }

  List<double> _derivative(List<double> coeffs) {
    final n = coeffs.length - 1;
    if (n <= 0) return [0];
    final deriv = <double>[];
    for (int i = 0; i < n; i++) {
      deriv.add(coeffs[i] * (n - i));
    }
    return deriv;
  }

  List<double> _findRootsNumerically(List<double> coeffs) {
    final roots = <double>[];
    final starts = [-10.0, -5.0, -2.0, -1.0, -0.5, 0.5, 1.0, 2.0, 5.0, 10.0, -20.0, 20.0];

    for (final start in starts) {
      double x = start;
      for (int iter = 0; iter < 80; iter++) {
        final fx = _evalPoly(coeffs, x);
        final dfx = _evalPoly(_derivative(coeffs), x);
        if (dfx.abs() < 1e-14) break;
        final next = x - fx / dfx;
        if ((next - x).abs() < 1e-10) {
          x = next;
          break;
        }
        x = next;
      }

      final fxFinal = _evalPoly(coeffs, x);
      if (fxFinal.abs() < 1e-6) {
        bool isNew = true;
        for (final r in roots) {
          if ((r - x).abs() < 1e-4) {
            isNew = false;
            break;
          }
        }
        if (isNew) roots.add(x);
      }
    }

    roots.sort();
    return roots;
  }

  String _formatPolynomial(List<double> coeffs) {
    final parts = <String>[];
    final n = coeffs.length - 1;
    for (int i = 0; i < coeffs.length; i++) {
      final c = coeffs[i];
      if (c.abs() < 1e-12) continue;
      final power = n - i;
      String term;
      if (power == 0) {
        term = c.toString();
      } else if (power == 1) {
        term = c == 1 ? 'x' : (c == -1 ? '-x' : '${c}x');
      } else {
        term = c == 1 ? 'x^$power' : (c == -1 ? '-x^$power' : '${c}x^$power');
      }
      parts.add(term);
    }
    if (parts.isEmpty) return '0';
    return parts.join(' + ').replaceAll('+ -', '- ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solveur d’équations')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Degré du polynôme', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _degree.toDouble(),
                  min: 1,
                  max: 8,
                  divisions: 7,
                  label: 'Degré $_degree',
                  onChanged: (v) {
                    setState(() {
                      _degree = v.round();
                      _initControllers();
                    });
                  },
                ),
              ),
              Text('n = $_degree', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Coefficients (aₙ → a₀)', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...List.generate(_controllers.length, (i) {
            final power = _degree - i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _controllers[i],
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: InputDecoration(
                  labelText: power == 0 ? 'a₀ (constante)' : 'a$power (coeff de x^$power)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _solve,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Résoudre', style: TextStyle(fontSize: 17)),
          ),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const Text('Solutions', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(
                      _result,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn().scale(),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Étapes & explications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    Text(_steps, style: const TextStyle(height: 1.45, fontSize: 13)),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 100.ms),
          ],
          const SizedBox(height: 20),
          const Text(
            'Note :\n'
            '• Degré 1 et 2 → solutions exactes\n'
            '• Degré ≥ 3 → solutions numériques approchées\n'
            '• Seules les racines réelles sont affichées',
            style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}
