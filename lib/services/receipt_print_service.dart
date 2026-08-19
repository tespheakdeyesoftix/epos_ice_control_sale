import 'dart:async';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../app/app_setting.dart';
import '../features/sell/sale.dart';
import '../shared/receipts/receipt_a6_widget.dart';
import '../shared/receipts/receipt_template.dart';
import '../shared/receipts/receipt_template_renderer.dart';
import 'print_preference_store.dart';
import 'receipt_template_service.dart';

class ReceiptPrinterInfo {
  const ReceiptPrinterInfo({
    required this.url,
    required this.name,
    required this.isDefault,
    required this.isAvailable,
  });

  final String url;
  final String name;
  final bool isDefault;
  final bool isAvailable;
}

abstract interface class ReceiptPrinterGateway {
  Future<List<ReceiptPrinterInfo>> listPrinters();

  Future<bool> printPdf({
    required ReceiptPrinterInfo printer,
    required Uint8List bytes,
    required String documentName,
    required PdfPageFormat format,
  });
}

class WindowsReceiptPrinterGateway implements ReceiptPrinterGateway {
  const WindowsReceiptPrinterGateway();

  @override
  Future<List<ReceiptPrinterInfo>> listPrinters() async {
    final printers = await Printing.listPrinters();
    return printers
        .map(
          (printer) => ReceiptPrinterInfo(
            url: printer.url,
            name: printer.name,
            isDefault: printer.isDefault,
            isAvailable: printer.isAvailable,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<bool> printPdf({
    required ReceiptPrinterInfo printer,
    required Uint8List bytes,
    required String documentName,
    required PdfPageFormat format,
  }) async {
    return Printing.directPrintPdf(
      printer: Printer(url: printer.url, name: printer.name),
      name: documentName,
      format: format,
      dynamicLayout: false,
      forceCustomPrintPaper: true,
      onLayout: (_) async => bytes,
    );
  }
}

typedef ReceiptPdfBuilder =
    Future<Uint8List> Function({
      required Sale sale,
      required AppSetting business,
      required String sellerFallback,
    });

typedef ReceiptTemplatePdfBuilder =
    Future<Uint8List> Function({
      required Sale sale,
      required AppSetting business,
      required String sellerFallback,
      required ReceiptTemplate template,
      required int copies,
      required Map<String, Uint8List> imageBytes,
    });

class ReceiptPrintService extends GetxService {
  ReceiptPrintService({
    ReceiptPrinterGateway? gateway,
    ReceiptPdfBuilder? pdfBuilder,
    ReceiptTemplatePdfBuilder? templatePdfBuilder,
    this.templateService,
    this.preferenceStore,
    this.preferredPrinterName = 'Canon iX6700 series',
  }) : _gateway = gateway ?? const WindowsReceiptPrinterGateway(),
       _legacyPdfBuilder = pdfBuilder,
       _templatePdfBuilder =
           templatePdfBuilder ?? ReceiptTemplateRenderer.buildPdf;

  final ReceiptPrinterGateway _gateway;
  final ReceiptPdfBuilder? _legacyPdfBuilder;
  final ReceiptTemplatePdfBuilder _templatePdfBuilder;
  final ReceiptTemplateService? templateService;
  final PrintPreferenceStore? preferenceStore;
  final String preferredPrinterName;
  final isBusy = false.obs;

  bool beginWorkflow() {
    if (isBusy.value) return false;
    isBusy.value = true;
    return true;
  }

  void endWorkflow() => isBusy.value = false;

  Future<List<ReceiptPrinterInfo>> listPrinters() => _gateway.listPrinters();

  Future<ReceiptPrinterInfo?> findDefaultPrinter() async {
    final printers = await _gateway.listPrinters();
    final preferredName = preferredPrinterName.trim().toLowerCase();
    if (preferredName.isNotEmpty) {
      for (final printer in printers) {
        if (printer.name.trim().toLowerCase() == preferredName &&
            printer.isAvailable) {
          return printer;
        }
      }
    }
    for (final printer in printers) {
      if (printer.isDefault && printer.isAvailable) return printer;
    }
    return null;
  }

  Future<void> printA6Pdf({
    required Uint8List bytes,
    required String documentName,
    ReceiptPrinterInfo? printer,
    PdfPageFormat format = PdfPageFormat.a6,
  }) async {
    final target = printer ?? await findDefaultPrinter();
    if (target == null) {
      throw const ReceiptPrintException(ReceiptPrintFailure.noDefaultPrinter);
    }
    final printed = await _gateway.printPdf(
      printer: target,
      bytes: bytes,
      documentName: documentName,
      format: format,
    );
    if (!printed) {
      throw const ReceiptPrintException(ReceiptPrintFailure.printRejected);
    }
  }

  Future<void> printSavedOrder({
    required Map<String, dynamic> savedOrder,
    required AppSetting business,
    required String sellerFallback,
    int? copies,
    ReceiptTemplate? template,
  }) async {
    final sale = Sale.fromJson(savedOrder);
    if (sale.name.trim().isEmpty) {
      throw const ReceiptPrintException(ReceiptPrintFailure.invalidSale);
    }

    final preference = preferenceStore?.read(sale.outlet);
    final printers = await _gateway.listPrinters();
    final preferredLocalPrinter = preference == null
        ? null
        : _findPrinter(printers, preference.printerUrl, preference.printerName);
    final defaultPrinter = preferredLocalPrinter ?? await findDefaultPrinter();
    if (defaultPrinter == null) {
      throw const ReceiptPrintException(ReceiptPrintFailure.noDefaultPrinter);
    }

    final resolvedTemplate =
        template ?? await _resolveTemplate(preference, business);
    final resolvedCopies = (copies ?? preference?.copies ?? 1).clamp(1, 3);
    final imageSources = ReceiptTemplateRenderer.resolveImageSources(
      sale: sale,
      business: business,
      template: resolvedTemplate,
      sellerFallback: sellerFallback,
    );
    final imageBytes =
        await templateService?.loadImages(imageSources) ??
        const <String, Uint8List>{};
    final legacyBuilder = _legacyPdfBuilder;
    final bytes = legacyBuilder != null
        ? await legacyBuilder(
            sale: sale,
            business: business,
            sellerFallback: sellerFallback,
          )
        : resolvedTemplate.isBuiltIn
        ? await ReceiptA6Widget.buildPdf(
            sale: sale,
            business: business,
            sellerFallback: sellerFallback,
            copies: resolvedCopies,
          )
        : await _templatePdfBuilder(
            sale: sale,
            business: business,
            sellerFallback: sellerFallback,
            template: resolvedTemplate,
            copies: resolvedCopies,
            imageBytes: imageBytes,
          );
    await printA6Pdf(
      printer: defaultPrinter,
      bytes: bytes,
      documentName: '${sale.name}.pdf',
      format: resolvedTemplate.pageFormat,
    );
  }

  ReceiptPrinterInfo? _findPrinter(
    List<ReceiptPrinterInfo> printers,
    String url,
    String name,
  ) {
    for (final printer in printers) {
      if (!printer.isAvailable) continue;
      if (url.trim().isNotEmpty && printer.url == url) return printer;
      if (name.trim().isNotEmpty &&
          printer.name.trim().toLowerCase() == name.trim().toLowerCase()) {
        return printer;
      }
    }
    return null;
  }

  Future<ReceiptTemplate> _resolveTemplate(
    PrintPreference? preference,
    AppSetting business,
  ) async {
    final service = templateService;
    if (service == null) return ReceiptTemplate.standardA6;
    try {
      final templates = await service.listTemplates();
      final candidates = [
        preference?.templateName.trim() ?? '',
        business.defaultPrintTemplate.trim(),
      ];
      for (final candidate in candidates.where((value) => value.isNotEmpty)) {
        for (final template in templates) {
          if (template.name == candidate ||
              template.templateName == candidate) {
            return template;
          }
        }
      }
    } on Exception {
      // Keep sales printable with the built-in layout when templates are offline.
    }
    return ReceiptTemplate.standardA6;
  }
}

enum ReceiptPrintFailure { invalidSale, noDefaultPrinter, printRejected }

class ReceiptPrintException implements Exception {
  const ReceiptPrintException(this.failure);

  final ReceiptPrintFailure failure;
}
