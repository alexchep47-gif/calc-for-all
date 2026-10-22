import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Filigrane « Powered by Calc for all » — fond gris, inclinaison 45°
class ExportWatermark {
  static const text = 'Powered by Calc for all';

  /// Dessine le filigrane en diagonale sur un canvas Flutter
  static void paintOnCanvas(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.grey.withOpacity(0.18),
          fontSize: math.min(size.width, size.height) * 0.07,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-math.pi / 4); // 45°
    for (var dy = -size.height; dy < size.height * 1.5; dy += tp.height * 3.5) {
      for (var dx = -size.width; dx < size.width * 1.5; dx += tp.width * 1.4) {
        tp.paint(canvas, Offset(dx - tp.width / 2, dy - tp.height / 2));
      }
    }
    canvas.restore();
  }

  /// Ajoute le filigrane à une image PNG (bytes)
  static Future<Uint8List> applyToPng(Uint8List pngBytes) async {
    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    final src = frame.image;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(src.width.toDouble(), src.height.toDouble());
    canvas.drawImage(src, Offset.zero, Paint());
    paintOnCanvas(canvas, size);
    final picture = recorder.endRecording();
    final out = await picture.toImage(src.width, src.height);
    final bd = await out.toByteData(format: ui.ImageByteFormat.png);
    src.dispose();
    out.dispose();
    return bd!.buffer.asUint8List();
  }

  /// Widget PDF de fond (filigrane)
  static pw.Widget pdfBackground(PdfPageFormat format) {
    return pw.FullPage(
      ignoreMargins: true,
      child: pw.Center(
        child: pw.Transform.rotate(
          angle: -math.pi / 4,
          child: pw.Text(
            text,
            style: pw.TextStyle(
              color: PdfColor.fromInt(0xFFB0B0B0),
              fontSize: 28,
            ),
          ),
        ),
      ),
    );
  }

  static List<pw.Widget> pdfWatermarkStack(List<pw.Widget> children) {
    return [
      pw.Stack(
        children: [
          pw.Positioned.fill(
            child: pw.Center(
              child: pw.Transform.rotate(
                angle: -math.pi / 4,
                child: pw.Opacity(
                  opacity: 0.15,
                  child: pw.Text(
                    text,
                    style: const pw.TextStyle(fontSize: 32),
                  ),
                ),
              ),
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: children,
          ),
        ],
      ),
    ];
  }
}
