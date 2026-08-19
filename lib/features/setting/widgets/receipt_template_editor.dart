import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../../../shared/receipts/receipt_template.dart';
import '../receipt_template_controller.dart';
import 'receipt_template_help_dialog.dart';

class ReceiptTemplateEditor extends StatefulWidget {
  const ReceiptTemplateEditor({super.key});

  @override
  State<ReceiptTemplateEditor> createState() => _ReceiptTemplateEditorState();
}

class _ReceiptTemplateEditorState extends State<ReceiptTemplateEditor> {
  late final ReceiptTemplateController controller = Get.find();
  late final TextEditingController codeController = TextEditingController(
    text: controller.layoutCode.value,
  );
  late final Worker codeWorker;

  @override
  void initState() {
    super.initState();
    codeWorker = ever<String>(controller.layoutCode, (value) {
      if (codeController.text == value) return;
      final offset = math.min(
        codeController.selection.baseOffset,
        value.length,
      );
      codeController.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: math.max(0, offset)),
      );
    });
  }

  @override
  void dispose() {
    codeWorker.dispose();
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final template = controller.selectedTemplate.value;
      if (template == null) {
        return const Center(child: Text('Select a receipt template.'));
      }
      final readOnly = template.isBuiltIn;
      final mode = controller.editorMode.value;
      return Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.templateName,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${template.pageSize.label} ${template.orientation.label} · ${_number(template.marginMm)} mm margin',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  SegmentedButton<ReceiptTemplateEditorMode>(
                    segments: const [
                      ButtonSegment(
                        value: ReceiptTemplateEditorMode.preview,
                        icon: Icon(Icons.preview_outlined),
                        label: Text('Preview'),
                      ),
                      ButtonSegment(
                        value: ReceiptTemplateEditorMode.code,
                        icon: Icon(Icons.code),
                        label: Text('Code'),
                      ),
                      ButtonSegment(
                        value: ReceiptTemplateEditorMode.split,
                        icon: Icon(Icons.vertical_split_outlined),
                        label: Text('Split'),
                      ),
                    ],
                    selected: {mode},
                    showSelectedIcon: false,
                    onSelectionChanged: (values) {
                      controller.editorMode.value = values.first;
                    },
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: 'Layout JSON reference',
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => const ReceiptTemplateHelpDialog(),
                    ),
                    icon: const Icon(Icons.help_outline),
                  ),
                  if (!readOnly) ...[
                    IconButton(
                      tooltip: 'Format JSON',
                      onPressed: controller.formatLayoutCode,
                      icon: const Icon(Icons.format_align_left),
                    ),
                    IconButton(
                      tooltip: 'Discard changes',
                      onPressed: controller.resetLayoutCode,
                      icon: const Icon(Icons.restore),
                    ),
                    FilledButton.icon(
                      onPressed: controller.isSaving.value
                          ? null
                          : controller.saveNow,
                      icon: controller.isSaving.value
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Save'),
                    ),
                  ],
                  if (controller.saveStatus.value.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Text(controller.saveStatus.value),
                  ],
                ],
              ),
            ),
          ),
          if (readOnly)
            const _MessageBar(
              icon: Icons.lock_outline,
              text:
                  'The built-in fallback is read-only. Select a server template to edit its layout JSON.',
            ),
          if (controller.codeError.value case final error?)
            _MessageBar(icon: Icons.error_outline, text: error, isError: true),
          for (final warning in controller.layoutWarnings)
            _MessageBar(icon: Icons.warning_amber_rounded, text: warning),
          Expanded(
            child: switch (mode) {
              ReceiptTemplateEditorMode.preview => _buildPreview(template),
              ReceiptTemplateEditorMode.code => _buildCodeEditor(readOnly),
              ReceiptTemplateEditorMode.split => Row(
                children: [
                  Expanded(child: _buildCodeEditor(readOnly)),
                  const VerticalDivider(width: 1),
                  Expanded(child: _buildPreview(template)),
                ],
              ),
            },
          ),
        ],
      );
    });
  }

  Widget _buildCodeEditor(bool readOnly) {
    return ColoredBox(
      color: Colors.white,
      child: TextField(
        controller: codeController,
        readOnly: readOnly,
        expands: true,
        minLines: null,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        onChanged: controller.updateLayoutCode,
        style: const TextStyle(
          color: Colors.black,
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.45,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
          hintText: 'Receipt layout JSON',
          hintStyle: TextStyle(color: Colors.black45),
        ),
      ),
    );
  }

  Widget _buildPreview(ReceiptTemplate template) {
    return PdfPreview(
      key: ValueKey(
        'preview-${template.name}-${controller.previewRevision.value}',
      ),
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
      allowPrinting: false,
      allowSharing: false,
      initialPageFormat: template.pageFormat,
      build: (_) => controller.buildPreview(),
    );
  }

  String _number(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}

class _MessageBar extends StatelessWidget {
  const _MessageBar({
    required this.icon,
    required this.text,
    this.isError = false,
  });

  final IconData icon;
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? Theme.of(context).colorScheme.errorContainer
        : Theme.of(context).colorScheme.tertiaryContainer;
    return ColoredBox(
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
