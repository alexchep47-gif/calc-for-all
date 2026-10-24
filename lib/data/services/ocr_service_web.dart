import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// OCR / HTR hors ligne via ML Kit (modèle on-device, script latin).
/// Pour le manuscrit, préfère un contraste fort, une seule ligne, photo nette.
class OcrService {
  final ImagePicker _picker = ImagePicker();

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

  String _normalizeMathText(String text) {
    var s = text
        .replaceAll('\u00A0', ' ')
        .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

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
      '∫': 'integral',
      '≤': '<=',
      '≥': '>=',
      '≠': '!=',
      '∞': 'inf',
      '…': '...',
      '’': "'",
      '“': '"',
      '”': '"',
      ',': '.',
    };

    s = s.replaceAllMapped(RegExp(r'[×·÷−–—²³√πΠ∫≤≥≠∞…’“”]'), (Match m) {
      return map[m.group(0)!] ?? m.group(0)!;
    });

    s = s.replaceAllMapped(
      RegExp(r'(?<=\d)\s*([a-zA-Z])'),
      (Match m) => '*${m.group(1)}',
    );
    s = s.replaceAllMapped(
      RegExp(r'(?<=[a-zA-Z)])\s*(\d)'),
      (Match m) => '*${m.group(1)}',
    );
    s = s.replaceAllMapped(
      RegExp(r'(?i)\b(sin|cos|tan|ln|log|exp|sqrt)\s*\(([^)]*)\)'),
      (Match m) => '${m.group(1)!.toLowerCase()}(${m.group(2)!})',
    );

    s = s.replaceAllMapped(
      RegExp(r'(?i)\b(sin|cos|tan|ln|log|exp|sqrt)\s*([a-zA-Z0-9(])'),
      (Match m) => '${m.group(1)!.toLowerCase()}(${m.group(2)!}',
    );

    s = s.replaceAll(RegExp(r'\bO\b', caseSensitive: false), '0');
    s = s.replaceAll(RegExp(r'\bI\b', caseSensitive: false), '1');
    s = s.replaceAll(RegExp(r'\bS\b', caseSensitive: false), '5');
    s = s.replaceAll(RegExp(r'\bZ\b', caseSensitive: false), '2');
    s = s.replaceAll(RegExp(r'\bG\b', caseSensitive: false), '6');

    s = s.replaceAllMapped(
      RegExp(r'(?i)\b(sinx|cosx|tanx|lnx|logx)\b'),
      (Match m) {
        final f = m.group(0)!.toLowerCase();
        final name = f.substring(0, f.length - 1);
        return '$name(x)';
      },
    );

    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

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
      'pi)': 'pi)',
      'sqrt)': 'sqrt)',
      'sqrtx': 'sqrt(x)',
      'sqr': 'sqrt',
      'e^x': 'exp(x)',
      'build': '',
    };

    final lower = s.toLowerCase();
    for (final e in replacements.entries) {
      if (lower.contains(e.key)) {
        s = s.replaceAll(RegExp(e.key, caseSensitive: false), e.value);
      }
    }

    s = s.replaceAllMapped(
      RegExp(r'(?<![A-Za-z])x\s*\^\s*(\d)'),
      (Match m) => 'x^${m.group(1)}',
    );
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }
}
