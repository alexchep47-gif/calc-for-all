import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/services/math_expression_engine.dart';
import '../../data/services/math_library.dart';
import '../../data/services/math_pretty.dart';

/// Module Dérivée & Intégrale — composées, parties, changement de variable
class DerivativeScreen extends StatefulWidget {
  const DerivativeScreen({super.key});

  @override
  State<DerivativeScreen> createState() => _DerivativeScreenState();
}

class _DerivativeScreenState extends State<DerivativeScreen> {
  final TextEditingController _funcController =
      TextEditingController(text: 'sin(2*x)');
  final TextEditingController _xController = TextEditingController();
  final TextEditingController _aController = TextEditingController(text: '0');
  final TextEditingController _bController = TextEditingController(text: '1');
  String _mode = 'derivée';
  String _result = '';
  String _numericResult = '';
  String _steps = '';
  bool _definedIntegral = false;

  final MathExpressionEngine _engine = MathExpressionEngine();

  double? _eval(String expr, double x) {
    try {
      return _engine.evaluate(expr, x);
    } catch (_) {
      return null;
    }
  }

  void _calculate() {
    final expr = _funcController.text.trim();
    if (expr.isEmpty) {
      setState(() {
        _result = 'Entre une fonction';
        _numericResult = '';
        _steps = '';
      });
      return;
    }

    if (_mode == 'derivée') {
      final symbolic = _engine.derivativePretty(expr);
      final steps = _engine.derivativeSteps(expr);

      if (symbolic == null) {
        setState(() {
          _result = 'Dérivée symbolique non disponible';
          _numericResult = '';
          _steps = steps;
        });
        return;
      }

      final buffer = StringBuffer(steps);
      buffer.writeln();

      if (_xController.text.trim().isNotEmpty) {
        final x0 = double.tryParse(_xController.text.replaceAll(',', '.'));
        // Évaluer la dérivée brute si possible
        final raw = _engine.derivative(expr);
        final value = x0 == null || raw == null
            ? null
            : _engine.evaluate(raw, x0);
        if (value != null) {
          _numericResult =
              'f′(${_xController.text.trim()}) = ${MathLibrary.format(value)}';
          buffer.writeln(_numericResult);
        } else {
          _numericResult = 'Valeur de x hors du domaine de définition';
          buffer.writeln(_numericResult);
        }
      } else {
        _numericResult = '';
      }

      buffer.writeln();
      buffer.writeln('Exemples de composées gérées :');
      buffer.writeln('• sin(2x), cos(x²), exp(3x+1), ln(x+1), √(x²+1)');
      buffer.writeln('• Règle de la chaîne : [g(u)]′ = g′(u)·u′');

      setState(() {
        _result = 'f′(x) = $symbolic';
        _steps = buffer.toString();
      });
    } else {
      // Intégrale
      final integ = _engine.integrateSymbolic(expr);

      if (!_definedIntegral) {
        setState(() {
          if (integ.primitive == null) {
            _result = 'Primitive non trouvée pour cette forme';
            _steps = integ.steps;
          } else {
            _result = '∫ ${MathPretty.format(expr)} dx = ${integ.primitive}';
            _steps =
                'Méthode : ${integ.method}\n\n${integ.steps}';
          }
          _numericResult = '';
        });
        return;
      }

      // Intégrale définie (trapèzes) + rappel symbolique si dispo
      final a = double.tryParse(_aController.text.replaceAll(',', '.')) ?? 0;
      final b = double.tryParse(_bController.text.replaceAll(',', '.')) ?? 1;
      const n = 200;
      final h = (b - a) / n;

      final fa = _eval(expr, a);
      final fb = _eval(expr, b);
      if (fa == null || fb == null) {
        setState(() {
          _result = 'Impossible d’évaluer la fonction aux bornes';
          _steps = '';
        });
        return;
      }

      double sum = (fa + fb) / 2;
      for (int i = 1; i < n; i++) {
        final yi = _eval(expr, a + i * h);
        if (yi != null) sum += yi;
      }
      final integral = sum * h;

      final buffer = StringBuffer();
      buffer.writeln('Fonction : f(x) = ${MathPretty.format(expr)}');
      buffer.writeln('Intervalle : [$a ; $b]');
      buffer.writeln();
      if (integ.primitive != null) {
        buffer.writeln('Primitive symbolique (${integ.method}) :');
        buffer.writeln('  ${integ.primitive}');
        buffer.writeln();
      }
      buffer.writeln('Méthode numérique : trapèzes (n = $n)');
      buffer.writeln('∫ₐᵇ f ≈ ${MathLibrary.format(integral)}');

      setState(() {
        _result = '∫ ≈ ${MathLibrary.format(integral)}';
        _steps = buffer.toString();
        _numericResult = '';
      });
    }
  }

  void _loadExample() {
    if (_mode == 'derivée') {
      const examples = [
        'sin(2*x)',
        'cos(x^2)',
        'exp(3*x+1)',
        'ln(x+1)',
        'sqrt(x^2+1)',
        'x*sin(x)',
      ];
      final cur = _funcController.text.trim();
      final i = examples.indexOf(cur);
      _funcController.text = examples[(i + 1) % examples.length];
    } else {
      const examples = [
        'x*sin(x)',
        'x*exp(x)',
        'ln(x)',
        'sin(2*x)',
        '1/(2*x+1)',
        '(3*x+1)^2',
        'x*ln(x)',
      ];
      final cur = _funcController.text.trim();
      final i = examples.indexOf(cur);
      _funcController.text = examples[(i + 1) % examples.length];
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dérivée & Intégrale'),
        actions: [
          TextButton(
            onPressed: _loadExample,
            child: const Text('Exemple'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'derivée', label: Text('Dérivée')),
              ButtonSegment(value: 'intégrale', label: Text('Intégrale')),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() {
              _mode = s.first;
              _result = '';
              _steps = '';
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _funcController,
            decoration: InputDecoration(
              labelText: 'f(x) =',
              hintText: _mode == 'derivée'
                  ? 'ex: sin(2*x), cos(x^2), ln(x+1)'
                  : 'ex: x*sin(x), ln(x), sin(2*x)',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          if (_mode == 'derivée')
            TextField(
              controller: _xController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Valeur de x (optionnel)',
                hintText: 'Laisser vide pour la forme générale',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            )
          else
            Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Intégrale définie'),
                  subtitle: const Text(
                      'Désactiver pour la primitive (parties / substitution)'),
                  value: _definedIntegral,
                  onChanged: (value) =>
                      setState(() => _definedIntegral = value),
                ),
                if (_definedIntegral)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _aController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                          decoration: const InputDecoration(
                            labelText: 'a',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _bController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                          decoration: const InputDecoration(
                            labelText: 'b',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.functions),
            label: Text(_mode == 'derivée' ? 'Dériver' : 'Intégrer'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
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
                    Text(
                      _result,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (_numericResult.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(_numericResult),
                    ],
                  ],
                ),
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Démarche pas à pas',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
