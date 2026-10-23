import 'dart:js_util' as js_util;
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class OcrService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> recognizeExpression({ImageSource source = ImageSource.camera}) async {
    final image = await _picker.pickImage(source: source, imageQuality: 95);
    if (image == null) return null;

    final Uint8List bytes = await image.readAsBytes();
    if (bytes.isEmpty) return null;

    final promise = js_util.callMethod<dynamic>(
      js_util.globalThis,
      'calcForAllOcr',
      <Object>[bytes],
    );
    final raw = await js_util.promiseToFuture<Object?>(promise);
    final text = raw?.toString().trim() ?? '';
    return text.isEmpty ? null : _normalizeMathText(text);
  }

  String _normalizeMathText(String text) {
    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.isEmpty ? '' : cleaned;
  }
}

