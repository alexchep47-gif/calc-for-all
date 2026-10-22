import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/locale_provider.dart';
import '../../data/services/math_library.dart';

/// Probabilités : combinatoire + lois binomiale et normale
class ProbabilityScreen extends StatefulWidget {
  const ProbabilityScreen({super.key});

  @override
  State<ProbabilityScreen> createState() => _ProbabilityScreenState();
}

class _ProbabilityScreenState extends State<ProbabilityScreen> {
  final TextEditingController _nController = TextEditingController();
  final TextEditingController _kController = TextEditingController();
  final TextEditingController _pController = TextEditingController(text: '0.5');
  final TextEditingController _muController = TextEditingController(text: '0');
  final TextEditingController _sigmaController =
      TextEditingController(text: '1');
  final TextEditingController _xController = TextEditingController(text: '0');

  String _result = '';
  String _steps = '';
  String _mode =
      'combinaison'; // combinaison, arrangement, permutation, puplet, binomiale, normale

  String _text(String fr, String en) =>
      context.read<LocaleProvider>().isFrench ? fr : en;

  int? _parseInt(String s) => int.tryParse(s.trim());
  double? _parseDouble(String s) =>
      double.tryParse(s.trim().replaceAll(',', '.'));

  BigInt _factorial(int n) {
    if (n < 0) return BigInt.zero;
    BigInt res = BigInt.one;
    for (int i = 2; i <= n; i++) {
      res *= BigInt.from(i);
    }
    return res;
  }

  BigInt _comb(int n, int k) {
    if (k < 0 || k > n) return BigInt.zero;
    if (k > n - k) k = n - k;
    BigInt res = BigInt.one;
    for (int i = 0; i < k; i++) {
      res = res * BigInt.from(n - i) ~/ BigInt.from(i + 1);
    }
    return res;
  }

  BigInt _powerInt(int base, int exponent) {
    BigInt result = BigInt.one;
    for (int i = 0; i < exponent; i++) {
      result *= BigInt.from(base);
    }
    return result;
  }

  void _loadExample() {
    setState(() {
      switch (_mode) {
        case 'combinaison':
          _nController.text = '10';
          _kController.text = '3';
          break;
        case 'arrangement':
          _nController.text = '8';
          _kController.text = '3';
          break;
        case 'permutation':
          _nController.text = '6';
          break;
        case 'puplet':
          _nController.text = '5';
          _kController.text = '3';
          break;
        case 'binomiale':
          _nController.text = '10';
          _kController.text = '4';
          _pController.text = '0.5';
          break;
        case 'normale':
          _muController.text = '0';
          _sigmaController.text = '1';
          _xController.text = '1.96';
          break;
      }
      _result = '';
      _steps = '';
    });
  }

  /// Approximation de Φ(z) (loi normale centrée réduite)
  double _phi(double z) {
    // Approximation de Hart / rational
    final t = 1.0 / (1.0 + 0.2316419 * z.abs());
    final d = 0.3989423 * math.exp(-z * z / 2);
    final p = d *
        t *
        (0.3193815 +
            t * (-0.3565638 + t * (1.781478 + t * (-1.821256 + t * 1.330274))));
    return z >= 0 ? 1 - p : p;
  }

