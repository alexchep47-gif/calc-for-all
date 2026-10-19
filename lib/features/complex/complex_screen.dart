import 'package:flutter/material.dart';
import '../../data/models/complex_number.dart';
import '../../data/services/complex_service.dart';
import '../../widgets/custom_button.dart';

/// Écran de manipulation des nombres complexes
class ComplexScreen extends StatefulWidget {
  const ComplexScreen({super.key});

  @override
  State<ComplexScreen> createState() => _ComplexScreenState();
}

class _ComplexScreenState extends State<ComplexScreen> {
  final ComplexService _service = ComplexService();
  final TextEditingController _aController = TextEditingController();
  final TextEditingController _bController = TextEditingController();
  String _result = '';
  String _extra = '';

  void _compute(String op) {
    final a = _service.parse(_aController.text);
    final b = _service.parse(_bController.text);

    if (a == null) {
      setState(() {
        _result = 'Nombre A invalide';
        _extra = '';
      });
      return;
    }

    setState(() {
      try {
        switch (op) {
          case '+':
            if (b == null) {
              _result = 'Nombre B invalide';
              return;
            }
            final r = a + b;
            _result = r.toString();
            _extra = r.toPolarString();
            break;
          case '−':
            if (b == null) {
              _result = 'Nombre B invalide';
              return;
            }
            final r = a - b;
            _result = r.toString();
            _extra = r.toPolarString();
            break;
          case '×':
            if (b == null) {
              _result = 'Nombre B invalide';
              return;
            }
            final r = a * b;
            _result = r.toString();
            _extra = r.toPolarString();
            break;
          case '÷':
            if (b == null) {
              _result = 'Nombre B invalide';
              return;
            }
            final r = a / b;
            _result = r.toString();
            _extra = r.toPolarString();
            break;
          case '|z|':
            _result = a.modulus.toStringAsFixed(6);
            _extra = 'Module';
            break;
          case 'arg':
            _result = (a.argument * 180 / 3.141592653589793).toStringAsFixed(4) + '°';
            _extra = 'Argument';
            break;
          case 'conj':
            final r = a.conjugate;
            _result = r.toString();
            _extra = r.toPolarString();
            break;
        }
      } catch (e) {
        _result = 'Erreur : ${e.toString()}';
        _extra = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nombres complexes'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Saisis les nombres sous la forme a+bi (ex: 3+4i ou -2-1.5i)',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _aController,
              decoration: InputDecoration(
                labelText: 'Nombre A',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.looks_one),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bController,
              decoration: InputDecoration(
                labelText: 'Nombre B (optionnel pour |z|, arg, conj)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.looks_two),
              ),
            ),
            const SizedBox(height: 24),
            // Opérations binaires
            Row(
              children: [
                Expanded(child: CustomButton(label: '+', isOperator: true, onTap: () => _compute('+'))),
                const SizedBox(width: 8),
                Expanded(child: CustomButton(label: '−', isOperator: true, onTap: () => _compute('−'))),
                const SizedBox(width: 8),
                Expanded(child: CustomButton(label: '×', isOperator: true, onTap: () => _compute('×'))),
                const SizedBox(width: 8),
                Expanded(child: CustomButton(label: '÷', isOperator: true, onTap: () => _compute('÷'))),
              ],
            ),
            const SizedBox(height: 12),
            // Opérations unaires
            Row(
              children: [
                Expanded(child: CustomButton(label: '|z|', isOperator: true, onTap: () => _compute('|z|'))),
                const SizedBox(width: 8),
                Expanded(child: CustomButton(label: 'arg', isOperator: true, onTap: () => _compute('arg'))),
                const SizedBox(width: 8),
                Expanded(child: CustomButton(label: 'conj', isOperator: true, onTap: () => _compute('conj'))),
              ],
            ),
            const SizedBox(height: 32),
            // Résultat
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('Résultat', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(
                      _result.isEmpty ? '—' : _result,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    if (_extra.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(_extra, style: TextStyle(color: Colors.grey.shade600)),
                    ],
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
