import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
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

  List<FlSpot> _spots = [];
  FunctionStudyResult? _study;
  double _xMin = -10;
  double _xMax = 10;
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
      if (ex.contains('/') && !ex.startsWith('ln') && !ex.startsWith('sin')) {
        // Parse simple quotient a/b
        final parts = ex.split('/');
        if (parts.length == 2) {
          _fractionMode = true;
          _numController.text = parts[0].replaceAll('(', '').replaceAll(')', '');
          _denController.text = parts[1].replaceAll('(', '').replaceAll(')', '');
          _funcController.text = '(${_numController.text})/(${_denController.text})';
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
    await Future.delayed(const Duration(milliseconds: 80));
    final expr = _funcController.text.trim();
    if (expr.isEmpty) {
      setState(() {
        _error = 'Entre une fonction (ex: (2x+1)/(x-3))';
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
      final points = _graphService.evaluateFunction(expr, _xMin, _xMax, 400);
      final study = _analysisService.analyze(expr, xMin: _xMin, xMax: _xMax);
      setState(() {
        _spots = points.map((e) => FlSpot(e.key, e.value)).toList();
        _study = study;
        _loading = false;
        if (_spots.isEmpty) {
          _error = 'Aucun point calculable. Verifie l expression et le domaine.';
        }
      });
    } catch (_) {
      setState(() {
        _error = 'Expression invalide';
        _loading = false;
        _spots = [];
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
          // Toggle mode fraction
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Barre de fraction'),
                  selected: _fractionMode,
                  avatar: const Icon(Icons.horizontal_rule, size: 18),
                  onSelected: (v) => setState(() {
                    _fractionMode = v;
                    if (v && _numController.text.isEmpty) {
                      _numController.text = '2x+1';
                      _denController.text = 'x-3';
                      _applyFraction();
                    }
                  }),
                ),
                const SizedBox(width: 8),
                if (_fractionMode)
                  Text('f(x) = num / den',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          if (_fractionMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Column(
                children: [
                  TextField(
                    controller: _numController,
                    decoration: InputDecoration(
                      labelText: 'Numerateur',
                      hintText: 'ex: 2x+1',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                    onChanged: (_) => _applyFraction(),
                    onSubmitted: (_) => _analyze(),
                  ),
                  // Barre de fraction visuelle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    height: 3,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  TextField(
                    controller: _denController,
                    decoration: InputDecoration(
                      labelText: 'Denominateur',
                      hintText: 'ex: x-3',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                    onChanged: (_) => _applyFraction(),
                    onSubmitted: (_) => _analyze(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'f(x) = ${_funcController.text}',
                    style: TextStyle(
                        color: Colors.grey.shade700,
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
                        hintText: 'ex: (2x+1)/(x-3)  ou  ln(2x+1)',
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
                child: const Text('Analyser le quotient'),
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
    if (_spots.isEmpty) {
      return const Center(child: Text('Aucune courbe'));
    }
    return RepaintBoundary(
      key: _chartKey,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 36),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 28),
              ),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                spots: _spots,
                isCurved: true,
                color: primary,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                    show: true, color: primary.withOpacity(0.08)),
              ),
            ],
            minX: _xMin,
            maxX: _xMax,
          ),
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
            ...items.map((e) => Text('• $e')),
          ],
        ),
      ),
    );
  }
}
