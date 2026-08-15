import 'package:flutter/material.dart';

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

  @override
  State<TextInputDialogWidget> createState() => _TextInputDialogWidgetState();
}

class _TextInputDialogWidgetState extends State<TextInputDialogWidget> {
  late final TextEditingController _controller;

  bool get _isSingleLine => widget.maxLines == 1;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(widget.icon, color: colors.primary),
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: TextField(
          key: widget.inputKey ?? const ValueKey('text-input-dialog-input'),
          controller: _controller,
          autofocus: true,
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
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('បោះបង់'),
        ),
        FilledButton.icon(
          key:
              widget.confirmButtonKey ??
              const ValueKey('confirm-text-input-dialog'),
          onPressed: _confirm,
          icon: const Icon(Icons.check_rounded),
          label: const Text('យល់ព្រម'),
        ),
      ],
    );
  }
}
