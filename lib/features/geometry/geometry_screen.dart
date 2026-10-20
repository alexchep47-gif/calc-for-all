import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

/// Module Géométrie : Pythagore, Thalès, aires, volumes
class GeometryScreen extends StatefulWidget {
  const GeometryScreen({super.key});

  @override
  State<GeometryScreen> createState() => _GeometryScreenState();
}

class _GeometryScreenState extends State<GeometryScreen> {
  String _tool = 'pythagore';
  final Map<String, TextEditingController> _ctrls = {};
  String _result = '';
  String _steps = '';

  TextEditingController _c(String key) {
    return _ctrls.putIfAbsent(key, () => TextEditingController());
  }

  double? _v(String key) => double.tryParse(_c(key).text.replaceAll(',', '.'));

  void _calculate() {
    final buffer = StringBuffer();

    switch (_tool) {
      case 'pythagore':
        final a = _v('a');
        final b = _v('b');
        final c = _v('c');
        if (a != null && b != null && c == null) {
          final hyp = math.sqrt(a * a + b * b);
          buffer.writeln('Théorème de Pythagore');
          buffer.writeln('a² + b² = c²');
          buffer.writeln('$a² + $b² = c²');
          buffer.writeln('${a * a} + ${b * b} = c²');
          buffer.writeln('${a * a + b * b} = c²');
          buffer.writeln('c = √${a * a + b * b} = $hyp');
          setState(() {
            _result = 'Hypoténuse c ≈ ${hyp.toStringAsFixed(6)}';
            _steps = buffer.toString();
          });
        } else if (a != null && c != null && b == null) {
          if (c <= a) {
            setState(() {
              _result = 'Impossible (c doit être > a)';
              _steps = '';
            });
            return;
          }
          final side = math.sqrt(c * c - a * a);
          buffer.writeln('b = √(c² − a²) = √(${c * c} − ${a * a}) = $side');
          setState(() {
            _result = 'Côté b ≈ ${side.toStringAsFixed(6)}';
            _steps = buffer.toString();
          });
        } else {
          setState(() {
            _result = 'Remplis deux valeurs (a et b, ou a et c…)';
            _steps = 'Laisse vide la valeur que tu cherches.';
          });
        }
        break;

      case 'thales':
        final ad = _v('ad');
        final ab = _v('ab');
        final ae = _v('ae');
        final ac = _v('ac');
        if (ad != null && ab != null && ae != null && ac == null) {
          final result = ae * ab / ad;
          buffer.writeln('Théorème de Thalès');
          buffer.writeln('AD/AB = AE/AC');
          buffer.writeln('$ad / $ab = $ae / AC');
          buffer.writeln('AC = $ae × $ab / $ad = $result');
          setState(() {
            _result = 'AC ≈ ${result.toStringAsFixed(6)}';
            _steps = buffer.toString();
          });
        } else {
          setState(() {
            _result = 'Remplis AD, AB et AE (laisse AC vide)';
            _steps = '';
          });
        }
        break;

      case 'aire':
        final shape = _c('shape').text;
        if (shape == 'rectangle') {
          final L = _v('L') ?? 0;
          final l = _v('l') ?? 0;
          final aire = L * l;
          buffer.writeln('Aire du rectangle = L × l = $L × $l = $aire');
          setState(() {
            _result = 'Aire = $aire';
            _steps = buffer.toString();
          });
        } else if (shape == 'triangle') {
          final base = _v('base') ?? 0;
          final h = _v('h') ?? 0;
          final aire = base * h / 2;
          buffer.writeln('Aire du triangle = (base × hauteur) / 2');
          buffer.writeln('= ($base × $h) / 2 = $aire');
          setState(() {
            _result = 'Aire = $aire';
            _steps = buffer.toString();
          });
        } else if (shape == 'cercle') {
          final r = _v('r') ?? 0;
          final aire = math.pi * r * r;
          buffer.writeln('Aire du cercle = π × r²');
          buffer.writeln('= π × $r² = $aire');
          setState(() {
            _result = 'Aire ≈ ${aire.toStringAsFixed(6)}';
            _steps = buffer.toString();
          });
        }
        break;

      case 'volume':
        final shape = _c('shape').text;
        if (shape == 'cube') {
          final a = _v('a') ?? 0;
          final vol = a * a * a;
          buffer.writeln('Volume du cube = a³ = $a³ = $vol');
          setState(() {
            _result = 'Volume = $vol';
            _steps = buffer.toString();
          });
        } else if (shape == 'sphère') {
          final r = _v('r') ?? 0;
          final vol = (4 / 3) * math.pi * r * r * r;
          buffer.writeln('Volume de la sphère = (4/3) × π × r³');
          buffer.writeln('= (4/3) × π × $r³ = $vol');
          setState(() {
            _result = 'Volume ≈ ${vol.toStringAsFixed(6)}';
            _steps = buffer.toString();
          });
        } else if (shape == 'cylindre') {
          final r = _v('r') ?? 0;
          final h = _v('h') ?? 0;
          final vol = math.pi * r * r * h;
          buffer.writeln('Volume du cylindre = π × r² × h');
          buffer.writeln('= π × $r² × $h = $vol');
          setState(() {
            _result = 'Volume ≈ ${vol.toStringAsFixed(6)}';
            _steps = buffer.toString();
          });
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Géométrie')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(label: const Text('Pythagore'), selected: _tool == 'pythagore', onSelected: (_) => setState(() => _tool = 'pythagore')),
              ChoiceChip(label: const Text('Thalès'), selected: _tool == 'thales', onSelected: (_) => setState(() => _tool = 'thales')),
              ChoiceChip(label: const Text('Aires'), selected: _tool == 'aire', onSelected: (_) => setState(() => _tool = 'aire')),
              ChoiceChip(label: const Text('Volumes'), selected: _tool == 'volume', onSelected: (_) => setState(() => _tool = 'volume')),
            ],
          ),
          const SizedBox(height: 20),
          if (_tool == 'pythagore') ...[
            _field('a', 'Côté a'),
            _field('b', 'Côté b'),
            _field('c', 'Hypoténuse c (laisser vide si cherché)'),
          ] else if (_tool == 'thales') ...[
            _field('ad', 'AD'),
            _field('ab', 'AB'),
            _field('ae', 'AE'),
            _field('ac', 'AC (laisser vide si cherché)'),
          ] else if (_tool == 'aire') ...[
            DropdownButtonFormField<String>(
              value: _c('shape').text.isEmpty ? 'rectangle' : _c('shape').text,
              items: const [
                DropdownMenuItem(value: 'rectangle', child: Text('Rectangle')),
                DropdownMenuItem(value: 'triangle', child: Text('Triangle')),
                DropdownMenuItem(value: 'cercle', child: Text('Cercle')),
              ],
              onChanged: (v) => setState(() => _c('shape').text = v!),
              decoration: InputDecoration(labelText: 'Figure', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 12),
            if (_c('shape').text == 'rectangle' || _c('shape').text.isEmpty) ...[
              _field('L', 'Longueur L'),
              _field('l', 'Largeur l'),
            ] else if (_c('shape').text == 'triangle') ...[
              _field('base', 'Base'),
              _field('h', 'Hauteur'),
            ] else ...[
              _field('r', 'Rayon r'),
            ],
          ] else if (_tool == 'volume') ...[
            DropdownButtonFormField<String>(
              value: _c('shape').text.isEmpty ? 'cube' : _c('shape').text,
              items: const [
                DropdownMenuItem(value: 'cube', child: Text('Cube')),
                DropdownMenuItem(value: 'sphère', child: Text('Sphère')),
                DropdownMenuItem(value: 'cylindre', child: Text('Cylindre')),
              ],
              onChanged: (v) => setState(() => _c('shape').text = v!),
              decoration: InputDecoration(labelText: 'Solide', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 12),
            if (_c('shape').text == 'cube' || _c('shape').text.isEmpty)
              _field('a', 'Arête a')
            else if (_c('shape').text == 'sphère')
              _field('r', 'Rayon r')
            else ...[
              _field('r', 'Rayon r'),
              _field('h', 'Hauteur h'),
            ],
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _calculate,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Calculer'),
          ),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(_result, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),
            ).animate().fadeIn().scale(),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_steps, style: const TextStyle(height: 1.45, fontSize: 13)),
              ),
            ).animate().fadeIn(delay: 80.ms),
          ],
        ],
      ),
    );
  }

  Widget _field(String key, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: _c(key),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
