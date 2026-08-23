import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

Document noteDocumentFromHtml(String html) {
  final source = html.trim();
  if (source.isEmpty) return Document();
  try {
    return Document.fromDelta(HtmlToDelta().convert(source));
  } on Object {
    return Document()..insert(0, _stripMarkup(source));
  }
}

String noteDocumentToHtml(Document document) {
  final operations = document
      .toDelta()
      .toJson()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
  final body = QuillDeltaToHtmlConverter(operations).convert();
  return '<div class="ql-editor read-mode">$body</div>';
}

String notePlainText(String html) {
  final source = html.trim();
  if (source.isEmpty) return '';
  try {
    return noteDocumentFromHtml(source).toPlainText().trim();
  } on Object {
    return _stripMarkup(source).trim();
  }
}

String _stripMarkup(String value) => value
    .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
    .replaceAll(RegExp(r'</(?:p|div|li|h[1-6])>', caseSensitive: false), '\n')
    .replaceAll(RegExp(r'<[^>]+>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>');
