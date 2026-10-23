import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> recognizeExpression({ImageSource source = ImageSource.camera}) async {
    final image = await _picker.pickImage(source: source, imageQuality: 95);
    if (image == null || image.path.isEmpty) return null;

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(image.path));
      final text = result.text.trim();
      return text.isEmpty ? null : _normalizeMathText(text);
    } finally {
      await recognizer.close();
    }
  }

  String _normalizeMathText(String text) => text
      .replaceAll(RegExp(r'[\n\r]+'), '')
      .replaceAll('×', '*')
      .replaceAll('·', '*')
      .replaceAll('÷', '/')
      .replaceAll('−', '-')
      .replaceAll('²', '^2')
      .replaceAll('³', '^3')
      .replaceAll('O', '0')
      .replaceAll('l', '1')
      .replaceAll(' ', '');
}
