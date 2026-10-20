import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

/// Module Suites : arithmétiques et géométriques
class SequencesScreen extends StatefulWidget {
  const SequencesScreen({super.key});

  @override
  State<SequencesScreen> createState() => _SequencesScreenState();
}

class _SequencesScreenState extends State<SequencesScreen> {
  String _type = 'arithmétique'; // arithmétique ou géométrique
  final TextEditingController _u1Controller = TextEditingController(text: '1');
  final TextEditingController _rController = TextEditingController(text: '2');
  final TextEditingController _nController = TextEditingController(text: '10');
  String _result = '';
  String _steps = '';

  void _calculate() {
    final u1 = double.tryParse(_u1Controller.text.replaceAll(',', '.'));
    final r = double.tryParse(_rController.text.replaceAll(',', '.'));
    final n = int.tryParse(_nController.text);

    if (u1 == null || r == null || n == null || n < 1) {
      setState(() {
        _result = 'Valeurs invalides';
        _steps = 'Vérifie u₁, la raison (r ou q) et n (n ≥ 1).';
      });
      return;
    }

    final buffer = StringBuffer();

    if (_type == 'arithmétique') {
      // u_n = u1 + (n-1)*r
      final un = u1 + (n - 1) * r;
      // Somme S_n = n/2 * (2*u1 + (n-1)*r)
      final sn = n / 2 * (2 * u1 + (n - 1) * r);

      buffer.writeln('Suite arithmétique');
      buffer.writeln('Premier terme u₁ = $u1');
      buffer.writeln('Raison r = $r');
      buffer.writeln('Rang n = $n');
      buffer.writeln();
      buffer.writeln('1. Terme général :');
      buffer.writeln('   uₙ = u₁ + (n − 1) × r');
      buffer.writeln('   uₙ = $u1 + (${n - 1}) × $r');
      buffer.writeln('   uₙ = $un');
      buffer.writeln();
      buffer.writeln('2. Somme des n premiers termes :');
      buffer.writeln('   Sₙ = n/2 × [2u₁ + (n − 1)r]');
      buffer.writeln('   Sₙ = $n/2 × [2×$u1 + (${n - 1})×$r]');
      buffer.writeln('   Sₙ = $sn');

      setState(() {
        _result = 'uₙ = $un\nSₙ = $sn';
        _steps = buffer.toString();
      });
    } else {
      // géométrique
      // u_n = u1 * q^(n-1)
      final un = u1 * math.pow(r, n - 1);
      // Somme S_n = u1 * (q^n - 1) / (q - 1)  si q ≠ 1
      double sn;
      if ((r - 1).abs() < 1e-10) {
        sn = u1 * n;
        buffer.writeln('Suite géométrique (q = 1)');
        buffer.writeln('Tous les termes sont égaux à u₁');
        buffer.writeln('Sₙ = n × u₁ = $sn');
      } else {
        sn = u1 * (math.pow(r, n) - 1) / (r - 1);
        buffer.writeln('Suite géométrique');
        buffer.writeln('Premier terme u₁ = $u1');
        buffer.writeln('Raison q = $r');
        buffer.writeln('Rang n = $n');
        buffer.writeln();
        buffer.writeln('1. Terme général :');
        buffer.writeln('   uₙ = u₁ × qⁿ⁻¹');
        buffer.writeln('   uₙ = $u1 × $r^${n - 1}');
        buffer.writeln('   uₙ = $un');
        buffer.writeln();
        buffer.writeln('2. Somme des n premiers termes :');
        buffer.writeln('   Sₙ = u₁ × (qⁿ − 1) / (q − 1)');
        buffer.writeln('   Sₙ = $sn');
      }

      setState(() {
        _result = 'uₙ = $un\nSₙ = $sn';
        _steps = buffer.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suites numériques')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'arithmétique', label: Text('Arithmétique')),
              ButtonSegment(value: 'géométrique', label: Text('Géométrique')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _u1Controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: InputDecoration(
              labelText: 'Premier terme u₁',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: InputDecoration(
              labelText: _type == 'arithmétique' ? 'Raison r' : 'Raison q',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Rang n',
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
            child: const Text('Calculer uₙ et Sₙ'),
          ),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(_result, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.5), textAlign: TextAlign.center),
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
