import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/locale_provider.dart';
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

  String _text(String fr, String en) =>
      context.read<LocaleProvider>().isFrench ? fr : en;

  /// Facteurs vers une unité de base par catégorie
  final Map<String, Map<String, num>> _units = {
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
      '°': math.pi / 180,
      'grade': math.pi / 200,
      'tour': 2 * math.pi,
    },
    'Numération': {
      'binaire': 2,
      'octal': 8,
      'décimal': 10,
      'hexadécimal': 16,
    },
  };

  static const double mathPi = 3.141592653589793;

  List<String> get _currentUnits => _units[_category]!.keys.toList();

  int _digitValue(String ch) {
    final value = ch.toUpperCase();
    if (value == 'A') return 10;
    if (value == 'B') return 11;
    if (value == 'C') return 12;
    if (value == 'D') return 13;
    if (value == 'E') return 14;
    if (value == 'F') return 15;
    return int.parse(value);
  }

  String _digitChar(int digit) {
    if (digit < 10) return digit.toString();
    switch (digit) {
      case 10:
        return 'A';
      case 11:
        return 'B';
      case 12:
        return 'C';
      case 13:
        return 'D';
      case 14:
        return 'E';
      case 15:
        return 'F';
      default:
        return digit.toString();
    }
  }

  double _baseStringToDecimal(String rawValue, int base) {
    final value = rawValue.trim();
    if (value.isEmpty) return 0;

    final sign = value.startsWith('-') ? -1.0 : 1.0;
    final normalized = value.replaceFirst('-', '');
    final parts = normalized.split('.');
    final integerPart = parts.first;
    final fractionalPart = parts.length > 1 ? parts[1] : '';

    double result = 0;
    for (int i = 0; i < integerPart.length; i++) {
      final digit = _digitValue(integerPart[i]);
      result = result * base + digit;
    }

    for (int i = 0; i < fractionalPart.length; i++) {
      final digit = _digitValue(fractionalPart[i]);
      result += digit / math.pow(base, i + 1);
    }

    return result * sign;
  }

  String _decimalToBase(double value, int base, {int maxFractionDigits = 12}) {
    final sign = value < 0 ? '-' : '';
    final absValue = value.abs();
    final integerPart = absValue.floor();
    final fractionPart = absValue - integerPart;

    final integerBuffer = StringBuffer();
    var current = integerPart;
    if (current == 0) {
      integerBuffer.write('0');
    }
    while (current > 0) {
      final remainder = current % base;
      integerBuffer.write(_digitChar(remainder));
      current = current ~/ base;
    }
    final integerString = integerBuffer.toString().split('').reversed.join();

    final fractionBuffer = StringBuffer();
    var fraction = fractionPart;
    for (int i = 0; i < maxFractionDigits && fraction > 0; i++) {
      fraction *= base;
      final digit = fraction.floor();
      fractionBuffer.write(_digitChar(digit));
      fraction -= digit;
      if (fraction == 0) break;
    }

    final fractionString =
        fractionBuffer.isNotEmpty ? '.${fractionBuffer.toString()}' : '';
    return '$sign$integerString$fractionString';
  }

  String _convertBaseValue(String value, int fromBase, int toBase) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return '0';
    if (fromBase == toBase) return normalized;
    final decimalValue = _baseStringToDecimal(normalized, fromBase);
    return _decimalToBase(decimalValue, toBase);
  }

  void _convert() {
    final raw = _valueController.text.trim().replaceAll(',', '.');
    final locale = context.read<LocaleProvider>();
    final isFr = locale.isFrench;

    if (_category == 'Numération') {
      if (raw.isEmpty) {
        setState(() {
          _result = isFr ? 'Valeur invalide' : 'Invalid value';
          _steps = '';
        });
        return;
      }

      final fromBase = (_units[_category]![_from] as num).toInt();
      final toBase = (_units[_category]![_to] as num).toInt();
      final converted = _convertBaseValue(raw, fromBase, toBase);

      setState(() {
        _result = '$converted $_to';
        _steps = '${isFr ? 'Conversion de base' : 'Base conversion'} '
            '$fromBase ${isFr ? 'vers' : 'to'} $toBase\n'
            '${isFr ? 'Valeur' : 'Value'}: $raw ($_from)\n'
            '${isFr ? 'Résultat' : 'Result'}: $converted $_to';
      });
      return;
    }

    final parsed = double.tryParse(raw);
    if (parsed == null) {
      setState(() {
        _result = isFr ? 'Valeur invalide' : 'Invalid value';
        _steps = '';
      });
      return;
    }

    final buffer = StringBuffer();
    double result;

    if (_category == 'Température') {
      double celsius;
      if (_from == '°C') {
        celsius = parsed;
        buffer.writeln(
            '${isFr ? 'Valeur déjà en °C' : 'Already in °C'} : ${MathLibrary.format(parsed)}');
      } else if (_from == '°F') {
        celsius = (parsed - 32) * 5 / 9;
        buffer.writeln(
            '${isFr ? 'Formule °F → °C' : 'Formula °F → °C'} : (°F − 32) × 5/9');
        buffer.writeln(
            '(${MathLibrary.format(parsed)} − 32) × 5/9 = ${MathLibrary.format(celsius)}');
      } else {
        celsius = parsed - 273.15;
        buffer.writeln(
            '${isFr ? 'Formule K → °C' : 'Formula K → °C'} : K − 273.15');
        buffer.writeln(
            '${MathLibrary.format(parsed)} − 273.15 = ${MathLibrary.format(celsius)}');
      }
      if (_to == '°C') {
        result = celsius;
      } else if (_to == '°F') {
        result = celsius * 9 / 5 + 32;
        buffer.writeln('${isFr ? '°C → °F' : '°C → °F'} : °C × 9/5 + 32');
      } else {
        result = celsius + 273.15;
        buffer.writeln('${isFr ? '°C → K' : '°C → K'} : °C + 273.15');
      }
    } else {
      final fromFactor = (_units[_category]![_from] as num).toDouble();
      final toFactor = (_units[_category]![_to] as num).toDouble();
      final base = parsed * fromFactor;
      result = base / toFactor;
      buffer.writeln(
          '1 $_from = ${MathLibrary.format(fromFactor)} (${isFr ? 'unité de base' : 'base unit'})');
      buffer.writeln(
          '${MathLibrary.format(parsed)} $_from = ${MathLibrary.format(base)} (${isFr ? 'base' : 'base'})');
      buffer.writeln(
          '1 $_to = ${MathLibrary.format(toFactor)} (${isFr ? 'base' : 'base'}) → ${isFr ? 'résultat' : 'result'} = base / facteur');
    }

    setState(() {
      _result = '${MathLibrary.format(result)} $_to';
      _steps = buffer.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final isFr = locale.isFrench;

    return Scaffold(
      appBar: AppBar(title: Text(_text('Convertisseur', 'Converter'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            value: _category,
            decoration: InputDecoration(
              labelText: _text('Catégorie', 'Category'),
              border: const OutlineInputBorder(),
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
            decoration: InputDecoration(
              labelText: _text('Valeur', 'Value'),
              border: const OutlineInputBorder(),
              hintText: _text('1 ou 3/4', '1 or 3/4'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _from,
                  decoration: InputDecoration(
                    labelText: _text('De', 'From'),
                    border: const OutlineInputBorder(),
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
                  decoration: InputDecoration(
                    labelText: _text('Vers', 'To'),
                    border: const OutlineInputBorder(),
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
            label: Text(_text('Convertir', 'Convert')),
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

