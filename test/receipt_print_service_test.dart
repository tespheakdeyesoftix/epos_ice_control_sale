import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/app/app_setting.dart';
import 'package:ice_control_sale/features/sell/sale.dart';
import 'package:ice_control_sale/services/receipt_print_service.dart';

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

  test(
    'prefers the configured Canon printer over the system default',
    () async {
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

      expect(gateway.printedPrinter?.url, 'printer://canon');
    },
  );

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
}

const _savedSale = <String, dynamic>{
  'name': 'SO2026-0001',
  'outlet': 'Main Outlet',
  'can_show_price': 1,
  'sale_products': <Map<String, dynamic>>[],
};

class _FakePrinterGateway implements ReceiptPrinterGateway {
  _FakePrinterGateway({required this.printers, this.printResult = true});

  final List<ReceiptPrinterInfo> printers;
  final bool printResult;
  int printCalls = 0;
  ReceiptPrinterInfo? printedPrinter;
  String? printedDocumentName;

  @override
  Future<List<ReceiptPrinterInfo>> listPrinters() async => printers;

  @override
  Future<bool> printPdf({
    required ReceiptPrinterInfo printer,
    required Uint8List bytes,
    required String documentName,
  }) async {
    printCalls++;
    printedPrinter = printer;
    printedDocumentName = documentName;
    return printResult;
  }
}
