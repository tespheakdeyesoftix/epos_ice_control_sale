import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/shared/note_dialog_widget.dart';

void main() {
  testWidgets('requires a note and sends the entered note to callback', (
    tester,
  ) async {
    String? submittedNote;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showNoteDialog(
                context,
                promptTitle: 'មូលហេតុដែលលុបបុង',
                onSubmit: (note) {
                  submittedNote = note;
                  return true;
                },
              ),
              child: const Text('បើក'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('បើក'));
    await tester.pumpAndSettle();
    expect(find.text('មូលហេតុដែលលុបបុង'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('confirm-note-dialog')));
    await tester.pump();
    expect(find.text('សូមបញ្ចូលកំណត់ចំណាំ'), findsOneWidget);
    expect(submittedNote, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('note-dialog-input')),
      ' បញ្ចូលខុស ',
    );
    await tester.tap(find.byKey(const ValueKey('confirm-note-dialog')));
    await tester.pumpAndSettle();

    expect(submittedNote, 'បញ្ចូលខុស');
    expect(find.byType(NoteDialogWidget), findsNothing);
  });
}
