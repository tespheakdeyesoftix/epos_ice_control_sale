import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/app/session_outlet_controller.dart';
import 'package:ice_control_sale/features/navigation/app_destination.dart';
import 'package:ice_control_sale/features/navigation/app_shell_controller.dart';
import 'package:ice_control_sale/features/sale_summary/sale_summary_controller.dart';
import 'package:ice_control_sale/features/sell/sell_controller.dart';
import 'package:ice_control_sale/services/customer_service.dart';
import 'package:ice_control_sale/services/product_service.dart';
import 'package:ice_control_sale/services/sale_service.dart';

void main() {
  test('refreshes stale summary only after switching back to it', () async {
    var summaryRequests = 0;
    var recentSaleRequests = 0;
    final client = MockClient((request) async {
      if (request.url.path.endsWith('get_daily_sale_summary')) {
        summaryRequests++;
        return _jsonResponse({'message': <String, dynamic>{}});
      }
      if (request.url.path == '/api/resource/Sale') {
        recentSaleRequests++;
        return _jsonResponse({'data': <dynamic>[]});
      }
      return _jsonResponse(<String, dynamic>{});
    });
    final baseUri = Uri.parse('http://127.0.0.1:8888/');
    final saleService = SaleService(baseUri, client: client);
    final sellController = SellController(
      productService: ProductService(baseUri, client: client),
      customerService: CustomerService(baseUri, client: client),
      saleService: saleService,
      outletName: 'Main Outlet',
      stationName: 'Cashier 01',
    );
    final shellController = AppShellController(sellController: sellController);
    final summaryController = SaleSummaryController(
      saleService: saleService,
      outletController: SessionOutletController(
        configuredOutlet: 'Main Outlet',
      ),
      sellController: sellController,
      appShellController: shellController,
    );
    summaryController.onInit();
    addTearDown(summaryController.onClose);

    await _waitUntil(() => summaryRequests == 1 && recentSaleRequests == 1);

    sellController.saleDataRevision.value++;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(summaryRequests, 1);
    expect(recentSaleRequests, 1);

    await shellController.navigateTo(
      AppDestination.saleSummary,
      resolveUnfinishedSale: () async => true,
    );
    await _waitUntil(() => summaryRequests == 2 && recentSaleRequests == 2);
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
