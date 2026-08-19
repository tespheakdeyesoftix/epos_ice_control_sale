import 'dart:typed_data';

import 'package:get/get.dart';

import '../../app/app_setting.dart';
import '../../app/app_setting_controller.dart';
import '../../features/login/login_controller.dart';
import '../../features/sell/sale.dart';
import '../../services/print_preference_store.dart';
import '../../services/receipt_print_service.dart';
import '../../shared/receipts/receipt_a6_widget.dart';
import '../../shared/receipts/receipt_template.dart';
import '../../shared/receipts/receipt_template_renderer.dart';

class SettingController extends GetxController {
  SettingController({
    required this.loginController,
    required this.appSettingController,
    required this.printService,
  });

  final LoginController loginController;
  final AppSettingController appSettingController;
  final ReceiptPrintService printService;

  final isLoadingPrintSettings = false.obs;
  final isSavingPrintSettings = false.obs;
  final printSettingsError = RxnString();
  final printers = <ReceiptPrinterInfo>[].obs;
  final templates = <ReceiptTemplate>[ReceiptTemplate.standardA6].obs;
  final selectedPrinter = Rxn<ReceiptPrinterInfo>();
  final selectedTemplate = ReceiptTemplate.standardA6.obs;
  final copies = 1.obs;

  bool get isAdministrator =>
      loginController.currentSession.value?.user.trim() == 'Administrator';

  String get outlet => appSettingController.current?.outlet.trim() ?? '';

  Future<void> loadPrintSettings() async {
    if (isLoadingPrintSettings.value) return;
    isLoadingPrintSettings.value = true;
    printSettingsError.value = null;
    try {
      final preference = printService.preferenceStore?.read(outlet);
      final results = await Future.wait<Object>([
        printService.listPrinters(),
        if (printService.templateService != null)
          printService.templateService!.listTemplates()
        else
          Future.value(const [ReceiptTemplate.standardA6]),
      ]);
      final availablePrinters = (results[0] as List<ReceiptPrinterInfo>)
          .where((printer) => printer.isAvailable)
          .toList(growable: false);
      final availableTemplates = results[1] as List<ReceiptTemplate>;
      printers.assignAll(availablePrinters);
      templates.assignAll(availableTemplates);
      copies.value = preference?.copies ?? 1;
      selectedPrinter.value = _matchPrinter(availablePrinters, preference);
      selectedTemplate.value =
          _matchTemplate(availableTemplates, preference?.templateName) ??
          ReceiptTemplate.standardA6;
    } on Exception {
      printSettingsError.value = 'មិនអាចទាញយកការកំណត់បោះពុម្ពបានទេ។';
    } finally {
      isLoadingPrintSettings.value = false;
    }
  }

  Future<bool> savePrintSettings() async {
    final store = printService.preferenceStore;
    if (store == null) {
      printSettingsError.value =
          'មិនមានឃ្លាំងរក្សាទុកការកំណត់ក្នុងម៉ាស៊ីននេះទេ។';
      return false;
    }
    isSavingPrintSettings.value = true;
    printSettingsError.value = null;
    try {
      final printer = selectedPrinter.value;
      await store.write(
        outlet,
        PrintPreference(
          printerUrl: printer?.url ?? '',
          printerName: printer?.name ?? '',
          templateName: selectedTemplate.value.name,
          copies: copies.value,
        ),
      );
      return true;
    } on Exception {
      printSettingsError.value = 'មិនអាចរក្សាទុកការកំណត់បោះពុម្ពបានទេ។';
      return false;
    } finally {
      isSavingPrintSettings.value = false;
    }
  }

  Future<void> testPrint() async {
    final printer = selectedPrinter.value;
    if (printer == null || isSavingPrintSettings.value) return;
    isSavingPrintSettings.value = true;
    printSettingsError.value = null;
    try {
      final template = selectedTemplate.value;
      final business =
          appSettingController.current ??
          const AppSetting(raw: <String, dynamic>{});
      final imageSources = ReceiptTemplateRenderer.resolveImageSources(
        sale: previewSale,
        business: business,
        template: template,
        sellerFallback: 'Administrator',
      );
      final imageBytes =
          await printService.templateService?.loadImages(imageSources) ??
          const <String, Uint8List>{};
      final bytes = template.isBuiltIn
          ? await ReceiptA6Widget.buildPdf(
              sale: previewSale,
              business: business,
              sellerFallback: 'Administrator',
            )
          : await ReceiptTemplateRenderer.buildPdf(
              sale: previewSale,
              business: business,
              sellerFallback: 'Administrator',
              template: template,
              imageBytes: imageBytes,
            );
      await printService.printA6Pdf(
        bytes: bytes,
        documentName: 'Test Print.pdf',
        printer: printer,
        format: template.pageFormat,
      );
    } on Exception {
      printSettingsError.value = 'ការបោះពុម្ពសាកល្បងបានបរាជ័យ។';
    } finally {
      isSavingPrintSettings.value = false;
    }
  }

  ReceiptPrinterInfo? _matchPrinter(
    List<ReceiptPrinterInfo> values,
    PrintPreference? preference,
  ) {
    for (final printer in values) {
      if (preference?.printerUrl.isNotEmpty == true &&
          printer.url == preference!.printerUrl) {
        return printer;
      }
    }
    for (final printer in values) {
      if (printer.isDefault) return printer;
    }
    return values.firstOrNull;
  }

  ReceiptTemplate? _matchTemplate(List<ReceiptTemplate> values, String? name) {
    for (final template in values) {
      if (template.name == name || template.templateName == name) {
        return template;
      }
    }
    return null;
  }

  static const previewSale = Sale(
    name: 'SO2026-0001',
    outlet: 'Main Outlet',
    saleProducts: [],
    customer: 'CUST-0001',
    customerName: 'Sample Customer',
    phoneNumber: '012 345 678',
    seller: 'Administrator',
    station: 'Cashier 01',
    canShowPrice: true,
  );
}
