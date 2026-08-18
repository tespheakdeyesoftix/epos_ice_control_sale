import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ice_control_sale/services/note_preset_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const containerName = 'note_preset_repository_test';
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory storageDirectory;
  late GetStorage storage;
  late GetStorageNotePresetRepository repository;

  setUpAll(() async {
    storageDirectory = await Directory.systemTemp.createTemp(
      'note-preset-repository-test-',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          pathProviderChannel,
          (_) async => storageDirectory.path,
        );
    await GetStorage.init(containerName);
    storage = GetStorage(containerName);
    repository = GetStorageNotePresetRepository(storage: storage);
  });

  tearDownAll(() async {
    await storage.erase();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  setUp(() async {
    await storage.erase();
  });

  test('isolates notes by user and preset key', () async {
    await repository.save(
      userKey: 'user-1',
      presetKey: 'delete_bill_note',
      note: 'note-a',
    );

    expect(
      await repository.load(userKey: 'user-1', presetKey: 'delete_bill_note'),
      ['note-a'],
    );
    expect(
      await repository.load(userKey: 'user-2', presetKey: 'delete_bill_note'),
      isEmpty,
    );
    expect(
      await repository.load(userKey: 'user-1', presetKey: 'another_note'),
      isEmpty,
    );
  });

  test('keeps newest 20 notes and ignores exact duplicates', () async {
    for (var index = 1; index <= 21; index++) {
      await repository.save(
        userKey: 'user-1',
        presetKey: 'delete_bill_note',
        note: ' note-$index ',
      );
    }
    await repository.save(
      userKey: 'user-1',
      presetKey: 'delete_bill_note',
      note: 'note-21',
    );

    final notes = await repository.load(
      userKey: 'user-1',
      presetKey: 'delete_bill_note',
    );
    expect(notes, hasLength(20));
    expect(notes.first, 'note-21');
    expect(notes.last, 'note-2');
    expect(notes.where((note) => note == 'note-21'), hasLength(1));
  });

  test('ignores malformed, empty, and duplicate stored values', () async {
    await storage.write('note_presets::user-1::delete_bill_note', [
      ' valid ',
      '',
      42,
      'valid',
      null,
    ]);

    expect(
      await repository.load(userKey: 'user-1', presetKey: 'delete_bill_note'),
      ['valid'],
    );
  });
}
