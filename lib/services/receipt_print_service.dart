import 'dart:async';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../app/app_setting.dart';
import '../features/sell/sale.dart';
import '../shared/receipts/receipt_a6_widget.dart';

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
  }) async {
    return Printing.directPrintPdf(
      printer: Printer(url: printer.url, name: printer.name),
      name: documentName,
      format: PdfPageFormat.a6,
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

class ReceiptPrintService extends GetxService {
  ReceiptPrintService({
    ReceiptPrinterGateway? gateway,
    ReceiptPdfBuilder? pdfBuilder,
    this.preferredPrinterName = 'Canon iX6700 series',
  }) : _gateway = gateway ?? const WindowsReceiptPrinterGateway(),
       _pdfBuilder = pdfBuilder ?? ReceiptA6Widget.buildPdf;

  final ReceiptPrinterGateway _gateway;
  final ReceiptPdfBuilder _pdfBuilder;
  final String preferredPrinterName;
  final isBusy = false.obs;

  bool beginWorkflow() {
    if (isBusy.value) return false;
    isBusy.value = true;
    return true;
  }

  void endWorkflow() => isBusy.value = false;

  Future<ReceiptPrinterInfo?> findDefaultPrinter() async {
    final printers = await _gateway.listPrinters();
    final preferredName = preferredPrinterName.trim().toLowerCase();
    if (preferredName.isNotEmpty) {
      for (final printer in printers) {
        if (printer.name.trim().toLowerCase() == preferredName) return printer;
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
  }) async {
    final target = printer ?? await findDefaultPrinter();
    if (target == null) {
      throw const ReceiptPrintException(ReceiptPrintFailure.noDefaultPrinter);
    }
    final printed = await _gateway.printPdf(
      printer: target,
      bytes: bytes,
      documentName: documentName,
    );
    if (!printed) {
      throw const ReceiptPrintException(ReceiptPrintFailure.printRejected);
    }
  }

  Future<void> printSavedOrder({
    required Map<String, dynamic> savedOrder,
    required AppSetting business,
    required String sellerFallback,
  }) async {
    final sale = Sale.fromJson(savedOrder);
    if (sale.name.trim().isEmpty) {
      throw const ReceiptPrintException(ReceiptPrintFailure.invalidSale);
    }

    final defaultPrinter = await findDefaultPrinter();
    if (defaultPrinter == null) {
      throw const ReceiptPrintException(ReceiptPrintFailure.noDefaultPrinter);
    }

    final bytes = await _pdfBuilder(
      sale: sale,
      business: business,
      sellerFallback: sellerFallback,
    );
    await printA6Pdf(
      printer: defaultPrinter,
      bytes: bytes,
      documentName: '${sale.name}.pdf',
    );
  }
}

enum ReceiptPrintFailure { invalidSale, noDefaultPrinter, printRejected }

class ReceiptPrintException implements Exception {
  const ReceiptPrintException(this.failure);

  final ReceiptPrintFailure failure;
}
