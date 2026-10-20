import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

/// Cercle trigonométrique interactif
class UnitCircleScreen extends StatefulWidget {
  const UnitCircleScreen({super.key});

  @override
  State<UnitCircleScreen> createState() => _UnitCircleScreenState();
}

class _UnitCircleScreenState extends State<UnitCircleScreen> {
  double _angleDeg = 45; // angle en degrés
  bool _useDegrees = true;

  double get _angleRad => _angleDeg * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    final cosVal = math.cos(_angleRad);
    final sinVal = math.sin(_angleRad);
    final tanVal = (cosVal.abs() < 1e-10) ? double.infinity : math.tan(_angleRad);

    return Scaffold(
      appBar: AppBar(title: const Text('Cercle trigonométrique')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CustomPaint(
                painter: _UnitCirclePainter(angleRad: _angleRad),
                child: Container(),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    const Text('Unité : '),
                    ChoiceChip(
                      label: const Text('Degrés'),
                      selected: _useDegrees,
                      onSelected: (_) => setState(() => _useDegrees = true),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Radians'),
                      selected: !_useDegrees,
                      onSelected: (_) => setState(() => _useDegrees = false),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _useDegrees
                      ? 'Angle : ${_angleDeg.toStringAsFixed(1)}°'
                      : 'Angle : ${(_angleRad).toStringAsFixed(3)} rad',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: _angleDeg,
                  min: 0,
                  max: 360,
                  divisions: 72,
                  label: '${_angleDeg.round()}°',
                  onChanged: (v) => setState(() => _angleDeg = v),
                ),
                const SizedBox(height: 8),
                _infoCard('cos(θ)', cosVal.toStringAsFixed(6)),
                _infoCard('sin(θ)', sinVal.toStringAsFixed(6)),
                _infoCard('tan(θ)', tanVal.isInfinite ? '∞' : tanVal.toStringAsFixed(6)),
                const SizedBox(height: 12),
                const Text(
                  'Le point rouge se déplace sur le cercle.\n'
                  'L’abscisse = cosinus, l’ordonnée = sinus.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    ).animate().fadeIn();
  }
}

class _UnitCirclePainter extends CustomPainter {
  final double angleRad;
  _UnitCirclePainter({required this.angleRad});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;

    final axisPaint = Paint()..color = Colors.grey.shade400..strokeWidth = 1;
    final circlePaint = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final pointPaint = Paint()..color = Colors.red..style = PaintingStyle.fill;
    final linePaint = Paint()..color = Colors.red.shade300..strokeWidth = 2;

    // Axes
    canvas.drawLine(Offset(center.dx - radius - 10, center.dy), Offset(center.dx + radius + 10, center.dy), axisPaint);
    canvas.drawLine(Offset(center.dx, center.dy - radius - 10), Offset(center.dx, center.dy + radius + 10), axisPaint);

    // Cercle
    canvas.drawCircle(center, radius, circlePaint);

    // Point et rayon
    final x = center.dx + radius * math.cos(angleRad);
    final y = center.dy - radius * math.sin(angleRad); // y inversé en Flutter
    canvas.drawLine(center, Offset(x, y), linePaint);
    canvas.drawCircle(Offset(x, y), 7, pointPaint);

    // Projections
    final projPaint = Paint()
      ..color = Colors.green.shade400
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(x, y), Offset(x, center.dy), projPaint);
    canvas.drawLine(Offset(x, y), Offset(center.dx, y), projPaint);
  }

  @override
  bool shouldRepaint(covariant _UnitCirclePainter old) => old.angleRad != angleRad;
}
