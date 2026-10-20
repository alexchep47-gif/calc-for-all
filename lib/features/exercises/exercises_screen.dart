import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

/// Module Exercices / Quiz – questions générées avec correction pas-à-pas
class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  String _category = 'calcul';
  _Exercise? _current;
  final TextEditingController _answerController = TextEditingController();
  String? _feedback;
  bool _showSolution = false;
  int _score = 0;
  int _total = 0;

  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    _answerController.clear();
    _feedback = null;
    _showSolution = false;

    switch (_category) {
      case 'calcul':
        final a = _rng.nextInt(20) + 1;
        final b = _rng.nextInt(20) + 1;
        final op = _rng.nextInt(3); // 0+, 1-, 2*
        if (op == 0) {
          _current = _Exercise(
            question: 'Calcule : $a + $b',
            answer: (a + b).toString(),
            solution: ' $a + $b = ${a + b}',
          );
        } else if (op == 1) {
          final x = math.max(a, b);
          final y = math.min(a, b);
          _current = _Exercise(
            question: 'Calcule : $x − $y',
            answer: (x - y).toString(),
            solution: ' $x − $y = ${x - y}',
          );
        } else {
          _current = _Exercise(
            question: 'Calcule : $a × $b',
            answer: (a * b).toString(),
            solution: ' $a × $b = ${a * b}',
          );
        }
        break;

      case 'fraction':
        final n1 = _rng.nextInt(9) + 1;
        final d1 = _rng.nextInt(9) + 2;
        final n2 = _rng.nextInt(9) + 1;
        final d2 = _rng.nextInt(9) + 2;
        final num = n1 * d2 + n2 * d1;
        final den = d1 * d2;
        final g = _gcd(num, den);
        _current = _Exercise(
          question: 'Calcule : $n1/$d1 + $n2/$d2  (forme simplifiée)',
          answer: '${num ~/ g}/${den ~/ g}',
          solution: ' $n1/$d1 + $n2/$d2 = ($n1×$d2 + $n2×$d1)/($d1×$d2) = $num/$den\n'
              'Simplification par $g → ${num ~/ g}/${den ~/ g}',
        );
        break;

      case 'pythagore':
        final a = _rng.nextInt(10) + 3;
        final b = _rng.nextInt(10) + 3;
        final c = math.sqrt(a * a + b * b);
        _current = _Exercise(
          question: 'Triangle rectangle : côtés $a et $b.\nQuelle est l’hypoténuse ? (arrondir à 2 décimales)',
          answer: c.toStringAsFixed(2),
          solution: 'c = √($a² + $b²) = √(${a * a} + ${b * b}) = √${a * a + b * b} ≈ ${c.toStringAsFixed(2)}',
        );
        break;

      case 'suite':
        final u1 = _rng.nextInt(10) + 1;
        final r = _rng.nextInt(5) + 1;
        final n = _rng.nextInt(8) + 3;
        final un = u1 + (n - 1) * r;
        _current = _Exercise(
          question: 'Suite arithmétique : u₁ = $u1 , raison r = $r.\nCalcule u_$n',
          answer: un.toString(),
          solution: 'uₙ = u₁ + (n−1)×r\nu_$n = $u1 + (${n - 1})×$r = $un',
        );
        break;

      case 'proba':
        final n = _rng.nextInt(6) + 4;
        final k = _rng.nextInt(n - 1) + 1;
        final c = _comb(n, k);
        _current = _Exercise(
          question: 'Combien de façons de choisir $k éléments parmi $n ?\n(C($n,$k))',
          answer: c.toString(),
          solution: 'C(n,k) = n! / (k! × (n−k)!)\nC($n,$k) = $c',
        );
        break;

      default:
        _current = _Exercise(question: 'Erreur', answer: '0', solution: '');
    }

    setState(() {});
  }

  int _gcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a.abs();
  }

  int _comb(int n, int k) {
    if (k < 0 || k > n) return 0;
    if (k > n - k) k = n - k;
    int res = 1;
    for (int i = 0; i < k; i++) {
      res = res * (n - i) ~/ (i + 1);
    }
    return res;
  }

  void _check() {
    if (_current == null) return;
    final user = _answerController.text.trim().replaceAll(',', '.');
    final correct = _current!.answer.trim();

    final ok = user == correct ||
        (double.tryParse(user) != null &&
            double.tryParse(correct) != null &&
            (double.parse(user) - double.parse(correct)).abs() < 0.02);

    setState(() {
      _total++;
      if (ok) {
        _score++;
        _feedback = 'Correct !';
      } else {
        _feedback = 'Incorrect. La bonne réponse était : $correct';
      }
      _showSolution = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercices'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Score : $_score / $_total',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _catChip('calcul', 'Calcul'),
              _catChip('fraction', 'Fractions'),
              _catChip('pythagore', 'Pythagore'),
              _catChip('suite', 'Suites'),
              _catChip('proba', 'Probas'),
            ],
          ),
          const SizedBox(height: 24),
          if (_current != null) ...[
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _current!.question,
                  style: const TextStyle(fontSize: 18, height: 1.4),
                ),
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 20),
            TextField(
              controller: _answerController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: InputDecoration(
                labelText: 'Ta réponse',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onSubmitted: (_) => _check(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _check,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Vérifier'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _generate,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Nouveau'),
                  ),
                ),
              ],
            ),
            if (_feedback != null) ...[
              const SizedBox(height: 20),
              Card(
                color: _feedback!.startsWith('Correct') ? Colors.green.shade50 : Colors.red.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _feedback!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _feedback!.startsWith('Correct') ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                ),
              ).animate().fadeIn(),
            ],
            if (_showSolution) ...[
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Solution détaillée', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_current!.solution, style: const TextStyle(height: 1.4)),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms),
            ],
          ],
        ],
      ),
    );
  }

  Widget _catChip(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _category == value,
      onSelected: (_) {
        setState(() {
          _category = value;
          _generate();
        });
      },
    );
  }
}

class _Exercise {
  final String question;
  final String answer;
  final String solution;
  _Exercise({required this.question, required this.answer, required this.solution});
}
