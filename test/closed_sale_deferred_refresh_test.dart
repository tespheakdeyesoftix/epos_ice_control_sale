import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/features/closed_sales/closed_sale_controller.dart';
import 'package:ice_control_sale/features/navigation/app_destination.dart';
import 'package:ice_control_sale/features/navigation/app_shell_controller.dart';
import 'package:ice_control_sale/features/sell/sell_controller.dart';
import 'package:ice_control_sale/services/customer_service.dart';
import 'package:ice_control_sale/services/product_service.dart';
import 'package:ice_control_sale/services/sale_service.dart';

void main() {
  test('updates badge immediately but defers the closed-sale list', () async {
    var saleListRequests = 0;
    var countRequests = 0;
    final client = MockClient((request) async {
      if (request.url.path == '/api/resource/Sale') {
        saleListRequests++;
        return _jsonResponse({'data': <dynamic>[]});
      }
      if (request.url.path.endsWith('frappe.desk.reportview.get_count')) {
        countRequests++;
        return _jsonResponse({'message': 0});
      }
      return _jsonResponse(<String, dynamic>{});
    });
    final baseUri = Uri.parse('http://127.0.0.1:8888/');
    final sellController = SellController(
      productService: ProductService(baseUri, client: client),
      customerService: CustomerService(baseUri, client: client),
      saleService: SaleService(baseUri, client: client),
      outletName: 'Main Outlet',
      stationName: 'Cashier 01',
    );
    final shellController = AppShellController(sellController: sellController);
    final closedSaleController = ClosedSaleController(
      sellController: sellController,
      appShellController: shellController,
    );
    closedSaleController.onInit();
    addTearDown(closedSaleController.onClose);

    await _waitUntil(() => saleListRequests == 1 && countRequests == 2);

    sellController.closedSaleRevision.value++;
    await _waitUntil(() => countRequests == 3);
    expect(saleListRequests, 1);

    await shellController.navigateTo(
      AppDestination.closedSales,
      resolveUnfinishedSale: () async => true,
      );
      await _waitUntil(() => saleListRequests == 2);
      expect(countRequests, 4);
  });
}

http.Response _jsonResponse(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json'},
);

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Timed out waiting for asynchronous controller work.');
}
