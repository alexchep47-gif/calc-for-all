import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/locale_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../data/services/calculator_service.dart';
import '../../data/services/ocr_service.dart';

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  final OcrService _ocrService = OcrService();
  final CalculatorService _calc = CalculatorService();
  bool _isBusy = false;
  String _text = '';
  String _error = '';
  String _calcResult = '';

  Future<void> _scanFrom(ImageSource source) async {
    setState(() {
      _isBusy = true;
      _error = '';
      _text = '';
      _calcResult = '';
    });
    try {
      final text = await _ocrService.recognizeExpression(source: source);
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _text = text ?? '';
        if (_text.isEmpty) {
          _error = kIsWeb
              ? 'Aucun texte détecté. Photo nette d’écriture imprimée recommandée.'
              : 'Aucun texte lisible. Pour le manuscrit : contraste élevé, une ligne.';
        } else {
          _calcResult = _calc.evaluate(_text);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _error = 'Échec de la lecture. Vérifiez l’image.';
      });
    }
  }

  void _sendToCalculator() {
    if (_text.isEmpty) return;
    Navigator.pushNamed(
      context,
      AppRoutes.calculator,
      arguments: _text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final isFr = locale.isFrench;

    return Scaffold(
      appBar: AppBar(
        title: Text(isFr ? 'Lecture OCR' : 'OCR Reader'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  isFr
                      ? 'Le texte reconnu est évalué. S’il est calculable, le résultat s’affiche ; sinon : « Erreur mathématique ». Vous pouvez l’envoyer à la calculatrice.'
                      : 'Recognized text is evaluated. If valid, the result is shown; otherwise “Erreur mathématique”. You can send it to the calculator.',
                  style: const TextStyle(height: 1.4, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        _isBusy ? null : () => _scanFrom(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(isFr ? 'Galerie' : 'Gallery'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        _isBusy ? null : () => _scanFrom(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(isFr ? 'Caméra' : 'Camera'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isBusy)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error.isNotEmpty)
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(_error),
                ),
              )
            else if (_text.isNotEmpty) ...[
              Text(isFr ? 'Texte reconnu' : 'Recognized text',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SelectableText(_text,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Text(isFr ? 'Résultat' : 'Result',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                _calcResult,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _calcResult == CalculatorService.mathError
                      ? Colors.red.shade700
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _text));
                    },
                    icon: const Icon(Icons.copy),
                    label: Text(isFr ? 'Copier' : 'Copy'),
                  ),
                  FilledButton.icon(
                    onPressed: _sendToCalculator,
                    icon: const Icon(Icons.calculate),
                    label: Text(isFr
                        ? 'Envoyer à la calculatrice'
                        : 'Send to calculator'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
