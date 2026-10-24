import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../data/services/export_watermark.dart';
import '../../data/services/function_analysis_service.dart';
import '../../data/services/graph_service.dart';
import '../../data/services/math_expression_engine.dart';
import '../../data/services/math_library.dart';

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
  final MathExpressionEngine _engine = MathExpressionEngine();

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

  bool get _isEnglish => Localizations.localeOf(context).languageCode == 'en';
  String _t(String en, String fr) => _isEnglish ? en : fr;

  void _refreshStudy() {
    final expr = _expressionController.text.trim();
    setState(() {
      _expression = expr.isEmpty ? 'sin(x)' : expr;
      _study = _analysisService.analyze(_expression, xMin: -10, xMax: 10);
    });
  }

  List<double> _rootCandidates() {
    final expr = _expression.trim();
    if (expr.isEmpty) return const [];

    final roots = <double>[];
    const n = 4000;
    final step = 20.0 / n;
    double? prevX;
    double? prevY;

    for (var i = 0; i <= n; i++) {
      final x = -10 + i * step;
      final y = _engine.evaluate(expr, x);
      if (y == null || !y.isFinite) {
        prevX = null;
        prevY = null;
        continue;
      }

      if (y.abs() < 1e-5) {
        if (roots.isEmpty || (x - roots.last).abs() > 0.08) {
          roots.add(x);
        }
      } else if (prevY != null && prevX != null && prevY * y < 0) {
        var a = prevX;
        var b = x;
        var fa = prevY;
        for (var k = 0; k < 20; k++) {
          final mid = (a + b) / 2;
          final fm = _engine.evaluate(expr, mid);
          if (fm == null || !fm.isFinite) break;
          if (fa * fm <= 0) {
            b = mid;
          } else {
            a = mid;
            fa = fm;
          }
        }
        final root = (a + b) / 2;
        if (roots.isEmpty || (root - roots.last).abs() > 0.08) {
          roots.add(root);
        }
      }

      prevX = x;
      prevY = y;
    }

    return roots.take(4).toList();
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
      final codec = await ui.instantiateImageCodec(rawBytes);
      final frame = await codec.getNextFrame();
      final src = frame.image;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(src.width.toDouble(), src.height.toDouble());
      canvas.drawImage(src, Offset.zero, Paint());

      final text = 'Curve of function f(x)= ${MathLibrary.sanitizeForDisplay(_expression)}. Powered by Calc for all';
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
      )..layout(maxWidth: size.width - 32);

      final bg = Paint()..color = Colors.black.withOpacity(0.35);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(8, size.height - 56, size.width - 16, 48),
        const Radius.circular(12),
      );
      canvas.drawRRect(rect, bg);
      textPainter.paint(canvas, Offset(18, size.height - 42));

      final picture = recorder.endRecording();
      final out = await picture.toImage(src.width, src.height);
      final pngBytes = await out.toByteData(format: ui.ImageByteFormat.png);
      final finalBytes = pngBytes!.buffer.asUint8List();

      src.dispose();
      out.dispose();

      await Share.shareXFiles([
        XFile.fromData(
          finalBytes,
          name: 'curve_${DateTime.now().millisecondsSinceEpoch}.png',
          mimeType: 'image/png',
        ),
      ]);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to export PNG image.')),
      );
    }
  }

  Future<void> _exportPdf() async {
    try {
      final graphPng = await _renderGraphAsPng();
      final pdf = pw.Document();
      final studyText = _buildStudyText();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Center(
                child: pw.Container(
                  width: PdfPageFormat.a4.width * 0.9,
                  height: PdfPageFormat.a4.height * 0.45,
                  child: pw.Image(
                    pw.MemoryImage(graphPng),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ),
              pw.SizedBox(height: 18),
              pw.Text(
                _t('Function study', 'Étude de la fonction'),
                style: const pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                studyText,
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Powered by Calc for all',
                style: pw.TextStyle(
                  color: PdfColors.grey,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ];
          },
        ),
      );

      final pdfBytes = await pdf.save();
      await Share.shareXFiles([
        XFile.fromData(
          pdfBytes,
          name: 'curve_${DateTime.now().millisecondsSinceEpoch}.pdf',
          mimeType: 'application/pdf',
        ),
      ]);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to export PDF.')),
      );
    }
  }

  String _buildStudyText() {
    final study = _study;
    if (study == null) {
      return 'No study available.';
    }

    final buffer = StringBuffer();
    buffer.writeln('Function : f(x) = ${MathLibrary.sanitizeForDisplay(_expression)}');
    buffer.writeln('Domain : ${MathLibrary.sanitizeForDisplay(study.domain)}');
    buffer.writeln('Derivative : ${MathLibrary.sanitizeForDisplay(study.derivative)}');
    buffer.writeln('Second derivative : ${MathLibrary.sanitizeForDisplay(study.secondDerivative)}');
    buffer.writeln('Period : ${MathLibrary.sanitizeForDisplay(study.period)}');
    buffer.writeln('Symmetry : ${MathLibrary.sanitizeForDisplay(study.symmetry)}');
    buffer.writeln();
    buffer.writeln('Roots :');
    for (final item in study.roots) {
      buffer.writeln('- ${MathLibrary.sanitizeForDisplay(item)}');
    }
    buffer.writeln();
    buffer.writeln('Extrema :');
    for (final item in study.extrema) {
      buffer.writeln('- ${MathLibrary.sanitizeForDisplay(item)}');
    }
    buffer.writeln();
    buffer.writeln('Asymptotes :');
    for (final item in study.asymptotes) {
      buffer.writeln('- ${MathLibrary.sanitizeForDisplay(item)}');
    }
    buffer.writeln();
    buffer.writeln('Variation table :');
    buffer.writeln(MathLibrary.sanitizeForDisplay(study.variationTable));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final segments = _curveSegments();
    final study = _study;
    final roots = _rootCandidates();

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Graph', 'Graphique')),
        actions: [
          IconButton(
            tooltip: _t('Export PNG', 'Exporter PNG'),
            onPressed: _exportPng,
            icon: const Icon(Icons.image_outlined),
          ),
          IconButton(
            tooltip: _t('Export PDF', 'Exporter PDF'),
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
                      labelText: _t('Function f(x)', 'Fonction f(x)'),
                      hintText: 'sin(x), x², exp(x), ...',
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
                  child: Text(_t('Plot', 'Tracer')),
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
                _QuickPresetChip(label: 'x²', onTap: () => _setPreset('x²')),
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
                        roots: roots,
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
                      Text(
                        _t('Function study', 'Étude de la fonction'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: _t('Domain', 'Domaine'),
                        value: MathLibrary.sanitizeForDisplay(study.domain),
                      ),
                      _InfoRow(
                        label: _t('Derivative', 'Dérivée'),
                        value: MathLibrary.sanitizeForDisplay(study.derivative),
                      ),
                      _InfoRow(
                        label: _t('Second derivative', 'Dérivée seconde'),
                        value: MathLibrary.sanitizeForDisplay(study.secondDerivative),
                      ),
                      _InfoRow(
                        label: _t('Period', 'Période'),
                        value: MathLibrary.sanitizeForDisplay(study.period),
                      ),
                      _InfoRow(
                        label: _t('Symmetry', 'Symétrie'),
                        value: MathLibrary.sanitizeForDisplay(study.symmetry),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _t('Roots', 'Racines'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      ...study.roots.map((item) => Text('• ${MathLibrary.sanitizeForDisplay(item)}')).toList(),
                      const SizedBox(height: 8),
                      Text(
                        _t('Extrema', 'Extrema'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      ...study.extrema.map((item) => Text('• ${MathLibrary.sanitizeForDisplay(item)}')).toList(),
                      const SizedBox(height: 8),
                      Text(
                        _t('Asymptotes', 'Asymptotes'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      ...study.asymptotes.map((item) => Text('• ${MathLibrary.sanitizeForDisplay(item)}')).toList(),
                      const SizedBox(height: 8),
                      Text(
                        _t('Variation table', 'Tableau de variation'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(MathLibrary.sanitizeForDisplay(study.variationTable)),
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
  final List<double> roots;
  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;

  const _CurvePainter({
    required this.segments,
    required this.roots,
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

    final rootPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;

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

    for (final root in roots) {
      final px = xToPx(root);
      final py = yToPy(0.0);
      canvas.drawCircle(Offset(px, py), 5, rootPaint);
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
      oldDelegate.roots != roots ||
      oldDelegate.xMin != xMin ||
      oldDelegate.xMax != xMax ||
      oldDelegate.yMin != yMin ||
      oldDelegate.yMax != yMax;
}

