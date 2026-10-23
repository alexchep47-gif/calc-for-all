import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/complex_number.dart';
import '../../data/services/complex_service.dart';
import '../../data/services/math_library.dart';

/// Nombres complexes — UI simple, arg en fractions de π
class ComplexScreen extends StatefulWidget {
  const ComplexScreen({super.key});

  @override
  State<ComplexScreen> createState() => _ComplexScreenState();
}

class _ComplexScreenState extends State<ComplexScreen> {
  final ComplexService _service = ComplexService();
  int _count = 2;
  late List<TextEditingController> _ctrls;
  String _result = '';
  String _extra = '';
  List<ComplexNumber> _points = [];
  ComplexNumber? _resultPoint;
  final _rootIndexCtrl = TextEditingController(text: '3');
  final _linearizeCtrl = TextEditingController(text: 'sin(x)^3');
  List<ComplexNumber> _roots = [];
  String _linearized = '';

  @override
  void initState() {
    super.initState();
    _rebuildCtrls();
  }

  void _rebuildCtrls() {
    _ctrls = List.generate(
      _count,
      (i) => TextEditingController(
        text: i == 0 ? '3+4i' : (i == 1 ? '1-2i' : '0'),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    _rootIndexCtrl.dispose();
    _linearizeCtrl.dispose();
    super.dispose();
  }

  List<ComplexNumber?> _parseAll() {
    return _ctrls.map((c) {
      try {
        return _service.parse(c.text);
      } catch (_) {
        return null;
      }
    }).toList();
  }

  void _compute(String op) {
    final parsed = _parseAll();
    final valid = parsed.whereType<ComplexNumber>().toList();
    if (valid.isEmpty) {
      setState(() {
        _result = 'Aucun nombre valide (ex: 3+4i)';
        _extra = '';
        _points = [];
        _resultPoint = null;
      });
      return;
    }
    setState(() {
      _points = valid;
      try {
        switch (op) {
          case '+':
            var r = valid.first;
            for (var i = 1; i < valid.length; i++) {
              r = r + valid[i];
            }
            _result = r.toString();
            _extra = r.toPolarString();
            _resultPoint = r;
            break;
          case '-':
            var r = valid.first;
            for (var i = 1; i < valid.length; i++) {
              r = r - valid[i];
            }
            _result = r.toString();
            _extra = r.toPolarString();
            _resultPoint = r;
            break;
          case '*':
            var r = valid.first;
            for (var i = 1; i < valid.length; i++) {
              r = r * valid[i];
            }
            _result = r.toString();
            _extra = r.toPolarString();
            _resultPoint = r;
            break;
          case '/':
            if (valid.length < 2) {
              _result = 'Il faut au moins 2 nombres';
              return;
            }
            var r = valid.first;
            for (var i = 1; i < valid.length; i++) {
              r = r / valid[i];
            }
            _result = r.toString();
            _extra = r.toPolarString();
            _resultPoint = r;
            break;
          case '|z|':
            final lines = <String>[];
            for (var i = 0; i < valid.length; i++) {
              lines.add(
                'z${i + 1} : |z| = ${MathLibrary.format(valid[i].modulus)}  '
                'arg = ${MathLibrary.formatArgAsPi(valid[i].argument)}',
              );
            }
            _result = lines.join('\n');
            _extra = valid.first.toPolarString();
            _resultPoint = valid.first;
            break;
          case 'conj':
            _result = valid.map((z) => z.conjugate.toString()).join('  ;  ');
            _extra = 'Conjugués';
            _resultPoint = valid.first.conjugate;
            break;
          case 'polar':
            _result = valid.map((z) => z.toPolarString()).join('\n');
            _extra = 'Forme trigonométrique (arg en π)';
            _resultPoint = valid.first;
            break;
          default:
            _result = 'Opération inconnue';
        }
      } catch (e) {
        _result = 'Erreur mathématique';
        _extra = '';
      }
    });
  }

  void _nthRoots() {
    final parsed = _parseAll().whereType<ComplexNumber>().toList();
    if (parsed.isEmpty) return;
    final n = int.tryParse(_rootIndexCtrl.text) ?? 3;
    if (n <= 0) return;
    final z = parsed.first;
    final radius = math.pow(z.modulus, 1 / n).toDouble();
    final roots = <ComplexNumber>[];
    for (var k = 0; k < n; k++) {
      final angle = (z.argument + 2 * math.pi * k) / n;
      roots.add(ComplexNumber(
        radius * math.cos(angle),
        radius * math.sin(angle),
      ));
    }
    setState(() {
      _roots = roots;
      _points = roots;
      _resultPoint = null;
      _result = roots.asMap().entries.map((e) {
        final zk = e.value;
        return 'z${e.key + 1} = ${zk.toString()}\n'
            '    arg = ${MathLibrary.formatArgAsPi(zk.argument)}';
      }).join('\n');
      _extra =
          'Racines de degré $n — module = ${MathLibrary.format(radius)}';
    });
  }

  void _linearize() {
    final expression = _linearizeCtrl.text.toLowerCase().replaceAll(' ', '');
    final result = switch (expression) {
      'sin(x)^2' => 'sin²(x) = (1 − cos(2x))/2',
      'cos(x)^2' => 'cos²(x) = (1 + cos(2x))/2',
      'sin(x)^3' => 'sin³(x) = (3sin(x) − sin(3x))/4',
      'cos(x)^3' => 'cos³(x) = (3cos(x) + cos(3x))/4',
      _ => 'Formules : sin²(x), cos²(x), sin³(x), cos³(x).',
    };
    setState(() => _linearized = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nombres complexes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Text('Nombre de z : '),
              DropdownButton<int>(
                value: _count,
                items: [1, 2, 3, 4, 5]
                    .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    for (final c in _ctrls) {
                      c.dispose();
                    }
                    _count = v;
                    _rebuildCtrls();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(_count, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _ctrls[i],
                decoration: InputDecoration(
                  labelText: 'z${i + 1} (ex: 3+4i ou 2cis(π/3))',
                  border: const OutlineInputBorder(),
                ),
              ),
            );
          }),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final op in ['+', '-', '*', '/', '|z|', 'conj', 'polar'])
                FilledButton(
                  onPressed: () => _compute(op),
                  child: Text(op),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _rootIndexCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Indice n (racines n-ièmes)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _nthRoots,
                child: const Text('Racines'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_result.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_result,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, height: 1.4)),
                    if (_extra.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(_extra, style: const TextStyle(height: 1.35)),
                    ],
                  ],
                ),
              ),
            ).animate().fadeIn(),
          const SizedBox(height: 16),
          const Text('Linéarisation (rappels)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            controller: _linearizeCtrl,
            decoration: const InputDecoration(
              hintText: 'sin(x)^2, cos(x)^3…',
              border: OutlineInputBorder(),
            ),
          ),
          TextButton(onPressed: _linearize, child: const Text('Linéariser')),
          if (_linearized.isNotEmpty) Text(_linearized),
        ],
      ),
    );
  }
}
