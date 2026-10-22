import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../data/services/calculator_service.dart';
import '../../data/services/math_library.dart';
import '../../data/storage/local_storage.dart';
import '../../widgets/custom_button.dart';

/// Calculatrice scientifique — Mode / Shift / virgule / ⁿ√
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final CalculatorService _service = CalculatorService();
  String _expression = '';
  String _result = '0';
  bool _justCalculated = false;
  bool _shift = false;
  /// deg | rad | grad
  String _angleMode = 'rad';
  /// norm | sci | eng
  String _displayMode = 'norm';

  void _onButtonPressed(String value) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_justCalculated &&
          !_isOperator(value) &&
          value != '=' &&
          value != '⌫' &&
          value != 'a/b' &&
          value != 'ⁿ√' &&
          value != 'SHIFT' &&
          value != 'MODE' &&
          value != ',') {
        _expression = '';
        _justCalculated = false;
      }

      switch (value) {
        case 'C':
          _expression = '';
          _result = '0';
          _shift = false;
          break;
        case '⌫':
          if (_expression.isNotEmpty) {
            _expression = _expression.substring(0, _expression.length - 1);
          }
          break;
        case 'SHIFT':
          _shift = !_shift;
          break;
        case 'MODE':
          _showModeSheet();
          break;
        case ',':
          // Virgule décimale (locale FR) → point interne
          _expression += '.';
          break;
        case '=':
          final res = _service.evaluate(_expression);
          _result = _formatResult(res);
          _justCalculated = true;
          _shift = false;
          try {
            context.read<LocalStorage>().addToHistory(_expression, _result);
          } catch (_) {}
          break;
        case 'a/b':
          if (_expression.isEmpty) {
            _expression = '1/';
          } else if (!_expression.endsWith('/')) {
            _expression += '/';
          }
          break;
        case 'ⁿ√':
          _expression += _shift ? 'cbrt(' : 'root(';
          _shift = false;
          break;
        case '√':
          _expression += _shift ? 'cbrt(' : 'sqrt(';
          _shift = false;
          break;
        case 'sin':
          _expression += _shift ? 'asin(' : 'sin(';
          _shift = false;
          break;
        case 'cos':
          _expression += _shift ? 'acos(' : 'cos(';
          _shift = false;
          break;
        case 'tan':
          _expression += _shift ? 'atan(' : 'tan(';
          _shift = false;
          break;
        case 'log':
          _expression += _shift ? '10^(' : 'log10(';
          _shift = false;
          break;
        case 'ln':
          _expression += _shift ? 'exp(' : 'ln(';
          _shift = false;
          break;
        case '^':
          _expression += _shift ? '^(1/' : '^';
          _shift = false;
          break;
        case '×':
          _expression += '*';
          break;
        case '÷':
          _expression += '/';
          break;
        case '−':
          _expression += '-';
          break;
        case 'π':
          _expression += _shift ? 'tau' : 'pi';
          _shift = false;
          break;
        case '!':
          _expression += _shift ? 'abs(' : '!';
          _shift = false;
          break;
        default:
          _expression += value;
      }
    });
  }

  String _formatResult(String raw) {
    final v = double.tryParse(raw.replaceAll(',', '.'));
    if (v == null) return raw;
    if (_displayMode == 'sci') {
      return v.toStringAsExponential(6);
    }
    if (_displayMode == 'eng') {
      // Engineering: exposant multiple de 3
      if (v == 0) return '0';
      final exp = (mathLog10(v.abs()) / 3).floor() * 3;
      final mant = v / MathLibrary.pow(10.0, exp.toDouble());
      return '${MathLibrary.format(mant)}×10^$exp';
    }
    return MathLibrary.format(v);
  }

  double mathLog10(double x) => MathLibrary.log10(x);

  void _showModeSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('MODE calculatrice',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            const ListTile(title: Text('Angle')),
            RadioListTile<String>(
              title: const Text('Degré (DEG)'),
              value: 'deg',
              groupValue: _angleMode,
              onChanged: (v) {
                setState(() => _angleMode = v!);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<String>(
              title: const Text('Radian (RAD)'),
              value: 'rad',
              groupValue: _angleMode,
              onChanged: (v) {
                setState(() => _angleMode = v!);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<String>(
              title: const Text('Grade (GRAD)'),
              value: 'grad',
              groupValue: _angleMode,
              onChanged: (v) {
                setState(() => _angleMode = v!);
                Navigator.pop(ctx);
              },
            ),
            const Divider(),
            const ListTile(title: Text('Affichage')),
            RadioListTile<String>(
              title: const Text('Normal (NORM)'),
              value: 'norm',
              groupValue: _displayMode,
              onChanged: (v) {
                setState(() => _displayMode = v!);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<String>(
              title: const Text('Scientifique (SCI)'),
              value: 'sci',
              groupValue: _displayMode,
              onChanged: (v) {
                setState(() => _displayMode = v!);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<String>(
              title: const Text('Engineering (ENG)'),
              value: 'eng',
              groupValue: _displayMode,
              onChanged: (v) {
                setState(() => _displayMode = v!);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isOperator(String v) =>
      ['+', '−', '×', '÷', '^', '*', '/'].contains(v);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculatrice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.functions_rounded),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.graph),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_angleMode.toUpperCase()} · ${_displayMode.toUpperCase()}'
                        '${_shift ? ' · SHIFT' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _shift ? Colors.orange : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Text(
                      _expression.isEmpty ? '0' : _expression,
                      style:
                          TextStyle(fontSize: 22, color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _result,
                    style: const TextStyle(
                        fontSize: 36, fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
                children: [
                  _buildRow(['MODE', 'SHIFT', 'a/b', '÷']),
                  _buildRow(['7', '8', '9', '×']),
                  _buildRow(['4', '5', '6', '−']),
                  _buildRow(['1', '2', '3', '+']),
                  _buildRow(['0', ',', 'π', '=']),
                  _buildRow(['sin', 'cos', 'tan', '√']),
                  _buildRow(['log', 'ln', '^', 'ⁿ√']),
                  _buildRow(['(', ')', 'e', '!']),
                  _buildRow(['C', '⌫', '.', '%']),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> buttons) {
    return Expanded(
      child: Row(
        children: buttons.map((b) {
          final isOp = _isOperator(b) ||
              b == '=' ||
              b == 'C' ||
              b == '⌫' ||
              b == 'a/b' ||
              b == 'MODE' ||
              b == 'SHIFT';
          final highlight = b == 'SHIFT' && _shift;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Material(
                color: highlight
                    ? Colors.orange.shade400
                    : (isOp
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _onButtonPressed(b),
                  child: Center(
                    child: Text(
                      b,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: b.length > 3 ? 12 : 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
