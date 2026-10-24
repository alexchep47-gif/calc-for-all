import 'package:flutter/material.dart';

import '../../data/models/complex_number.dart';
import '../../data/services/complex_service.dart';

enum ComplexOperation { add, subtract, multiply, divide }

class ComplexScreen extends StatefulWidget {
  const ComplexScreen({super.key});

  @override
  State<ComplexScreen> createState() => _ComplexScreenState();
}

class _ComplexScreenState extends State<ComplexScreen> {
  final _service = ComplexService();
  final _aController = TextEditingController(text: '3+4i');
  final _bController = TextEditingController(text: '1-2i');

  ComplexOperation _operation = ComplexOperation.add;
  String _resultText = '7+2i';
  String _detailsText = 'Z = (3+4i) + (1-2i) = 4+2i';

  @override
  void dispose() {
    _aController.dispose();
    _bController.dispose();
    super.dispose();
  }

  void _calculate() {
    final a = _service.parse(_aController.text);
    final b = _service.parse(_bController.text);

    if (a == null || b == null) {
      setState(() {
        _resultText = 'Entrée invalide';
        _detailsText = 'Utilise une forme du type 3+4i, -2.5-1.2i, 5i, -i, 7';
      });
      return;
    }

    try {
      late final ComplexNumber result;
      switch (_operation) {
        case ComplexOperation.add:
          result = _service.add(a, b);
          break;
        case ComplexOperation.subtract:
          result = _service.subtract(a, b);
          break;
        case ComplexOperation.multiply:
          result = _service.multiply(a, b);
          break;
        case ComplexOperation.divide:
          result = _service.divide(a, b);
          break;
      }

      final mod = _service.modulus(result);
      final argDeg = _service.argument(result);
      final conj = _service.conjugate(result);

      setState(() {
        _resultText = result.toString();
        _detailsText = 'Module : $mod\n'
            'Argument : $argDeg\n'
            'Conjugué : $conj\n'
            'Forme polaire : ${result.toPolarString()}';
      });
    } catch (_) {
      setState(() {
        _resultText = 'Erreur';
        _detailsText = 'Division par zéro ou calcul impossible.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final operationLabel = switch (_operation) {
      ComplexOperation.add => '+',
      ComplexOperation.subtract => '-',
      ComplexOperation.multiply => '×',
      ComplexOperation.divide => '÷',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nombres complexes'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Opération',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<ComplexOperation>(
                      segments: const [
                        ButtonSegment(value: ComplexOperation.add, label: Text('+')),
                        ButtonSegment(
                          value: ComplexOperation.subtract,
                          label: Text('-'),
                        ),
                        ButtonSegment(
                          value: ComplexOperation.multiply,
                          label: Text('×'),
                        ),
                        ButtonSegment(
                          value: ComplexOperation.divide,
                          label: Text('÷'),
                        ),
                      ],
                      selected: {_operation},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _operation = selection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _aController,
                      decoration: const InputDecoration(
                        labelText: 'Premier nombre complexe',
                        hintText: '3+4i',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bController,
                      decoration: const InputDecoration(
                        labelText: 'Deuxième nombre complexe',
                        hintText: '1-2i',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _calculate,
                        icon: const Icon(Icons.calculate_outlined),
                        label: const Text('Calculer'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Résultat',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_aController.text} $operationLabel ${_bController.text} = $_resultText',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Détails',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _detailsText,
                      style: const TextStyle(height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Exemples',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ExampleChip(
                          label: '3+4i + 1-2i',
                          onTap: () {
                            _aController.text = '3+4i';
                            _bController.text = '1-2i';
                            _operation = ComplexOperation.add;
                            _calculate();
                          },
                        ),
                        _ExampleChip(
                          label: '2-3i × 1+i',
                          onTap: () {
                            _aController.text = '2-3i';
                            _bController.text = '1+i';
                            _operation = ComplexOperation.multiply;
                            _calculate();
                          },
                        ),
                        _ExampleChip(
                          label: '5i / 2-i',
                          onTap: () {
                            _aController.text = '5i';
                            _bController.text = '2-i';
                            _operation = ComplexOperation.divide;
                            _calculate();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ExampleChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.blueGrey.withOpacity(0.18),
    );
  }
}

