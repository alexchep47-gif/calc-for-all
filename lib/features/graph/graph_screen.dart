import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/services/graph_service.dart';
import '../../data/services/function_analysis_service.dart';

/// Écran de tracé + étude de fonction complète
class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> with SingleTickerProviderStateMixin {
  final GraphService _graphService = GraphService();
  final FunctionAnalysisService _analysisService = FunctionAnalysisService();
  final TextEditingController _funcController = TextEditingController(text: 'sin(x)');

  List<FlSpot> _spots = [];
  FunctionStudyResult? _study;
  double _xMin = -10;
  double _xMax = 10;
  String _error = '';
  bool _loading = false;
  late TabController _tabController;

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

    await Future.delayed(const Duration(milliseconds: 150)); // petit feedback

    final expr = _funcController.text.trim();
    if (expr.isEmpty) {
      setState(() {
        _error = 'Entre une fonction';
        _loading = false;
      });
      return;
    }

    try {
      final points = _graphService.evaluateFunction(expr, _xMin, _xMax, 250);
      final study = _analysisService.analyze(expr, xMin: _xMin, xMax: _xMax);

      setState(() {
        _spots = points.map((e) => FlSpot(e.key, e.value)).toList();
        _study = study;
        _loading = false;
        if (_spots.isEmpty) _error = 'Aucun point calculable';
      });
    } catch (e) {
      setState(() {
        _error = 'Expression invalide';
        _loading = false;
        _spots = [];
        _study = null;
      });
    }
  }

  Future<void> _exportPdf() async {
    if (_study == null) return;

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Étude de fonction – Calc For All')),
          pw.SizedBox(height: 12),
          pw.Text('Fonction : f(x) = ${_study!.expression}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          pw.Text('1. Domaine de définition', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(_study!.domain),
          pw.SizedBox(height: 10),
          pw.Text('2. Périodicité', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(_study!.period),
          pw.SizedBox(height: 10),
          pw.Text('3. Extremums', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ..._study!.extrema.map((e) => pw.Text('• $e')),
          pw.SizedBox(height: 10),
          pw.Text('4. Asymptotes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ..._study!.asymptotes.map((e) => pw.Text('• $e')),
          pw.SizedBox(height: 10),
          pw.Text('5. Symétrie', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(_study!.symmetry),
          pw.SizedBox(height: 16),
          pw.Text('Tableau de variation (extrait)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(_study!.variationTable, style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 16),
          pw.Text('Explications', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(_study!.explanations, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 20),
          pw.Text('Généré par Calc For All', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'etude_fonction.pdf');
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
          // Saisie
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _funcController,
                    decoration: InputDecoration(
                      labelText: 'f(x) =',
                      hintText: 'ex: sin(x), x^2, 1/x, cos(x)+x',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.play_arrow_rounded),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1),

          // Zoom
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _zoomBtn('−', () {
                  setState(() {
                    _xMin -= 3;
                    _xMax += 3;
                  });
                  _analyze();
                }),
                const SizedBox(width: 8),
                _zoomBtn('Reset', () {
                  setState(() {
                    _xMin = -10;
                    _xMax = 10;
                  });
                  _analyze();
                }),
                const SizedBox(width: 8),
                _zoomBtn('+', () {
                  setState(() {
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
              child: Text(_error, style: const TextStyle(color: Colors.red)),
            ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // --- Graphique ---
                _buildChart(primary),
                // --- Étude ---
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildChart(Color primary) {
    if (_spots.isEmpty) {
      return const Center(child: Text('Aucune courbe'));
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
    );
  }

  Widget _buildStudy() {
    if (_study == null) {
      return const Center(child: Text('Analyse une fonction pour voir l’étude'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section('Fonction', 'f(x) = ${_study!.expression}', Icons.functions),
        _section('Domaine de définition', _study!.domain, Icons.domain),
        _section('Périodicité', _study!.period, Icons.loop),
        _sectionList('Extremums', _study!.extrema, Icons.trending_up),
        _sectionList('Asymptotes', _study!.asymptotes, Icons.vertical_align_center),
        _section('Symétrie', _study!.symmetry, Icons.swap_horiz),
        _section('Tableau de variation (extrait)', _study!.variationTable, Icons.table_chart),
        _section('Explications détaillées', _study!.explanations, Icons.menu_book),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _exportPdf,
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Exporter le plan d’étude en PDF'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $e'),
                )),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05);
  }
}
