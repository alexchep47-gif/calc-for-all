import 'package:flutter/material.dart';

import '../../data/models/complex_number.dart';
import '../../data/services/complex_service.dart';
import '../../data/services/math_library.dart';

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
  final _rootInputController = TextEditingController(text: '1+0i');
  final _rootIndexController = TextEditingController(text: '3');

  ComplexOperation _operation = ComplexOperation.add;
  String _resultText = '7+2i';
  String _detailsText = 'Z = (3+4i) + (1-2i) = 4+2i';
  String _nthRootsText = 'z₀ = 1\nz₁ = cos(2π/3)+i sin(2π/3)\nz₂ = cos(4π/3)+i sin(4π/3)';

  @override
  void dispose() {
    _aController.dispose();
    _bController.dispose();
    _rootInputController.dispose();
    _rootIndexController.dispose();
    super.dispose();
  }

  bool get _isEnglish => Localizations.localeOf(context).languageCode == 'en';
  String _t(String en, String fr) => _isEnglish ? en : fr;

  void _calculate() {
    final a = _service.parse(_aController.text);
    final b = _service.parse(_bController.text);

    if (a == null || b == null) {
      setState(() {
        _resultText = _t('Invalid input', 'Entrée invalide');
        _detailsText = _t(
          'Use a form like 3+4i, -2.5-1.2i, 5i, -i, 7',
          'Utilise une forme du type 3+4i, -2.5-1.2i, 5i, -i, 7',
        );
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
        _resultText = MathLibrary.sanitizeForDisplay(result.toString());
        _detailsText = '${_t('Modulus', 'Module')} : $mod\n'
            '${_t('Argument', 'Argument')} : $argDeg\n'
            '${_t('Conjugate', 'Conjugué')} : ${MathLibrary.sanitizeForDisplay(conj.toString())}\n'
            '${_t('Polar form', 'Forme polaire')} : ${MathLibrary.sanitizeForDisplay(result.toPolarString())}';
      });
    } catch (_) {
      setState(() {
        _resultText = _t('Error', 'Erreur');
        _detailsText = _t(
          'Division by zero or impossible calculation.',
          'Division par zéro ou calcul impossible.',
        );
      });
    }
  }

  void _calculateNthRoots() {
    final z = _service.parse(_rootInputController.text);
    final n = int.tryParse(_rootIndexController.text);
    if (z == null || n == null || n <= 0) {
      setState(() {
        _nthRootsText = _t(
          'Invalid input. Enter a complex number and n > 0.',
          'Entrée invalide. Entrez un nombre complexe et n > 0.',
        );
      });
      return;
    }

    try {
      final roots = _service.nthRoots(z, n);
      final lines = <String>[];
      for (var i = 0; i < roots.length; i++) {
        final root = roots[i];
        lines.add('z${i} = ${MathLibrary.sanitizeForDisplay(root.toString())}');
      }
      setState(() {
        _nthRootsText = lines.join('\n');
      });
    } catch (_) {
      setState(() {
        _nthRootsText = _t('Calculation impossible for this value.', 'Calcul impossible pour cette valeur.');
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
        title: Text(_t('Complex numbers', 'Nombres complexes')),
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
                    Text(
                      _t('Operation', 'Opération'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<ComplexOperation>(
                      segments: const [
                        ButtonSegment(value: ComplexOperation.add, label: Text('+')),
                        ButtonSegment(value: ComplexOperation.subtract, label: Text('-')),
                        ButtonSegment(value: ComplexOperation.multiply, label: Text('×')),
                        ButtonSegment(value: ComplexOperation.divide, label: Text('÷')),
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
                      decoration: InputDecoration(
                        labelText: _t('First complex number', 'Premier nombre complexe'),
                        hintText: '3+4i',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bController,
                      decoration: InputDecoration(
                        labelText: _t('Second complex number', 'Deuxième nombre complexe'),
                        hintText: '1-2i',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _calculate,
                        icon: const Icon(Icons.calculate_outlined),
                        label: Text(_t('Calculate', 'Calculer')),
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
                    Text(
                      _t('Result', 'Résultat'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${MathLibrary.sanitizeForDisplay(_aController.text)} $operationLabel ${MathLibrary.sanitizeForDisplay(_bController.text)} = ${MathLibrary.sanitizeForDisplay(_resultText)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _t('Details', 'Détails'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      MathLibrary.sanitizeForDisplay(_detailsText),
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
                    Text(
                      _t('n-th roots', 'Racines n-ièmes'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _rootInputController,
                      decoration: InputDecoration(
                        labelText: _t('Complex z', 'Nombre complexe z'),
                        hintText: '1+i',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _rootIndexController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _t('Index n', 'Indice n'),
                        hintText: '3',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _calculateNthRoots,
                        icon: const Icon(Icons.autorenew_outlined),
                        label: Text(_t('Calculate roots', 'Calculer les racines')),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _t('Results', 'Résultats'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      MathLibrary.sanitizeForDisplay(_nthRootsText),
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
                    Text(
                      _t('Examples', 'Exemples'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                          label: '5i ÷ 2-i',
                          onTap: () {
                            _aController.text = '5i';
                            _bController.text = '2-i';
                            _operation = ComplexOperation.divide;
                            _calculate();
                          },
                        ),
                        _ExampleChip(
                          label: '1, n=3',
                          onTap: () {
                            _rootInputController.text = '1';
                            _rootIndexController.text = '3';
                            _calculateNthRoots();
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

