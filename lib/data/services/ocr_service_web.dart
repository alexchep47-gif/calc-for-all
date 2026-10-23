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
        // Fallback : pas de moteur JS → message clair côté UI
        return null;
      }
      final promise = js_util.callMethod<dynamic>(
        js_util.globalThis,
        'calcForAllOcr',
        <Object>[bytes, 'fra'], // langue FR par défaut pour le dictionnaire
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
    s = s
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll('π', 'pi')
        .replaceAll('²', '^2')
        .replaceAll('³', '^3');
    return s;
  }
}
