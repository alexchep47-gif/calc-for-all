import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

/// Module Probabilités : permutations, arrangements, combinaisons
class ProbabilityScreen extends StatefulWidget {
  const ProbabilityScreen({super.key});

  @override
  State<ProbabilityScreen> createState() => _ProbabilityScreenState();
}

class _ProbabilityScreenState extends State<ProbabilityScreen> {
  final TextEditingController _nController = TextEditingController();
  final TextEditingController _kController = TextEditingController();
  String _result = '';
  String _steps = '';
  String _mode = 'combinaison'; // permutation, arrangement, combinaison

  int? _parse(String s) => int.tryParse(s.trim());

  BigInt _factorial(int n) {
    if (n < 0) return BigInt.from(0);
    BigInt res = BigInt.one;
    for (int i = 2; i <= n; i++) {
      res *= BigInt.from(i);
    }
    return res;
  }

  void _calculate() {
    final n = _parse(_nController.text);
    final k = _parse(_kController.text);

    if (n == null || n < 0) {
      setState(() {
        _result = 'n invalide';
        _steps = 'n doit être un entier ≥ 0';
      });
      return;
    }

    if (_mode != 'permutation' && (k == null || k < 0)) {
      setState(() {
        _result = 'k invalide';
        _steps = 'k doit être un entier ≥ 0';
      });
      return;
    }

    if (k != null && k > n) {
      setState(() {
        _result = 'Impossible';
        _steps = 'k ne peut pas être supérieur à n';
      });
      return;
    }

    final buffer = StringBuffer();
    BigInt value;

    switch (_mode) {
      case 'permutation':
        // n!
        value = _factorial(n);
        buffer.writeln('Formule : P(n) = n!');
        buffer.writeln('P($n) = $n!');
        buffer.writeln();
        buffer.writeln('Calcul :');
        if (n <= 12) {
          buffer.write('$n! = ');
          for (int i = n; i >= 1; i--) {
            buffer.write(i);
            if (i > 1) buffer.write(' × ');
          }
          buffer.writeln();
        }
        buffer.writeln('Résultat = $value');
        break;

      case 'arrangement':
        // A(n,k) = n! / (n-k)!
        value = _factorial(n) ~/ _factorial(n - k!);
        buffer.writeln('Formule : A(n, k) = n! / (n − k)!');
        buffer.writeln('A($n, $k) = $n! / (${n - k})!');
        buffer.writeln();
        buffer.writeln('Étapes :');
        buffer.writeln('1. Calculer $n! = ${_factorial(n)}');
        buffer.writeln('2. Calculer (${n - k})! = ${_factorial(n - k)}');
        buffer.writeln('3. Diviser : ${_factorial(n)} ÷ ${_factorial(n - k)}');
        buffer.writeln();
        buffer.writeln('Résultat = $value');
        break;

      case 'combinaison':
      default:
        // C(n,k) = n! / (k! × (n-k)!)
        value = _factorial(n) ~/ (_factorial(k!) * _factorial(n - k));
        buffer.writeln('Formule : C(n, k) = n! / (k! × (n − k)!)');
        buffer.writeln('C($n, $k) = $n! / ($k! × (${n - k})!)');
        buffer.writeln();
        buffer.writeln('Étapes :');
        buffer.writeln('1. Calculer $n! = ${_factorial(n)}');
        buffer.writeln('2. Calculer $k! = ${_factorial(k)}');
        buffer.writeln('3. Calculer (${n - k})! = ${_factorial(n - k)}');
        buffer.writeln('4. Multiplier k! × (n−k)! = ${_factorial(k) * _factorial(n - k)}');
        buffer.writeln('5. Diviser : ${_factorial(n)} ÷ ${_factorial(k) * _factorial(n - k)}');
        buffer.writeln();
        buffer.writeln('Résultat = $value');
        break;
    }

    setState(() {
      _result = value.toString();
      _steps = buffer.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Probabilités')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Choix du type
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'combinaison', label: Text('C(n,k)')),
              ButtonSegment(value: 'arrangement', label: Text('A(n,k)')),
              ButtonSegment(value: 'permutation', label: Text('n!')),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ).animate().fadeIn(),
          const SizedBox(height: 20),

          TextField(
            controller: _nController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'n (total d’éléments)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          if (_mode != 'permutation') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _kController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'k (éléments choisis)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _calculate,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Calculer', style: TextStyle(fontSize: 17)),
          ),
          const SizedBox(height: 24),

          if (_result.isNotEmpty) ...[
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const Text('Résultat', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 6),
                    Text(
                      _result,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn().scale(),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Explications pas-à-pas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    Text(_steps, style: const TextStyle(height: 1.45, fontFamily: 'monospace', fontSize: 13)),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 150.ms),
          ],

          const SizedBox(height: 20),
          const Text(
            'Rappel :\n'
            '• Combinaison C(n,k) → l’ordre ne compte pas\n'
            '• Arrangement A(n,k) → l’ordre compte\n'
            '• Permutation n! → tous les rangements possibles',
            style: TextStyle(color: Colors.grey, height: 1.4),
          ),
        ],
      ),
    );
  }
}
