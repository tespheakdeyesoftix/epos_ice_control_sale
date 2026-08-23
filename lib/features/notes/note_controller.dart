import 'dart:async';

import 'package:get/get.dart';

import '../../app/session_outlet_controller.dart';
import '../../services/note_service.dart';
import 'note_html.dart';
import 'note_record.dart';

class NoteController extends GetxController {
  NoteController({required this.service, required this.outletController});

  final NoteService service;
  final SessionOutletController outletController;
  final pinnedNotes = <NoteRecord>[].obs;
  final notes = <NoteRecord>[].obs;
  final searchInput = ''.obs;
  final search = ''.obs;
  final dueTodayCount = 0.obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMoreRegularNotes = true.obs;
  final errorMessage = RxnString();
  final lastMutationError = RxnString();
  final savingNames = <String>{}.obs;
  late final Worker _outletWorker;
  late final Worker _searchWorker;
  int _requestGeneration = 0;
  int _nextRegularOffset = 0;

  static const pinLimitMessage = 'អាចខ្ទាស់កំណត់ចំណាំបានអតិបរមា ៥ ប៉ុណ្ណោះ។';

  String get outlet => outletController.currentOutlet.value;

  List<NoteRecord> _filter(Iterable<NoteRecord> source) {
    final keyword = search.value.trim().toLowerCase();
    if (keyword.isEmpty) return source.toList(growable: false);
    return source
        .where(
          (note) =>
              note.title.toLowerCase().contains(keyword) ||
              notePlainText(note.content).toLowerCase().contains(keyword) ||
              note.tags.any((tag) => tag.toLowerCase().contains(keyword)),
        )
        .toList(growable: false);
  }

  List<NoteRecord> get visiblePinnedNotes => _filter(pinnedNotes);

  List<NoteRecord> get visibleRegularNotes => _filter(notes);

  List<NoteRecord> get visibleNotes => [
    ...visiblePinnedNotes,
    ...visibleRegularNotes,
  ];

  @override
  void onInit() {
    super.onInit();
    _outletWorker = ever<String>(outletController.currentOutlet, (_) {
      load();
      loadDueTodayCount();
    });
    _searchWorker = debounce<String>(
      searchInput,
      (value) => search.value = value.trim(),
      time: const Duration(milliseconds: 1500),
    );
    load();
    loadDueTodayCount();
  }

  void updateSearch(String value) => searchInput.value = value;

  Future<void> loadDueTodayCount() async {
    try {
      dueTodayCount.value = await service.dueTodayCount(
        outlet: outlet,
        today: DateTime.now(),
      );
    } on Exception {
      // The badge is supplementary and must not interrupt normal navigation.
    }
  }

  Future<void> load() async {
    final generation = ++_requestGeneration;
    isLoading.value = true;
    isLoadingMore.value = false;
    errorMessage.value = null;
    try {
      final result = await Future.wait([
        service.listPinnedForOutlet(outlet),
        service.listRegularForOutlet(outlet),
      ]);
      if (generation != _requestGeneration) return;
      final pinned = result[0];
      final regular = result[1];
      pinnedNotes.assignAll(pinned);
      notes.assignAll(regular);
      _nextRegularOffset = regular.length;
      hasMoreRegularNotes.value = regular.length == NoteService.regularPageSize;
    } on Exception {
      if (generation == _requestGeneration) {
        errorMessage.value = 'មិនអាចទាញយកកំណត់ចំណាំបានទេ។';
      }
    } finally {
      if (generation == _requestGeneration) isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMoreRegularNotes.value) {
      return;
    }
    final generation = _requestGeneration;
    final offset = _nextRegularOffset;
    isLoadingMore.value = true;
    try {
      final result = await service.listRegularForOutlet(outlet, offset: offset);
      if (generation != _requestGeneration) return;
      final existingNames = notes.map((note) => note.name).toSet();
      notes.addAll(result.where((note) => existingNames.add(note.name)));
      _nextRegularOffset += result.length;
      hasMoreRegularNotes.value = result.length == NoteService.regularPageSize;
    } on Exception {
      // Keep the current page visible; another scroll can retry the request.
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<bool> create({
    required String title,
    required String content,
    required String color,
    required bool isPinned,
    List<String> tags = const [],
    DateTime? notifyOn,
  }) async {
    lastMutationError.value = null;
    if (isPinned && _pinLimitReached()) {
      lastMutationError.value = pinLimitMessage;
      return false;
    }
    try {
      final saved = await service.create(
        outlet: outlet,
        title: title,
        content: content,
        color: color,
        isPinned: isPinned,
        tags: tags,
        notifyOn: notifyOn,
      );
      _replace(saved);
      unawaited(loadDueTodayCount());
      return true;
    } on Exception {
      return false;
    }
  }

  Future<bool> updateNote({
    required NoteRecord note,
    required String title,
    required String content,
    required String color,
    required bool isPinned,
    List<String> tags = const [],
    DateTime? notifyOn,
  }) async {
    lastMutationError.value = null;
    if (isPinned && _pinLimitReached(excludingName: note.name)) {
      lastMutationError.value = pinLimitMessage;
      return false;
    }
    if (!_beginSave(note.name)) return false;
    try {
      final saved = await service.update(
        name: note.name,
        title: title,
        content: content,
        color: color,
        isPinned: isPinned,
        existingTags: note.tags,
        tags: tags,
        notifyOn: notifyOn,
      );
      _replace(saved);
      unawaited(loadDueTodayCount());
      return true;
    } on Exception {
      return false;
    } finally {
      savingNames.remove(note.name);
    }
  }

  Future<bool> togglePinned(NoteRecord note) async {
    lastMutationError.value = null;
    if (!note.isPinned && _pinLimitReached()) {
      lastMutationError.value = pinLimitMessage;
      return false;
    }
    if (!_beginSave(note.name)) return false;
    try {
      _replace(await service.setPinned(note, !note.isPinned));
      return true;
    } on Exception {
      return false;
    } finally {
      savingNames.remove(note.name);
    }
  }

  Future<bool> deleteNote(NoteRecord note) async {
    if (!_beginSave(note.name)) return false;
    try {
      await service.delete(note.name);
      notes.removeWhere((item) => item.name == note.name);
      pinnedNotes.removeWhere((item) => item.name == note.name);
      unawaited(loadDueTodayCount());
      return true;
    } on Exception {
      return false;
    } finally {
      savingNames.remove(note.name);
    }
  }

  bool _beginSave(String name) {
    if (savingNames.contains(name)) return false;
    savingNames.add(name);
    return true;
  }

  void _replace(NoteRecord saved) {
    notes.removeWhere((item) => item.name == saved.name);
    pinnedNotes.removeWhere((item) => item.name == saved.name);
    if (saved.isPinned) {
      pinnedNotes.insert(0, saved);
    } else {
      notes.insert(0, saved);
    }
  }

  bool _pinLimitReached({String? excludingName}) =>
      pinnedNotes.where((note) => note.name != excludingName).length >=
      NoteService.maximumPinnedNotes;

  @override
  void onClose() {
    _outletWorker.dispose();
    _searchWorker.dispose();
    super.onClose();
  }
}
