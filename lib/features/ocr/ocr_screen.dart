import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/locale_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../data/services/ocr_service.dart';

/// Lecture d’expressions : OCR imprimé + conseils HTR manuscrit (on-device).
class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  final OcrService _ocrService = OcrService();
  bool _isBusy = false;
  String _text = '';
  String _error = '';
  String _langHint = 'fr'; // fr | en

  Future<void> _scanFrom(ImageSource source) async {
    setState(() {
      _isBusy = true;
      _error = '';
      _text = '';
    });
    try {
      final text = await _ocrService.recognizeExpression(source: source);
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _text = text ?? '';
        if (_text.isEmpty) {
          _error = kIsWeb
              ? (_langHint == 'fr'
                  ? 'Aucun texte détecté. Sur le web, le manuscrit est peu fiable. '
                      'Utilisez une photo nette d’écriture imprimée, ou l’app mobile (modèle hors ligne).'
                  : 'No text detected. Handwriting is unreliable on web. '
                      'Use a sharp photo of printed text, or the mobile app (on-device model).')
              : (_langHint == 'fr'
                  ? 'Aucun texte lisible. Pour le manuscrit : contraste élevé, une ligne, '
                      'écriture large, bonne lumière. Le modèle hors ligne (latin) est optimisé '
                      'pour l’imprimé ; le manuscrit reste approximatif.'
                  : 'No readable text. For handwriting: high contrast, single line, '
                      'large writing, good light. The offline model works best on print.');
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _error = _langHint == 'fr'
            ? 'Échec de la lecture. Vérifiez l’image (format, netteté). '
                'Le texte manuscrit nécessite souvent plusieurs essais.'
            : 'Read failed. Check the image (format, sharpness). '
                'Handwriting often needs several tries.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final isFr = locale.isFrench;
    _langHint = isFr ? 'fr' : 'en';

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
                      ? 'Hors ligne (mobile) : modèle on-device latin.\n'
                          'Manuscrit : photo nette, contraste fort, une expression par image.\n'
                          'Langue du document : alignée sur la langue de l’app (FR/EN) '
                          'pour le dictionnaire de correction.'
                      : 'Offline (mobile): on-device Latin model.\n'
                          'Handwriting: sharp photo, strong contrast, one expression per image.\n'
                          'Document language follows app language (FR/EN) for corrections.',
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
                  child: Text(_error, style: const TextStyle(height: 1.4)),
                ),
              )
            else if (_text.isNotEmpty) ...[
              Text(
                isFr ? 'Texte reconnu' : 'Recognized text',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SelectableText(
                _text,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(isFr ? 'Copié' : 'Copied')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: Text(isFr ? 'Copier' : 'Copy'),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.calculator);
                    },
                    icon: const Icon(Icons.calculate),
                    label: Text(isFr ? 'Ouvrir calculatrice' : 'Open calculator'),
                  ),
                ],
              ),
            ] else
              Text(
                isFr
                    ? 'Choisissez une image d’équation ou de formule.'
                    : 'Pick an image of an equation or formula.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
          ],
        ),
      ),
    );
  }
}
