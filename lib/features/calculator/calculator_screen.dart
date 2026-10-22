import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/routes/app_routes.dart';
import '../../data/services/calculator_service.dart';
import '../../data/storage/local_storage.dart';
import '../../widgets/custom_button.dart';

/// Calculatrice scientifique — fractions + racines n-ièmes
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

  void _onButtonPressed(String value) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_justCalculated &&
          !_isOperator(value) &&
          value != '=' &&
          value != '⌫' &&
          value != 'a/b' &&
          value != 'ⁿ√') {
        _expression = '';
        _justCalculated = false;
      }

      switch (value) {
        case 'C':
          _expression = '';
          _result = '0';
          break;
        case '⌫':
          if (_expression.isNotEmpty) {
            _expression = _expression.substring(0, _expression.length - 1);
          }
          break;
        case '=':
          final res = _service.evaluate(_expression);
          _result = res;
          _justCalculated = true;
          try {
            context.read<LocalStorage>().addHistory(_expression, res);
          } catch (_) {}
          break;
        case 'a/b':
          // Fraction : si expression = num, ajoute /
          if (_expression.isEmpty) {
            _expression = '1/';
          } else if (!_expression.contains('/')) {
            _expression += '/';
          }
          break;
        case 'ⁿ√':
          // root(a,n) — utilisateur complète a et n
          _expression += 'root(';
          break;
        case '√':
          _expression += 'sqrt(';
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
          _expression += 'pi';
          break;
        default:
          _expression += value;
      }
    });
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
            tooltip: 'Graphique',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.graph),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Réglages',
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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
                        fontSize: 38, fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ⁿ√ : root(a,n)  ex. root(8,3) = 2',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
              child: Column(
                children: [
                  _buildRow(['C', '⌫', 'a/b', '÷']),
                  _buildRow(['7', '8', '9', '×']),
                  _buildRow(['4', '5', '6', '−']),
                  _buildRow(['1', '2', '3', '+']),
                  _buildRow(['0', '.', 'π', '=']),
                  _buildRow(['sin', 'cos', 'tan', '√']),
                  _buildRow(['log', 'ln', '^', 'ⁿ√']),
                  _buildRow(['(', ')', 'e', '!']),
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
          final isOp =
              _isOperator(b) || b == '=' || b == 'C' || b == '⌫' || b == 'a/b';
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(3.5),
              child: CustomButton(
                label: b,
                isOperator: isOp,
                onTap: () => _onButtonPressed(b),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
