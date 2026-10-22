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
  double _gestureXMin = 0, _gestureXMax = 0, _gestureYMin = 0, _gestureYMax = 0;
  late TabController _tabController;
  final GlobalKey _chartKey = GlobalKey();
  final GlobalKey _studyKey = GlobalKey();

  static const _examples = [
    'sin(x)',
    'cos(x)',
    'x^3-3*x',
    'a*x^2+b*x+c',
    'ln(2x+1)',
    '(2x+1)/(x-3)',
    'sqrt(x)',
    '1/x',
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

  void _addExpression() {
    if (_exprCtrls.length >= 5) return;
    setState(() {
      _exprCtrls.add(TextEditingController());
      _exprVisible.add(true);
    });
  }

  void _removeExpression(int i) {
    if (_exprCtrls.length <= 1) return;
    setState(() {
      _exprCtrls[i].dispose();
      _exprCtrls.removeAt(i);
      _exprVisible.removeAt(i);
    });
    _analyze();
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
      _detectSliders(exprs.join('+'));
      if (_autoDomain) {
        final w = _engine.suggestWindow(exprs.first);
        _xMin = w.xMin;
        _xMax = w.xMax;
        _yMin = w.yMin;
        _yMax = w.yMax;
        _piLabels = w.piLabels;
        // Restreindre strictement au domaine reel
        final clamped = _graphService.clampToDomain(exprs.first, _xMin, _xMax);
        _xMin = clamped.xMin;
        _xMax = clamped.xMax;
      }
      var ymin = double.infinity;
      var ymax = -double.infinity;
      for (final expr in exprs) {
        for (final seg
            in _graphService.evaluateSegments(expr, _xMin, _xMax, 1000)) {
          for (final p in seg) {
            if (p.value < ymin) ymin = p.value;
            if (p.value > ymax) ymax = p.value;
          }
        }
      }
      if (!_piLabels && _autoDomain) {
        if (!ymin.isFinite) {
          ymin = -5;
          ymax = 5;
        }
        if (ymax - ymin < 1e-6) {
          ymin -= 1;
          ymax += 1;
        }
        final yPad = (ymax - ymin) * 0.12;
        ymin -= yPad;
        ymax += yPad;
        if (ymax - ymin > 30) {
          final mid = (ymin + ymax) / 2;
          ymin = mid - 15;
          ymax = mid + 15;
        }
        final span = math.max(_xMax - _xMin, ymax - ymin);
        final xMid = (_xMin + _xMax) / 2;
        final yMid = (ymin + ymax) / 2;
        _xMin = xMid - span / 2;
        _xMax = xMid + span / 2;
        _yMin = yMid - span / 2;
        _yMax = yMid + span / 2;
        // Re-clamp apres orthonorme pour ne pas reintroduire hors domaine
        final clamped2 = _graphService.clampToDomain(exprs.first, _xMin, _xMax);
        // Garder orthonorme mais ne tracer que dans domaine : X peut etre plus large,
        // les segments ignoreront hors domaine
        _xMin = math.min(_xMin, clamped2.xMin);
        _xMax = math.max(_xMax, clamped2.xMax);
      }
      final allSegs2 = <List<List<MapEntry<double, double>>>>[];
      for (final expr in exprs) {
        allSegs2.add(_graphService.evaluateSegments(expr, _xMin, _xMax, 1200));
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
    x = _snapPi(x);
    final y = _engine.evaluate(_withParams(_primaryExpr), x);
    setState(() {
      _traceX = x;
      _traceY = (y != null && y.isFinite && y.abs() < 1e5)
          ? MathLibrary.clean(y)
          : null;
    });
  }

  String _fmtTraceX(double v) {
    if (!_piLabels) return _fmtDec(v);
    final tol = (_xMax - _xMin) / 80;
    String? best;
    var bestDist = tol;
    for (final den in [1, 2, 3, 4, 5, 6, 8, 12]) {
      final step = math.pi / den;
      final k = (v / step).round();
      final candidate = k * step;
      final d = (v - candidate).abs();
      if (d <= bestDist) {
        bestDist = d;
        best = _piFractionLabel(k, den);
      }
    }
    return best ?? _fmtDec(v);
  }

  String _fmtTraceY(double v) {
    if (_piLabels) {
      final vals = <double>[
        0,
        1,
        -1,
        0.5,
        -0.5,
        math.sqrt(2) / 2,
        -math.sqrt(2) / 2,
        math.sqrt(3) / 2,
        -math.sqrt(3) / 2,
      ];
      final labs = <String>[
        '0',
        '1',
        '-1',
        '1/2',
        '-1/2',
        '√2/2',
        '-√2/2',
        '√3/2',
        '-√3/2',
      ];
      for (var i = 0; i < vals.length; i++) {
        if ((v - vals[i]).abs() < 0.04) return labs[i];
      }
    }
    return _fmtDec(v);
  }

  String _piFractionLabel(int k, int den) {
    if (k == 0) return '0';
    final sign = k < 0 ? '-' : '';
    final num = k.abs();
    final g = num.gcd(den);
    final n = num ~/ g;
    final d = den ~/ g;
    if (d == 1) return n == 1 ? '${sign}π' : '$sign$nπ';
    if (n == 1) return '${sign}π/$d';
    return '$sign$nπ/$d';
  }

  String _fmtDec(double v) {
    return MathLibrary.format(v);
  }

  double _snapPi(double x) {
    if (!_piLabels) return x;
    final tol = (_xMax - _xMin) / 60;
    var best = x;
    var bestDist = tol;
    for (final den in [1, 2, 3, 4, 5, 6, 8, 12]) {
      final step = math.pi / den;
      final k = (x / step).round();
      final c = k * step;
      final d = (x - c).abs();
      if (d < bestDist) {
        bestDist = d;
        best = c;
      }
    }
    return best;
  }

  void _zoomFromGesture(double scale) {
    if (!scale.isFinite || scale <= 0) return;
    final factor = (1 / scale).clamp(0.2, 5.0);
    final xCenter = (_gestureXMin + _gestureXMax) / 2;
    final yCenter = (_gestureYMin + _gestureYMax) / 2;
    setState(() {
      _autoDomain = false;
      final xHalf = (_gestureXMax - _gestureXMin) * factor / 2;
      final yHalf = (_gestureYMax - _gestureYMin) * factor / 2;
      _xMin = xCenter - xHalf;
      _xMax = xCenter + xHalf;
      _yMin = yCenter - yHalf;
      _yMax = yCenter + yHalf;
    });
    _analyze();
  }

  Future<ui.Image?> _captureChart() async {
    return _captureBoundary(_chartKey);
  }

  Future<ui.Image?> _captureStudy() async {
    return _captureBoundary(_studyKey);
  }

  Future<ui.Image?> _captureBoundary(GlobalKey key) async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    return boundary.toImage(pixelRatio: 3.0);
  }

  Future<ui.Image?> _captureVisibleStudyWithChart() async {
    final study = await _captureStudy();
    if (study == null) return null;

    _tabController.animateTo(0);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final chart = await _captureChart();
    _tabController.animateTo(1);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (chart == null) return study;

    final width = math.max(study.width, chart.width);
    final height = chart.height + study.height;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    canvas.drawImage(chart, Offset((width - chart.width) / 2, 0), Paint());
    canvas.drawImage(study,
        Offset((width - study.width) / 2, chart.height.toDouble()), Paint());
    final result = await recorder.endRecording().toImage(width, height);
    return result;
  }

  Future<Uint8List> _pngWithWatermark(ui.Image image) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(image, Offset.zero, Paint());
    canvas.save();
    canvas.translate(image.width / 2, image.height / 2);
    canvas.rotate(-math.pi / 4);
    final painter = TextPainter(
      text: const TextSpan(
          text: 'Calc For All',
          style: TextStyle(
              color: Color(0x55333333),
              fontSize: 52,
              fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    for (var y = -image.height; y < image.height; y += 150) {
      for (var x = -image.width; x < image.width; x += 360) {
        painter.paint(canvas, Offset(x.toDouble(), y.toDouble()));
      }
    }
    canvas.restore();
    final result =
        await recorder.endRecording().toImage(image.width, image.height);
    final bytes = await result.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  Future<void> _exportImage() async {
    final image = _tabController.index == 1
        ? await _captureVisibleStudyWithChart()
        : await _captureChart();
    if (image == null) return;
    final bytes = await _pngWithWatermark(image);
    final name = _tabController.index == 1
        ? 'calc-for-all-etude-et-courbe.png'
        : 'calc-for-all-graph.png';
    await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'image/png', name: name)]);
  }

  Future<void> _exportPdf() async {
    final studyTab = _tabController.index == 1;
    ui.Image? image;
    if (studyTab) {
      _tabController.animateTo(0);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      image = await _captureChart();
      _tabController.animateTo(1);
      await Future<void>.delayed(const Duration(milliseconds: 120));
    } else {
      image = await _captureChart();
    }
    if (image == null) return;
    final png = await _pngWithWatermark(image);
    final document = pw.Document();
    final graphImage = pw.MemoryImage(png);
    document.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Stack(children: [
        pw.Positioned.fill(
          child: pw.Center(
            child: pw.Transform.rotate(
              angle: -math.pi / 4,
              child: pw.Opacity(
                opacity: .08,
                child: pw.Text(
                  'Calc For All',
                  style: pw.TextStyle(fontSize: 48.0, color: PdfColors.grey),
                ),
              ),
            ),
          ),
        ),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Calc For All',
              style:
                  pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Fonction : ${_primaryExpr}'),
          pw.SizedBox(height: 12),
          pw.Image(graphImage, fit: pw.BoxFit.contain),
          if (_study != null) ...[
            pw.SizedBox(height: 12),
            pw.Text('Étude de fonction',
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text('Domaine : ${_study!.domain}'),
            pw.Text('Dérivée : ${_study!.derivative}'),
            pw.Text('Limites : ${_study!.limits}'),
            pw.Text('Asymptotes : ${_study!.asymptotes.join(' ; ')}'),
            pw.Text('Variation : ${_study!.variationTable}'),
          ],
        ]),
      ]),
    ));
    await Printing.sharePdf(
        bytes: await document.save(),
        filename: studyTab
            ? 'calc-for-all-etude-et-courbe.pdf'
            : 'calc-for-all-graph.pdf');
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
          PopupMenuButton<String>(
            tooltip: 'Exporter',
            icon: const Icon(Icons.ios_share_rounded),
            onSelected: (value) =>
                value == 'png' ? _exportImage() : _exportPdf(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'png', child: Text('Exporter en image PNG')),
              PopupMenuItem(value: 'pdf', child: Text('Exporter en PDF')),
            ],
          ),
          TextButton(onPressed: _loadExample, child: const Text('Exemple')),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Graphique'), Tab(text: 'Étude')],
        ),
      ),
      body: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 140),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _exprCtrls.length,
              itemBuilder: (_, i) {
                final color = _desmosColors[i % _desmosColors.length];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() => _exprVisible[i] = !_exprVisible[i]);
                          _analyze();
                        },
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: _exprVisible[i] ? color : Colors.transparent,
                            border: Border.all(color: color, width: 2),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _exprCtrls[i],
                          decoration: InputDecoration(
                            hintText: 'sin(x)  ou  ln(x)  ou  sqrt(x)',
                            isDense: true,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          onSubmitted: (_) => _analyze(),
                          onChanged: (v) {
                            if (i == 0) _detectSliders(v);
                          },
                        ),
                      ),
                      if (_exprCtrls.length > 1)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => _removeExpression(i),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _addExpression,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Expression'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _loading ? null : _analyze,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Tracer'),
                ),
              ],
            ),
          ),
          if (_showSliders)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  _slider('a', _a, (v) {
                    setState(() => _a = v);
                    _analyze();
                  }),
                  _slider('b', _b, (v) {
                    setState(() => _b = v);
                    _analyze();
                  }),
                  _slider('c', _c, (v) {
                    setState(() => _c = v);
                    _analyze();
                  }),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _autoDomain = false;
                        final mid = (_xMin + _xMax) / 2;
                        final half = (_xMax - _xMin) / 2 * 1.4;
                        _xMin = mid - half;
                        _xMax = mid + half;
                      });
                      _analyze();
                    },
                    child: const Text('-'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _autoDomain = true);
                      _analyze();
                    },
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _autoDomain = false;
                        final mid = (_xMin + _xMax) / 2;
                        final half = (_xMax - _xMin) / 4;
                        _xMin = mid - half;
                        _xMax = mid + half;
                      });
                      _analyze();
                    },
                    child: const Text('+'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exportImage,
                    icon: const Icon(Icons.image_outlined, size: 17),
                    label: const Text('PNG'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exportPdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
                    label: const Text('PDF'),
                  ),
                ),
              ],
            ),
          ),
          if (_traceX != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                _traceY != null
                    ? 'x = ${_fmtTraceX(_traceX!)}    y = ${_fmtTraceY(_traceY!)}'
                    : 'x = ${_fmtTraceX(_traceX!)}  — f non définie ici',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Theme.of(context).primaryColor),
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

  Widget _slider(String name, double value, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(
            width: 20,
            child: Text(name,
                style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(
          child: Slider(
            value: value.clamp(-5, 5),
            min: -5,
            max: 5,
            divisions: 100,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    if (_allSegments.isEmpty || _allSegments.every((s) => s.isEmpty)) {
      return const Center(
        child: Text(
          'Aucun point dans le domaine sur cette fenêtre.\nEssaie Reset ou une autre expression.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return RepaintBoundary(
      key: _chartKey,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: LayoutBuilder(builder: (context, c) {
          final size = Size(c.maxWidth, c.maxHeight);
          return GestureDetector(
            onScaleStart: (_) => setState(() {
              _gestureXMin = _xMin;
              _gestureXMax = _xMax;
              _gestureYMin = _yMin;
              _gestureYMax = _yMax;
            }),
            onScaleUpdate: (d) {
              if ((d.scale - 1).abs() > 0.01) {
                _zoomFromGesture(d.scale);
              } else {
                _onTrace(d.localFocalPoint, size);
              }
            },
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
    return RepaintBoundary(
      key: _studyKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card('Fonction', MathPretty.functionLine(_study!.expression)),
          _card('Domaine', _study!.domain),
          _card('f′(x)', MathPretty.format(_study!.derivative)),
          _card('f″(x)', MathPretty.format(_study!.secondDerivative)),
          _card('Racines (f = 0)', _study!.roots.join('\n')),
          _card("Ordonnée à l'origine", _study!.intercepts.join('\n')),
          _card("Extrema (f′ = 0)", _study!.extrema.join('\n')),
          _card("Points d'inflexion", _study!.inflections.join('\n')),
          _card('Asymptotes', _study!.asymptotes.join('\n')),
          _card('Limites', _study!.limits),
          _card('Tableau de variation', _study!.variationTable),
          _card('Symétrie', _study!.symmetry),
          _card('Méthode', _study!.explanations),
        ],
      ),
    );
  }

  Widget _card(String t, String c) {
    final isMath = t.contains('f') || t.contains('Fonction');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              c,
              style: TextStyle(
                height: 1.45,
                fontSize: isMath ? 17 : 14,
                fontWeight: isMath ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
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
      Paint()
        ..color = light ? const Color(0xFFF7F7F7) : const Color(0xFF0B1220),
    );

    final minor = Paint()
      ..color = light ? const Color(0xFFE0E0E0) : const Color(0xFF1A2740)
      ..strokeWidth = 0.7;
    final major = Paint()
      ..color = light ? const Color(0xFFC8C8C8) : const Color(0xFF2C3E5A)
      ..strokeWidth = 1.15;
    final axis = Paint()
      ..color = light ? const Color(0xFF2C2C2C) : const Color(0xFFB8C5D6)
      ..strokeWidth = 1.7;
    final labelColor =
        light ? const Color(0xFF555555) : const Color(0xFF9BB0C9);

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

    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (var x = _floor(xMin, stepMajor); x <= xMax + 1e-9; x += stepMajor) {
      if (x.abs() < stepMajor * 0.01) continue;
      final px = toPx(x);
      final label = piLabels ? _fmtPi(x) : _fmt(x);
      tp.text = TextSpan(
          text: label, style: TextStyle(color: labelColor, fontSize: 10));
      tp.layout();
      tp.paint(canvas, Offset(px - tp.width / 2, oy + usedH + 4));
    }
    for (var y = _floor(yMin, stepMajor); y <= yMax + 1e-9; y += stepMajor) {
      if (y.abs() < stepMajor * 0.01) continue;
      final py = toPy(y);
      tp.text = TextSpan(
          text: _fmt(y), style: TextStyle(color: labelColor, fontSize: 10));
      tp.layout();
      tp.paint(canvas, Offset(ox - tp.width - 6, py - tp.height / 2));
    }

    final plotRect = Rect.fromLTWH(ox, oy, usedW, usedH);
    canvas.save();
    canvas.clipRect(plotRect);

    for (var i = 0; i < allSegments.length; i++) {
      final curve = Paint()
        ..color = colors[i % colors.length]
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;
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
      final px = toPx(p.key);
      final py = toPy(p.value);
      canvas.drawCircle(Offset(px, py), 6, Paint()..color = colors[1]);
      canvas.drawCircle(
        Offset(px, py),
        6,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    if (traceX != null && traceY != null) {
      final px = toPx(traceX!);
      final py = toPy(traceY!);
      final cross = Paint()
        ..color = colors[0].withOpacity(0.45)
        ..strokeWidth = 1;
      canvas.drawLine(Offset(px, oy), Offset(px, oy + usedH), cross);
      canvas.drawLine(Offset(ox, py), Offset(ox + usedW, py), cross);
      canvas.drawCircle(Offset(px, py), 5, Paint()..color = colors[0]);
    }

    canvas.restore();

    canvas.drawRect(
      plotRect,
      Paint()
        ..color = light ? const Color(0xFFAAAAAA) : const Color(0xFF3A4A66)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  String _fmtPi(double v) {
    final half = math.pi / 2;
    final k = (v / half).round();
    if ((v - k * half).abs() > 0.08) return _fmt(v);
    if (k == 0) return '0';
    final sign = k < 0 ? '-' : '';
    final a = k.abs();
    if (a % 2 == 0) {
      final n = a ~/ 2;
      return n == 1 ? '${sign}π' : '$sign$nπ';
    }
    return a == 1 ? '${sign}π/2' : '$sign$aπ/2';
  }

  String _fmt(double v) {
    return MathLibrary.format(v);
  }

  double _niceStep(double rough) {
    if (rough <= 0) return 1;
    final exp = (math.log(rough) / math.ln10).floor();
    final f = rough / math.pow(10.0, exp);
    final nf = f < 1.5
        ? 1.0
        : f < 3
            ? 2.0
            : f < 7
                ? 5.0
                : 10.0;
    return nf * math.pow(10.0, exp).toDouble();
  }

  double _floor(double v, double step) => (v / step).floor() * step;
  bool _mult(double v, double step) =>
      ((v / step) - (v / step).roundToDouble()).abs() < 1e-6;

  @override
  bool shouldRepaint(covariant _DesmosPainter old) => true;
}
