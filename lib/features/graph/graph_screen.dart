import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../data/services/export_watermark.dart';
import '../../data/services/function_analysis_service.dart';
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
  final FunctionAnalysisService _analysisService = FunctionAnalysisService();
  final GlobalKey _graphKey = GlobalKey();

  String _expression = 'sin(x)';
  FunctionStudyResult? _study;

  @override
  void initState() {
    super.initState();
    _refreshStudy();
  }

  @override
  void dispose() {
    _expressionController.dispose();
    super.dispose();
  }

  void _refreshStudy() {
    final expr = _expressionController.text.trim();
    setState(() {
      _expression = expr.isEmpty ? 'sin(x)' : expr;
      _study = _analysisService.analyze(_expression, xMin: -10, xMax: 10);
    });
  }

  List<List<MapEntry<double, double>>> _curveSegments() {
    final expr = _expression.trim();
    if (expr.isEmpty) return const [];
    final raw = _graphService.evaluateSegments(expr, -10, 10, 2000);
    return raw
        .map((segment) => segment
            .where((point) =>
                point.key >= -10 &&
                point.key <= 10 &&
                point.value >= -10 &&
                point.value <= 10)
            .toList())
        .where((segment) => segment.length >= 2)
        .toList();
  }

  void _applyExpression() {
    final value = _expressionController.text.trim();
    if (value.isEmpty) {
      _expressionController.text = 'sin(x)';
    }
    _refreshStudy();
  }

  Future<Uint8List> _renderGraphAsPng() async {
    final boundary = _graphKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      throw StateError('Graph area is not ready for export.');
    }
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('PNG export failed.');
    }
    return byteData.buffer.asUint8List();
  }

  Future<void> _exportPng() async {
    try {
      final rawBytes = await _renderGraphAsPng();
      final watermarked = await ExportWatermark.applyToPng(rawBytes);
      await Share.shareXFiles([
        XFile.fromData(
          watermarked,
          name: 'courbe_${DateTime.now().millisecondsSinceEpoch}.png',
          mimeType: 'image/png',
        ),
      ]);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’exporter l’image PNG.')),
      );
    }
  }

  Future<void> _exportPdf() async {
    try {
      final rawBytes = await _renderGraphAsPng();
      final watermarked = await ExportWatermark.applyToPng(rawBytes);
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (contextPdf) {
            return pw.Stack(
              children: [
                pw.Positioned.fill(
                  child: pw.Center(
                    child: pw.Container(
                      width: PdfPageFormat.a4.width,
                      height: PdfPageFormat.a4.height,
                      child: pw.Image(
                        pw.MemoryImage(watermarked),
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                ExportWatermark.pdfBackground(PdfPageFormat.a4),
              ],
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();
      await Share.shareXFiles([
        XFile.fromData(
          pdfBytes,
          name: 'courbe_${DateTime.now().millisecondsSinceEpoch}.pdf',
          mimeType: 'application/pdf',
        ),
      ]);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’exporter le PDF.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final segments = _curveSegments();
    final study = _study;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Graphique'),
        actions: [
          IconButton(
            tooltip: 'Exporter PNG',
            onPressed: _exportPng,
            icon: const Icon(Icons.image_outlined),
          ),
          IconButton(
            tooltip: 'Exporter PDF',
            onPressed: _exportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            SizedBox(
              height: 420,
              child: RepaintBoundary(
                key: _graphKey,
                child: ClipRect(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF101820),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: CustomPaint(
                      painter: _CurvePainter(
                        segments: segments,
                        xMin: -10,
                        xMax: 10,
                        yMin: -10,
                        yMax: 10,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (study != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Étude de la fonction',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(label: 'Domaine', value: study.domain),
                      _InfoRow(label: 'Dérivée', value: study.derivative),
                      _InfoRow(label: 'Dérivée seconde', value: study.secondDerivative),
                      _InfoRow(label: 'Période', value: study.period),
                      _InfoRow(label: 'Parité', value: study.symmetry),
                      const SizedBox(height: 8),
                      const Text(
                        'Racines',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      ...study.roots.map((item) => Text('• $item')).toList(),
                      const SizedBox(height: 8),
                      const Text(
                        'Extrema',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      ...study.extrema.map((item) => Text('• $item')).toList(),
                      const SizedBox(height: 8),
                      const Text(
                        'Asymptotes',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      ...study.asymptotes.map((item) => Text('• $item')).toList(),
                      const SizedBox(height: 8),
                      const Text(
                        'Tableau de variation',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(study.variationTable),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _setPreset(String value) {
    _expressionController.text = value;
    _refreshStudy();
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label : ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
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
    final safeRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.save();
    canvas.clipRect(safeRect);

    final backgroundPaint = Paint()..color = const Color(0xFF101820);
    canvas.drawRect(safeRect, backgroundPaint);

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
      final validPoints = segment
          .where((point) =>
              point.key >= xMin &&
              point.key <= xMax &&
              point.value >= yMin &&
              point.value <= yMax)
          .toList();
      if (validPoints.length < 2) continue;

      final path = Path();
      for (var i = 0; i < validPoints.length; i++) {
        final point = validPoints[i];
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

    final labelStyle = const TextStyle(
      color: Colors.white70,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    for (var i = -10; i <= 10; i += 2) {
      final px = xToPx(i.toDouble());
      final textPainter = TextPainter(
        text: TextSpan(text: i.toString(), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(px - 4, originY + 6));
    }

    for (var i = -10; i <= 10; i += 2) {
      final py = yToPy(i.toDouble());
      final textPainter = TextPainter(
        text: TextSpan(text: i.toString(), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(originX + 6, py - 8));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CurvePainter oldDelegate) =>
      oldDelegate.segments != segments ||
      oldDelegate.xMin != xMin ||
      oldDelegate.xMax != xMax ||
      oldDelegate.yMin != yMin ||
      oldDelegate.yMax != yMax;
}

