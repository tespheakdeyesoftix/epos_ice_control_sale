import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' as fw;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../app/app_theme.dart';

/// Shapes receipt text with Flutter before embedding it in the PDF.
///
/// The Dart PDF package does not currently apply the OpenType shaping needed
/// by Khmer. Flutter uses HarfBuzz, so rasterizing only the text preserves the
/// correct Khmer clusters while PDF borders and barcodes remain vector-based.
class ReceiptRasterText {
  const ReceiptRasterText._();

  static Future<void>? _fontLoad;

  static Future<pw.Widget> create(
    String text, {
    double fontSize = 8,
    pw.FontWeight fontWeight = pw.FontWeight.normal,
    PdfColor color = PdfColors.black,
    pw.TextAlign textAlign = pw.TextAlign.left,
    double? maxWidth,
    double lineHeight = 1.25,
    double scale = 4,
  }) async {
    if (text.isEmpty) return pw.SizedBox();
    await (_fontLoad ??= _loadFont());

    final painter = fw.TextPainter(
      text: fw.TextSpan(
        text: text,
        style: fw.TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: fontSize,
          fontWeight: fontWeight == pw.FontWeight.bold
              ? fw.FontWeight.w700
              : fw.FontWeight.w400,
          color: fw.Color.fromARGB(
            (color.alpha * 255).round(),
            (color.red * 255).round(),
            (color.green * 255).round(),
            (color.blue * 255).round(),
          ),
          height: lineHeight,
        ),
      ),
      textAlign: _flutterTextAlign(textAlign),
      textDirection: ui.TextDirection.ltr,
      textWidthBasis: fw.TextWidthBasis.longestLine,
    )..layout(maxWidth: maxWidth ?? double.infinity);

    final logicalWidth = painter.width.ceil().clamp(1, 100000).toDouble();
    final logicalHeight = painter.height.ceil().clamp(1, 100000).toDouble();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)..scale(scale, scale);
    painter.paint(canvas, ui.Offset.zero);
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (logicalWidth * scale).ceil(),
      (logicalHeight * scale).ceil(),
    );
    picture.dispose();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) throw StateError('Unable to render receipt text.');

    return pw.Image(
      pw.MemoryImage(data.buffer.asUint8List()),
      width: logicalWidth,
      height: logicalHeight,
    );
  }

  static Future<void> _loadFont() async {
    final loader = FontLoader(AppTheme.fontFamily)
      ..addFont(rootBundle.load('assets/fonts/NotoSansKhmer-Variable.ttf'));
    await loader.load();
  }

  static fw.TextAlign _flutterTextAlign(pw.TextAlign value) {
    return switch (value) {
      pw.TextAlign.right => fw.TextAlign.right,
      pw.TextAlign.center => fw.TextAlign.center,
      pw.TextAlign.justify => fw.TextAlign.justify,
      pw.TextAlign.end => fw.TextAlign.end,
      pw.TextAlign.start => fw.TextAlign.start,
      pw.TextAlign.left => fw.TextAlign.left,
    };
  }
}
