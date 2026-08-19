import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../receipt_template_controller.dart';
import 'receipt_template_editor.dart';

class ReceiptTemplateManagerScreen extends GetView<ReceiptTemplateController> {
  const ReceiptTemplateManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('គំរូវិក្កយបត្រ')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            if (controller.errorMessage.value case final error?)
              MaterialBanner(
                content: Text(error),
                actions: [
                  TextButton(
                    onPressed: controller.loadTemplates,
                    child: const Text('ព្យាយាមម្ដងទៀត'),
                  ),
                ],
              ),
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 260,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: controller.templates.length,
                      itemBuilder: (context, index) {
                        final template = controller.templates[index];
                        return ListTile(
                          selected:
                              controller.selectedTemplate.value?.name ==
                              template.name,
                          leading: const Icon(Icons.description_outlined),
                          title: Text(template.templateName),
                          subtitle: Text(template.pageSize.label),
                          trailing: template.isBuiltIn
                              ? const Tooltip(
                                  message: 'Built-in fallback',
                                  child: Icon(Icons.shield_outlined, size: 18),
                                )
                              : null,
                          onTap: () => controller.selectTemplate(template),
                        );
                      },
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  const Expanded(child: ReceiptTemplateEditor()),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
