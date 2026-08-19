import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/app/app_setting.dart';
import 'package:ice_control_sale/features/sell/sale.dart';
import 'package:ice_control_sale/services/print_preference_store.dart';
import 'package:ice_control_sale/services/receipt_print_service.dart';
import 'package:ice_control_sale/shared/receipts/receipt_template.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const business = AppSetting(
    raw: <String, dynamic>{},
    businessNameKh: 'អាជីវកម្មសាកល្បង',
  );

  test('prints only through the available default printer', () async {
    final gateway = _FakePrinterGateway(
      printers: const [
        ReceiptPrinterInfo(
          url: 'printer://other',
          name: 'Other',
          isDefault: false,
          isAvailable: true,
        ),
        ReceiptPrinterInfo(
          url: 'printer://default',
          name: 'Default A6',
          isDefault: true,
          isAvailable: true,
        ),
      ],
    );
    Sale? builtSale;
    final service = ReceiptPrintService(
      gateway: gateway,
      pdfBuilder:
          ({
            required Sale sale,
            required AppSetting business,
            required String sellerFallback,
          }) async {
            builtSale = sale;
            return Uint8List.fromList(const [1, 2, 3]);
          },
    );

    await service.printSavedOrder(
      savedOrder: _savedSale,
      business: business,
      sellerFallback: 'Administrator',
    );

    expect(builtSale?.name, 'SO2026-0001');
    expect(gateway.printCalls, 1);
    expect(gateway.printedPrinter?.url, 'printer://default');
    expect(gateway.printedDocumentName, 'SO2026-0001.pdf');
  });

  test('skips an unavailable configured Canon printer', () async {
    final gateway = _FakePrinterGateway(
      printers: const [
        ReceiptPrinterInfo(
          url: 'printer://default',
          name: 'Default A6',
          isDefault: true,
          isAvailable: true,
        ),
        ReceiptPrinterInfo(
          url: 'printer://canon',
          name: 'Canon iX6700 series',
          isDefault: false,
          isAvailable: false,
        ),
      ],
    );
    final service = ReceiptPrintService(
      gateway: gateway,
      preferredPrinterName: 'Canon iX6700 series',
      pdfBuilder:
          ({
            required Sale sale,
            required AppSetting business,
            required String sellerFallback,
          }) async => Uint8List.fromList(const [1]),
    );

    await service.printSavedOrder(
      savedOrder: _savedSale,
      business: business,
      sellerFallback: '',
    );

    expect(gateway.printedPrinter?.url, 'printer://default');
  });

  test('does not choose an arbitrary printer when no default exists', () async {
    final gateway = _FakePrinterGateway(
      printers: const [
        ReceiptPrinterInfo(
          url: 'printer://other',
          name: 'Other',
          isDefault: false,
          isAvailable: true,
        ),
      ],
    );
    final service = ReceiptPrintService(gateway: gateway);

    await expectLater(
      service.printSavedOrder(
        savedOrder: _savedSale,
        business: business,
        sellerFallback: '',
      ),
      throwsA(
        isA<ReceiptPrintException>().having(
          (error) => error.failure,
          'failure',
          ReceiptPrintFailure.noDefaultPrinter,
        ),
      ),
    );
    expect(gateway.printCalls, 0);
  });

  test('reports a rejected printer job', () async {
    final gateway = _FakePrinterGateway(
      printers: const [
        ReceiptPrinterInfo(
          url: 'printer://default',
          name: 'Default A6',
          isDefault: true,
          isAvailable: true,
        ),
      ],
      printResult: false,
    );
    final service = ReceiptPrintService(
      gateway: gateway,
      pdfBuilder:
          ({
            required Sale sale,
            required AppSetting business,
            required String sellerFallback,
          }) async => Uint8List.fromList(const [1]),
    );

    await expectLater(
      service.printSavedOrder(
        savedOrder: _savedSale,
        business: business,
        sellerFallback: '',
      ),
      throwsA(
        isA<ReceiptPrintException>().having(
          (error) => error.failure,
          'failure',
          ReceiptPrintFailure.printRejected,
        ),
      ),
    );
  });

  test('reports when Windows has no installed printers', () async {
    final service = ReceiptPrintService(
      gateway: _FakePrinterGateway(printers: const []),
    );

    await expectLater(
      service.printSavedOrder(
        savedOrder: _savedSale,
        business: business,
        sellerFallback: '',
      ),
      throwsA(
        isA<ReceiptPrintException>().having(
          (error) => error.failure,
          'failure',
          ReceiptPrintFailure.noPrintersFound,
        ),
      ),
    );
  });

  test('reports an offline selected printer before sending the job', () async {
    final service = ReceiptPrintService(
      gateway: _FakePrinterGateway(printers: const []),
    );

    await expectLater(
      service.printA6Pdf(
        bytes: Uint8List.fromList(const [1]),
        documentName: 'SO.pdf',
        printer: const ReceiptPrinterInfo(
          url: 'printer://offline',
          name: 'Offline A6',
          isDefault: true,
          isAvailable: false,
        ),
      ),
      throwsA(
        isA<ReceiptPrintException>()
            .having(
              (error) => error.failure,
              'failure',
              ReceiptPrintFailure.printerOffline,
            )
            .having((error) => error.printerName, 'printerName', 'Offline A6'),
      ),
    );
  });

  test('reports when the configured printer name no longer exists', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = PrintPreferenceStore(
      preferences: preferences,
      serverKey: 'test-server',
      stationName: 'POS-1',
    );
    await store.write(
      'Main Outlet',
      const PrintPreference(
        printerUrl: 'printer://removed',
        printerName: 'Removed Driver',
      ),
    );
    final service = ReceiptPrintService(
      gateway: _FakePrinterGateway(
        printers: const [
          ReceiptPrinterInfo(
            url: 'printer://default',
            name: 'Default A6',
            isDefault: true,
            isAvailable: true,
          ),
        ],
      ),
      preferenceStore: store,
    );

    await expectLater(
      service.printSavedOrder(
        savedOrder: _savedSale,
        business: business,
        sellerFallback: '',
      ),
      throwsA(
        isA<ReceiptPrintException>()
            .having(
              (error) => error.failure,
              'failure',
              ReceiptPrintFailure.configuredPrinterNotFound,
            )
            .having(
              (error) => error.printerName,
              'printerName',
              'Removed Driver',
            ),
      ),
    );
  });

  test('classifies a printer port failure and preserves details', () async {
    final gateway = _FakePrinterGateway(
      printers: const [
        ReceiptPrinterInfo(
          url: 'printer://default',
          name: 'Default A6',
          isDefault: true,
          isAvailable: true,
        ),
      ],
      printError: Exception('The specified printer port is unknown'),
    );
    final service = ReceiptPrintService(
      gateway: gateway,
      pdfBuilder:
          ({
            required Sale sale,
            required AppSetting business,
            required String sellerFallback,
          }) async => Uint8List.fromList(const [1]),
    );

    await expectLater(
      service.printSavedOrder(
        savedOrder: _savedSale,
        business: business,
        sellerFallback: '',
      ),
      throwsA(
        isA<ReceiptPrintException>()
            .having(
              (error) => error.failure,
              'failure',
              ReceiptPrintFailure.invalidPrinterPort,
            )
            .having(
              (error) => error.technicalMessage,
              'technicalMessage',
              contains('port'),
            ),
      ),
    );
  });

  test('builds selected paper size and copies as one print job', () async {
    final gateway = _FakePrinterGateway(
      printers: const [
        ReceiptPrinterInfo(
          url: 'printer://default',
          name: 'Default',
          isDefault: true,
          isAvailable: true,
        ),
      ],
    );
    var builtCopies = 0;
    ReceiptTemplate? builtTemplate;
    final service = ReceiptPrintService(
      gateway: gateway,
      templatePdfBuilder:
          ({
            required Sale sale,
            required AppSetting business,
            required String sellerFallback,
            required ReceiptTemplate template,
            required int copies,
            required Map<String, Uint8List> imageBytes,
          }) async {
            builtCopies = copies;
            builtTemplate = template;
            return Uint8List.fromList(const [1]);
          },
    );
    final template = ReceiptTemplate.standardA6.copyWith(
      name: 'Large A5',
      templateName: 'Large A5',
      pageSize: ReceiptPageSize.a5,
      isBuiltIn: false,
    );

    await service.printSavedOrder(
      savedOrder: _savedSale,
      business: business,
      sellerFallback: '',
      template: template,
      copies: 3,
    );

    expect(builtCopies, 3);
    expect(builtTemplate?.name, 'Large A5');
    expect(gateway.printCalls, 1);
    expect(gateway.printedFormat?.width, PdfPageFormat.a5.width);
  });
}

const _savedSale = <String, dynamic>{
  'name': 'SO2026-0001',
  'outlet': 'Main Outlet',
  'can_show_price': 1,
  'sale_products': <Map<String, dynamic>>[],
};

class _FakePrinterGateway implements ReceiptPrinterGateway {
  _FakePrinterGateway({
    required this.printers,
    this.printResult = true,
    this.printError,
  });

  final List<ReceiptPrinterInfo> printers;
  final bool printResult;
  final Exception? printError;
  int printCalls = 0;
  ReceiptPrinterInfo? printedPrinter;
  String? printedDocumentName;
  PdfPageFormat? printedFormat;

  @override
  Future<List<ReceiptPrinterInfo>> listPrinters() async => printers;

  @override
  Future<bool> printPdf({
    required ReceiptPrinterInfo printer,
    required Uint8List bytes,
    required String documentName,
    required PdfPageFormat format,
  }) async {
    if (printError case final error?) throw error;
    printCalls++;
    printedPrinter = printer;
    printedDocumentName = documentName;
    printedFormat = format;
    return printResult;
  }
}
