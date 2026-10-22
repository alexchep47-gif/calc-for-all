import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/complex_number.dart';
import '../../data/services/complex_service.dart';
import '../../data/services/math_library.dart';
import '../../widgets/custom_button.dart';

/// Nombres complexes + représentation sur le plan complexe
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
  ComplexNumber? _pointA;
  ComplexNumber? _pointB;
  ComplexNumber? _pointResult;

  void _loadExample() {
    setState(() {
      _aController.text = '3+4i';
      _bController.text = '1-2i';
      _result = '';
      _extra = '';
      _pointA = _service.parse('3+4i');
      _pointB = _service.parse('1-2i');
      _pointResult = null;
    });
  }

  void _compute(String op) {
    final a = _service.parse(_aController.text);
    final b = _service.parse(_bController.text);

    if (a == null) {
      setState(() {
        _result = 'Nombre A invalide (ex: 3+4i)';
        _extra = '';
        _pointA = null;
        _pointResult = null;
      });
      return;
    }

    setState(() {
      _pointA = a;
      _pointB = b;
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
            _pointResult = r;
            break;
          case '−':
            if (b == null) {
              _result = 'Nombre B invalide';
              return;
            }
            final r = a - b;
            _result = r.toString();
            _extra = r.toPolarString();
            _pointResult = r;
            break;
          case '×':
            if (b == null) {
              _result = 'Nombre B invalide';
              return;
            }
            final r = a * b;
            _result = r.toString();
            _extra = r.toPolarString();
            _pointResult = r;
            break;
          case '÷':
            if (b == null) {
              _result = 'Nombre B invalide';
              return;
            }
            final r = a / b;
            _result = r.toString();
            _extra = r.toPolarString();
            _pointResult = r;
            break;
          case '|z|':
            _result = MathLibrary.format(a.modulus);
            _extra = 'Module de A';
            _pointResult = a;
            break;
          case 'arg':
            _result = '${MathLibrary.format(a.argument * 180 / math.pi)}°';
            _extra = 'Argument de A';
            _pointResult = a;
            break;
          case 'conj':
            final r = a.conjugate;
            _result = r.toString();
            _extra = r.toPolarString();
            _pointResult = r;
            break;
        }
      } catch (e) {
        _result = 'Erreur : $e';
        _extra = '';
        _pointResult = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nombres complexes'),
        actions: [
          TextButton(
            onPressed: _loadExample,
            child: const Text('Exemple'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Forme a+bi (ex: 3+4i). Le plan complexe affiche A, B et le résultat.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _aController,
              decoration: InputDecoration(
                labelText: 'Nombre A',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.looks_one),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bController,
              decoration: InputDecoration(
                labelText: 'Nombre B (optionnel pour |z|, arg, conj)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.looks_two),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: '+',
                    isOperator: true,
                    onTap: () => _compute('+'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    label: '−',
                    isOperator: true,
                    onTap: () => _compute('−'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    label: '×',
                    isOperator: true,
                    onTap: () => _compute('×'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    label: '÷',
                    isOperator: true,
                    onTap: () => _compute('÷'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: '|z|',
                    isOperator: true,
                    onTap: () => _compute('|z|'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    label: 'arg',
                    isOperator: true,
                    onTap: () => _compute('arg'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    label: 'conj',
                    isOperator: true,
                    onTap: () => _compute('conj'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Résultat',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _result.isEmpty ? '—' : _result,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_extra.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _extra,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 20),
            Text(
              'Plan complexe',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 260,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: CustomPaint(
                  painter: _ComplexPlanePainter(
                    a: _pointA,
                    b: _pointB,
                    result: _pointResult,
                  ),
                  child: Container(),
                ),
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 8),
            Text(
              'Bleu = A · Orange = B · Rouge = résultat',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComplexPlanePainter extends CustomPainter {
  final ComplexNumber? a;
  final ComplexNumber? b;
  final ComplexNumber? result;

  _ComplexPlanePainter({this.a, this.b, this.result});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = math.min(size.width, size.height) / 14;

    final axis = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(20, center.dy),
      Offset(size.width - 20, center.dy),
      axis,
    );
    canvas.drawLine(
      Offset(center.dx, 20),
      Offset(center.dx, size.height - 20),
      axis,
    );

    // Grille légère
    final grid = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 0.5;
    for (var i = -6; i <= 6; i++) {
      if (i == 0) continue;
      final x = center.dx + i * scale;
      final y = center.dy - i * scale;
      canvas.drawLine(Offset(x, 20), Offset(x, size.height - 20), grid);
      canvas.drawLine(Offset(20, y), Offset(size.width - 20, y), grid);
    }

    void drawPoint(ComplexNumber? z, Color color, String label) {
      if (z == null) return;
      final p = Offset(
        center.dx + z.real * scale,
        center.dy - z.imag * scale,
      );
      final line = Paint()
        ..color = color.withOpacity(0.5)
        ..strokeWidth = 1.5;
      canvas.drawLine(center, p, line);
      canvas.drawCircle(p, 7, Paint()..color = color);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p + const Offset(8, -14));
    }

    drawPoint(a, const Color(0xFF1565C0), 'A');
    drawPoint(b, const Color(0xFFEF6C00), 'B');
    drawPoint(result, const Color(0xFFC62828), 'R');
  }

  @override
  bool shouldRepaint(covariant _ComplexPlanePainter old) =>
      old.a != a || old.b != b || old.result != result;
}
