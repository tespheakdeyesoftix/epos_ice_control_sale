import 'dart:async';

import 'package:flutter/material.dart';

typedef NoteSubmitCallback = FutureOr<bool> Function(String note);

Future<void> showNoteDialog(
  BuildContext context, {
  required String promptTitle,
  required NoteSubmitCallback onSubmit,
  String initialNote = '',
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => NoteDialogWidget(
      promptTitle: promptTitle,
      initialNote: initialNote,
      onSubmit: onSubmit,
    ),
  );
}

class NoteDialogWidget extends StatefulWidget {
  const NoteDialogWidget({
    super.key,
    required this.promptTitle,
    required this.onSubmit,
    this.initialNote = '',
  });

  final String promptTitle;
  final String initialNote;
  final NoteSubmitCallback onSubmit;

  @override
  State<NoteDialogWidget> createState() => _NoteDialogWidgetState();
}

class _NoteDialogWidgetState extends State<NoteDialogWidget> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final shouldClose = await widget.onSubmit(_controller.text.trim());
    if (!mounted) return;
    if (shouldClose) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(Icons.note_alt_outlined, color: colors.primary),
      title: Text(widget.promptTitle),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: TextFormField(
            key: const ValueKey('note-dialog-input'),
            controller: _controller,
            autofocus: true,
            enabled: !_isSubmitting,
            minLines: 4,
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
