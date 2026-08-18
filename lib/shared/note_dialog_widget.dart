import 'dart:async';

import 'package:flutter/material.dart';

import '../services/note_preset_repository.dart';

typedef NoteSubmitCallback = FutureOr<bool> Function(String note);

Future<void> showNoteDialog(
  BuildContext context, {
  required String promptTitle,
  required String presetKey,
  required String userKey,
  required NoteSubmitCallback onSubmit,
  String initialNote = '',
  bool allowDeletingSavedNotes = false,
  NotePresetRepository? presetRepository,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => NoteDialogWidget(
      promptTitle: promptTitle,
      presetKey: presetKey,
      userKey: userKey,
      initialNote: initialNote,
      allowDeletingSavedNotes: allowDeletingSavedNotes,
      presetRepository: presetRepository,
      onSubmit: onSubmit,
    ),
  );
}

class NoteDialogWidget extends StatefulWidget {
  const NoteDialogWidget({
    super.key,
    required this.promptTitle,
    required this.presetKey,
    required this.userKey,
    required this.onSubmit,
    this.initialNote = '',
    this.allowDeletingSavedNotes = false,
    this.presetRepository,
  });

  final String promptTitle;
  final String presetKey;
  final String userKey;
  final String initialNote;
  final bool allowDeletingSavedNotes;
  final NotePresetRepository? presetRepository;
  final NoteSubmitCallback onSubmit;

  @override
  State<NoteDialogWidget> createState() => _NoteDialogWidgetState();
}

class _NoteDialogWidgetState extends State<NoteDialogWidget> {
  late final TextEditingController _controller;
  late final NotePresetRepository _presetRepository;
  final _formKey = GlobalKey<FormState>();
  List<String> _presets = const [];
  bool _isLoadingPresets = true;
  bool _isSubmitting = false;
  bool _isManageMode = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
    _presetRepository =
        widget.presetRepository ?? GetStorageNotePresetRepository();
    _loadPresets();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadPresets() async {
    try {
      final notes = await _presetRepository.load(
        userKey: widget.userKey,
        presetKey: widget.presetKey,
      );
      if (mounted) setState(() => _presets = notes);
    } on Exception {
      // Presets are optional; a local-storage error must not block the dialog.
    } finally {
      if (mounted) setState(() => _isLoadingPresets = false);
    }
  }

  void _selectPreset(String note) {
    _controller.value = TextEditingValue(
      text: note,
      selection: TextSelection.collapsed(offset: note.length),
    );
  }

  Future<void> _deletePreset(String note) async {
    final previous = _presets;
    setState(() => _presets = _presets.where((item) => item != note).toList());
    try {
      final notes = await _presetRepository.remove(
        userKey: widget.userKey,
        presetKey: widget.presetKey,
        note: note,
      );
      if (mounted) setState(() => _presets = notes);
    } on Exception {
      if (mounted) setState(() => _presets = previous);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    final note = _controller.text.trim();
    setState(() => _isSubmitting = true);
    final shouldClose = await widget.onSubmit(note);
    if (!mounted) return;
    if (!shouldClose) {
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      await _presetRepository.save(
        userKey: widget.userKey,
        presetKey: widget.presetKey,
        note: note,
      );
    } on Exception {
      // The business action succeeded, so local-storage failure is non-fatal.
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(Icons.note_alt_outlined, color: colors.primary),
      title: Text(widget.promptTitle),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  key: const ValueKey('note-dialog-input'),
                  controller: _controller,
                  autofocus: true,
                  enabled: !_isSubmitting,
                  minLines: 2,
                  maxLines: 6,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'កំណត់ចំណាំ',
                    hintText: 'សូមបញ្ចូលកំណត់ចំណាំ',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'សូមបញ្ចូលកំណត់ចំណាំ'
                      : null,
                ),
                if (_isLoadingPresets) ...[
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(),
                ] else if (_presets.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'កំណត់ចំណាំដែលបានរក្សាទុក',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      if (widget.allowDeletingSavedNotes)
                        TextButton.icon(
                          key: const ValueKey('toggle-note-manage-mode'),
                          onPressed: _isSubmitting
                              ? null
                              : () => setState(
                                  () => _isManageMode = !_isManageMode,
                                ),
                          icon: Icon(
                            _isManageMode
                                ? Icons.check_rounded
                                : Icons.edit_outlined,
                            size: 18,
                          ),
                          label: Text(_isManageMode ? 'រួចរាល់' : 'គ្រប់គ្រង'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final note in _presets)
                        InputChip(
                          key: ValueKey('note-preset-$note'),
                          label: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 300),
                            child: Text(
                              note,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          onPressed: _isSubmitting
                              ? null
                              : () => _selectPreset(note),
                          onDeleted: _isManageMode && !_isSubmitting
                              ? () => _deletePreset(note)
                              : null,
                          deleteIcon: const Icon(Icons.close_rounded, size: 18),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('បោះបង់'),
        ),
        FilledButton.icon(
          key: const ValueKey('confirm-note-dialog'),
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded),
          label: const Text('យល់ព្រម'),
        ),
      ],
    );
  }
}
