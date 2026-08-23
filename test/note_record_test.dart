import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/features/notes/note_html.dart';
import 'package:ice_control_sale/features/notes/note_record.dart';

void main() {
  test('NoteRecord parses flags, dates, and optional values', () {
    final note = NoteRecord.fromJson({
      'name': 'NOTE 1',
      'title': 'Reminder',
      'content': '<p>Hello</p>',
      'custom_color': '#FFF2B2',
      'custom_outlet': 'Outlet A',
      'custom_is_pin': '1',
      'custom_notify_on': '2026-08-21',
      'modified': '2026-08-21 10:30:00',
    });

    expect(note.isPinned, isTrue);
    expect(note.notifyOn, DateTime(2026, 8, 21));
    expect(note.modified, DateTime(2026, 8, 21, 10, 30));
    expect(note.owner, isEmpty);
  });

  test('NoteRecord tolerates malformed optional values', () {
    final note = NoteRecord.fromJson({
      'custom_is_pin': 'false',
      'custom_notify_on': 'not-a-date',
      'modified': '',
    });

    expect(note.isPinned, isFalse);
    expect(note.notifyOn, isNull);
    expect(note.modified, isNull);
  });

  test('Note HTML round trip keeps supported formatting and plain text', () {
    final document = noteDocumentFromHtml(
      '<div class="ql-editor read-mode"><p>Hello <strong>world</strong></p></div>',
    );
    final html = noteDocumentToHtml(document);

    expect(notePlainText(html), 'Hello world');
    expect(html, contains('<strong>world</strong>'));
    expect(html, startsWith('<div class="ql-editor read-mode">'));
  });

  test('noteDateValue emits Frappe date format', () {
    expect(noteDateValue(DateTime(2026, 2, 3)), '2026-02-03');
  });

  test('parses native Frappe tags without leading commas or duplicates', () {
    final note = NoteRecord.fromJson({
      '_user_tags': ',urgent,Follow Up,URGENT',
    });

    expect(note.tags, ['urgent', 'Follow Up']);
    expect(parseNoteTags(['#Sales', ' sales ', '', '#Today']), [
      'Sales',
      'Today',
    ]);
  });
}
