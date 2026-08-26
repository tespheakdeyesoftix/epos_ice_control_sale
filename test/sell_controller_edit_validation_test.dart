import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/features/navigation/app_destination.dart';
import 'package:ice_control_sale/features/navigation/app_shell_controller.dart';
import 'package:ice_control_sale/features/sell/sell_controller.dart';
import 'package:ice_control_sale/features/sell/sale.dart';
import 'package:ice_control_sale/services/customer_service.dart';
import 'package:ice_control_sale/services/product_service.dart';
import 'package:ice_control_sale/services/sale_service.dart';

void main() {
  test(
    'all edit entry points use the server-validated Sale endpoint',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        final name = request.url.queryParameters['name']!;
        return http.Response(
          jsonEncode({
            'message': {
              'name': name,
              'doctype': 'Sale',
              'outlet': 'Main Outlet',
              'sale_status': 'Deleted',
              'status': 'Paid',
              'total_split_bill': 1,
              'can_edit_bill': 0,
              'sale_products': <dynamic>[],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final baseUri = Uri.parse('http://127.0.0.1:8888/');
      final controller = SellController(
        productService: ProductService(baseUri, client: client),
        customerService: CustomerService(baseUri, client: client),
        saleService: SaleService(baseUri, client: client),
        outletName: 'Main Outlet',
        stationName: 'Cashier 01',
      );

      await controller.openClosedOrder('SO-CLOSED');
      expect(controller.openedSale.value?.name, 'SO-CLOSED');
      expect(controller.currentSale.totalSplitBill, 1);
      expect(controller.isSaleDirty, isFalse);
      controller.startNewSale();
      await controller.openPendingOrder('SO-DRAFT');
      expect(controller.openedSale.value?.name, 'SO-DRAFT');
      controller.startNewSale();
      await controller.searchBillForEdit('SO-SCANNED');
      expect(controller.openedSale.value?.name, 'SO-SCANNED');

      expect(requests, hasLength(3));
      for (final request in requests) {
        expect(
          request.url.path,
          '/api/method/ice_control.selling.doctype.sale.sale.get_sale_for_edit',
        );
        expect(request.url.queryParameters['station_name'], 'Cashier 01');
      }
      expect(requests.map((request) => request.url.queryParameters['name']), [
        'SO-CLOSED',
        'SO-DRAFT',
        'SO-SCANNED',
      ]);
    },
  );

  test('opened Sale only blocks navigation after local edits', () async {
    final client = MockClient((request) async {
      final name = request.url.queryParameters['name']!;
      return http.Response(
        jsonEncode({
          'message': {
            'name': name,
            'doctype': 'Sale',
            'outlet': 'Main Outlet',
            'sale_status': 'Closed',
            'status': 'Unpaid',
            'can_edit_bill': 1,
            'reference_number': '',
            'sale_products': <dynamic>[],
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final baseUri = Uri.parse('http://127.0.0.1:8888/');
    final controller = SellController(
      productService: ProductService(baseUri, client: client),
      customerService: CustomerService(baseUri, client: client),
      saleService: SaleService(baseUri, client: client),
      outletName: 'Main Outlet',
      stationName: 'Cashier 01',
    );
    await controller.openClosedOrder('SO-CLOSED');

    final shell = AppShellController(sellController: controller);
    var unfinishedSalePromptCount = 0;
    expect(
      await shell.navigateTo(
        AppDestination.saleSummary,
        resolveUnfinishedSale: () async {
          unfinishedSalePromptCount++;
          return false;
        },
      ),
      isTrue,
    );
    expect(unfinishedSalePromptCount, 0);
    await shell.navigateTo(
      AppDestination.sale,
      resolveUnfinishedSale: () async => true,
    );

    controller.updateReferenceNumber('UPDATED-REFERENCE');
    expect(controller.isSaleDirty, isTrue);
    expect(
      await shell.navigateTo(
        AppDestination.saleSummary,
        resolveUnfinishedSale: () async {
          unfinishedSalePromptCount++;
          return false;
        },
      ),
      isFalse,
    );
    expect(unfinishedSalePromptCount, 1);
    controller.updateReferenceNumber('');
    expect(controller.isSaleDirty, isFalse);
  });

  test('delete_bill permission applies to Draft and Closed Sales', () async {
    var requestCount = 0;
    final client = MockClient((_) async {
      requestCount++;
      return http.Response('{}', 200);
    });
    final baseUri = Uri.parse('http://127.0.0.1:8888/');
    final controller = SellController(
      productService: ProductService(baseUri, client: client),
      customerService: CustomerService(baseUri, client: client),
      saleService: SaleService(baseUri, client: client),
      outletName: 'Main Outlet',
      stationName: 'Cashier 01',
      canDeleteBillProvider: () => false,
    );

    for (final status in ['Draft', 'Closed']) {
      controller.openedSale.value = Sale(
        name: 'SO-$status',
        outlet: 'Main Outlet',
        saleStatus: status,
        saleProducts: const [],
      );
      await expectLater(
        controller.deleteOpenedSale('Test note'),
        throwsA(isA<DeleteBillPermissionException>()),
      );
      expect(controller.openedSale.value?.name, 'SO-$status');
    }
    expect(requestCount, 0);
  });
}