  void _calculate() {
    final buffer = StringBuffer();
    final isFr = context.read<LocaleProvider>().isFrench;

    if (_mode == 'binomiale') {
      final n = _parseInt(_nController.text);
      final k = _parseInt(_kController.text);
      final p = _parseDouble(_pController.text);
      if (n == null ||
          k == null ||
          p == null ||
          n < 0 ||
          k < 0 ||
          k > n ||
          p < 0 ||
          p > 1) {
        setState(() {
          _result = _text('Paramètres invalides', 'Invalid parameters');
          _steps = _text('n ≥ k ≥ 0 et 0 ≤ p ≤ 1', 'n ≥ k ≥ 0 and 0 ≤ p ≤ 1');
        });
        return;
      }
      final c = _comb(n, k).toDouble();
      final prob = c * math.pow(p, k) * math.pow(1 - p, n - k);
      buffer.writeln(_text('Loi binomiale B(n, p)', 'Binomial law B(n, p)'));
      buffer.writeln(_text('P(X = k) = C(n,k) × p^k × (1-p)^(n-k)',
          'P(X = k) = C(n,k) × p^k × (1-p)^(n-k)'));
      buffer.writeln('n = $n, k = $k, p = $p');
      buffer.writeln('C($n,$k) = $c');
      buffer.writeln('${_text('P(X = ', 'P(X = ')}$k) = ${MathLibrary.format(prob)}');
      setState(() {
        _result = MathLibrary.format(prob);
        _steps = buffer.toString();
      });
      return;
    }

    if (_mode == 'normale') {
      final mu = _parseDouble(_muController.text) ?? 0;
      final sigma = _parseDouble(_sigmaController.text) ?? 1;
      final x = _parseDouble(_xController.text) ?? 0;
      if (sigma <= 0) {
        setState(() {
          _result = _text('σ doit être > 0', 'σ must be > 0');
          _steps = '';
        });
        return;
      }
      final z = (x - mu) / sigma;
      final density =
          (1 / (sigma * math.sqrt(2 * math.pi))) * math.exp(-0.5 * z * z);
      final cdf = _phi(z);
      buffer.writeln(_text('Loi normale N(μ, σ²)', 'Normal law N(μ, σ²)'));
      buffer.writeln('μ = $mu, σ = $sigma, x = $x');
      buffer.writeln('z = (x − μ) / σ = $z');
      buffer.writeln('${_text('Densité f(x) = ', 'Density f(x) = ')}${MathLibrary.format(density)}');
      buffer.writeln('${_text('P(X ≤ x) = Φ(z) = ', 'P(X ≤ x) = Φ(z) = ')}${MathLibrary.format(cdf)}');
      setState(() {
        _result =
            '${_text('f(x) = ', 'f(x) = ')}${MathLibrary.format(density)}\n${_text('P(X≤x) = ', 'P(X≤x) = ')}${MathLibrary.format(cdf)}';
        _steps = buffer.toString();
      });
      return;
    }

    if (_mode == 'puplet') {
      final n = _parseInt(_nController.text);
      final k = _parseInt(_kController.text);
      if (n == null || k == null || n < 0 || k < 0) {
        setState(() {
          _result = _text('Paramètres invalides', 'Invalid parameters');
          _steps = _text('n ≥ 0 et p ≥ 0', 'n ≥ 0 and p ≥ 0');
        });
        return;
      }

      final value = _powerInt(n, k);
      buffer.writeln(_text('p-uplet : n^p', 'p-tuple: n^p'));
      buffer.writeln(_text('Nombre d’ordres possibles : ', 'Number of possible ordered tuples: '));
      buffer.writeln('n = $n, p = $k');
      buffer.writeln('$n^$k = $value');
      setState(() {
        _result = value.toString();
        _steps = buffer.toString();
      });
      return;
    }

    final n = _parseInt(_nController.text);
    final k = _parseInt(_kController.text);

    if (n == null || n < 0) {
      setState(() {
        _result = _text('n invalide', 'invalid n');
        _steps = _text('n doit être un entier ≥ 0', 'n must be an integer ≥ 0');
      });
      return;
    }

    if (_mode != 'permutation' && (k == null || k < 0)) {
      setState(() {
        _result = _text('k invalide', 'invalid k');
        _steps = _text('k doit être un entier ≥ 0', 'k must be an integer ≥ 0');
      });
      return;
    }

    if (k != null && k > n) {
      setState(() {
        _result = _text('Impossible', 'Impossible');
        _steps = _text('k ne peut pas être supérieur à n', 'k cannot be greater than n');
      });
      return;
    }

    BigInt value;
    switch (_mode) {
      case 'permutation':
        value = _factorial(n);
        buffer.writeln(_text('Formule : n!', 'Formula: n!'));
        buffer.writeln('${_text('Résultat = ', 'Result = ')}$value');
        break;
      case 'arrangement':
        value = _factorial(n) ~/ _factorial(n - k!);
        buffer.writeln('A(n,k) = n! / (n−k)!');
        buffer.writeln('A($n,$k) = $value');
        break;
      default:
        value = _comb(n, k!);
        buffer.writeln('C(n,k) = n! / (k! × (n−k)!)');
        buffer.writeln('C($n,$k) = $value');
        break;
    }

    setState(() {
      _result = value.toString();
      _steps = buffer.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final isFr = locale.isFrench;
    final segments = [
      ButtonSegment(value: 'combinaison', label: Text(_text('Combinaison', 'Combination'))),
      ButtonSegment(value: 'arrangement', label: Text(_text('Arrangement', 'Arrangement'))),
      ButtonSegment(value: 'permutation', label: Text(_text('Permutation', 'Permutation'))),
      ButtonSegment(value: 'puplet', label: Text(_text('p-uplet', 'p-tuple'))),
      ButtonSegment(value: 'binomiale', label: Text(_text('Binomiale', 'Binomial'))),
      ButtonSegment(value: 'normale', label: Text(_text('Normale', 'Normal'))),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_text('Probabilités', 'Probability')),
        actions: [
          TextButton(
            onPressed: _loadExample,
            child: Text(_text('Exemple', 'Example')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<String>(
              segments: segments,
              selected: {_mode},
              onSelectionChanged: (s) => setState(() {
                _mode = s.first;
                _result = '';
                _steps = '';
              }),
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 20),
          if (_mode == 'normale') ...[
            TextField(
              controller: _muController,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: InputDecoration(
                labelText: 'μ (${_text('moyenne', 'mean')})',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sigmaController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'σ (${_text('écart-type', 'std-dev')})',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _xController,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: InputDecoration(
                labelText: 'x',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ] else ...[
            TextField(
              controller: _nController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _mode == 'binomiale'
                    ? _text('n (essais)', 'n (trials)')
                    : _text('n', 'n'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            if (_mode != 'permutation' && _mode != 'puplet') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _kController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _mode == 'binomiale'
                      ? _text('k (succès)', 'k (successes)')
                      : _text('k', 'k'),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
            if (_mode == 'puplet' || _mode == 'binomiale') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _kController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _mode == 'binomiale'
                      ? _text('k (succès)', 'k (successes)')
                      : _text('p', 'p'),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
            if (_mode == 'binomiale') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _pController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _text('p (proba de succès)', 'p (success probability)'),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _calculate,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(_text('Calculer', 'Calculate'),
                style: const TextStyle(fontSize: 17)),
          ),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  _result,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ).animate().fadeIn().scale(),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _text('Explications', 'Explanation'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _steps,
                      style: const TextStyle(height: 1.45, fontSize: 13),
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

