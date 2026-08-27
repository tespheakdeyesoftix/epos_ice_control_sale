import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/services/note_preset_repository.dart';
import 'package:ice_control_sale/shared/text_input_dialog_widget.dart';

class _MemoryPresetRepository implements NotePresetRepository {
  final Map<String, List<String>> values = {};
  final List<String> loadedKeys = [];
  final List<String> savedKeys = [];

  String _key(String userKey, String presetKey) => '$userKey::$presetKey';

  @override
  Future<List<String>> load({
    required String userKey,
    required String presetKey,
  }) async {
    final key = _key(userKey, presetKey);
    loadedKeys.add(key);
    return List.of(values[key] ?? const []);
  }

  @override
  Future<List<String>> save({
    required String userKey,
    required String presetKey,
    required String note,
  }) async {
    final key = _key(userKey, presetKey);
    savedKeys.add(key);
    final current = values[key] ?? const [];
    values[key] = [
      note,
      ...current.where((value) => value != note),
    ].take(NotePresetRepository.maximumNotes).toList();
    return List.of(values[key]!);
  }

  @override
  Future<List<String>> remove({
    required String userKey,
    required String presetKey,
    required String note,
  }) async {
    final key = _key(userKey, presetKey);
    values[key] = (values[key] ?? const [])
        .where((value) => value != note)
        .toList();
    return List.of(values[key]!);
  }
}

Widget _testApp({
  required _MemoryPresetRepository repository,
  String? userKey,
  String? presetKey,
  ValueChanged<String?>? onResult,
  bool allowDeletingSavedValues = false,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          key: const ValueKey('open-dialog'),
          onPressed: () async {
            final result = await showTextInputDialog(
              context,
              title: 'Plate number',
              userKey: userKey,
              presetKey: presetKey,
              presetRepository: repository,
              allowDeletingSavedValues: allowDeletingSavedValues,
            );
            onResult?.call(result);
          },
          child: const Text('Open'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('existing callers do not load or save remembered values', (
    tester,
  ) async {
    final repository = _MemoryPresetRepository();
    String? result;
    await tester.pumpWidget(
      _testApp(repository: repository, onResult: (value) => result = value),
    );

    await tester.tap(find.byKey(const ValueKey('open-dialog')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('text-input-dialog-input')),
      ' 2AB-1234 ',
    );
    await tester.tap(find.byKey(const ValueKey('confirm-text-input-dialog')));
    await tester.pumpAndSettle();

    expect(result, '2AB-1234');
    expect(repository.loadedKeys, isEmpty);
    expect(repository.savedKeys, isEmpty);
    expect(find.byType(InputChip), findsNothing);
  });

  testWidgets('loads and saves values under the selected driver key', (
    tester,
  ) async {
    final repository = _MemoryPresetRepository()
      ..values['user-1::driver_plate_number::DRIVER-001'] = ['2AB-1234']
      ..values['user-1::driver_plate_number::DRIVER-002'] = ['2CD-5678'];
    String? result;
    await tester.pumpWidget(
      _testApp(
        repository: repository,
        userKey: 'user-1',
        presetKey: 'driver_plate_number::DRIVER-001',
        onResult: (value) => result = value,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open-dialog')));
    await tester.pumpAndSettle();

    expect(find.text('2AB-1234'), findsOneWidget);
    expect(find.text('2CD-5678'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('text-input-preset-2AB-1234')));
    await tester.tap(find.byKey(const ValueKey('confirm-text-input-dialog')));
    await tester.pumpAndSettle();

    expect(result, '2AB-1234');
    expect(repository.loadedKeys, ['user-1::driver_plate_number::DRIVER-001']);
    expect(repository.savedKeys, ['user-1::driver_plate_number::DRIVER-001']);
  });

  testWidgets('can delete a remembered plate number', (tester) async {
    final repository = _MemoryPresetRepository()
      ..values['user-1::driver_plate_number::DRIVER-001'] = ['2AB-1234'];
    await tester.pumpWidget(
      _testApp(
        repository: repository,
        userKey: 'user-1',
        presetKey: 'driver_plate_number::DRIVER-001',
        allowDeletingSavedValues: true,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open-dialog')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('toggle-text-input-manage-mode')),
    );
    await tester.pump();
    final chip = tester.widget<InputChip>(find.byType(InputChip));
    chip.onDeleted!();
    await tester.pumpAndSettle();

    expect(find.text('2AB-1234'), findsNothing);
    expect(
      repository.values['user-1::driver_plate_number::DRIVER-001'],
      isEmpty,
    );
  });
}
