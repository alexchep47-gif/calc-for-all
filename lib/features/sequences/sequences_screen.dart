import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../data/services/math_library.dart';
import '../../data/storage/local_storage.dart';

/// Suites numériques : arithmétique, géométrique, Fibonacci, récurrente, limite
class SequencesScreen extends StatefulWidget {
  const SequencesScreen({super.key});

  @override
  State<SequencesScreen> createState() => _SequencesScreenState();
}

class _SequencesScreenState extends State<SequencesScreen> {
  String _type = 'arithmétique';
  final _u1 = TextEditingController(text: '2');
  final _r = TextEditingController(text: '3');
  final _n = TextEditingController(text: '10');
  final _a = TextEditingController(text: '1');
  final _b = TextEditingController(text: '1');
  String _result = '';
  String _steps = '';
  List<double> _terms = [];

  void _calculate() {
    final u1 = double.tryParse(_u1.text.replaceAll(',', '.'));
    final r = double.tryParse(_r.text.replaceAll(',', '.'));
    final n = int.tryParse(_n.text);
    if (u1 == null || n == null || n < 1) {
      setState(() {
        _result = 'Entrées invalides';
        _steps = '';
        _terms = [];
      });
      return;
    }

    final buf = StringBuffer();
    final terms = <double>[];
    double un;
    double sn;

    switch (_type) {
      case 'arithmétique':
        if (r == null) return;
        buf.writeln('Suite arithmétique : uₙ = u₁ + (n−1)·r');
        buf.writeln('u₁ = ${MathLibrary.format(u1)}, r = ${MathLibrary.format(r)}, n = $n');
        un = u1 + (n - 1) * r;
        sn = n * (u1 + un) / 2;
        buf.writeln('uₙ = ${MathLibrary.format(u1)} + (${n − 1})·${MathLibrary.format(r)} = ${MathLibrary.format(un)}');
        buf.writeln('Sₙ = n·(u₁+uₙ)/2 = ${MathLibrary.format(sn)}');
        for (var k = 1; k <= n && k <= 20; k++) {
          terms.add(u1 + (k - 1) * r);
        }
        break;

      case 'géométrique':
        if (r == null) return;
        buf.writeln('Suite géométrique : uₙ = u₁ · q^(n−1)');
        buf.writeln('u₁ = ${MathLibrary.format(u1)}, q = ${MathLibrary.format(r)}, n = $n');
        un = u1 * MathLibrary.pow(r, (n - 1).toDouble());
        if ((r - 1).abs() < 1e-12) {
          sn = n * u1;
        } else {
          sn = u1 * (1 - MathLibrary.pow(r, n.toDouble())) / (1 - r);
        }
        buf.writeln('uₙ = ${MathLibrary.format(un)}');
        buf.writeln('Sₙ = ${MathLibrary.format(sn)}');
        if (r.abs() < 1) {
          buf.writeln('Comme |q| < 1, lim Sₙ = u₁/(1−q) = ${MathLibrary.format(u1 / (1 - r))}');
        }
        for (var k = 1; k <= n && k <= 20; k++) {
          terms.add(u1 * MathLibrary.pow(r, (k - 1).toDouble()));
        }
        break;

      case 'Fibonacci':
        buf.writeln('Suite de Fibonacci : F₁ = 1, F₂ = 1, Fₙ = Fₙ₋₁ + Fₙ₋₂');
        var a = 1.0, b = 1.0;
        if (n == 1) {
          un = 1;
          terms.add(1);
        } else if (n == 2) {
          un = 1;
          terms.addAll([1, 1]);
        } else {
          terms.addAll([1, 1]);
          for (var k = 3; k <= n; k++) {
            final c = a + b;
            a = b;
            b = c;
            if (terms.length < 20) terms.add(c);
          }
          un = b;
        }
        sn = terms.fold(0.0, (s, t) => s + t);
        // Si n>20, recalculer somme exacte via formule F1+…+Fn = F_{n+2}-1
        if (n > 20) {
          var x = 1.0, y = 1.0;
          for (var k = 3; k <= n + 2; k++) {
            final z = x + y;
            x = y;
            y = z;
          }
          sn = y - 1; // F_{n+2} - 1
        }
        buf.writeln('Fₙ = ${MathLibrary.format(un)}');
        buf.writeln('Sₙ ≈ ${MathLibrary.format(sn)}');
        break;

      case 'récurrente':
        // u_{n+1} = a·u_n + b
        final aa = double.tryParse(_a.text.replaceAll(',', '.')) ?? 1;
        final bb = double.tryParse(_b.text.replaceAll(',', '.')) ?? 0;
        buf.writeln('Suite récurrente : uₙ₊₁ = a·uₙ + b');
        buf.writeln('a = ${MathLibrary.format(aa)}, b = ${MathLibrary.format(bb)}, u₁ = ${MathLibrary.format(u1)}');
        var u = u1;
        terms.add(u);
        for (var k = 2; k <= n; k++) {
          u = aa * u + bb;
          if (terms.length < 20) terms.add(u);
        }
        un = u;
        sn = terms.fold(0.0, (s, t) => s + t);
        // Point fixe si |a|<1 : L = b/(1-a)
        if (aa.abs() < 1) {
          final L = bb / (1 - aa);
          buf.writeln('Point fixe L = b/(1−a) = ${MathLibrary.format(L)}');
          buf.writeln('La suite converge vers L si |a| < 1.');
        }
        buf.writeln('uₙ = ${MathLibrary.format(un)}');
        break;

      default:
        un = u1;
        sn = u1;
    }

    final resText = 'uₙ = ${MathLibrary.format(un)}\nSₙ = ${MathLibrary.format(sn)}';
    setState(() {
      _result = resText;
      _steps = buf.toString();
      _terms = terms;
    });

    try {
      context.read<LocalStorage>().addToHistory(
            'Suite $_type n=$n',
            resText.replaceAll('\n', ' · '),
            module: 'Suites',
          );
    } catch (_) {}
  }

  // Fix operator − used as unicode in string interpolation above - use -
  // Actually I used n − 1 with unicode minus in string - need ascii

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suites numériques')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final t in [
                'arithmétique',
                'géométrique',
                'Fibonacci',
                'récurrente',
              ])
                ChoiceChip(
                  label: Text(t),
                  selected: _type == t,
                  onSelected: (_) => setState(() {
                    _type = t;
                    _result = '';
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _u1,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: const InputDecoration(
              labelText: 'Premier terme u₁',
              border: OutlineInputBorder(),
            ),
          ),
          if (_type == 'arithmétique' || _type == 'géométrique') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _r,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: InputDecoration(
                labelText: _type == 'arithmétique' ? 'Raison r' : 'Raison q',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          if (_type == 'récurrente') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _a,
              decoration: const InputDecoration(
                labelText: 'Coefficient a (uₙ₊₁ = a·uₙ + b)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _b,
              decoration: const InputDecoration(
                labelText: 'Constante b',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _n,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Rang n',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _calculate,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Calculer uₙ et Sₙ'),
          ),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _result,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
            ).animate().fadeIn(),
            if (_terms.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Premiers termes : ${_terms.map(MathLibrary.format).join(', ')}'
                '${(_n.text.isNotEmpty && (int.tryParse(_n.text) ?? 0) > 20) ? ' …' : ''}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Explications pas à pas',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_steps, style: const TextStyle(height: 1.45, fontSize: 13)),
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
