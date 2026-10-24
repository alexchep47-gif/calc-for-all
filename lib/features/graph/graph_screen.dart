import 'package:flutter/material.dart';

import '../../data/services/graph_service.dart';

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  final TextEditingController _expressionController =
      TextEditingController(text: 'sin(x)');
  final GraphService _graphService = GraphService();

  String _expression = 'sin(x)';

  @override
  void dispose() {
    _expressionController.dispose();
    super.dispose();
  }

  List<List<MapEntry<double, double>>> _curveSegments() {
    final expr = _expression.trim();
    if (expr.isEmpty) return const [];
    return _graphService.evaluateSegments(expr, -10, 10, 2000);
  }

  void _applyExpression() {
    final value = _expressionController.text.trim();
    setState(() {
      _expression = value.isEmpty ? 'sin(x)' : value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final segments = _curveSegments();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Graphique'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expressionController,
                    decoration: InputDecoration(
                      labelText: 'Fonction f(x)',
                      hintText: 'sin(x), x^2, exp(x), ...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (_) => _applyExpression(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _applyExpression,
                  child: const Text('Tracer'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickPresetChip(label: 'sin(x)', onTap: () => _setPreset('sin(x)')),
                _QuickPresetChip(label: 'cos(x)', onTap: () => _setPreset('cos(x)')),
                _QuickPresetChip(label: 'x^2', onTap: () => _setPreset('x^2')),
                _QuickPresetChip(label: 'exp(x)', onTap: () => _setPreset('exp(x)')),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF101820),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return CustomPaint(
                      painter: _CurvePainter(
                        segments: segments,
                        xMin: -10,
                        xMax: 10,
                        yMin: -10,
                        yMax: 10,
                      ),
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setPreset(String value) {
    _expressionController.text = value;
    setState(() {
      _expression = value;
    });
  }
}

class _QuickPresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickPresetChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.blueGrey.withOpacity(0.2),
    );
  }
}

class _CurvePainter extends CustomPainter {
  final List<List<MapEntry<double, double>>> segments;
  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;

  const _CurvePainter({
    required this.segments,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = const Color(0xFF101820);
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1;

    final axisPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.2;

    final curvePaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final xRange = xMax - xMin;
    final yRange = yMax - yMin;

    double xToPx(double x) => ((x - xMin) / xRange) * size.width;
    double yToPy(double y) => size.height - ((y - yMin) / yRange) * size.height;

    final originX = xToPx(0);
    final originY = yToPy(0);

    for (var i = -10; i <= 10; i++) {
      final x = i.toDouble();
      final px = xToPx(x);
      canvas.drawLine(
        Offset(px, 0),
        Offset(px, size.height),
        gridPaint,
      );
      final py = yToPy(x);
      canvas.drawLine(
        Offset(0, py),
        Offset(size.width, py),
        gridPaint,
      );
    }

    canvas.drawLine(
      Offset(originX, 0),
      Offset(originX, size.height),
      axisPaint,
    );
    canvas.drawLine(
      Offset(0, originY),
      Offset(size.width, originY),
      axisPaint,
    );

    for (final segment in segments) {
      if (segment.length < 2) continue;
      final path = Path();
      for (var i = 0; i < segment.length; i++) {
        final point = segment[i];
        final px = xToPx(point.key);
        final py = yToPy(point.value);
        if (i == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      canvas.drawPath(path, curvePaint);
    }

    final labelPaint = Paint()..color = Colors.white70;
    final labelStyle = const TextStyle(
      color: Colors.white70,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    for (var i = -10; i <= 10; i += 2) {
      final px = xToPx(i.toDouble());
      final py = yToPy(0.0);
      final textPainter = TextPainter(
        text: TextSpan(text: i.toString(), style: labelStyle),
        textDirection: Directionality.of(context),
      )..layout();
      textPainter.paint(canvas, Offset(px - 4, py + 6));
    }

    for (var i = -10; i <= 10; i += 2) {
      final py = yToPy(i.toDouble());
      final textPainter = TextPainter(
        text: TextSpan(text: i.toString(), style: labelStyle),
        textDirection: Directionality.of(context),
      )..layout();
      textPainter.paint(canvas, Offset(originX + 6, py - 8));
    }
  }

  @override
  bool shouldRepaint(covariant _CurvePainter oldDelegate) =>
      oldDelegate.segments != segments ||
      oldDelegate.xMin != xMin ||
      oldDelegate.xMax != xMax ||
      oldDelegate.yMin != yMin ||
      oldDelegate.yMax != yMax;
}

extension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

