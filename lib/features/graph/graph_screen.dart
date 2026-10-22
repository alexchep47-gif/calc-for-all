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
  final TextEditingController _funcController =
      TextEditingController(text: 'sin(x)');
  final TextEditingController _numController = TextEditingController();
  final TextEditingController _denController = TextEditingController();

  List<List<MapEntry<double, double>>> _segments = [];
  FunctionStudyResult? _study;
  double _xMin = -10;
  double _xMax = 10;
  double _yMin = -10;
  double _yMax = 10;
  String _error = '';
  bool _loading = false;
  bool _autoDomain = true;
  bool _fractionMode = false;
  late TabController _tabController;
  final GlobalKey _chartKey = GlobalKey();

  static const _examples = [
    'ln(2x+1)',
    'sin(x)',
    'x^2',
    '1/x',
    'sqrt(x-1)',
    '(2x+1)/(x-3)',
    '(2x+1)/ln(x-e)',
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
    _funcController.dispose();
    _numController.dispose();
    _denController.dispose();
    super.dispose();
  }

  void _loadExample() {
    setState(() {
      final ex = _examples[_exampleIndex % _examples.length];
      _exampleIndex++;
      _autoDomain = true;
      if (ex.contains('/') &&
          !ex.startsWith('ln') &&
          !ex.startsWith('sin')) {
        final parts = ex.split('/');
        if (parts.length == 2) {
          _fractionMode = true;
          _numController.text =
              parts[0].replaceAll('(', '').replaceAll(')', '');
          _denController.text =
              parts[1].replaceAll('(', '').replaceAll(')', '');
          _funcController.text =
              '(${_numController.text})/(${_denController.text})';
        } else {
          _fractionMode = false;
          _funcController.text = ex;
        }
      } else {
        _fractionMode = false;
        _funcController.text = ex;
      }
    });
    _analyze();
  }

  void _applyFraction() {
    final n = _numController.text.trim();
    final d = _denController.text.trim();
    if (n.isEmpty || d.isEmpty) return;
    _funcController.text = '($n)/($d)';
  }

  Future<void> _analyze() async {
    if (_fractionMode) _applyFraction();
    setState(() {
      _loading = true;
      _error = '';
    });
    await Future.delayed(const Duration(milliseconds: 60));
    final expr = _funcController.text.trim();
    if (expr.isEmpty) {
      setState(() {
        _error = 'Entre une fonction (ex: (2x+1)/ln(x-e))';
        _loading = false;
      });
      return;
    }
    try {
      if (_autoDomain) {
        final suggested = _engine.suggestDomain(expr);
        _xMin = suggested.xMin;
        _xMax = suggested.xMax;
      }
      final segments =
          _graphService.evaluateSegments(expr, _xMin, _xMax, 800);
      // Y auto pour repere orthonorme raisonnable
      var ymin = double.infinity;
      var ymax = -double.infinity;
      for (final seg in segments) {
        for (final p in seg) {
          if (p.value < ymin) ymin = p.value;
          if (p.value > ymax) ymax = p.value;
        }
      }
      if (!ymin.isFinite || !ymax.isFinite) {
        ymin = -5;
        ymax = 5;
      }
      // Marge + ecretage extremes asymptotes
      if (ymax - ymin < 1e-6) {
        ymin -= 1;
        ymax += 1;
      }
      final yPad = (ymax - ymin) * 0.15;
      ymin -= yPad;
      ymax += yPad;
      // Limiter l'echelle Y si asymptote verticale
      if (ymax - ymin > 40) {
        final mid = (ymin + ymax) / 2;
        ymin = mid - 20;
        ymax = mid + 20;
      }
      // Orthonorme : meme amplitude en X et Y (centimetres / unites)
      final xSpan = _xMax - _xMin;
      final ySpan = ymax - ymin;
      final span = math.max(xSpan, ySpan);
      final xMid = (_xMin + _xMax) / 2;
      final yMid = (ymin + ymax) / 2;
      // On garde le domaine X calcule, on etend Y pour orthonorme visuel
      // si possible — sinon on force span commun autour du centre
      if (span > 0) {
        _yMin = yMid - span / 2;
        _yMax = yMid + span / 2;
        // Si domaine X est le vrai domaine, on n'elargit pas X force
      } else {
        _yMin = ymin;
        _yMax = ymax;
      }

      final study = _analysisService.analyze(expr, xMin: _xMin, xMax: _xMax);
      setState(() {
        _segments = segments;
        _study = study;
        _loading = false;
        if (_segments.isEmpty) {
          _error =
              'Aucun point calculable. Verifie l expression et le domaine.';
        }
      });
    } catch (_) {
      setState(() {
        _error = 'Expression invalide';
        _loading = false;
        _segments = [];
        _study = null;
      });
    }
  }

  Future<void> _exportLatex() async {
    if (_study == null) return;
    final latex = StringBuffer()
      ..writeln(r'\documentclass{article}')
      ..writeln(r'\usepackage{amsmath}')
      ..writeln(r'\begin{document}')
      ..writeln(r'\section*{Etude de fonction}')
      ..writeln(r'\[ f(x) = ' + _study!.expression + r' \]')
      ..writeln(r'\subsection*{Domaine}')
      ..writeln(_study!.domain)
      ..writeln(r'\end{document}');
    await Share.share(latex.toString(), subject: 'etude_fonction.tex');
  }

  Future<void> _exportPng() async {
    final renderObject = _chartKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return;
    final image = await renderObject.toImage(pixelRatio: 3.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) return;
    await Share.shareXFiles([
      XFile.fromData(bytes.buffer.asUint8List(),
          mimeType: 'image/png', name: 'courbe.png'),
    ]);
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
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Exporter LaTeX'),
              onTap: () {
                Navigator.pop(ctx);
                _exportLatex();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Etude de fonction'),
        actions: [
          TextButton(onPressed: _loadExample, child: const Text('Exemple')),
          if (_study != null)
            IconButton(
              icon: const Icon(Icons.ios_share),
              onPressed: _showExportMenu,
            ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Fraction'),
                  selected: _fractionMode,
                  avatar: const Icon(Icons.horizontal_rule, size: 18),
                  onSelected: (v) => setState(() {
                    _fractionMode = v;
                    if (v && _numController.text.isEmpty) {
                      _numController.text = '2x+1';
                      _denController.text = 'ln(x-e)';
                      _applyFraction();
                    }
                  }),
                ),
                const SizedBox(width: 8),
                Text(
                  _fractionMode ? 'Numerateur / Denominateur' : 'Expression',
                  style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          if (_fractionMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
              child: Column(
                children: [
                  // Fraction style : num
                  //                 ———
                  //                 den
                  TextField(
                    controller: _numController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      hintText: 'numerateur',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (_) => _applyFraction(),
                    onSubmitted: (_) => _analyze(),
                  ),
                  Container(
                    height: 2.5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: primary,
                  ),
                  TextField(
                    controller: _denController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      hintText: 'denominateur',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (_) => _applyFraction(),
                    onSubmitted: (_) => _analyze(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'f(x) = ${_funcController.text}',
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _funcController,
                      decoration: InputDecoration(
                        labelText: 'f(x) =',
                        hintText: 'ex: (2x+1)/ln(x-e)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                      ),
                      onSubmitted: (_) => _analyze(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _loading ? null : _analyze,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.play_arrow_rounded),
                  ),
                ],
              ),
            ),
          if (_fractionMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton(
                onPressed: _loading ? null : _analyze,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Analyser'),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _zoomBtn('-', () {
                  setState(() {
                    _autoDomain = false;
                    _xMin -= 3;
                    _xMax += 3;
                  });
                  _analyze();
                }),
                const SizedBox(width: 8),
                _zoomBtn('Reset', () {
                  setState(() {
                    _autoDomain = true;
                    _xMin = -10;
                    _xMax = 10;
                  });
                  _analyze();
                }),
                const SizedBox(width: 8),
                _zoomBtn('+', () {
                  setState(() {
                    _autoDomain = false;
                    final mid = (_xMin + _xMax) / 2;
                    final half = (_xMax - _xMin) / 4;
                    _xMin = mid - half;
                    _xMax = mid + half;
                  });
                  _analyze();
                }),
              ],
            ),
          ),
          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChart(primary),
                _buildStudy(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoomBtn(String label, VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildChart(Color primary) {
    if (_segments.isEmpty) {
      return const Center(child: Text('Aucune courbe'));
    }
    return RepaintBoundary(
      key: _chartKey,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: CustomPaint(
          painter: _OrthonormalPainter(
            segments: _segments,
            xMin: _xMin,
            xMax: _xMax,
            yMin: _yMin,
            yMax: _yMax,
            curveColor: primary,
          ),
          child: const SizedBox.expand(),
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
          label: const Text('Exporter (PDF / PNG / LaTeX)'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
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
}

/// Repere orthonorme : grillage type papier millimetre (1 u = 1 cm),
/// axes gradues, courbe en segments (pas de liaison aux asymptotes).
class _OrthonormalPainter extends CustomPainter {
  final List<List<MapEntry<double, double>>> segments;
  final double xMin, xMax, yMin, yMax;
  final Color curveColor;

  _OrthonormalPainter({
    required this.segments,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
    required this.curveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final padL = 36.0, padR = 12.0, padT = 12.0, padB = 28.0;
    final w = size.width - padL - padR;
    final h = size.height - padT - padB;
    if (w <= 0 || h <= 0) return;

    // Echelle orthonorme : meme pixels par unite en X et Y
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

    // Fond
    final bg = Paint()..color = const Color(0xFF0E1520);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(12)),
      bg,
    );

    // Grille fine (0.2) + grosse (1) style cm
    final gridFine = Paint()
      ..color = const Color(0xFF1A2740)
      ..strokeWidth = 0.5;
    final gridMajor = Paint()
      ..color = const Color(0xFF2A3A55)
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = const Color(0xFF8FA3BF)
      ..strokeWidth = 1.5;

    final stepMajor = _niceStep(math.min(xSpan, ySpan) / 8);
    final stepFine = stepMajor / 5;

    // Verticales
    for (var x = _floorTo(xMin, stepFine); x <= xMax + 1e-9; x += stepFine) {
      final px = toPx(x);
      if (px < ox - 1 || px > ox + usedW + 1) continue;
      final major = _isMultiple(x, stepMajor);
      canvas.drawLine(
          Offset(px, oy), Offset(px, oy + usedH), major ? gridMajor : gridFine);
    }
    // Horizontales
    for (var y = _floorTo(yMin, stepFine); y <= yMax + 1e-9; y += stepFine) {
      final py = toPy(y);
      if (py < oy - 1 || py > oy + usedH + 1) continue;
      final major = _isMultiple(y, stepMajor);
      canvas.drawLine(
          Offset(ox, py), Offset(ox + usedW, py), major ? gridMajor : gridFine);
    }

    // Axes
    if (xMin <= 0 && xMax >= 0) {
      final px = toPx(0);
      canvas.drawLine(Offset(px, oy), Offset(px, oy + usedH), axisPaint);
    }
    if (yMin <= 0 && yMax >= 0) {
      final py = toPy(0);
      canvas.drawLine(Offset(ox, py), Offset(ox + usedW, py), axisPaint);
    }

    // Graduations + labels
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (var x = _floorTo(xMin, stepMajor); x <= xMax + 1e-9; x += stepMajor) {
      if (x.abs() < stepMajor * 0.01) continue;
      final px = toPx(x);
      tp.text = TextSpan(
        text: _fmt(x),
        style: const TextStyle(color: Color(0xFF9BB0C9), fontSize: 10),
      );
      tp.layout();
      tp.paint(canvas, Offset(px - tp.width / 2, oy + usedH + 4));
    }
    for (var y = _floorTo(yMin, stepMajor); y <= yMax + 1e-9; y += stepMajor) {
      if (y.abs() < stepMajor * 0.01) continue;
      final py = toPy(y);
      tp.text = TextSpan(
        text: _fmt(y),
        style: const TextStyle(color: Color(0xFF9BB0C9), fontSize: 10),
      );
      tp.layout();
      tp.paint(canvas, Offset(ox - tp.width - 6, py - tp.height / 2));
    }

    // Courbe par segments
    final curve = Paint()
      ..color = curveColor
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    for (final seg in segments) {
      if (seg.length < 2) continue;
      final path = Path();
      path.moveTo(toPx(seg.first.key), toPy(seg.first.value));
      for (var i = 1; i < seg.length; i++) {
        path.lineTo(toPx(seg[i].key), toPy(seg[i].value));
      }
      canvas.drawPath(path, curve);
    }

    // Cadre
    final border = Paint()
      ..color = const Color(0xFF3A4A66)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(Rect.fromLTWH(ox, oy, usedW, usedH), border);
  }

  double _niceStep(double rough) {
    if (rough <= 0) return 1;
    final exp = (math.log(rough) / math.ln10).floor();
    final f = rough / math.pow(10.0, exp);
    double nf;
    if (f < 1.5) {
      nf = 1;
    } else if (f < 3) {
      nf = 2;
    } else if (f < 7) {
      nf = 5;
    } else {
      nf = 10;
    }
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
  bool shouldRepaint(covariant _OrthonormalPainter old) =>
      old.segments != segments ||
      old.xMin != xMin ||
      old.xMax != xMax ||
      old.yMin != yMin ||
      old.yMax != yMax;
}
