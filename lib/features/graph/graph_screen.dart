import 'dart:math' as math;
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

/// Couleurs type Desmos pour multi-courbes
const _desmosColors = [
  Color(0xFF2D70B3), // bleu
  Color(0xFFC74440), // rouge
  Color(0xFF388C46), // vert
  Color(0xFF6042A6), // violet
  Color(0xFFFA7E19), // orange
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

  // Liste d'expressions (style Desmos)
  final List<TextEditingController> _exprCtrls = [
    TextEditingController(text: 'sin(x)'),
  ];
  final List<bool> _exprVisible = [true];

  final TextEditingController _numController = TextEditingController();
  final TextEditingController _denController = TextEditingController();

  // Segments par expression
  List<List<List<MapEntry<double, double>>>> _allSegments = [];
  FunctionStudyResult? _study;

  double _xMin = -10, _xMax = 10, _yMin = -10, _yMax = 10;
  String _error = '';
  bool _loading = false;
  bool _autoDomain = true;
  bool _fractionMode = false;
  bool _desmosLight = true; // grille claire style Desmos

  // Curseurs parametres a, b, c (Desmos sliders)
  double _a = 1, _b = 0, _c = 0;
  bool _showSliders = false;

  // Trace interactive
  Offset? _tracePixel;
  double? _traceX, _traceY;

  late TabController _tabController;
  final GlobalKey _chartKey = GlobalKey();

  static const _examples = [
    'sin(x)',
    'a*x^2+b*x+c',
    'ln(2x+1)',
    '(2x+1)/(x-3)',
    '(2x+1)/ln(x-e)',
    'cos(x)',
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
    _numController.dispose();
    _denController.dispose();
    super.dispose();
  }

  String get _primaryExpr {
    if (_fractionMode) {
      final n = _numController.text.trim();
      final d = _denController.text.trim();
      if (n.isNotEmpty && d.isNotEmpty) return '($n)/($d)';
    }
    return _exprCtrls.isNotEmpty ? _exprCtrls.first.text.trim() : '';
  }

  /// Remplace a,b,c par les valeurs des curseurs
  String _withParams(String expr) {
    var s = MathLibrary.normalizeExpression(expr);
    // Eviter de remplacer dans sin, cos, tan, abs, etc.
    s = s.replaceAllMapped(RegExp(r'(?<![a-z])a(?![a-z])'), (_) => '($_a)');
    s = s.replaceAllMapped(RegExp(r'(?<![a-z])b(?![a-z])'), (_) => '($_b)');
    s = s.replaceAllMapped(RegExp(r'(?<![a-z])c(?![a-z])'), (_) => '($_c)');
    return s;
  }

  void _detectSliders(String expr) {
    final n = MathLibrary.normalizeExpression(expr);
    final hasA = RegExp(r'(?<![a-z])a(?![a-z])').hasMatch(n);
    final hasB = RegExp(r'(?<![a-z])b(?![a-z])').hasMatch(n);
    final hasC = RegExp(r'(?<![a-z])c(?![a-z])').hasMatch(n);
    setState(() => _showSliders = hasA || hasB || hasC);
  }

  void _addExpression() {
    if (_exprCtrls.length >= 5) return;
    setState(() {
      _exprCtrls.add(TextEditingController(text: ''));
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
      _fractionMode = false;
      _exprCtrls.first.text = ex;
      _detectSliders(ex);
    });
    _analyze();
  }

  Future<void> _analyze() async {
    setState(() {
      _loading = true;
      _error = '';
      _tracePixel = null;
      _traceX = null;
      _traceY = null;
    });
    await Future.delayed(const Duration(milliseconds: 30));

    final exprs = <String>[];
    if (_fractionMode) {
      final e = _primaryExpr;
      if (e.isEmpty) {
        setState(() {
          _error = 'Complete la fraction';
          _loading = false;
        });
        return;
      }
      exprs.add(_withParams(e));
    } else {
      for (var i = 0; i < _exprCtrls.length; i++) {
        if (!_exprVisible[i]) continue;
        final t = _exprCtrls[i].text.trim();
        if (t.isEmpty) continue;
        exprs.add(_withParams(t));
      }
    }

    if (exprs.isEmpty) {
      setState(() {
        _error = 'Ajoute au moins une expression';
        _loading = false;
      });
      return;
    }

    try {
      _detectSliders(exprs.join('+'));

      if (_autoDomain) {
        final suggested = _engine.suggestDomain(exprs.first);
        _xMin = suggested.xMin;
        _xMax = suggested.xMax;
      }

      final allSegs = <List<List<MapEntry<double, double>>>>[];
      var ymin = double.infinity;
      var ymax = -double.infinity;

      for (final expr in exprs) {
        final segs =
            _graphService.evaluateSegments(expr, _xMin, _xMax, 900);
        allSegs.add(segs);
        for (final seg in segs) {
          for (final p in seg) {
            if (p.value < ymin) ymin = p.value;
            if (p.value > ymax) ymax = p.value;
          }
        }
      }

      if (!ymin.isFinite || !ymax.isFinite) {
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

      // Orthonorme
      final xSpan = _xMax - _xMin;
      final ySpan = ymax - ymin;
      final span = math.max(xSpan, ySpan);
      final xMid = (_xMin + _xMax) / 2;
      final yMid = (ymin + ymax) / 2;
      _xMin = xMid - span / 2;
      _xMax = xMid + span / 2;
      _yMin = yMid - span / 2;
      _yMax = yMid + span / 2;

      final allSegs2 = <List<List<MapEntry<double, double>>>>[];
      for (final expr in exprs) {
        allSegs2.add(
            _graphService.evaluateSegments(expr, _xMin, _xMax, 1000));
      }

      final study = _analysisService.analyze(
        exprs.first,
        xMin: _xMin,
        xMax: _xMax,
      );

      setState(() {
        _allSegments = allSegs2;
        _study = study;
        _loading = false;
        if (allSegs2.every((s) => s.isEmpty)) {
          _error = 'Aucun point calculable.';
        }
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
    // Conversion pixel → coordonnees (meme logique que le painter)
    const padL = 40.0, padR = 14.0, padT = 14.0, padB = 30.0;
    final w = size.width - padL - padR;
    final h = size.height - padT - padB;
    if (w <= 0 || h <= 0) return;
    final xSpan = (_xMax - _xMin).abs();
    final ySpan = (_yMax - _yMin).abs();
    final scale = math.min(w / xSpan, h / ySpan);
    final usedW = xSpan * scale;
    final usedH = ySpan * scale;
    final ox = padL + (w - usedW) / 2;
    final oy = padT + (h - usedH) / 2;

    final x = _xMin + (local.dx - ox) / scale;
    if (x < _xMin || x > _xMax) return;

    final expr = _withParams(_primaryExpr);
    final y = _engine.evaluate(expr, x);
    if (y == null || !y.isFinite) {
      setState(() {
        _tracePixel = local;
        _traceX = x;
        _traceY = null;
      });
      return;
    }
    setState(() {
      _tracePixel = local;
      _traceX = x;
      _traceY = MathLibrary.clean(y);
    });
  }

  Future<void> _exportPdf() async {
    if (_study == null) return;
    try {
      final regular =
          pw.Font.ttf(await rootBundle.load('assets/DejaVuSans.ttf'));
      final bold =
          pw.Font.ttf(await rootBundle.load('assets/DejaVuSans-Bold.ttf'));
      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        build: (context) => [
          pw.Text('Etude de fonction - Calc For All',
              style: pw.TextStyle(font: bold, fontSize: 18)),
          pw.SizedBox(height: 12),
          pw.Text('f(x) = ${_study!.expression}',
              style: pw.TextStyle(font: bold, fontSize: 14)),
          pw.Text(_study!.domain),
          pw.Text("f'(x) = ${_study!.derivative}"),
          pw.Text(_study!.limits),
          ..._study!.extrema.map((e) => pw.Text('- $e')),
          ..._study!.asymptotes.map((e) => pw.Text('- $e')),
          pw.Text(_study!.explanations),
        ],
      ));
      await Printing.sharePdf(
          bytes: await pdf.save(), filename: 'etude_fonction.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur PDF : $e')));
      }
    }
  }

  Future<void> _exportPng() async {
    final ro = _chartKey.currentContext?.findRenderObject();
    if (ro is! RenderRepaintBoundary) return;
    final image = await ro.toImage(pixelRatio: 3.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) return;
    await Share.shareXFiles([
      XFile.fromData(bytes.buffer.asUint8List(),
          mimeType: 'image/png', name: 'courbe.png'),
    ]);
  }

  void _showExportMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Exporter PDF'),
              onTap: () {
                Navigator.pop(ctx);
                _exportPdf();
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Exporter PNG'),
              onTap: () {
                Navigator.pop(ctx);
                _exportPng();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Graphique'),
        actions: [
          IconButton(
            tooltip: _desmosLight ? 'Grille sombre' : 'Grille Desmos claire',
            icon: Icon(_desmosLight ? Icons.dark_mode : Icons.light_mode),
            onPressed: () => setState(() => _desmosLight = !_desmosLight),
          ),
          TextButton(onPressed: _loadExample, child: const Text('Exemple')),
          if (_study != null)
            IconButton(
                icon: const Icon(Icons.ios_share), onPressed: _showExportMenu),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Graphique'),
            Tab(text: 'Etude complete'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Liste d'expressions style Desmos
          if (!_fractionMode)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _exprCtrls.length,
                itemBuilder: (ctx, i) {
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
                              color: _exprVisible[i]
                                  ? color
                                  : Colors.transparent,
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
                              hintText: i == 0
                                  ? 'f(x) = sin(x)  ou  a*x^2+b*x+c'
                                  : 'autre expression',
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
          if (!_fractionMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _addExpression,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Expression'),
                  ),
                  FilterChip(
                    label: const Text('Fraction'),
                    selected: _fractionMode,
                    onSelected: (v) => setState(() => _fractionMode = v),
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

          // Mode fraction
          if (_fractionMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _desmosColors[0], width: 1.2),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _numController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                              hintText: 'numerateur',
                              border: InputBorder.none,
                              isDense: true),
                          onSubmitted: (_) => _analyze(),
                        ),
                        Container(
                            height: 2.5,
                            color: _desmosColors[0],
                            margin: const EdgeInsets.symmetric(vertical: 2)),
                        TextField(
                          controller: _denController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                              hintText: 'denominateur',
                              border: InputBorder.none,
                              isDense: true),
                          onSubmitted: (_) => _analyze(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  FilledButton(
                      onPressed: _analyze, child: const Text('Analyser')),
                ],
              ),
            ),

          // Curseurs a, b, c (Desmos)
          if (_showSliders)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  _sliderRow('a', _a, -5, 5, (v) {
                    setState(() => _a = v);
                    _analyze();
                  }),
                  _sliderRow('b', _b, -5, 5, (v) {
                    setState(() => _b = v);
                    _analyze();
                  }),
                  _sliderRow('c', _c, -5, 5, (v) {
                    setState(() => _c = v);
                    _analyze();
                  }),
                ],
              ),
            ),

          // Zoom
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                _zoomBtn('-', () {
                  setState(() {
                    _autoDomain = false;
                    final mid = (_xMin + _xMax) / 2;
                    final half = (_xMax - _xMin) / 2 * 1.4;
                    _xMin = mid - half;
                    _xMax = mid + half;
                    final midY = (_yMin + _yMax) / 2;
                    _yMin = midY - half;
                    _yMax = midY + half;
                  });
                  _analyze();
                }),
                const SizedBox(width: 6),
                _zoomBtn('Reset', () {
                  setState(() {
                    _autoDomain = true;
                    _xMin = -10;
                    _xMax = 10;
                    _yMin = -10;
                    _yMax = 10;
                  });
                  _analyze();
                }),
                const SizedBox(width: 6),
                _zoomBtn('+', () {
                  setState(() {
                    _autoDomain = false;
                    final mid = (_xMin + _xMax) / 2;
                    final half = (_xMax - _xMin) / 4;
                    _xMin = mid - half;
                    _xMax = mid + half;
                    final midY = (_yMin + _yMax) / 2;
                    _yMin = midY - half;
                    _yMax = midY + half;
                  });
                  _analyze();
                }),
              ],
            ),
          ),

          // Trace readout
          if (_traceX != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _traceY != null
                    ? 'x ≈ ${_fmt(_traceX!)}   y ≈ ${_fmt(_traceY!)}'
                    : 'x ≈ ${_fmt(_traceX!)}   (hors domaine)',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor),
              ),
            ),

          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_error,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center),
            ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChart(),
                _buildStudy(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sliderRow(
      String name, double value, double min, double max, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(
            width: 24,
            child: Text(name,
                style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: 100,
            label: value.toStringAsFixed(2),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
            width: 44,
            child: Text(value.toStringAsFixed(2),
                style: const TextStyle(fontSize: 12))),
      ],
    );
  }

  Widget _zoomBtn(String label, VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Text(label),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
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
                ),
                child: const SizedBox.expand(),
              ),
            );
          },
        ),
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
        _section('Fonction', 'f(x) = ${_study!.expression}', Icons.functions),
        _section('Domaine', _study!.domain, Icons.domain),
        _section('Derivee', "f'(x) = ${_study!.derivative}", Icons.functions),
        _section('Limites', _study!.limits, Icons.compare_arrows),
        _sectionList('Extremums', _study!.extrema, Icons.trending_up),
        _sectionList(
            'Asymptotes', _study!.asymptotes, Icons.vertical_align_center),
        _section('Symetrie', _study!.symmetry, Icons.swap_horiz),
        _section(
            'Tableau de variation', _study!.variationTable, Icons.table_chart),
        _section('Explications', _study!.explanations, Icons.menu_book),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _showExportMenu,
          icon: const Icon(Icons.ios_share),
          label: const Text('Exporter'),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _section(String title, String content, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _sectionList(String title, List<String> items, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            const SizedBox(height: 8),
            ...items.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $e', style: const TextStyle(height: 1.35)),
                )),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v.abs() < 1e-9) return '0';
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(3);
  }
}

