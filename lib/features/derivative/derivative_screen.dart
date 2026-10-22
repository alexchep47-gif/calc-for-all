import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/services/math_expression_engine.dart';
import '../../data/services/math_library.dart';

/// Module Dérivée & Intégrale (symbolique hors-ligne + calcul numérique optionnel).
class DerivativeScreen extends StatefulWidget {
  const DerivativeScreen({super.key});

  @override
  State<DerivativeScreen> createState() => _DerivativeScreenState();
}

class _DerivativeScreenState extends State<DerivativeScreen> {
  final TextEditingController _funcController =
      TextEditingController(text: 'x^2');
  final TextEditingController _xController = TextEditingController(text: '2');
  final TextEditingController _aController = TextEditingController(text: '0');
  final TextEditingController _bController = TextEditingController(text: '1');
  String _mode = 'derivée'; // derivée, intégrale
  String _result = '';
  String _numericResult = '';
  String _steps = '';

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

    final buffer = StringBuffer();

    if (_mode == 'derivée') {
      final symbolic = _engine.derivativePretty(expr);
      if (symbolic == null) {
        setState(() {
          _result = 'Dérivée symbolique non disponible';
          _numericResult = '';
          _steps = '';
        });
        return;
      }

      buffer.writeln('Fonction : f(x) = $expr');
      buffer.writeln();
      buffer.writeln('Méthode : dérivation symbolique hors-ligne');
      buffer.writeln(
          'Application récursive des règles de somme, produit, quotient, puissance et fonctions usuelles.');
      buffer.writeln();
      buffer.writeln('Forme algébrique : f′(x) = $symbolic');
      buffer.writeln();
      if (_xController.text.trim().isNotEmpty) {
        final x0 = double.tryParse(_xController.text.replaceAll(',', '.'));
        final value = x0 == null ? null : _engine.evaluate(symbolic, x0);
        if (value != null) {
          _numericResult =
              'f′(${_xController.text.trim()}) = ${MathLibrary.format(value)}';
          buffer.writeln(_numericResult);
        } else {
          _numericResult = 'Valeur de x hors du domaine de définition';
        }
      } else {
        _numericResult = '';
        buffer.writeln('Aucune valeur numérique demandée.');
      }

      // Quelques règles classiques rappelées
      buffer.writeln();
      buffer.writeln('Rappels de règles usuelles :');
      buffer.writeln('• (xⁿ)′ = n·xⁿ⁻¹');
      buffer.writeln('• (sin x)′ = cos x');
      buffer.writeln('• (cos x)′ = −sin x');
      buffer.writeln('• (eˣ)′ = eˣ');
      buffer.writeln('• (ln x)′ = 1/x');

      setState(() {
        _result = 'f′(x) = $symbolic';
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
      buffer.writeln('Résultat approximatif : ${MathLibrary.format(integral)}');

      setState(() {
        _result = '∫ ≈ ${MathLibrary.format(integral)}';
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
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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
                hintText: 'Laisser vide pour garder la forme générale',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _aController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'a (borne inf)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _bController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'b (borne sup)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(_mode == 'derivée'
                ? 'Calculer la dérivée'
                : 'Calculer l’intégrale'),
          ),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(_result,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
              ),
            ).animate().fadeIn().scale(),
            if (_mode == 'derivée' && _numericResult.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      _numericResult,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Explications pas-à-pas',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    Text(_steps,
                        style: const TextStyle(height: 1.45, fontSize: 13)),
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
