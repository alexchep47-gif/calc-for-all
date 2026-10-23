import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// OCR / HTR hors ligne via ML Kit (modèle on-device, script latin).
/// Pour le manuscrit, préfère un contraste fort, une seule ligne, photo nette.
class OcrService {
  final ImagePicker _picker = ImagePicker();

  /// [script] : latin (FR/EN), chinese, japanese, korean, devanagari
  Future<String?> recognizeExpression({
    ImageSource source = ImageSource.camera,
    TextRecognitionScript script = TextRecognitionScript.latin,
  }) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 100,
      maxWidth: 2400,
      maxHeight: 2400,
    );
    if (image == null || image.path.isEmpty) return null;

    final recognizer = TextRecognizer(script: script);
    try {
      final input = InputImage.fromFilePath(image.path);
      final result = await recognizer.processImage(input);

      // Préférer les blocs / lignes les plus confiants
      final lines = <String>[];
      for (final block in result.blocks) {
        for (final line in block.lines) {
          final t = line.text.trim();
          if (t.isNotEmpty) lines.add(t);
        }
      }
      var text = lines.isNotEmpty ? lines.join(' ') : result.text.trim();
      if (text.isEmpty) return null;

      text = _normalizeMathText(text);
      text = _dictionaryCorrect(text);
      return text.isEmpty ? null : text;
    } finally {
      await recognizer.close();
    }
  }

  /// Nettoyage math : caractères confondus OCR / manuscrit
  String _normalizeMathText(String text) {
    var s = text;
    // Substitutions OCR fréquentes pour formules
    const map = {
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
      '∫': 'integral',
      '≤': '<=',
      '≥': '>=',
      '≠': '!=',
      '∞': 'inf',
      'O': '0',
      'o': '0',
      'l': '1',
      'I': '1',
      'S': '5',
      ',': '.',
    };
    // Appliquer seulement hors mots alphabétiques longs
    s = s.replaceAllMapped(RegExp(r'[×·÷−–—²³√πΠ∫≤≥≠∞]'), (m) {
      return map[m.group(0)!] ?? m.group(0)!;
    });
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// Mini-dictionnaire contextuel (FR/EN maths) pour corriger des erreurs évidentes
  String _dictionaryCorrect(String text) {
    var s = text;
    final replacements = <String, String>{
      'sinx': 'sin(x)',
      'cosx': 'cos(x)',
      'tanx': 'tan(x)',
      'lnx': 'ln(x)',
      'logx': 'log(x)',
      '5qrt': 'sqrt',
      '5in': 'sin',
      'c0s': 'cos',
      't4n': 'tan',
      'xn': 'x^n',
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
