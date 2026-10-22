import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../data/services/math_library.dart';

/// Cercle trigonometrique — angles en fractions de pi
class UnitCircleScreen extends StatefulWidget {
  const UnitCircleScreen({super.key});

  @override
  State<UnitCircleScreen> createState() => _UnitCircleScreenState();
}

class _UnitCircleScreenState extends State<UnitCircleScreen> {
  /// Angle en degres (0..360), pas de 15° pour coller aux fractions usuelles
  double _angleDeg = 45;
  bool _useDegrees = false; // radians par defaut pour afficher les fractions

  double get _angleRad => _angleDeg * math.pi / 180;

  /// Convertit un angle (rad) en fraction de pi : k*pi/n
  String _radToPiFraction(double rad) {
    // Normalise dans [0, 2pi)
    var r = rad % (2 * math.pi);
    if (r < 0) r += 2 * math.pi;
    if (r < 1e-9 || (2 * math.pi - r) < 1e-9) return '0';

    // r = (num/den) * pi  =>  num/den = r/pi
    final ratio = r / math.pi; // dans [0, 2)
    // Cherche fraction p/q avec q <= 24
    int bestP = 1, bestQ = 1;
    double bestErr = double.infinity;
    for (var q = 1; q <= 24; q++) {
      final p = (ratio * q).round();
      if (p < 0 || p > 2 * q) continue;
      final err = (ratio - p / q).abs();
      if (err < bestErr) {
        bestErr = err;
        bestP = p;
        bestQ = q;
      }
    }
    if (bestErr > 0.02) {
      return '${MathLibrary.format(ratio)} π';
    }
    // Simplifie bestP/bestQ
    final g = _gcd(bestP, bestQ);
    bestP ~/= g;
    bestQ ~/= g;

    if (bestP == 0) return '0';
    if (bestQ == 1) {
      if (bestP == 1) return 'π';
      if (bestP == 2) return '2π';
      return '$bestP π';
    }
    if (bestP == 1) return 'π/$bestQ';
    return '$bestP π/$bestQ';
  }

  int _gcd(int a, int b) {
    a = a.abs();
    b = b.abs();
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a == 0 ? 1 : a;
  }

  String _exactTrig(String fn, double deg) {
    // Valeurs remarquables
    final d = ((deg % 360) + 360) % 360;
    final table = <double, Map<String, String>>{
      0: {'cos': '1', 'sin': '0', 'tan': '0'},
      30: {'cos': '√3/2', 'sin': '1/2', 'tan': '1/√3'},
      45: {'cos': '√2/2', 'sin': '√2/2', 'tan': '1'},
      60: {'cos': '1/2', 'sin': '√3/2', 'tan': '√3'},
      90: {'cos': '0', 'sin': '1', 'tan': '∞'},
      120: {'cos': '-1/2', 'sin': '√3/2', 'tan': '-√3'},
      135: {'cos': '-√2/2', 'sin': '√2/2', 'tan': '-1'},
      150: {'cos': '-√3/2', 'sin': '1/2', 'tan': '-1/√3'},
      180: {'cos': '-1', 'sin': '0', 'tan': '0'},
      210: {'cos': '-√3/2', 'sin': '-1/2', 'tan': '1/√3'},
      225: {'cos': '-√2/2', 'sin': '-√2/2', 'tan': '1'},
      240: {'cos': '-1/2', 'sin': '-√3/2', 'tan': '√3'},
      270: {'cos': '0', 'sin': '-1', 'tan': '∞'},
      300: {'cos': '1/2', 'sin': '-√3/2', 'tan': '-√3'},
      315: {'cos': '√2/2', 'sin': '-√2/2', 'tan': '-1'},
      330: {'cos': '√3/2', 'sin': '-1/2', 'tan': '-1/√3'},
      360: {'cos': '1', 'sin': '0', 'tan': '0'},
    };
    for (final e in table.entries) {
      if ((d - e.key).abs() < 0.5) return e.value[fn] ?? '';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final cosVal = math.cos(_angleRad);
    final sinVal = math.sin(_angleRad);
    final tanVal =
        (cosVal.abs() < 1e-10) ? double.infinity : math.tan(_angleRad);

    final cosExact = _exactTrig('cos', _angleDeg);
    final sinExact = _exactTrig('sin', _angleDeg);
    final tanExact = _exactTrig('tan', _angleDeg);

    return Scaffold(
      appBar: AppBar(title: const Text('Cercle trigonometrique')),
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
                    const Text('Unite : '),
                    ChoiceChip(
                      label: const Text('Degres'),
                      selected: _useDegrees,
                      onSelected: (_) => setState(() => _useDegrees = true),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Radians (π)'),
                      selected: !_useDegrees,
                      onSelected: (_) => setState(() => _useDegrees = false),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _useDegrees
                      ? 'Angle : ${_angleDeg.round()}°'
                      : 'Angle : ${_radToPiFraction(_angleRad)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!_useDegrees)
                  Text(
                    '(≈ ${MathLibrary.format(_angleRad)} rad)',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                Slider(
                  value: _angleDeg,
                  min: 0,
                  max: 360,
                  divisions: 24, // pas de 15°
                  label: _useDegrees
                      ? '${_angleDeg.round()}°'
                      : _radToPiFraction(_angleRad),
                  onChanged: (v) => setState(() => _angleDeg = v),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final d in [
                      0,
                      30,
                      45,
                      60,
                      90,
                      120,
                      150,
                      180,
                      270,
                      360
                    ])
                      ActionChip(
                        label: Text(_useDegrees
                            ? '$d°'
                            : _radToPiFraction(d * math.pi / 180)),
                        onPressed: () =>
                            setState(() => _angleDeg = d.toDouble()),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _infoCard(
                  'cos(θ)',
                  cosExact.isNotEmpty
                      ? '$cosExact  (≈ ${MathLibrary.format(cosVal)})'
                      : MathLibrary.format(cosVal),
                ),
                _infoCard(
                  'sin(θ)',
                  sinExact.isNotEmpty
                      ? '$sinExact  (≈ ${MathLibrary.format(sinVal)})'
                      : MathLibrary.format(sinVal),
                ),
                _infoCard(
                  'tan(θ)',
                  tanExact.isNotEmpty
                      ? tanExact
                      : (tanVal.isInfinite ? '∞' : MathLibrary.format(tanVal)),
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
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
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

    final axisPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;
    final circlePaint = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final pointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = Colors.red.shade300
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(center.dx - radius - 10, center.dy),
      Offset(center.dx + radius + 10, center.dy),
      axisPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius - 10),
      Offset(center.dx, center.dy + radius + 10),
      axisPaint,
    );
    canvas.drawCircle(center, radius, circlePaint);

    final x = center.dx + radius * math.cos(angleRad);
    final y = center.dy - radius * math.sin(angleRad);
    canvas.drawLine(center, Offset(x, y), linePaint);
    canvas.drawCircle(Offset(x, y), 7, pointPaint);

    final projPaint = Paint()
      ..color = Colors.green.shade400
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(x, y), Offset(x, center.dy), projPaint);
    canvas.drawLine(Offset(x, y), Offset(center.dx, y), projPaint);
  }

  @override
  bool shouldRepaint(covariant _UnitCirclePainter old) =>
      old.angleRad != angleRad;
}
