import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../services/receipt_print_service.dart';
import '../../../shared/receipts/receipt_template.dart';
import '../setting_controller.dart';

class PrintSettingsDialog extends StatefulWidget {
  const PrintSettingsDialog({super.key});

  @override
  State<PrintSettingsDialog> createState() => _PrintSettingsDialogState();
}

class _PrintSettingsDialogState extends State<PrintSettingsDialog> {
  SettingController get controller => Get.find<SettingController>();

  @override
  void initState() {
    super.initState();
    controller.loadPrintSettings();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('print-settings-dialog'),
      title: const Text('ការកំណត់ការបោះពុម្ព'),
      content: SizedBox(
        width: 520,
        child: Obx(() {
          if (controller.isLoadingPrintSettings.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (controller.printSettingsError.value case final error?) ...[
                Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              DropdownButtonFormField<ReceiptPrinterInfo>(
                key: const ValueKey('default-printer-dropdown'),
                initialValue: controller.selectedPrinter.value,
                decoration: const InputDecoration(
                  labelText: 'ម៉ាស៊ីនបោះពុម្ព',
                  border: OutlineInputBorder(),
                ),
                items: controller.printers
                    .map(
                      (printer) => DropdownMenuItem(
                        value: printer,
                        child: Text(
                          printer.isDefault
                              ? '${printer.name} (Default)'
                              : printer.name,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => controller.selectedPrinter.value = value,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ReceiptTemplate>(
                key: const ValueKey('default-template-dropdown'),
                initialValue: controller.selectedTemplate.value,
                decoration: const InputDecoration(
                  labelText: 'គំរូវិក្កយបត្រ',
                  border: OutlineInputBorder(),
                ),
                items: controller.templates
                    .map(
                      (template) => DropdownMenuItem(
                        value: template,
                        child: Text(
                          '${template.templateName} • ${template.pageSize.label}',
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) controller.selectedTemplate.value = value;
                },
              ),
              const SizedBox(height: 16),
              const Text('ចំនួនច្បាប់ចម្លងលំនាំដើម'),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                key: const ValueKey('default-copy-selector'),
                segments: const [
                  ButtonSegment(value: 1, label: Text('1')),
                  ButtonSegment(value: 2, label: Text('2')),
                  ButtonSegment(value: 3, label: Text('3')),
                ],
                selected: {controller.copies.value},
                onSelectionChanged: (value) =>
                    controller.copies.value = value.first,
              ),
            ],
          );
        }),
      ),
      actions: [
        Obx(
          () => OutlinedButton.icon(
            key: const ValueKey('test-print-settings'),
            onPressed:
                controller.selectedPrinter.value == null ||
                    controller.isSavingPrintSettings.value
                ? null
                : controller.testPrint,
            icon: const Icon(Icons.print_outlined),
            label: const Text('សាកល្បង'),
          ),
        ),
        Obx(
          () => TextButton(
            onPressed: controller.isSavingPrintSettings.value
                ? null
                : () => Navigator.of(context).pop(),
            child: const Text('បោះបង់'),
          ),
        ),
        Obx(
          () => FilledButton.icon(
            key: const ValueKey('save-print-settings'),
            onPressed: controller.isSavingPrintSettings.value
                ? null
                : () async {
                    final saved = await controller.savePrintSettings();
                    if (saved && context.mounted) Navigator.of(context).pop();
                  },
            icon: const Icon(Icons.save_outlined),
            label: const Text('រក្សាទុក'),
          ),
        ),
      ],
    );
  }
}
