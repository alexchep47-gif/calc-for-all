import 'dart:js_util' as js_util;
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// OCR web : délègue à `window.calcForAllOcr` (Tesseract.js si injecté).
/// Le manuscrit reste fragile sur le web ; privilégier mobile (ML Kit on-device).
class OcrService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> recognizeExpression({
    ImageSource source = ImageSource.camera,
    Object? script,
  }) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 100,
      maxWidth: 2400,
      maxHeight: 2400,
    );
    if (image == null) return null;

    final Uint8List bytes = await image.readAsBytes();
    if (bytes.isEmpty) return null;

    try {
      final hasFn = js_util.hasProperty(js_util.globalThis, 'calcForAllOcr');
      if (!hasFn) {
        return null;
      }
      final promise = js_util.callMethod<dynamic>(
        js_util.globalThis,
        'calcForAllOcr',
        <Object>[bytes, 'fra'],
      );
      final raw = await js_util.promiseToFuture<Object?>(promise);
      final text = raw?.toString().trim() ?? '';
      if (text.isEmpty) return null;
      return _normalizeMathText(text);
    } catch (_) {
      return null;
    }
  }

  String _normalizeMathText(String text) {
    var s = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final map = <String, String>{
      '×': '*',
      '·': '*',
      '÷': '/',
      '−': '-',
      '–': '-',
      '—': '-',
      '²': '^2',
      '³': '^3',
      '√': 'sqrt',
      'π': 'pi',
      'Π': 'pi',
      '≤': '<=',
      '≥': '>=',
      '≠': '!=',
      '∞': 'inf',
      ',': '.',
    };

    s = s.replaceAllMapped(RegExp(r'[×·÷−–—²³√πΠ≤≥≠∞]'), (m) {
      return map[m.group(0)!] ?? m.group(0)!;
    });

    s = s.replaceAllMapped(RegExp(r'(?<=\d)\s*([a-zA-Z])'), (m) => '*${m.group(1)}');
    s = s.replaceAllMapped(RegExp(r'(?<=[a-zA-Z)])\s*(\d)'), (m) => '*${m.group(1)}');
    s = s.replaceAllMapped(RegExp(r'(?i)\b(sin|cos|tan|ln|log|exp|sqrt)\s*\(([^)]*)\)'),
        (m) => '${m.group(1)!.toLowerCase()}(${m.group(2)!})');

    s = s.replaceAll(RegExp(r'\bO\b', caseSensitive: false), '0');
    s = s.replaceAll(RegExp(r'\bI\b', caseSensitive: false), '1');
    s = s.replaceAll(RegExp(r'\bS\b', caseSensitive: false), '5');
    s = s.replaceAll(RegExp(r'\bZ\b', caseSensitive: false), '2');

    final replacements = <String, String>{
      'sinx': 'sin(x)',
      'cosx': 'cos(x)',
      'tanx': 'tan(x)',
      'lnx': 'ln(x)',
      'logx': 'log(x)',
      'sqrtx': 'sqrt(x)',
      'x2': 'x^2',
      'x3': 'x^3',
    };
    final lower = s.toLowerCase();
    for (final e in replacements.entries) {
      if (lower.contains(e.key)) {
        s = s.replaceAll(RegExp(e.key, caseSensitive: false), e.value);
      }
    }

    return s.trim();
  }
}


































































































































































