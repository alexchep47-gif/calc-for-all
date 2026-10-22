import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../data/services/math_library.dart';
import '../../data/storage/local_storage.dart';

/// Suites numériques : arithmétique, géométrique, Fibonacci, récurrente
class SequencesScreen extends StatefulWidget {
  const SequencesScreen({super.key});

  @override
  State<SequencesScreen> createState() => _SequencesScreenState();
}

class _SequencesScreenState extends State<SequencesScreen> {
  String _type = 'arithmetique';
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
        _result = 'Entrees invalides';
        _steps = '';
        _terms = [];
      });
      return;
    }

    final buf = StringBuffer();
    final terms = <double>[];
    late double un;
    late double sn;

    switch (_type) {
      case 'arithmetique':
        if (r == null) return;
        buf.writeln('Suite arithmetique : un = u1 + (n-1)*r');
        buf.writeln(
            'u1 = ${MathLibrary.format(u1)}, r = ${MathLibrary.format(r)}, n = $n');
        un = u1 + (n - 1) * r;
        sn = n * (u1 + un) / 2;
        buf.writeln(
            'un = ${MathLibrary.format(u1)} + (${n - 1})*${MathLibrary.format(r)} = ${MathLibrary.format(un)}');
        buf.writeln('Sn = n*(u1+un)/2 = ${MathLibrary.format(sn)}');
        for (var k = 1; k <= n && k <= 20; k++) {
          terms.add(u1 + (k - 1) * r);
        }
        break;

      case 'geometrique':
        if (r == null) return;
        buf.writeln('Suite geometrique : un = u1 * q^(n-1)');
        buf.writeln(
            'u1 = ${MathLibrary.format(u1)}, q = ${MathLibrary.format(r)}, n = $n');
        un = u1 * MathLibrary.pow(r, (n - 1).toDouble());
        if ((r - 1).abs() < 1e-12) {
          sn = n * u1;
        } else {
          sn = u1 * (1 - MathLibrary.pow(r, n.toDouble())) / (1 - r);
        }
        buf.writeln('un = ${MathLibrary.format(un)}');
        buf.writeln('Sn = ${MathLibrary.format(sn)}');
        if (r.abs() < 1) {
          buf.writeln(
              'Comme |q| < 1, lim Sn = u1/(1-q) = ${MathLibrary.format(u1 / (1 - r))}');
        }
        for (var k = 1; k <= n && k <= 20; k++) {
          terms.add(u1 * MathLibrary.pow(r, (k - 1).toDouble()));
        }
        break;

      case 'Fibonacci':
        buf.writeln('Suite de Fibonacci : F1=1, F2=1, Fn = F(n-1)+F(n-2)');
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
        if (n > 20) {
          var x = 1.0, y = 1.0;
          for (var k = 3; k <= n + 2; k++) {
            final z = x + y;
            x = y;
            y = z;
          }
          sn = y - 1;
        }
        buf.writeln('Fn = ${MathLibrary.format(un)}');
        buf.writeln('Sn = ${MathLibrary.format(sn)}');
        break;

      case 'recurrente':
        final aa = double.tryParse(_a.text.replaceAll(',', '.')) ?? 1;
        final bb = double.tryParse(_b.text.replaceAll(',', '.')) ?? 0;
        buf.writeln('Suite recurrente : u(n+1) = a*un + b');
        buf.writeln(
            'a = ${MathLibrary.format(aa)}, b = ${MathLibrary.format(bb)}, u1 = ${MathLibrary.format(u1)}');
        var u = u1;
        terms.add(u);
        for (var k = 2; k <= n; k++) {
          u = aa * u + bb;
          if (terms.length < 20) terms.add(u);
        }
        un = u;
        sn = terms.fold(0.0, (s, t) => s + t);
        if (aa.abs() < 1) {
          final L = bb / (1 - aa);
          buf.writeln('Point fixe L = b/(1-a) = ${MathLibrary.format(L)}');
          buf.writeln('La suite converge vers L si |a| < 1.');
        }
        buf.writeln('un = ${MathLibrary.format(un)}');
        break;

      default:
        un = u1;
        sn = u1;
    }

    final resText =
        'un = ${MathLibrary.format(un)}\nSn = ${MathLibrary.format(sn)}';
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

  @override
  Widget build(BuildContext context) {
    final labels = {
      'arithmetique': 'Arithmetique',
      'geometrique': 'Geometrique',
      'Fibonacci': 'Fibonacci',
      'recurrente': 'Recurrente',
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Suites numeriques')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final t in labels.keys)
                ChoiceChip(
                  label: Text(labels[t]!),
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
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
            decoration: const InputDecoration(
              labelText: 'Premier terme u1',
              border: OutlineInputBorder(),
            ),
          ),
          if (_type == 'arithmetique' || _type == 'geometrique') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _r,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: InputDecoration(
                labelText: _type == 'arithmetique' ? 'Raison r' : 'Raison q',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          if (_type == 'recurrente') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _a,
              decoration: const InputDecoration(
                labelText: 'Coefficient a (u(n+1) = a*un + b)',
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
            child: const Text('Calculer un et Sn'),
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
                'Premiers termes : ${_terms.map(MathLibrary.format).join(', ')}',
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
                    const Text('Explications pas a pas',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_steps,
                        style: const TextStyle(height: 1.45, fontSize: 13)),
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
