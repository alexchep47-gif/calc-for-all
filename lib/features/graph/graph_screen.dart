import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Solveur d'équations et d'inéquations.
class SolverScreen extends StatefulWidget {
  const SolverScreen({super.key});

  @override
  State<SolverScreen> createState() => _SolverScreenState();
}

class _SolverScreenState extends State<SolverScreen> {
  final TextEditingController _exprController =
      TextEditingController(text: 'x^2-5*x+6=0');
  String _mode = 'equation';
  String _result = '';
  String _steps = '';

  @override
  void dispose() {
    _exprController.dispose();
    super.dispose();
  }

  void _solve() {
    final raw = _exprController.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _result = 'Saisis une équation ou une inéquation';
        _steps = 'Exemples : x^2-5*x+6=0 ou x^2-4<0';
      });
      return;
    }

    final isInequality = raw.contains('>') ||
        raw.contains('<') ||
        raw.contains('>=') ||
        raw.contains('<=') ||
        raw.contains('!=');

    if (isInequality || _mode == 'inequation') {
      _solveInequality(raw);
      return;
    }

    _solveEquation(raw);
  }

  void _solveEquation(String raw) {
    final normalized = raw
        .replaceAll(' ', '')
        .replaceAll('−', '-')
        .replaceAll('×', '*')
        .replaceAll('÷', '/');

    final eq = normalized.contains('=') ? normalized.split('=')[0] : normalized;
    final coeffs = _parsePolynomial(eq);
    if (coeffs == null) {
      setState(() {
        _result = 'Expression invalide';
        _steps = 'Format attendu : x^2-5*x+6, 2*x+3, x^3-1';
      });
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('Équation : ${_formatPolynomial(coeffs)} = 0');

    final roots = _rootsFromCoefficients(coeffs);
    if (roots.isEmpty) {
      setState(() {
        _result = 'Aucune racine réelle';
        _steps = buffer.toString();
      });
      return;
    }

    final lines = <String>[];
    for (final root in roots) {
      lines.add('x = ${_nice(root)}');
    }
    buffer.writeln('Solutions réelles :');
    for (final line in lines) {
      buffer.writeln('  $line');
    }

    setState(() {
      _result = lines.join('\n');
      _steps = buffer.toString();
    });
  }

  void _solveInequality(String raw) {
    final normalized = raw
        .replaceAll(' ', '')
        .replaceAll('−', '-')
        .replaceAll('×', '*')
        .replaceAll('÷', '/');

    final rel = _extractRelation(normalized);
    if (rel == null) {
      setState(() {
        _result = 'Inéquation invalide';
        _steps = 'Exemples : x^2-4<0, x^2-5*x+6>=0, 2*x+3>0';
      });
      return;
    }

    final left = rel.left;
    final right = rel.right;
    final poly = _parsePolynomial(left, includeRight: right);
    if (poly == null) {
      setState(() {
        _result = 'Inéquation non pris en charge';
        _steps = 'Essayez une forme polynomiale simple en x';
      });
      return;
    }

    final roots = _rootsFromCoefficients(poly);
    if (roots.isEmpty) {
      final sample = _evalPolynomial(poly, 0);
      final sign = sample > 0 ? 'toujours positif' : 'toujours négatif';
      setState(() {
        _result = sign;
        _steps = 'Le polynôme ne change pas de signe sur l’ensemble des réels.';
      });
      return;
    }

    final combined = <double>[...roots, double.negativeInfinity, double.infinity];
    combined.sort();
    final intervals = <String>[];

    for (var i = 0; i < combined.length - 1; i++) {
      final a = combined[i];
      final b = combined[i + 1];
      if (a == double.infinity || b == double.negativeInfinity) continue;
      final mid = (a + b) / 2;
      final val = _evalPolynomial(poly, mid);
      final ok = _signMatches(rel.op, val);
      final leftText = a == double.negativeInfinity ? '-∞' : _nice(a);
      final rightText = b == double.infinity ? '+∞' : _nice(b);
      if (ok) {
        intervals.add(']$leftText ; $rightText[');
      }
    }

    final result = intervals.isNotEmpty
        ? intervals.join(' ∪ ')
        : 'Aucune solution réelle';

    final buffer = StringBuffer();
    buffer.writeln('Inéquation : ${rel.raw}');
    buffer.writeln('Racines : ${roots.map(_nice).join(', ')}');
    buffer.writeln('Ensemble solution : $result');

    setState(() {
      _result = result;
      _steps = buffer.toString();
    });
  }

  _Relation? _extractRelation(String s) {
    final match = RegExp(r'^(.*?)(>=|<=|>|<|!=|=)(.*)$').firstMatch(s);
    if (match == null) return null;
    final left = match.group(1)!;
    final op = match.group(2)!;
    final right = match.group(3)!;
    if (right.isEmpty) return null;
    return _Relation(raw: s, left: left, right: right, op: op);
  }

  List<double>? _parsePolynomial(String expr, {String includeRight = ''}) {
    final fullExpr = (expr.isEmpty ? '0' : expr) + (includeRight.isEmpty ? '' : '-($includeRight)');
    final normalized = fullExpr
        .replaceAll(' ', '')
        .replaceAll('−', '-')
        .replaceAll('×', '*')
        .replaceAll('÷', '/');

    if (!normalized.contains('x')) return null;

    final terms = <String>[];
    var current = '';
    for (var i = 0; i < normalized.length; i++) {
      final ch = normalized[i];
      final isOperator = ch == '+' || ch == '-';
      if (isOperator && current.isNotEmpty && !current.endsWith('^')) {
        terms.add(current);
        current = ch;
      } else {
        current += ch;
      }
    }
    if (current.isNotEmpty) terms.add(current);

    final degreeMap = <int, double>{};
    for (final term in terms) {
      if (term.isEmpty) continue;
      final sign = term.startsWith('-') ? -1 : 1;
      final clean = term.startsWith('+') || term.startsWith('-') ? term.substring(1) : term;
      if (clean.isEmpty) continue;

      if (!clean.contains('x')) {
        degreeMap[0] = (degreeMap[0] ?? 0.0) + sign * double.tryParse(clean)!.toDouble();
        continue;
      }

      final xIndex = clean.indexOf('x');
      final before = clean.substring(0, xIndex);
      final after = clean.substring(xIndex + 1);
      double coeff = 1;
      if (before.isNotEmpty && before != '+') {
        coeff = double.tryParse(before) ?? 1;
      }
      int degree = 1;
      if (after.startsWith('^')) {
        degree = int.tryParse(after.substring(1)) ?? 1;
      }
      degreeMap[degree] = (degreeMap[degree] ?? 0.0) + sign * coeff;
    }

    if (degreeMap.isEmpty) return null;
    final maxDegree = degreeMap.keys.reduce(math.max);
    final coeffs = List<double>.filled(maxDegree + 1, 0.0);
    for (final entry in degreeMap.entries) {
      coeffs[maxDegree - entry.key] = entry.value;
    }
    return coeffs;
  }

  List<double> _rootsFromCoefficients(List<double> coeffs) {
    final real = <double>[];
    final degree = coeffs.length - 1;
    if (degree <= 0) return real;

    if (degree == 1) {
      final a = coeffs[0];
      final b = coeffs[1];
      if (a.abs() < 1e-12) return real;
      real.add(-b / a);
      return real;
    }

    if (degree == 2) {
      final a = coeffs[0];
      final b = coeffs[1];
      final c = coeffs[2];
      final delta = b * b - 4 * a * c;
      if (delta >= 0) {
        final sqrt = math.sqrt(delta);
        real.add((-b + sqrt) / (2 * a));
        if (delta.abs() > 1e-12) real.add((-b - sqrt) / (2 * a));
      }
      return real..sort();
    }

    final candidates = [
      -10.0, -8.0, -6.0, -5.0, -4.0, -3.0, -2.0, -1.5, -1.0, -0.5,
      0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0
    ];
    for (final c in candidates) {
      final x = _newtonSolve(coeffs, c);
      if (x == null) continue;
      final fx = _evalPolynomial(coeffs, x);
      if (fx.abs() < 1e-6) {
        if (!real.any((r) => (r - x).abs() < 1e-4)) real.add(x);
      }
    }
    real.sort();
    return real;
  }

  double? _newtonSolve(List<double> coeffs, double start) {
    var x = start;
    for (var i = 0; i < 80; i++) {
      final fx = _evalPolynomial(coeffs, x);
      final dfx = _evalDerivative(coeffs, x);
      if (dfx.abs() < 1e-12) return null;
      final next = x - fx / dfx;
      if ((next - x).abs() < 1e-10) {
        x = next;
        break;
      }
      x = next;
    }
    return x;
  }

  double _evalPolynomial(List<double> coeffs, double x) {
    var value = 0.0;
    for (var i = 0; i < coeffs.length; i++) {
      value = value * x + coeffs[i];
    }
    return value;
  }

  double _evalDerivative(List<double> coeffs, double x) {
    if (coeffs.length <= 1) return 0;
    var degree = coeffs.length - 1;
    var value = 0.0;
    for (var i = 0; i < coeffs.length - 1; i++) {
      value = value * x + coeffs[i] * degree;
      degree--;
    }
    return value;
  }

  bool _signMatches(String op, double value) {
    switch (op) {
      case '>':
        return value > 0;
      case '>=':
        return value >= 0;
      case '<':
        return value < 0;
      case '<=':
        return value <= 0;
      case '!=':
        return value != 0;
      case '=':
        return value == 0;
      default:
        return false;
    }
  }

  String _formatPolynomial(List<double> coeffs) {
    final parts = <String>[];
    final degree = coeffs.length - 1;
    for (var i = 0; i < coeffs.length; i++) {
      final c = coeffs[i];
      if (c.abs() < 1e-12) continue;
      final power = degree - i;
      if (power == 0) {
        parts.add(c.toString());
      } else if (power == 1) {
        parts.add(c == 1 ? 'x' : (c == -1 ? '-x' : '${c}x'));
      } else {
        parts.add(c == 1 ? 'x^$power' : (c == -1 ? '-x^$power' : '${c}x^$power'));
      }
    }
    if (parts.isEmpty) return '0';
    return parts.join(' + ').replaceAll('+ -', '- ');
  }

  String _nice(double v) {
    if (v.abs() < 1e-9) return '0';
    return v.toStringAsFixed(v.abs() >= 100 ? 2 : 6).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solveur d’équations & inéquations')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'equation', label: Text('Équation')),
              ButtonSegment(value: 'inequation', label: Text('Inéquation')),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) {
              setState(() {
                _mode = selection.first;
                _result = '';
                _steps = '';
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _exprController,
            decoration: InputDecoration(
              labelText: _mode == 'equation' ? 'Équation' : 'Inéquation',
              hintText: 'Ex : x^2-5*x+6=0  /  x^2-4<0',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _solve,
            icon: const Icon(Icons.calculate_outlined),
            label: Text(_mode == 'equation' ? 'Résoudre' : 'Étudier'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Résultat', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SelectableText(
                      _result,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Étapes', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SelectableText(
                      _steps,
                      style: const TextStyle(height: 1.6, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 100.ms),
          ],
        ],
      ),
    );
  }
}

class _Relation {
  final String raw;
  final String left;
  final String right;
  final String op;

  const _Relation({
    required this.raw,
    required this.left,
    required this.right,
    required this.op,
  });
}






























































































































































