/// Grille orthonorme style Desmos (claire ou sombre)
class _DesmosPainter extends CustomPainter {
  final List<List<List<MapEntry<double, double>>>> allSegments;
  final double xMin, xMax, yMin, yMax;
  final bool light;
  final List<Color> colors;
  final double? traceX, traceY;

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

    // Fond Desmos
    final bgColor = light ? const Color(0xFFF7F7F7) : const Color(0xFF0B1220);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ),
      Paint()..color = bgColor,
    );

    final minorColor =
        light ? const Color(0xFFE0E0E0) : const Color(0xFF1A2740);
    final majorColor =
        light ? const Color(0xFFC8C8C8) : const Color(0xFF2C3E5A);
    final axisColor =
        light ? const Color(0xFF2C2C2C) : const Color(0xFFB8C5D6);
    final labelColor =
        light ? const Color(0xFF555555) : const Color(0xFF9BB0C9);

    final gridMinor = Paint()
      ..color = minorColor
      ..strokeWidth = 0.7;
    final gridMajor = Paint()
      ..color = majorColor
      ..strokeWidth = 1.15;
    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1.7;

    final stepMajor = _niceStep(math.min(xSpan, ySpan) / 8);
    final stepMinor = stepMajor / 5;

    for (var x = _floorTo(xMin, stepMinor); x <= xMax + 1e-9; x += stepMinor) {
      final px = toPx(x);
      if (px < ox - 1 || px > ox + usedW + 1) continue;
      canvas.drawLine(
        Offset(px, oy),
        Offset(px, oy + usedH),
        _isMultiple(x, stepMajor) ? gridMajor : gridMinor,
      );
    }
    for (var y = _floorTo(yMin, stepMinor); y <= yMax + 1e-9; y += stepMinor) {
      final py = toPy(y);
      if (py < oy - 1 || py > oy + usedH + 1) continue;
      canvas.drawLine(
        Offset(ox, py),
        Offset(ox + usedW, py),
        _isMultiple(y, stepMajor) ? gridMajor : gridMinor,
      );
    }

    if (xMin <= 0 && xMax >= 0) {
      canvas.drawLine(
          Offset(toPx(0), oy), Offset(toPx(0), oy + usedH), axisPaint);
    }
    if (yMin <= 0 && yMax >= 0) {
      canvas.drawLine(
          Offset(ox, toPy(0)), Offset(ox + usedW, toPy(0)), axisPaint);
    }

    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (var x = _floorTo(xMin, stepMajor); x <= xMax + 1e-9; x += stepMajor) {
      if (x.abs() < stepMajor * 0.01) continue;
      final px = toPx(x);
      tp.text = TextSpan(
          text: _fmt(x), style: TextStyle(color: labelColor, fontSize: 10));
      tp.layout();
      tp.paint(canvas, Offset(px - tp.width / 2, oy + usedH + 4));
    }
    for (var y = _floorTo(yMin, stepMajor); y <= yMax + 1e-9; y += stepMajor) {
      if (y.abs() < stepMajor * 0.01) continue;
      final py = toPy(y);
      tp.text = TextSpan(
          text: _fmt(y), style: TextStyle(color: labelColor, fontSize: 10));
      tp.layout();
      tp.paint(canvas, Offset(ox - tp.width - 6, py - tp.height / 2));
    }

    // Courbes multi-couleurs
    for (var i = 0; i < allSegments.length; i++) {
      final color = colors[i % colors.length];
      final curve = Paint()
        ..color = color
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

    // Trace interactive (croix + point)
    if (traceX != null && traceY != null) {
      final px = toPx(traceX!);
      final py = toPy(traceY!);
      final cross = Paint()
        ..color = colors[0].withOpacity(0.5)
        ..strokeWidth = 1;
      canvas.drawLine(Offset(px, oy), Offset(px, oy + usedH), cross);
      canvas.drawLine(Offset(ox, py), Offset(ox + usedW, py), cross);
      canvas.drawCircle(Offset(px, py), 5, Paint()..color = colors[0]);
      canvas.drawCircle(
          Offset(px, py),
          5,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }

    canvas.drawRect(
      Rect.fromLTWH(ox, oy, usedW, usedH),
      Paint()
        ..color = light ? const Color(0xFFAAAAAA) : const Color(0xFF3A4A66)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
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

  double _floorTo(double v, double step) => (v / step).floor() * step;

  bool _isMultiple(double v, double step) {
    final q = v / step;
    return (q - q.roundToDouble()).abs() < 1e-6;
  }

  String _fmt(double v) {
    if (v.abs() < 1e-9) return '0';
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  @override
  bool shouldRepaint(covariant _DesmosPainter old) => true;
}
