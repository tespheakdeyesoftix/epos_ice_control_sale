import 'package:flutter/material.dart';

import '../services/note_preset_repository.dart';

Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  String initialValue = '',
  String? labelText,
  String? hintText,
  IconData icon = Icons.edit_note_rounded,
  int maxLength = 500,
  int minLines = 1,
  int maxLines = 1,
  Key? inputKey,
  Key? confirmButtonKey,
  String? presetKey,
  String? userKey,
  String savedValuesTitle = 'តម្លៃដែលបានរក្សាទុក',
  bool allowDeletingSavedValues = false,
  NotePresetRepository? presetRepository,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => TextInputDialogWidget(
      title: title,
      initialValue: initialValue,
      labelText: labelText,
      hintText: hintText,
      icon: icon,
      maxLength: maxLength,
      minLines: minLines,
      maxLines: maxLines,
      inputKey: inputKey,
      confirmButtonKey: confirmButtonKey,
      presetKey: presetKey,
      userKey: userKey,
      savedValuesTitle: savedValuesTitle,
      allowDeletingSavedValues: allowDeletingSavedValues,
      presetRepository: presetRepository,
    ),
  );
}

class TextInputDialogWidget extends StatefulWidget {
  const TextInputDialogWidget({
    super.key,
    required this.title,
    this.initialValue = '',
    this.labelText,
    this.hintText,
    this.icon = Icons.edit_note_rounded,
    this.maxLength = 500,
    this.minLines = 1,
    this.maxLines = 1,
    this.inputKey,
    this.confirmButtonKey,
    this.presetKey,
    this.userKey,
    this.savedValuesTitle = 'តម្លៃដែលបានរក្សាទុក',
    this.allowDeletingSavedValues = false,
    this.presetRepository,
  });

  final String title;
  final String initialValue;
  final String? labelText;
  final String? hintText;
  final IconData icon;
  final int maxLength;
  final int minLines;
  final int maxLines;
  final Key? inputKey;
  final Key? confirmButtonKey;
  final String? presetKey;
  final String? userKey;
  final String savedValuesTitle;
  final bool allowDeletingSavedValues;
  final NotePresetRepository? presetRepository;

  @override
  State<TextInputDialogWidget> createState() => _TextInputDialogWidgetState();
}

class _TextInputDialogWidgetState extends State<TextInputDialogWidget> {
  late final TextEditingController _controller;
  NotePresetRepository? _presetRepository;
  List<String> _presets = const [];
  bool _isLoadingPresets = false;
  bool _isSaving = false;
  bool _isManageMode = false;

  bool get _isSingleLine => widget.maxLines == 1;
  bool get _hasRememberedValues =>
      widget.presetKey?.trim().isNotEmpty == true &&
      widget.userKey?.trim().isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    if (_hasRememberedValues) {
      _presetRepository =
          widget.presetRepository ?? GetStorageNotePresetRepository();
      _isLoadingPresets = true;
      _loadPresets();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadPresets() async {
    try {
      final values = await _presetRepository!.load(
        userKey: widget.userKey!,
        presetKey: widget.presetKey!,
      );
      if (mounted) setState(() => _presets = values);
    } on Exception {
      // Remembered values are optional and must not block text input.
    } finally {
      if (mounted) setState(() => _isLoadingPresets = false);
    }
  }

  void _selectPreset(String value) {
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _deletePreset(String value) async {
    final previous = _presets;
    setState(() => _presets = _presets.where((item) => item != value).toList());
    try {
      final values = await _presetRepository!.remove(
        userKey: widget.userKey!,
        presetKey: widget.presetKey!,
        note: value,
      );
      if (mounted) setState(() => _presets = values);
    } on Exception {
      if (mounted) setState(() => _presets = previous);
    }
  }

  Future<void> _confirm() async {
    if (_isSaving) return;
    final value = _controller.text.trim();
    if (!_hasRememberedValues || value.isEmpty) {
      Navigator.of(context).pop(value);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _presetRepository!.save(
        userKey: widget.userKey!,
        presetKey: widget.presetKey!,
        note: value,
      );
    } on Exception {
      // Saving locally is best-effort and must not block the entered value.
    }
    if (mounted) Navigator.of(context).pop(value);
  }

  Widget _buildTextField() {
    return TextField(
      key: widget.inputKey ?? const ValueKey('text-input-dialog-input'),
      controller: _controller,
      autofocus: true,
      enabled: !_isSaving,
      maxLength: widget.maxLength,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      textInputAction: _isSingleLine
          ? TextInputAction.done
          : TextInputAction.newline,
      onSubmitted: _isSingleLine ? (_) => _confirm() : null,
      decoration: InputDecoration(
        labelText: widget.labelText ?? widget.title,
        hintText: widget.hintText,
        prefixIcon: _isSingleLine ? Icon(widget.icon) : null,
        alignLabelWithHint: !_isSingleLine,
      ),
    );
  }

  Widget _buildRememberedValues(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(),
          if (_isLoadingPresets) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ] else if (_presets.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.savedValuesTitle,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                if (widget.allowDeletingSavedValues)
                  TextButton.icon(
                    key: const ValueKey('toggle-text-input-manage-mode'),
                    onPressed: _isSaving
                        ? null
                        : () => setState(() => _isManageMode = !_isManageMode),
                    icon: Icon(
                      _isManageMode ? Icons.check_rounded : Icons.edit_outlined,
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
                for (final value in _presets)
                  InputChip(
                    key: ValueKey('text-input-preset-$value'),
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    onPressed: _isSaving ? null : () => _selectPreset(value),
                    onDeleted: _isManageMode && !_isSaving
                        ? () => _deletePreset(value)
                        : null,
                    deleteIcon: const Icon(Icons.close_rounded, size: 18),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(widget.icon, color: colors.primary),
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: _hasRememberedValues
            ? _buildRememberedValues(context)
            : _buildTextField(),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('បោះបង់'),
        ),
        FilledButton.icon(
          key:
              widget.confirmButtonKey ??
              const ValueKey('confirm-text-input-dialog'),
          onPressed: _isSaving ? null : _confirm,
          icon: _isSaving
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
