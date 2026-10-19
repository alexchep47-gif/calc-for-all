import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/services/graph_service.dart';

/// Écran de tracé de courbes
class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  final GraphService _service = GraphService();
  final TextEditingController _funcController = TextEditingController(text: 'sin(x)');
  List<FlSpot> _spots = [];
  double _xMin = -10;
  double _xMax = 10;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _plot();
  }

  void _plot() {
    setState(() {
      _error = '';
      final points = _service.evaluateFunction(
        _funcController.text,
        _xMin,
        _xMax,
        200,
      );
      if (points.isEmpty) {
        _error = 'Expression invalide ou aucun point défini';
        _spots = [];
      } else {
        _spots = points.map((e) => FlSpot(e.key, e.value)).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracé de courbes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Saisie de la fonction
            TextField(
              controller: _funcController,
              decoration: InputDecoration(
                labelText: 'f(x) =',
                hintText: 'ex: sin(x), x^2, cos(x)+x',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: _plot,
                ),
              ),
              onSubmitted: (_) => _plot(),
            ),
            const SizedBox(height: 12),
            // Contrôles de zoom
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _xMin -= 5;
                        _xMax += 5;
                      });
                      _plot();
                    },
                    child: const Text('Zoom −'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _xMin = -10;
                        _xMax = 10;
                      });
                      _plot();
                    },
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        final mid = (_xMin + _xMax) / 2;
                        final half = (_xMax - _xMin) / 4;
                        _xMin = mid - half;
                        _xMax = mid + half;
                      });
                      _plot();
                    },
                    child: const Text('Zoom +'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_error.isNotEmpty)
              Text(_error, style: const TextStyle(color: Colors.red))
            else
              Expanded(
                child: _spots.isEmpty
                    ? const Center(child: Text('Aucune courbe à afficher'))
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _spots,
                              isCurved: true,
                              color: Theme.of(context).primaryColor,
                              barWidth: 2.5,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(show: false),
                            ),
                          ],
                          minX: _xMin,
                          maxX: _xMax,
                        ),
                      ),
              ),
            const SizedBox(height: 8),
            Text(
              'Exemples : sin(x)  •  x^2  •  cos(x)+x  •  1/x',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
