import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/services/graph_service.dart';
import '../../data/services/function_analysis_service.dart';
import '../../data/services/math_expression_engine.dart';
import '../../data/services/math_library.dart';
import '../../data/services/math_pretty.dart';
import '../../data/services/export_watermark.dart';

const _desmosColors = [
  Color(0xFF2D70B3),
  Color(0xFFC74440),
  Color(0xFF388C46),
  Color(0xFF6042A6),
  Color(0xFFFA7E19),
];

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});
  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen>
    with SingleTickerProviderStateMixin {
  final GraphService _graphService = GraphService();
  final FunctionAnalysisService _analysisService = FunctionAnalysisService();
  final MathExpressionEngine _engine = MathExpressionEngine();

  final List<TextEditingController> _exprCtrls = [
    TextEditingController(text: 'sin(x)'),
  ];
  final List<bool> _exprVisible = [true];

  List<List<List<MapEntry<double, double>>>> _allSegments = [];
  FunctionStudyResult? _study;
  double _xMin = -2 * math.pi, _xMax = 2 * math.pi;
  double _yMin = -2, _yMax = 2;
  String _error = '';
  bool _loading = false;
  bool _autoDomain = true;
  bool _desmosLight = true;
  bool _piLabels = true;
  double _a = 1, _b = 0, _c = 0;
  bool _showSliders = false;
  double? _traceX, _traceY;
  late TabController _tabController;
  final GlobalKey _chartKey = GlobalKey();

  static const _examples = [
    'sin(x)', 'cos(x)', 'x^3-3*x', 'sqrt(x)', 'x^(1/3)', 'x^2', '1/x', 'exp(x)',
  ];
  int _exampleIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _analyze();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _exprCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  String get _primaryExpr =>
      _exprCtrls.isNotEmpty ? _exprCtrls.first.text.trim() : '';

  String _withParams(String expr) {
    var s = MathLibrary.normalizeExpression(expr);
    s = s.replaceAllMapped(RegExp(r'(?<![a-z])a(?![a-z])'), (_) => '($_a)');
    s = s.replaceAllMapped(RegExp(r'(?<![a-z])b(?![a-z])'), (_) => '($_b)');
    s = s.replaceAllMapped(RegExp(r'(?<![a-z])c(?![a-z])'), (_) => '($_c)');
    return s;
  }

  void _detectSliders(String expr) {
    final n = MathLibrary.normalizeExpression(expr);
    setState(() {
      _showSliders = RegExp(r'(?<![a-z])[abc](?![a-z])').hasMatch(n);
    });
  }

  void _loadExample() {
    setState(() {
      final ex = _examples[_exampleIndex % _examples.length];
      _exampleIndex++;
      _autoDomain = true;
      _exprCtrls.first.text = ex;
      _detectSliders(ex);
    });
    _analyze();
  }

  Future<void> _analyze() async {
    setState(() {
      _loading = true;
      _error = '';
      _traceX = null;
      _traceY = null;
    });
    await Future.delayed(const Duration(milliseconds: 20));
    final exprs = <String>[];
    for (var i = 0; i < _exprCtrls.length; i++) {
      if (!_exprVisible[i]) continue;
      final t = _exprCtrls[i].text.trim();
      if (t.isEmpty) continue;
      exprs.add(_withParams(t));
    }
    if (exprs.isEmpty) {
      setState(() {
        _error = 'Ajoute une expression';
        _loading = false;
      });
      return;
    }
    try {
      if (_autoDomain) {
        final w = _engine.suggestWindow(exprs.first);
        _xMin = w.xMin;
        _xMax = w.xMax;
        _yMin = w.yMin;
        _yMax = w.yMax;
        _piLabels = w.piLabels;
        final clamped =
            _graphService.clampToDomain(exprs.first, _xMin, _xMax);
        _xMin = clamped.xMin;
        _xMax = clamped.xMax;
      }
      final allSegs2 = <List<List<MapEntry<double, double>>>>[];
      for (final expr in exprs) {
        allSegs2.add(
            _graphService.evaluateSegments(expr, _xMin, _xMax, 1200));
      }
      final study =
          _analysisService.analyze(exprs.first, xMin: _xMin, xMax: _xMax);
      setState(() {
        _allSegments = allSegs2;
        _study = study;
        _loading = false;
        _error = '';
      });
    } catch (_) {
      setState(() {
        _error = 'Expression invalide';
        _loading = false;
        _allSegments = [];
        _study = null;
      });
    }
  }

  void _onTrace(Offset local, Size size) {
    const padL = 40.0, padR = 14.0, padT = 14.0, padB = 30.0;
    final w = size.width - padL - padR;
    final h = size.height - padT - padB;
    if (w <= 0 || h <= 0) return;
    final xSpan = (_xMax - _xMin).abs();
    final ySpan = (_yMax - _yMin).abs();
    final scale = math.min(w / xSpan, h / ySpan);
    final usedW = xSpan * scale;
    final ox = padL + (w - usedW) / 2;
    var x = _xMin + (local.dx - ox) / scale;
    if (x < _xMin || x > _xMax) return;
    final y = _engine.evaluate(_withParams(_primaryExpr), x);
    setState(() {
      _traceX = x;
      _traceY = (y != null && y.isFinite && y.abs() < 1e5)
          ? MathLibrary.clean(y)
          : null;
    });
  }

  Future<ui.Image?> _captureChart() async {
    final ro = _chartKey.currentContext?.findRenderObject();
    if (ro is! RenderRepaintBoundary) return null;
    return ro.toImage(pixelRatio: 3.0);
  }

  Future<void> _exportImage() async {
    final image = await _captureChart();
    if (image == null) return;
    final bd = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bd == null) return;
    final withMark =
        await ExportWatermark.applyToPng(bd.buffer.asUint8List());
    await Share.shareXFiles([
      XFile.fromData(withMark,
          mimeType: 'image/png', name: 'calc-for-all-graph.png'),
    ]);
  }

  Future<void> _exportPdf() async {
    if (_study == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analyse d\'abord une fonction')),
        );
      }
      return;
    }
    try {
      pw.Font regular;
      pw.Font bold;
      try {
        regular = pw.Font.ttf(await rootBundle.load('assets/DejaVuSans.ttf'));
        bold = pw.Font.ttf(await rootBundle.load('assets/DejaVuSans-Bold.ttf'));
      } catch (_) {
        regular = pw.Font.helvetica();
        bold = pw.Font.helveticaBold();
      }
      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        build: (_) => [
          pw.Text('Étude de fonction — Calc For All',
              style: pw.TextStyle(font: bold, fontSize: 18)),
          pw.SizedBox(height: 12),
          pw.Text(MathPretty.functionLine(_study!.expression),
              style: pw.TextStyle(font: bold, fontSize: 14)),
          pw.Text('Domaine : ${_study!.domain}'),
          pw.Text("f'(x) = ${MathPretty.format(_study!.derivative)}"),
          pw.Text("f''(x) = ${MathPretty.format(_study!.secondDerivative)}"),
          pw.SizedBox(height: 8),
          pw.Text('Racines :', style: pw.TextStyle(font: bold)),
          ..._study!.roots.map((e) => pw.Text(e)),
          pw.Text('Extrema :', style: pw.TextStyle(font: bold)),
          ..._study!.extrema.map((e) => pw.Text(e)),
          pw.Text(_study!.variationTable),
          pw.Text(_study!.explanations),
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Transform.rotate(
              angle: -0.785398,
              child: pw.Opacity(
                opacity: 0.22,
                child: pw.Text(
                  'Powered by Calc for all',
                  style: const pw.TextStyle(fontSize: 22),
                ),
              ),
            ),
          ),
        ],
      ));
      await Printing.sharePdf(
          bytes: await pdf.save(), filename: 'etude_calc_for_all.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur PDF : $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Graphique'),
        actions: [
          IconButton(
            icon: Icon(_desmosLight ? Icons.dark_mode : Icons.light_mode),
            onPressed: () => setState(() => _desmosLight = !_desmosLight),
          ),
          TextButton(onPressed: _loadExample, child: const Text('Exemple')),
          PopupMenuButton<String>(
            tooltip: 'Exporter',
            onSelected: (value) {
              if (value == 'png') {
                _exportImage();
              } else {
                _exportPdf();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'png', child: Text('Exporter PNG')),
              PopupMenuItem(value: 'pdf', child: Text('Exporter PDF')),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.ios_share_rounded),
                  SizedBox(width: 6),
                  Text('Exporter',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Graphique'), Tab(text: 'Étude')],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _exprCtrls.first,
                    decoration: InputDecoration(
                      hintText: 'sin(x), sqrt(x)…',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _analyze(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading ? null : _analyze,
                  child: const Text('Tracer'),
                ),
              ],
            ),
          ),
          if (_error.isNotEmpty)
            Text(_error, style: const TextStyle(color: Colors.red)),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildChart(), _buildStudy()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_allSegments.isEmpty || _allSegments.every((s) => s.isEmpty)) {
      return const Center(child: Text('Aucune courbe'));
    }
    return RepaintBoundary(
      key: _chartKey,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: LayoutBuilder(builder: (context, c) {
          final size = Size(c.maxWidth, c.maxHeight);
          return GestureDetector(
            onPanUpdate: (d) => _onTrace(d.localPosition, size),
            onTapDown: (d) => _onTrace(d.localPosition, size),
            child: CustomPaint(
              painter: _DesmosPainter(
                allSegments: _allSegments,
                xMin: _xMin,
                xMax: _xMax,
                yMin: _yMin,
                yMax: _yMax,
                light: _desmosLight,
                colors: _desmosColors,
                traceX: _traceX,
                traceY: _traceY,
                piLabels: _piLabels,
                remarkable: _study?.remarkablePoints ?? const [],
              ),
              child: const SizedBox.expand(),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStudy() {
    if (_study == null) {
      return const Center(child: Text('Analyse une fonction'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card('Fonction', MathPretty.functionLine(_study!.expression)),
        _card('Domaine', _study!.domain),
        _card("f'(x)", MathPretty.format(_study!.derivative)),
        _card('Racines', _study!.roots.join('\n')),
        _card('Extrema', _study!.extrema.join('\n')),
        _card('Tableau de variation', _study!.variationTable),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _exportPdf,
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Exporter PDF'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _exportImage,
          icon: const Icon(Icons.image),
          label: const Text('Exporter PNG'),
        ),
      ],
    );
  }

  Widget _card(String t, String c) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(c, style: const TextStyle(height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _DesmosPainter extends CustomPainter {
  final List<List<List<MapEntry<double, double>>>> allSegments;
  final double xMin, xMax, yMin, yMax;
  final bool light;
  final List<Color> colors;
  final double? traceX, traceY;
  final bool piLabels;
  final List<MapEntry<double, double>> remarkable;

  _DesmosPainter({
    required this.allSegments,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
    required this.light,
    required this.colors,
    this.traceX,
    this.traceY,
    this.piLabels = false,
    this.remarkable = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    const padL = 40.0, padR = 14.0, padT = 14.0, padB = 30.0;
    final w = size.width - padL - padR;
    final h = size.height - padT - padB;
    if (w <= 0 || h <= 0) return;
    final xSpan = (xMax - xMin).abs();
    final ySpan = (yMax - yMin).abs();
    if (xSpan < 1e-12 || ySpan < 1e-12) return;
    final scale = math.min(w / xSpan, h / ySpan);
    final usedW = xSpan * scale;
    final usedH = ySpan * scale;
    final ox = padL + (w - usedW) / 2;
    final oy = padT + (h - usedH) / 2;
    double toPx(double x) => ox + (x - xMin) * scale;
    double toPy(double y) => oy + usedH - (y - yMin) * scale;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ),
      Paint()..color = light ? const Color(0xFFF7F7F7) : const Color(0xFF0B1220),
    );

    final minor = Paint()
      ..color = light ? const Color(0xFFE0E0E0) : const Color(0xFF1A2740)
      ..strokeWidth = 0.8;
    final major = Paint()
      ..color = light ? const Color(0xFFC8C8C8) : const Color(0xFF2C3E5A)
      ..strokeWidth = 1.2;
    final axis = Paint()
      ..color = light ? const Color(0xFF2C2C2C) : const Color(0xFFB8C5D6)
      ..strokeWidth = 1.8;

    final stepMajor =
        piLabels ? (math.pi / 2) : _niceStep(math.min(xSpan, ySpan) / 8);
    final stepMinor = piLabels ? (math.pi / 12) : stepMajor / 5;

    for (var x = _floor(xMin, stepMinor); x <= xMax + 1e-9; x += stepMinor) {
      final px = toPx(x);
      if (px < ox - 1 || px > ox + usedW + 1) continue;
      canvas.drawLine(Offset(px, oy), Offset(px, oy + usedH),
          _mult(x, stepMajor) ? major : minor);
    }
    for (var y = _floor(yMin, stepMinor); y <= yMax + 1e-9; y += stepMinor) {
      final py = toPy(y);
      if (py < oy - 1 || py > oy + usedH + 1) continue;
      canvas.drawLine(Offset(ox, py), Offset(ox + usedW, py),
          _mult(y, stepMajor) ? major : minor);
    }

    if (xMin <= 0 && xMax >= 0) {
      canvas.drawLine(Offset(toPx(0), oy), Offset(toPx(0), oy + usedH), axis);
    }
    if (yMin <= 0 && yMax >= 0) {
      canvas.drawLine(Offset(ox, toPy(0)), Offset(ox + usedW, toPy(0)), axis);
    }

    final plotRect = Rect.fromLTWH(ox, oy, usedW, usedH);
    canvas.save();
    canvas.clipRect(plotRect);

    for (var i = 0; i < allSegments.length; i++) {
      final curve = Paint()
        ..color = colors[i % colors.length]
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (final seg in allSegments[i]) {
        if (seg.length < 2) continue;
        final path = Path();
        path.moveTo(toPx(seg.first.key), toPy(seg.first.value));
        for (var j = 1; j < seg.length; j++) {
          path.lineTo(toPx(seg[j].key), toPy(seg[j].value));
        }
        canvas.drawPath(path, curve);
      }
    }

    for (final p in remarkable) {
      if (p.key < xMin || p.key > xMax) continue;
      if (p.value < yMin || p.value > yMax) continue;
      canvas.drawCircle(
          Offset(toPx(p.key), toPy(p.value)), 6, Paint()..color = colors[1]);
    }

    if (traceX != null && traceY != null) {
      canvas.drawCircle(
          Offset(toPx(traceX!), toPy(traceY!)), 5, Paint()..color = colors[0]);
    }
    canvas.restore();

    final labelColor = light ? const Color(0xFF1A1A1A) : const Color(0xFFEFF5FF);
    final labelStyle = TextStyle(
      color: labelColor,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    for (var x = _floor(xMin, stepMajor); x <= xMax + 1e-9; x += stepMajor) {
      final px = toPx(x);
      if (px < ox - 1 || px > ox + usedW + 1) continue;
      if (x.abs() < 1e-9) continue;
      final value = MathLibrary.format(x);
      final text = TextPainter(
        text: TextSpan(text: value, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(px - text.width / 2, oy + usedH + 4));
    }

    for (var y = _floor(yMin, stepMajor); y <= yMax + 1e-9; y += stepMajor) {
      final py = toPy(y);
      if (py < oy - 1 || py > oy + usedH + 1) continue;
      if (y.abs() < 1e-9) continue;
      final value = MathLibrary.format(y);
      final text = TextPainter(
        text: TextSpan(text: value, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(ox - text.width - 6, py - text.height / 2));
    }

    canvas.drawRect(
      plotRect,
      Paint()
        ..color = light ? const Color(0xFFAAAAAA) : const Color(0xFF3A4A66)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  double _niceStep(double rough) {
    if (rough <= 0) return 1;
    final exp = (math.log(rough) / math.ln10).floor();
    final f = rough / math.pow(10.0, exp);
    final nf = f < 1.5 ? 1.0 : f < 3 ? 2.0 : f < 7 ? 5.0 : 10.0;
    return nf * math.pow(10.0, exp).toDouble();
  }

  double _floor(double v, double step) => (v / step).floor() * step;
  bool _mult(double v, double step) =>
      ((v / step) - (v / step).roundToDouble()).abs() < 1e-6;

  @override
  bool shouldRepaint(covariant _DesmosPainter old) => true;
}



























































































































































































































































































































































































































































































































































































































































































































































































