import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../data/services/calculator_service.dart';
import '../../data/services/math_library.dart';
import '../../data/services/math_pretty.dart';
import '../../data/services/ocr_service.dart';
import '../../data/storage/local_storage.dart';

/// Calculatrice scientifique — ⁿ√ simplifiée, Mode, Shift, virgule
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
  final OcrService _ocrService = OcrService();

  Future<void> _scanExpression() async {
    final expression = await _ocrService.recognizeExpression();
    if (!mounted) return;
    if (expression == null || expression.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OCR indisponible sur le Web ou image illisible. Utilisez une photo nette sur Android/iOS.')));
      return;
    }
    setState(() { _expression = expression; _result = '0'; _justCalculated = false; });
  }
  String _angleMode = 'rad';
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
          _expression += '.';
          break;
        case 'ⁿ√':
          _showNthRootDialog();
          break;
        case '=':
          final res = _service.evaluate(_expression);
          _result = _formatResult(res);
          _justCalculated = true;
          _shift = false;
          try {
            context.read<LocalStorage>().addToHistory(
                  MathPretty.format(_expression),
                  _result,
                  module: 'Calculatrice',
                );
          } catch (_) {}
          break;
        case 'a/b':
          if (_expression.isEmpty) {
            _expression = '1/';
          } else if (!_expression.endsWith('/')) {
            _expression += '/';
          }
          break;
        case '√':
          _expression += _shift ? 'cbrt(' : 'sqrt(';
          _shift = false;
          break;
        case 'sec':
          _expression += 'sec(';
          _shift = false;
          break;
        case 'csc':
          _expression += 'csc(';
          _shift = false;
          break;
        case 'cot':
          _expression += 'cot(';
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

  void _showNthRootDialog() {
    final aCtrl = TextEditingController(
      text: _expression.isEmpty ? '8' : _expression,
    );
    final nCtrl = TextEditingController(text: '3');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Racine n-ième'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: aCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: const InputDecoration(
                labelText: 'Valeur (a)',
                border: OutlineInputBorder(),
                hintText: 'ex: 8',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: const InputDecoration(
                labelText: 'Indice n',
                border: OutlineInputBorder(),
                hintText: 'ex: 3 → racine cubique',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Calcule ⁿ√a',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final a = double.tryParse(aCtrl.text.replaceAll(',', '.'));
              final n = double.tryParse(nCtrl.text.replaceAll(',', '.'));
              if (a == null || n == null) return;
              final res = _service.nthRoot(a, n);
              setState(() {
                _expression = 'root($a,$n)';
                _result = res;
                _justCalculated = true;
              });
              try {
                context.read<LocalStorage>().addToHistory(
                      'ⁿ√($a) indice $n',
                      res,
                      module: 'Calculatrice',
                    );
              } catch (_) {}
              Navigator.pop(ctx);
            },
            child: const Text('Calculer'),
          ),
        ],
      ),
    );
  }

  String _formatResult(String raw) {
    final v = double.tryParse(raw.replaceAll(',', '.'));
    if (v == null) return MathPretty.format(raw);
    if (_displayMode == 'sci') {
      return MathPretty.format(v.toStringAsExponential(6));
    }
    if (_displayMode == 'eng') {
      if (v == 0) return '0';
      final exp = (MathLibrary.log10(v.abs()) / 3).floor() * 3;
      final mant = v / MathLibrary.pow(10.0, exp.toDouble());
      return '${MathLibrary.format(mant)}×10${_sup(exp)}';
    }
    return MathLibrary.format(v);
  }

  String _sup(int n) {
    const m = {
      '0': '⁰',
      '1': '¹',
      '2': '²',
      '3': '³',
      '4': '⁴',
      '5': '⁵',
      '6': '⁶',
      '7': '⁷',
      '8': '⁸',
      '9': '⁹',
      '-': '⁻',
    };
    return n.toString().split('').map((c) => m[c] ?? c).join();
  }

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
            for (final m in [
              ('deg', 'Degré (DEG)'),
              ('rad', 'Radian (RAD)'),
              ('grad', 'Grade (GRAD)'),
            ])
              RadioListTile<String>(
                title: Text(m.$2),
                value: m.$1,
                groupValue: _angleMode,
                onChanged: (v) {
                  setState(() => _angleMode = v!);
                  Navigator.pop(ctx);
                },
              ),
            const Divider(),
            const ListTile(title: Text('Affichage')),
            for (final m in [
              ('norm', 'Normal (NORM)'),
              ('sci', 'Scientifique (SCI)'),
              ('eng', 'Engineering (ENG)'),
            ])
              RadioListTile<String>(
                title: Text(m.$2),
                value: m.$1,
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
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Historique',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.history),
          ),
          IconButton(
            icon: const Icon(Icons.document_scanner_rounded),
            tooltip: 'Lire une expression avec l’OCR',
            onPressed: _scanExpression,
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
                  Text(
                    '${_angleMode.toUpperCase()} · ${_displayMode.toUpperCase()}'
                    '${_shift ? ' · SHIFT' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _shift ? Colors.orange : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Text(
                      _expression.isEmpty
                          ? '0'
                          : MathPretty.format(_expression),
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
                  _buildRow([_shift ? 'sec' : 'sin', _shift ? 'csc' : 'cos', _shift ? 'cot' : 'tan', '√']),
                  _buildRow(['log', 'ln', 'xʸ', 'ⁿ√']),
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
          final key = b == 'xʸ' ? '^' : b;
          final isOp = _isOperator(key) ||
              key == '=' ||
              key == 'C' ||
              key == '⌫' ||
              key == 'a/b' ||
              key == 'MODE' ||
              key == 'SHIFT' ||
              key == 'ⁿ√';
          final highlight = key == 'SHIFT' && _shift;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Material(
                color: highlight
                    ? Colors.orange.shade400
                    : (isOp
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _onButtonPressed(key),
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
