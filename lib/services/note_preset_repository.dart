import 'package:get_storage/get_storage.dart';

abstract interface class NotePresetRepository {
  static const containerName = 'note_presets';
  static const maximumNotes = 20;

  Future<List<String>> load({
    required String userKey,
    required String presetKey,
  });

  Future<List<String>> save({
    required String userKey,
    required String presetKey,
    required String note,
  });

  Future<List<String>> remove({
    required String userKey,
    required String presetKey,
    required String note,
  });
}

class GetStorageNotePresetRepository implements NotePresetRepository {
  GetStorageNotePresetRepository({GetStorage? storage})
    : _storage = storage ?? GetStorage(NotePresetRepository.containerName);

  final GetStorage _storage;

  @override
  Future<List<String>> load({
    required String userKey,
    required String presetKey,
  }) async {
    return _read(userKey: userKey, presetKey: presetKey);
  }

  @override
  Future<List<String>> save({
    required String userKey,
    required String presetKey,
    required String note,
  }) async {
    final normalized = note.trim();
    final notes = _read(userKey: userKey, presetKey: presetKey);
    if (normalized.isEmpty || notes.contains(normalized)) return notes;
    final updated = [
      normalized,
      ...notes,
    ].take(NotePresetRepository.maximumNotes).toList(growable: false);
    await _storage.write(_key(userKey, presetKey), updated);
    return updated;
  }

  @override
  Future<List<String>> remove({
    required String userKey,
    required String presetKey,
    required String note,
  }) async {
    final notes = _read(userKey: userKey, presetKey: presetKey);
    final updated = notes.where((item) => item != note).toList(growable: false);
    await _storage.write(_key(userKey, presetKey), updated);
    return updated;
  }

  List<String> _read({required String userKey, required String presetKey}) {
    final stored = _storage.read<dynamic>(_key(userKey, presetKey));
    if (stored is! List) return const [];
    final notes = <String>[];
    for (final value in stored) {
      if (value is! String) continue;
      final note = value.trim();
      if (note.isEmpty || notes.contains(note)) continue;
      notes.add(note);
      if (notes.length == NotePresetRepository.maximumNotes) break;
    }
    return List<String>.unmodifiable(notes);
  }

  String _key(String userKey, String presetKey) =>
      'note_presets::${userKey.trim()}::${presetKey.trim()}';
}
