import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

/// Module Statistiques : saisie d’une série et calcul des indicateurs
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final TextEditingController _dataController = TextEditingController();
  String _result = '';
  String _steps = '';

  void _calculate() {
    final raw = _dataController.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _result = '';
        _steps = 'Entre des nombres séparés par des espaces ou des virgules';
      });
      return;
    }

    final parts = raw.split(RegExp(r'[\s,;]+')).where((e) => e.isNotEmpty);
    final values = <double>[];
    for (final p in parts) {
      final v = double.tryParse(p.replaceAll(',', '.'));
      if (v != null) values.add(v);
    }

    if (values.isEmpty) {
      setState(() {
        _result = 'Aucune donnée valide';
        _steps = '';
      });
      return;
    }

    values.sort();
    final n = values.length;
    final sum = values.reduce((a, b) => a + b);
    final mean = sum / n;

    // Médiane
    double median;
    if (n % 2 == 1) {
      median = values[n ~/ 2];
    } else {
      median = (values[n ~/ 2 - 1] + values[n ~/ 2]) / 2;
    }

    // Variance & écart-type (population)
    double variance = 0;
    for (final v in values) {
      variance += math.pow(v - mean, 2);
    }
    variance /= n;
    final std = math.sqrt(variance);

    // Min / Max / Étendue
    final minV = values.first;
    final maxV = values.last;
    final range = maxV - minV;

    final buffer = StringBuffer();
    buffer.writeln('Données triées : ${values.map((e) => e.toStringAsFixed(2)).join(', ')}');
    buffer.writeln('Effectif n = $n');
    buffer.writeln();
    buffer.writeln('1. Somme = $sum');
    buffer.writeln('2. Moyenne (x̄) = somme / n = $sum / $n = ${mean.toStringAsFixed(4)}');
    buffer.writeln('3. Médiane = ${median.toStringAsFixed(4)}');
    buffer.writeln('4. Minimum = $minV');
    buffer.writeln('5. Maximum = $maxV');
    buffer.writeln('6. Étendue = max − min = $range');
    buffer.writeln('7. Variance = ${variance.toStringAsFixed(4)}');
    buffer.writeln('8. Écart-type (σ) = √variance = ${std.toStringAsFixed(4)}');

    setState(() {
      _result = 'Moyenne : ${mean.toStringAsFixed(4)}\n'
          'Médiane : ${median.toStringAsFixed(4)}\n'
          'Écart-type : ${std.toStringAsFixed(4)}\n'
          'Min : $minV  |  Max : $maxV';
      _steps = buffer.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Entre ta série de nombres (séparés par des espaces ou des virgules)',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dataController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Ex: 12 15 18 20 22 25 30',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _calculate,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Calculer les statistiques', style: TextStyle(fontSize: 16)),
          ),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(_result, style: const TextStyle(fontSize: 16, height: 1.5)),
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
                    const Text('Détail des calculs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    Text(_steps, style: const TextStyle(height: 1.45, fontSize: 13)),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 120.ms),
          ],
        ],
      ),
    );
  }
}
