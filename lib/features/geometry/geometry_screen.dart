import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../data/services/math_library.dart';

/// Geometrie : Pythagore, Thales, aires, volumes, vecteurs 3D
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

  TextEditingController _c(String key) =>
      _ctrls.putIfAbsent(key, () => TextEditingController());

  double? _v(String key) => double.tryParse(_c(key).text.replaceAll(',', '.'));

  void _loadExample() {
    setState(() {
      switch (_tool) {
        case 'pythagore':
          _c('a').text = '3';
          _c('b').text = '4';
          _c('c').text = '';
          break;
        case 'thales':
          _c('ad').text = '2';
          _c('ab').text = '6';
          _c('ae').text = '3';
          _c('ac').text = '';
          break;
        case 'vecteurs':
          _c('ux').text = '1';
          _c('uy').text = '2';
          _c('uz').text = '3';
          _c('vx').text = '4';
          _c('vy').text = '5';
          _c('vz').text = '6';
          break;
        default:
          break;
      }
      _result = '';
      _steps = '';
    });
  }

  void _calculate() {
    final buffer = StringBuffer();

    switch (_tool) {
      case 'pythagore':
        final a = _v('a');
        final b = _v('b');
        final c = _v('c');
        if (a != null && b != null && c == null) {
          final hyp = math.sqrt(a * a + b * b);
          buffer.writeln('Theoreme de Pythagore');
          buffer.writeln('a^2 + b^2 = c^2');
          buffer.writeln('$a^2 + $b^2 = c^2');
          buffer.writeln('c = sqrt(${a * a + b * b}) = $hyp');
          setState(() {
            _result = 'Hypotenuse c = ${MathLibrary.format(hyp)}';
            _steps = buffer.toString();
          });
        } else if (a != null && c != null && b == null) {
          if (c <= a) {
            setState(() {
              _result = 'Impossible (c doit etre > a)';
              _steps = '';
            });
            return;
          }
          final side = math.sqrt(c * c - a * a);
          buffer.writeln('b = sqrt(c^2 - a^2) = $side');
          setState(() {
            _result = 'Cote b = ${MathLibrary.format(side)}';
            _steps = buffer.toString();
          });
        } else {
          setState(() {
            _result = 'Remplis deux valeurs (a et b, ou a et c)';
            _steps = 'Laisse vide la valeur cherchee.';
          });
        }
        break;

      case 'thales':
        final ad = _v('ad');
        final ab = _v('ab');
        final ae = _v('ae');
        if (ad != null && ab != null && ae != null) {
          final result = ae * ab / ad;
          buffer.writeln('Theoreme de Thales');
          buffer.writeln('AD/AB = AE/AC');
          buffer.writeln('AC = $ae * $ab / $ad = $result');
          setState(() {
            _result = 'AC = ${MathLibrary.format(result)}';
            _steps = buffer.toString();
          });
        } else {
          setState(() {
            _result = 'Remplis AD, AB et AE';
            _steps = '';
          });
        }
        break;

      case 'aire':
        final shape = _c('shape').text;
        if (shape == 'rectangle' || shape.isEmpty) {
          final L = _v('L') ?? 0;
          final l = _v('l') ?? 0;
          setState(() {
            _result = 'Aire = ${L * l}';
            _steps = 'Aire rectangle = L * l = $L * $l';
          });
        } else if (shape == 'triangle') {
          final base = _v('base') ?? 0;
          final h = _v('h') ?? 0;
          setState(() {
            _result = 'Aire = ${base * h / 2}';
            _steps = 'Aire triangle = (base * h) / 2';
          });
        } else {
          final r = _v('r') ?? 0;
          final aire = math.pi * r * r;
          setState(() {
            _result = 'Aire = ${MathLibrary.format(aire)}';
            _steps = 'Aire cercle = pi * r^2';
          });
        }
        break;

      case 'volume':
        final shape = _c('shape').text;
        if (shape == 'cube' || shape.isEmpty) {
          final a = _v('a') ?? 0;
          setState(() {
            _result = 'Volume = ${a * a * a}';
            _steps = 'Volume cube = a^3';
          });
        } else if (shape == 'sphere') {
          final r = _v('r') ?? 0;
          final vol = (4 / 3) * math.pi * r * r * r;
          setState(() {
            _result = 'Volume = ${MathLibrary.format(vol)}';
            _steps = 'Volume sphere = (4/3) * pi * r^3';
          });
        } else {
          final r = _v('r') ?? 0;
          final h = _v('h') ?? 0;
          final vol = math.pi * r * r * h;
          setState(() {
            _result = 'Volume = ${MathLibrary.format(vol)}';
            _steps = 'Volume cylindre = pi * r^2 * h';
          });
        }
        break;

      case 'vecteurs':
        final ux = _v('ux') ?? 0;
        final uy = _v('uy') ?? 0;
        final uz = _v('uz') ?? 0;
        final vx = _v('vx') ?? 0;
        final vy = _v('vy') ?? 0;
        final vz = _v('vz') ?? 0;

        final dot = ux * vx + uy * vy + uz * vz;
        final cx = uy * vz - uz * vy;
        final cy = uz * vx - ux * vz;
        final cz = ux * vy - uy * vx;
        final nu = math.sqrt(ux * ux + uy * uy + uz * uz);
        final nv = math.sqrt(vx * vx + vy * vy + vz * vz);
        final nc = math.sqrt(cx * cx + cy * cy + cz * cz);
        double angleDeg = 0;
        if (nu > 0 && nv > 0) {
          final cosA = (dot / (nu * nv)).clamp(-1.0, 1.0);
          angleDeg = math.acos(cosA) * 180 / math.pi;
        }

        buffer.writeln('u = ($ux, $uy, $uz)');
        buffer.writeln('v = ($vx, $vy, $vz)');
        buffer.writeln('');
        buffer.writeln(
            'Produit scalaire u·v = $ux*$vx + $uy*$vy + $uz*$vz = $dot');
        buffer.writeln('Produit vectoriel u×v = ($cx, $cy, $cz)');
        buffer.writeln('|u| = $nu');
        buffer.writeln('|v| = $nv');
        buffer.writeln('|u×v| = $nc');
        buffer.writeln('Angle (u,v) = ${MathLibrary.format(angleDeg)}°');

        setState(() {
          _result =
              'u·v = ${MathLibrary.format(dot)}\nu×v = (${MathLibrary.format(cx)}, ${MathLibrary.format(cy)}, ${MathLibrary.format(cz)})\n|u|=${MathLibrary.format(nu)}  |v|=${MathLibrary.format(nv)}\nAngle = ${MathLibrary.format(angleDeg)}°';
          _steps = buffer.toString();
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geometrie'),
        actions: [
          TextButton(onPressed: _loadExample, child: const Text('Exemple')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('pythagore', 'Pythagore'),
              _chip('thales', 'Thales'),
              _chip('aire', 'Aires'),
              _chip('volume', 'Volumes'),
              _chip('vecteurs', 'Vecteurs 3D'),
            ],
          ),
          const SizedBox(height: 20),
          if (_tool == 'pythagore') ...[
            _field('a', 'Cote a'),
            _field('b', 'Cote b'),
            _field('c', 'Hypotenuse c (vide si cherche)'),
          ] else if (_tool == 'thales') ...[
            _field('ad', 'AD'),
            _field('ab', 'AB'),
            _field('ae', 'AE'),
          ] else if (_tool == 'aire') ...[
            DropdownButtonFormField<String>(
              value: _c('shape').text.isEmpty ? 'rectangle' : _c('shape').text,
              items: const [
                DropdownMenuItem(value: 'rectangle', child: Text('Rectangle')),
                DropdownMenuItem(value: 'triangle', child: Text('Triangle')),
                DropdownMenuItem(value: 'cercle', child: Text('Cercle')),
              ],
              onChanged: (v) => setState(() => _c('shape').text = v!),
              decoration: InputDecoration(
                labelText: 'Figure',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            if (_c('shape').text == 'triangle') ...[
              _field('base', 'Base'),
              _field('h', 'Hauteur'),
            ] else if (_c('shape').text == 'cercle') ...[
              _field('r', 'Rayon r'),
            ] else ...[
              _field('L', 'Longueur L'),
              _field('l', 'Largeur l'),
            ],
          ] else if (_tool == 'volume') ...[
            DropdownButtonFormField<String>(
              value: _c('shape').text.isEmpty ? 'cube' : _c('shape').text,
              items: const [
                DropdownMenuItem(value: 'cube', child: Text('Cube')),
                DropdownMenuItem(value: 'sphere', child: Text('Sphere')),
                DropdownMenuItem(value: 'cylindre', child: Text('Cylindre')),
              ],
              onChanged: (v) => setState(() => _c('shape').text = v!),
              decoration: InputDecoration(
                labelText: 'Solide',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            if (_c('shape').text == 'sphere')
              _field('r', 'Rayon r')
            else if (_c('shape').text == 'cylindre') ...[
              _field('r', 'Rayon r'),
              _field('h', 'Hauteur h'),
            ] else
              _field('a', 'Arete a'),
          ] else if (_tool == 'vecteurs') ...[
            const Text('Vecteur u',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Row(children: [
              Expanded(child: _field('ux', 'ux')),
              const SizedBox(width: 8),
              Expanded(child: _field('uy', 'uy')),
              const SizedBox(width: 8),
              Expanded(child: _field('uz', 'uz')),
            ]),
            const Text('Vecteur v',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Row(children: [
              Expanded(child: _field('vx', 'vx')),
              const SizedBox(width: 8),
              Expanded(child: _field('vy', 'vy')),
              const SizedBox(width: 8),
              Expanded(child: _field('vz', 'vz')),
            ]),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _calculate,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Calculer'),
          ),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  _result,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ),
            ).animate().fadeIn().scale(),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_steps,
                    style: const TextStyle(height: 1.45, fontSize: 13)),
              ),
            ).animate().fadeIn(delay: 80.ms),
          ],
        ],
      ),
    );
  }

  Widget _chip(String id, String label) => ChoiceChip(
        label: Text(label),
        selected: _tool == id,
        onSelected: (_) => setState(() {
          _tool = id;
          _result = '';
          _steps = '';
        }),
      );

  Widget _field(String key, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: _c(key),
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true, signed: true),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
