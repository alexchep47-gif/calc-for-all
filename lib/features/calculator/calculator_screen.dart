import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../data/services/calculator_service.dart';
import '../../data/storage/local_storage.dart';
import '../../widgets/custom_button.dart';

/// Écran principal de la calculatrice scientifique
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
    setState(() {
      if (_justCalculated && !_isOperator(value) && value != '=') {
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
          if (_expression.isNotEmpty) {
            final res = _service.evaluate(_expression);
            _result = res;
            _justCalculated = true;
            // Sauvegarde dans l'historique
            context.read<LocalStorage>().addToHistory(_expression, res);
          }
          break;
        default:
          _expression += value;
          _justCalculated = false;
      }
    });
  }

  bool _isOperator(String v) => ['+', '−', '×', '÷', '^', '%'].contains(v);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calc For All'),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            tooltip: 'Graphiques',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.graph),
          ),
          IconButton(
            icon: const Icon(Icons.functions),
            tooltip: 'Complexes',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.complex),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historique',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.history),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Réglages',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          // Affichage
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Text(
                      _expression.isEmpty ? '0' : _expression,
                      style: TextStyle(
                        fontSize: 28,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _result,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          // Clavier
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  _buildRow(['C', '⌫', '%', '÷']),
                  _buildRow(['7', '8', '9', '×']),
                  _buildRow(['4', '5', '6', '−']),
                  _buildRow(['1', '2', '3', '+']),
                  _buildRow(['0', '.', 'π', '=']),
                  _buildRow(['sin', 'cos', 'tan', '√']),
                  _buildRow(['log', 'ln', '^', '( )']),
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
          final isOp = _isOperator(b) || b == '=' || b == 'C' || b == '⌫';
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: CustomButton(
                label: b,
                isOperator: isOp,
                onTap: () {
                  if (b == '( )') {
                    // Bascule simple entre ( et )
                    _onButtonPressed(_expression.contains('(') &&
                            !_expression.contains(')')
                        ? ')'
                        : '(');
                  } else {
                    _onButtonPressed(b);
                  }
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
