import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Module Convertisseur (longueurs, masses, températures, devises approximatives)
class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  String _category = 'Longueur';
  String _from = 'm';
  String _to = 'km';
  final TextEditingController _valueController = TextEditingController(text: '1');
  String _result = '';
  String _steps = '';

  final Map<String, Map<String, double>> _units = {
    'Longueur': {
      'mm': 0.001,
      'cm': 0.01,
      'm': 1.0,
      'km': 1000.0,
      'inch': 0.0254,
      'ft': 0.3048,
      'mile': 1609.344,
    },
    'Masse': {
      'mg': 0.000001,
      'g': 0.001,
      'kg': 1.0,
      't': 1000.0,
      'lb': 0.453592,
      'oz': 0.0283495,
    },
    'Température': {
      '°C': 0,
      '°F': 0,
      'K': 0,
    },
    'Devise (approx)': {
      'XAF': 1.0,        // Franc CFA (référence locale)
      'EUR': 655.957,
      'USD': 600.0,      // approximatif
      'GBP': 760.0,
      'NGN': 0.38,
    },
  };

  List<String> get _currentUnits => _units[_category]!.keys.toList();

  void _convert() {
    final raw = double.tryParse(_valueController.text.replaceAll(',', '.'));
    if (raw == null) {
      setState(() {
        _result = 'Valeur invalide';
        _steps = '';
      });
      return;
    }

    final buffer = StringBuffer();
    double result;

    if (_category == 'Température') {
      // Conversion température spéciale
      double celsius;
      if (_from == '°C') {
        celsius = raw;
        buffer.writeln('Valeur déjà en °C : $raw');
      } else if (_from == '°F') {
        celsius = (raw - 32) * 5 / 9;
        buffer.writeln('Formule °F → °C : (°F − 32) × 5/9');
        buffer.writeln('($raw − 32) × 5/9 = $celsius');
      } else {
        celsius = raw - 273.15;
        buffer.writeln('Formule K → °C : K − 273.15');
        buffer.writeln('$raw − 273.15 = $celsius');
      }

      if (_to == '°C') {
        result = celsius;
      } else if (_to == '°F') {
        result = celsius * 9 / 5 + 32;
        buffer.writeln('Formule °C → °F : °C × 9/5 + 32');
        buffer.writeln('$celsius × 9/5 + 32 = $result');
      } else {
        result = celsius + 273.15;
        buffer.writeln('Formule °C → K : °C + 273.15');
        buffer.writeln('$celsius + 273.15 = $result');
      }
    } else {
      // Conversion par facteur vers l’unité de base
      final fromFactor = _units[_category]![_from]!;
      final toFactor = _units[_category]![_to]!;

      final base = raw * fromFactor;
      result = base / toFactor;

      buffer.writeln('1. Convertir $_from vers l’unité de base');
      buffer.writeln('   $raw × $fromFactor = $base');
      buffer.writeln('2. Convertir la base vers $_to');
      buffer.writeln('   $base ÷ $toFactor = $result');
    }

    setState(() {
      _result = result.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      _steps = buffer.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Convertisseur')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            value: _category,
            decoration: InputDecoration(
              labelText: 'Catégorie',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            items: _units.keys.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) {
              setState(() {
                _category = v!;
                _from = _currentUnits.first;
                _to = _currentUnits.length > 1 ? _currentUnits[1] : _currentUnits.first;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Valeur',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _from,
                  decoration: InputDecoration(
                    labelText: 'De',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  items: _currentUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) => setState(() => _from = v!),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward),
              ),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _to,
                  decoration: InputDecoration(
                    labelText: 'Vers',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  items: _currentUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) => setState(() => _to = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _convert,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Convertir', style: TextStyle(fontSize: 17)),
          ),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Text('$_result $_to', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ).animate().fadeIn().scale(),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Étapes', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_steps, style: const TextStyle(height: 1.4)),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 100.ms),
          ],
          const SizedBox(height: 20),
          const Text(
            'Note : les taux de change sont approximatifs et à titre éducatif uniquement.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
