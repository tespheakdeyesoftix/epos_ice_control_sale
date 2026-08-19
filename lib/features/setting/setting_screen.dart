import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'setting_controller.dart';
import 'widgets/print_settings_dialog.dart';
import 'widgets/receipt_template_manager_screen.dart';
import 'widgets/setting_card.dart';

class SettingScreen extends GetView<SettingController> {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ការកំណត់')),
      body: Obx(() {
        final isAdministrator = controller.isAdministrator;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            SettingCard(
              key: const ValueKey('print-settings-card'),
              icon: Icons.print_outlined,
              title: 'ការកំណត់ការបោះពុម្ព',
              subtitle:
                  'ជ្រើសរើសម៉ាស៊ីនបោះពុម្ព គំរូវិក្កយបត្រ និងចំនួនច្បាប់ចម្លង',
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => const PrintSettingsDialog(),
              ),
            ),
            const SizedBox(height: 16),
            SettingCard(
              key: const ValueKey('receipt-template-settings-card'),
              icon: Icons.dashboard_customize_outlined,
              title: 'គំរូវិក្កយបត្រ',
              subtitle: isAdministrator
                  ? 'បង្កើត និងកែសម្រួលគំរូ A6, A5 ឬ A4'
                  : 'អាចកែសម្រួលបានដោយ Administrator ប៉ុណ្ណោះ',
              trailing: isAdministrator
                  ? null
                  : const Icon(Icons.lock_outline_rounded),
              onTap: isAdministrator
                  ? () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ReceiptTemplateManagerScreen(),
                      ),
                    )
                  : null,
            ),
          ],
        );
      }),
    );
  }
}
