import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/services/graph_service.dart';
import '../../data/services/function_analysis_service.dart';
import '../../data/services/math_expression_engine.dart';

/// Écran de tracé + étude de fonction complète
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
  final TextEditingController _funcController = TextEditingController(
    text: 'sin(x)',
  );

  List<FlSpot> _spots = [];
  FunctionStudyResult? _study;
  double _xMin = -10;
  double _xMax = 10;
  String _error = '';
  bool _loading = false;
  bool _autoDomain = true; // ajuste la fenêtre pour ln / sqrt
  late TabController _tabController;
  final GlobalKey _chartKey = GlobalKey();

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
    super.dispose();
  }

  Future<void> _analyze() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    await Future.delayed(const Duration(milliseconds: 80));

    final expr = _funcController.text.trim();
    if (expr.isEmpty) {
      setState(() {
        _error = 'Entre une fonction (ex: ln(2x+1), sin(x), x^2)';
        _loading = false;
      });
      return;
    }

    try {
      // Domaine automatique pour log / sqrt
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
          _error =
              'Aucun point calculable sur [${_xMin.toStringAsFixed(2)} ; ${_xMax.toStringAsFixed(2)}].\n'
              'Vérifie l\'écriture (ex: ln(2x+1) ou log(2*x+1)) et le domaine.';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Expression invalide. Essaie : ln(2x+1), sin(x), 1/x, x^2';
        _loading = false;
        _spots = [];
        _study = null;
      });
    }
  }

  Future<void> _exportPdf() async {
    if (_study == null) return;

    try {
      final regular = pw.Font.ttf(
        await rootBundle.load('assets/DejaVuSans.ttf'),
      );
      final bold = pw.Font.ttf(
        await rootBundle.load('assets/DejaVuSans-Bold.ttf'),
      );

      pw.MemoryImage? chartImage;
      final renderObject = _chartKey.currentContext?.findRenderObject();
      if (renderObject is RenderRepaintBoundary) {
        final image = await renderObject.toImage(pixelRatio: 2.0);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes != null) {
          chartImage = pw.MemoryImage(bytes.buffer.asUint8List());
        }
        image.dispose();
      }

      final pdf = pw.Document();
      final base = pw.TextStyle(font: regular, fontSize: 10);
      final heading = pw.TextStyle(font: bold, fontSize: 13);

      // Texte ASCII-safe pour éviter tout bug d'encodage restant
      String safe(String s) => s
          .replaceAll('′', "'")
          .replaceAll('−', '-')
          .replaceAll('∞', 'inf')
          .replaceAll('π', 'pi')
          .replaceAll('·', '.')
          .replaceAll('≥', '>=')
          .replaceAll('≤', '<=');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: regular, bold: bold),
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Etude de fonction - Calc For All',
                style: pw.TextStyle(font: bold, fontSize: 18),
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Fonction : f(x) = ${safe(_study!.expression)}',
              style: pw.TextStyle(font: bold, fontSize: 14),
            ),
            pw.SizedBox(height: 14),
            pw.Text('1. Domaine de definition', style: heading),
            pw.Text(safe(_study!.domain), style: base),
            pw.SizedBox(height: 10),
            pw.Text('2. Derivee symbolique', style: heading),
            pw.Text("f'(x) = ${safe(_study!.derivative)}", style: base),
            pw.SizedBox(height: 10),
            pw.Text('3. Limites', style: heading),
            pw.Text(safe(_study!.limits), style: base),
            pw.SizedBox(height: 10),
            pw.Text('4. Extremums', style: heading),
            ..._study!.extrema.map((e) => pw.Text('- ${safe(e)}', style: base)),
            pw.SizedBox(height: 10),
            pw.Text('5. Asymptotes', style: heading),
            ..._study!.asymptotes
                .map((e) => pw.Text('- ${safe(e)}', style: base)),
            pw.SizedBox(height: 10),
            pw.Text('6. Periodicite et parite', style: heading),
            pw.Text(
              '${safe(_study!.period)} ${safe(_study!.symmetry)}',
              style: base,
            ),
            pw.SizedBox(height: 14),
            pw.Text('7. Tableau de variation', style: heading),
            pw.Text(
              safe(_study!.variationTable),
              style: pw.TextStyle(font: regular, fontSize: 8),
            ),
            pw.SizedBox(height: 14),
            pw.Text('8. Courbe', style: heading),
            if (chartImage != null)
              pw.Container(
                height: 230,
                child: pw.Image(chartImage, fit: pw.BoxFit.contain),
              )
            else
              pw.Text(
                '(Courbe non disponible - ouvre l\'onglet Graphique puis reexporte)',
                style: base,
              ),
            pw.SizedBox(height: 12),
            pw.Text('Explications', style: heading),
            pw.Text(safe(_study!.explanations), style: base),
            pw.SizedBox(height: 16),
            pw.Text(
              'Genere par Calc For All',
              style: pw.TextStyle(
                font: regular,
                fontSize: 9,
                color: PdfColors.grey,
              ),
            ),
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'etude_fonction.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur export PDF : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Étude de fonction'),
        actions: [
          if (_study != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Exporter PDF',
              onPressed: _exportPdf,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Graphique'),
            Tab(text: 'Étude complète'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _funcController,
                    decoration: InputDecoration(
                      labelText: 'f(x) =',
                      hintText: 'ex: ln(2x+1), sin(x), x^2',
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
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _zoomBtn('−', () {
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
              child: Text(
                _error,
                style: const TextStyle(color: Colors.red, height: 1.3),
                textAlign: TextAlign.center,
              ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
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
                  show: true,
                  color: primary.withOpacity(0.08),
                ),
              ),
            ],
            minX: _xMin,
            maxX: _xMax,
          ),
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }

  Widget _buildStudy() {
    if (_study == null) {
      return const Center(
        child: Text('Analyse une fonction pour voir l’étude'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section('Fonction', 'f(x) = ${_study!.expression}', Icons.functions),
        _section('Domaine de définition', _study!.domain, Icons.domain),
        _section(
          'Dérivée symbolique',
          "f'(x) = ${_study!.derivative}",
          Icons.functions,
        ),
        _section('Limites', _study!.limits, Icons.compare_arrows),
        _section('Périodicité', _study!.period, Icons.loop),
        _sectionList('Extremums', _study!.extrema, Icons.trending_up),
        _sectionList(
          'Asymptotes',
          _study!.asymptotes,
          Icons.vertical_align_center,
        ),
        _section('Symétrie', _study!.symmetry, Icons.swap_horiz),
        _section(
          'Tableau de variation (extrait)',
          _study!.variationTable,
          Icons.table_chart,
        ),
        _section(
          'Explications détaillées',
          _study!.explanations,
          Icons.menu_book,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _exportPdf,
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Exporter le plan d’étude en PDF'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 30),
      ],
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _section(String title, String content, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(height: 1.4)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05);
  }

  Widget _sectionList(String title, List<String> items, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $e'),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05);
  }
}
