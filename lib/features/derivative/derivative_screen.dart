import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:math_expressions/math_expressions.dart';

/// Module Dérivée & Intégrale (numérique + règles de base + explications)
class DerivativeScreen extends StatefulWidget {
  const DerivativeScreen({super.key});

  @override
  State<DerivativeScreen> createState() => _DerivativeScreenState();
}

class _DerivativeScreenState extends State<DerivativeScreen> {
  final TextEditingController _funcController = TextEditingController(text: 'x^2');
  final TextEditingController _xController = TextEditingController(text: '2');
  final TextEditingController _aController = TextEditingController(text: '0');
  final TextEditingController _bController = TextEditingController(text: '1');
  String _mode = 'derivée'; // derivée, intégrale
  String _result = '';
  String _steps = '';

  final Parser _parser = Parser();

  double? _eval(String expr, double x) {
    try {
      final e = expr
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', 'pi')
          .replaceAll('√', 'sqrt');
      final exp = _parser.parse(e);
      final ctx = ContextModel();
      ctx.bindVariable(Variable('x'), Number(x));
      final y = exp.evaluate(EvaluationType.REAL, ctx);
      if (y is double && y.isFinite) return y;
    } catch (_) {}
    return null;
  }

  void _calculate() {
    final expr = _funcController.text.trim();
    if (expr.isEmpty) {
      setState(() {
        _result = 'Entre une fonction';
        _steps = '';
      });
      return;
    }

    final buffer = StringBuffer();

    if (_mode == 'derivée') {
      final x0 = double.tryParse(_xController.text.replaceAll(',', '.')) ?? 0;
      // Approximation numérique de la dérivée (différence centrale)
      const h = 1e-5;
      final fPlus = _eval(expr, x0 + h);
      final fMinus = _eval(expr, x0 - h);

      if (fPlus == null || fMinus == null) {
        setState(() {
          _result = 'Impossible d’évaluer la fonction';
          _steps = '';
        });
        return;
      }

      final deriv = (fPlus - fMinus) / (2 * h);

      buffer.writeln('Fonction : f(x) = $expr');
      buffer.writeln('Point d’évaluation : x = $x0');
      buffer.writeln();
      buffer.writeln('Méthode : approximation par différence centrale');
      buffer.writeln('f′(x) ≈ [f(x+h) − f(x−h)] / (2h)');
      buffer.writeln('avec h = $h');
      buffer.writeln();
      buffer.writeln('f(${x0 + h}) ≈ ${fPlus.toStringAsFixed(8)}');
      buffer.writeln('f(${x0 - h}) ≈ ${fMinus.toStringAsFixed(8)}');
      buffer.writeln();
      buffer.writeln('f′($x0) ≈ ${deriv.toStringAsFixed(6)}');

      // Quelques règles classiques rappelées
      buffer.writeln();
      buffer.writeln('Rappels de règles usuelles :');
      buffer.writeln('• (xⁿ)′ = n·xⁿ⁻¹');
      buffer.writeln('• (sin x)′ = cos x');
      buffer.writeln('• (cos x)′ = −sin x');
      buffer.writeln('• (eˣ)′ = eˣ');
      buffer.writeln('• (ln x)′ = 1/x');

      setState(() {
        _result = 'f′($x0) ≈ ${deriv.toStringAsFixed(6)}';
        _steps = buffer.toString();
      });
    } else {
      // Intégrale définie (méthode des trapèzes)
      final a = double.tryParse(_aController.text.replaceAll(',', '.')) ?? 0;
      final b = double.tryParse(_bController.text.replaceAll(',', '.')) ?? 1;
      const n = 200;
      final h = (b - a) / n;
      double sum = 0;

      final fa = _eval(expr, a);
      final fb = _eval(expr, b);
      if (fa == null || fb == null) {
        setState(() {
          _result = 'Impossible d’évaluer la fonction';
          _steps = '';
        });
        return;
      }

      sum = (fa + fb) / 2;
      for (int i = 1; i < n; i++) {
        final xi = a + i * h;
        final yi = _eval(expr, xi);
        if (yi != null) sum += yi;
      }
      final integral = sum * h;

      buffer.writeln('Fonction : f(x) = $expr');
      buffer.writeln('Intervalle : [$a ; $b]');
      buffer.writeln();
      buffer.writeln('Méthode : trapèzes (n = $n subdivisions)');
      buffer.writeln('∫ₐᵇ f(x) dx ≈ (h/2) · [f(a) + 2Σf(xi) + f(b)]');
      buffer.writeln();
      buffer.writeln('Résultat approximatif : ${integral.toStringAsFixed(6)}');

      setState(() {
        _result = '∫ ≈ ${integral.toStringAsFixed(6)}';
        _steps = buffer.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dérivée & Intégrale')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'derivée', label: Text('Dérivée')),
              ButtonSegment(value: 'intégrale', label: Text('Intégrale')),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _funcController,
            decoration: InputDecoration(
              labelText: 'f(x) =',
              hintText: 'ex: x^2, sin(x), 1/x',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          if (_mode == 'derivée')
            TextField(
              controller: _xController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Valeur de x',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _aController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'a (borne inf)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _bController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'b (borne sup)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _calculate,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(_mode == 'derivée' ? 'Calculer la dérivée' : 'Calculer l’intégrale'),
          ),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(_result, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
                    const Text('Explications pas-à-pas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    Text(_steps, style: const TextStyle(height: 1.45, fontSize: 13)),
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
