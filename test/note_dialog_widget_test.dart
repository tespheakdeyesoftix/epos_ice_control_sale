import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/services/note_preset_repository.dart';
import 'package:ice_control_sale/shared/note_dialog_widget.dart';

class _MemoryNotePresetRepository implements NotePresetRepository {
  final Map<String, List<String>> values = {};
  bool failSave = false;

  String _key(String userKey, String presetKey) => '$userKey::$presetKey';

  @override
  Future<List<String>> load({
    required String userKey,
    required String presetKey,
  }) async => List.of(values[_key(userKey, presetKey)] ?? const []);

  @override
  Future<List<String>> save({
    required String userKey,
    required String presetKey,
    required String note,
  }) async {
    if (failSave) throw Exception('storage failed');
    final key = _key(userKey, presetKey);
    final current = values[key] ?? const [];
    if (!current.contains(note)) {
      values[key] = [
        note,
        ...current,
      ].take(NotePresetRepository.maximumNotes).toList();
    }
    return List.of(values[key] ?? const []);
  }

  @override
  Future<List<String>> remove({
    required String userKey,
    required String presetKey,
    required String note,
  }) async {
    final key = _key(userKey, presetKey);
    values[key] = (values[key] ?? const [])
        .where((item) => item != note)
        .toList();
    return List.of(values[key]!);
  }
}

Widget _testApp({
  required NotePresetRepository repository,
  required NoteSubmitCallback onSubmit,
  bool allowDeletingSavedNotes = false,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showNoteDialog(
            context,
            promptTitle: 'មូលហេតុដែលលុបបុង',
            presetKey: 'delete_bill_note',
            userKey: 'user-1',
            allowDeletingSavedNotes: allowDeletingSavedNotes,
            presetRepository: repository,
            onSubmit: onSubmit,
          ),
          child: const Text('បើក'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('requires a note and saves only after successful callback', (
    tester,
  ) async {
    final repository = _MemoryNotePresetRepository();
    String? submittedNote;
    await tester.pumpWidget(
      _testApp(
        repository: repository,
        onSubmit: (note) {
          submittedNote = note;
          return true;
        },
      ),
    );

    await tester.tap(find.text('បើក'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-note-dialog')));
    await tester.pump();
    expect(find.text('សូមបញ្ចូលកំណត់ចំណាំ'), findsWidgets);
    expect(submittedNote, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('note-dialog-input')),
      ' បញ្ចូលខុស ',
    );
    await tester.tap(find.byKey(const ValueKey('confirm-note-dialog')));
    await tester.pumpAndSettle();

    expect(submittedNote, 'បញ្ចូលខុស');
    expect(repository.values['user-1::delete_bill_note'], ['បញ្ចូលខុស']);
    expect(find.byType(NoteDialogWidget), findsNothing);
  });

  testWidgets('selecting a preset fills input without submitting', (
    tester,
  ) async {
    final repository = _MemoryNotePresetRepository()
      ..values['user-1::delete_bill_note'] = ['លេខបុងខុស'];
    var submitCount = 0;
    await tester.pumpWidget(
      _testApp(
        repository: repository,
        onSubmit: (_) {
          submitCount += 1;
          return true;
        },
      ),
    );

    await tester.tap(find.text('បើក'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('លេខបុងខុស'));
    await tester.pump();

    final input = tester.widget<TextFormField>(
      find.byKey(const ValueKey('note-dialog-input')),
    );
    final editableText = tester.widget<EditableText>(find.byType(EditableText));
    expect(input.controller!.text, 'លេខបុងខុស');
    expect(editableText.minLines, 2);
    expect(editableText.maxLines, 6);
    expect(submitCount, 0);
    expect(find.byType(NoteDialogWidget), findsOneWidget);
  });

  testWidgets('manage mode removes a saved preset', (tester) async {
    final repository = _MemoryNotePresetRepository()
      ..values['user-1::delete_bill_note'] = ['មិនត្រឹមត្រូវ'];
    await tester.pumpWidget(
      _testApp(
        repository: repository,
        allowDeletingSavedNotes: true,
        onSubmit: (_) => true,
      ),
    );

    await tester.tap(find.text('បើក'));
    await tester.pumpAndSettle();
    var chip = tester.widget<InputChip>(find.byType(InputChip));
    expect(chip.onDeleted, isNull);

    await tester.tap(find.byKey(const ValueKey('toggle-note-manage-mode')));
    await tester.pump();
    chip = tester.widget<InputChip>(find.byType(InputChip));
    expect(chip.onDeleted, isNotNull);
    chip.onDeleted!();
    await tester.pumpAndSettle();

    expect(find.text('មិនត្រឹមត្រូវ'), findsNothing);
    expect(repository.values['user-1::delete_bill_note'], isEmpty);
  });

  testWidgets('storage failure does not block successful dialog closure', (
    tester,
  ) async {
    final repository = _MemoryNotePresetRepository()..failSave = true;
    await tester.pumpWidget(
      _testApp(repository: repository, onSubmit: (_) => true),
    );

    await tester.tap(find.text('បើក'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('note-dialog-input')),
      'មូលហេតុ',
    );
    await tester.tap(find.byKey(const ValueKey('confirm-note-dialog')));
    await tester.pumpAndSettle();

    expect(find.byType(NoteDialogWidget), findsNothing);
  });

  testWidgets('failed business callback does not save the note', (
    tester,
  ) async {
    final repository = _MemoryNotePresetRepository();
    await tester.pumpWidget(
      _testApp(repository: repository, onSubmit: (_) => false),
    );

    await tester.tap(find.text('បើក'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('note-dialog-input')),
      'មិនត្រូវរក្សាទុក',
    );
    await tester.tap(find.byKey(const ValueKey('confirm-note-dialog')));
    await tester.pumpAndSettle();

    expect(repository.values['user-1::delete_bill_note'], isNull);
    expect(find.byType(NoteDialogWidget), findsOneWidget);
  });
}
