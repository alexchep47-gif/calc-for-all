import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/locale_provider.dart';

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  bool _isBusy = false;
  String _text = '';
  String _error = '';

  Future<void> _scanFrom(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      setState(() {
        _isBusy = true;
        _error = '';
        _text = '';
      });

      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (!mounted) return;

      setState(() {
        _isBusy = false;
        _text = recognizedText.text.trim();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _error = 'OCR non disponible ou image invalide';
      });
    }
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isBusy ? null : () => _scanFrom(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(isFr ? 'Galerie' : 'Gallery'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isBusy ? null : () => _scanFrom(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text(isFr ? 'Caméra' : 'Camera'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isBusy)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error.isNotEmpty)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),
                )
              else if (_text.isNotEmpty)
                Expanded(
                  child: Card(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        _text,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Text(
                      isFr
                          ? 'Sélectionnez une image pour lire le texte hors ligne.'
                          : 'Select an image to read text offline.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

