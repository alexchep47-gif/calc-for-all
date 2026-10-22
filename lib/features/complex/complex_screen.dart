import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/complex_number.dart';
import '../../data/services/complex_service.dart';
import '../../data/services/math_library.dart';

/// Nombres complexes — nombre de points configurable + MathLibrary
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
    super.dispose();
  }

  List<ComplexNumber?> _parseAll() =>
      _ctrls.map((c) => _service.parse(c.text)).toList();

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
            _extra =
                '${r.toPolarString()}\nModule = ${MathLibrary.format(r.modulus)}';
            _resultPoint = r;
            break;
          case '−':
            if (valid.length < 2) {
              _result = 'Il faut au moins 2 nombres';
              return;
            }
            var r = valid.first;
            for (var i = 1; i < valid.length; i++) {
              r = r - valid[i];
            }
            _result = r.toString();
            _extra = r.toPolarString();
            _resultPoint = r;
            break;
          case '×':
            var r = valid.first;
            for (var i = 1; i < valid.length; i++) {
              r = r * valid[i];
            }
            _result = r.toString();
            _extra = r.toPolarString();
            _resultPoint = r;
            break;
          case '÷':
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
                  'z${i + 1} : |z| = ${MathLibrary.format(valid[i].modulus)}  arg = ${MathLibrary.format(valid[i].argument)} rad');
            }
            _result = lines.join('\n');
            _extra = '';
            _resultPoint = valid.first;
            break;
          case 'conj':
            final lines = valid
                .map((z) => z.conjugate.toString())
                .toList();
            _result = lines.join('  ;  ');
            _extra = 'Conjugués';
            _resultPoint = valid.first.conjugate;
            break;
          default:
            _result = 'Opération inconnue';
        }
      } catch (e) {
        _result = 'Erreur : $e';
        _extra = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nombres complexes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: () {
              setState(() {
                _count = 2;
                for (final c in _ctrls) {
                  c.dispose();
                }
                _rebuildCtrls();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                const Text('Nombre de complexes :'),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _count,
                  items: [1, 2, 3, 4, 5, 6]
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text('$e')))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      for (final c in _ctrls) {
                        c.dispose();
                      }
                      _count = v;
                      _rebuildCtrls();
                      _result = '';
                      _points = [];
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _count,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: _ctrls[i],
                  decoration: InputDecoration(
                    labelText: 'z${i + 1}  (ex: 3+4i ou 2cis(π/3))',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final op in ['+', '−', '×', '÷', '|z|', 'conj'])
                ActionChip(
                  label: Text(op),
                  onPressed: () => _compute(op),
                ),
            ],
          ),
          if (_result.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_result,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      if (_extra.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(_extra),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: CustomPaint(
                painter: _ComplexPlanePainter(
                  points: _points,
                  result: _resultPoint,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComplexPlanePainter extends CustomPainter {
  final List<ComplexNumber> points;
  final ComplexNumber? result;

  _ComplexPlanePainter({required this.points, this.result});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = math.min(size.width, size.height) / 12;

    final axis = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), axis);
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), axis);

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.brown,
    ];

    for (var i = 0; i < points.length; i++) {
      final z = points[i];
      final p = Offset(cx + z.real * scale, cy - z.imag * scale);
      canvas.drawLine(
          Offset(cx, cy), p, Paint()..color = colors[i % colors.length]);
      canvas.drawCircle(p, 6, Paint()..color = colors[i % colors.length]);
    }

    if (result != null) {
      final p =
          Offset(cx + result!.real * scale, cy - result!.imag * scale);
      canvas.drawCircle(p, 8, Paint()..color = Colors.red);
    }
  }

  @override
  bool shouldRepaint(covariant _ComplexPlanePainter old) => true;
}
