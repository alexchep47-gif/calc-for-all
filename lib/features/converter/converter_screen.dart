import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/services/math_library.dart';

/// Convertisseur d'unités — grandeurs scientifiques + quantités du quotidien
class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  String _category = 'Longueur';
  String _from = 'm';
  String _to = 'km';
  final TextEditingController _valueController =
      TextEditingController(text: '1');
  String _result = '';
  String _steps = '';

  /// Facteurs vers une unité de base par catégorie
  final Map<String, Map<String, double>> _units = {
    'Longueur': {
      'mm': 0.001,
      'cm': 0.01,
      'dm': 0.1,
      'm': 1.0,
      'dam': 10.0,
      'hm': 100.0,
      'km': 1000.0,
      'inch': 0.0254,
      'ft': 0.3048,
      'yd': 0.9144,
      'mile': 1609.344,
      'mille nautique': 1852.0,
    },
    'Masse': {
      'mg': 1e-6,
      'g': 0.001,
      'kg': 1.0,
      't': 1000.0,
      'lb': 0.453592,
      'oz': 0.0283495,
      'quintal': 100.0,
    },
    'Volume': {
      'mL': 0.001,
      'cL': 0.01,
      'dL': 0.1,
      'L': 1.0,
      'm³': 1000.0,
      'gallon US': 3.78541,
      'pint': 0.473176,
      'cuillère à café': 0.005,
      'cuillère à soupe': 0.015,
      'tasse': 0.25,
    },
    'Surface': {
      'mm²': 1e-6,
      'cm²': 1e-4,
      'm²': 1.0,
      'are': 100.0,
      'hectare': 10000.0,
      'km²': 1e6,
      'acre': 4046.86,
    },
    'Temps': {
      'ms': 0.001,
      's': 1.0,
      'min': 60.0,
      'h': 3600.0,
      'jour': 86400.0,
      'semaine': 604800.0,
      'mois (30j)': 2592000.0,
      'année': 31536000.0,
    },
    'Vitesse': {
      'm/s': 1.0,
      'km/h': 1 / 3.6,
      'mph': 0.44704,
      'nœud': 0.514444,
    },
    'Énergie': {
      'J': 1.0,
      'kJ': 1000.0,
      'cal': 4.184,
      'kcal': 4184.0,
      'Wh': 3600.0,
      'kWh': 3.6e6,
    },
    'Puissance': {
      'W': 1.0,
      'kW': 1000.0,
      'MW': 1e6,
      'ch': 735.5,
      'hp': 745.7,
    },
    'Pression': {
      'Pa': 1.0,
      'hPa': 100.0,
      'bar': 1e5,
      'atm': 101325.0,
      'mmHg': 133.322,
      'psi': 6894.76,
    },
    'Données numériques': {
      'octet': 1.0,
      'Ko': 1024.0,
      'Mo': 1048576.0,
      'Go': 1073741824.0,
      'To': 1099511627776.0,
      'bit': 0.125,
    },
    'Cuisine': {
      'g (farine)': 1.0,
      'c.à.s farine': 8.0,
      'c.à.c sucre': 4.0,
      'c.à.s sucre': 12.0,
      'tasse farine': 120.0,
      'tasse sucre': 200.0,
      'tasse lait (mL)': 250.0,
    },
    'Température': {
      '°C': 0,
      '°F': 0,
      'K': 0,
    },
    'Devise (approx)': {
      'XAF': 1.0,
      'EUR': 655.957,
      'USD': 600.0,
      'GBP': 760.0,
      'NGN': 0.38,
      'CNY': 82.0,
      'JPY': 4.0,
      'CAD': 440.0,
    },
    'Angle': {
      'rad': 1.0,
      '°': mathPi / 180,
      'grade': mathPi / 200,
      'tour': 2 * mathPi,
    },
  };

  static const mathPi = 3.141592653589793;

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
      double celsius;
      if (_from == '°C') {
        celsius = raw;
        buffer.writeln('Valeur déjà en °C : ${MathLibrary.format(raw)}');
      } else if (_from == '°F') {
        celsius = (raw - 32) * 5 / 9;
        buffer.writeln('Formule °F → °C : (°F − 32) × 5/9');
        buffer.writeln(
            '(${MathLibrary.format(raw)} − 32) × 5/9 = ${MathLibrary.format(celsius)}');
      } else {
        celsius = raw - 273.15;
        buffer.writeln('Formule K → °C : K − 273.15');
        buffer.writeln(
            '${MathLibrary.format(raw)} − 273.15 = ${MathLibrary.format(celsius)}');
      }
      if (_to == '°C') {
        result = celsius;
      } else if (_to == '°F') {
        result = celsius * 9 / 5 + 32;
        buffer.writeln('°C → °F : °C × 9/5 + 32');
      } else {
        result = celsius + 273.15;
        buffer.writeln('°C → K : °C + 273.15');
      }
    } else {
      final fromFactor = _units[_category]![_from]!;
      final toFactor = _units[_category]![_to]!;
      final base = raw * fromFactor;
      result = base / toFactor;
      buffer.writeln(
          '1 $_from = ${MathLibrary.format(fromFactor)} (unité de base)');
      buffer.writeln(
          '${MathLibrary.format(raw)} $_from = ${MathLibrary.format(base)} (base)');
      buffer.writeln(
          '1 $_to = ${MathLibrary.format(toFactor)} (base) → résultat = base / facteur');
    }

    setState(() {
      _result = '${MathLibrary.format(result)} $_to';
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
            decoration: const InputDecoration(
              labelText: 'Catégorie',
              border: OutlineInputBorder(),
            ),
            items: _units.keys
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) {
              setState(() {
                _category = v!;
                final u = _currentUnits;
                _from = u.first;
                _to = u.length > 1 ? u[1] : u.first;
                _result = '';
                _steps = '';
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Valeur',
              border: OutlineInputBorder(),
              hintText: '1 ou 3/4',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _from,
                  decoration: const InputDecoration(
                    labelText: 'De',
                    border: OutlineInputBorder(),
                  ),
                  items: _currentUnits
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
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
                  decoration: const InputDecoration(
                    labelText: 'Vers',
                    border: OutlineInputBorder(),
                  ),
                  items: _currentUnits
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => setState(() => _to = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _convert,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Convertir'),
          ),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _result,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 8),
            Text(_steps, style: const TextStyle(height: 1.4)),
          ],
        ],
      ),
    );
  }
}
