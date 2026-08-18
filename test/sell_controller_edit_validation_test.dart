import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/features/sell/sell_controller.dart';
import 'package:ice_control_sale/features/sell/sale.dart';
import 'package:ice_control_sale/services/customer_service.dart';
import 'package:ice_control_sale/services/product_service.dart';
import 'package:ice_control_sale/services/sale_service.dart';

void main() {
  test('blocks Sale documents that are not editable', () async {
    final documents = <String, Map<String, dynamic>>{
      'PAID': _sale(status: 'Paid'),
      'SPLIT': _sale(totalSplitBill: 1),
      'DENIED': _sale(canEditBill: false),
      'DELETED': _sale(saleStatus: 'Deleted'),
      'ALLOWED': _sale(),
      'EDIT-DENIED': _sale(),
      'DRAFT-ALLOWED': _sale(saleStatus: 'Draft'),
    };
    final client = MockClient((request) async {
      final name = request.url.pathSegments.last;
      return http.Response(
        jsonEncode({
          'data': {...documents[name]!, 'name': name},
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

    await _expectBlocked(
      controller.openClosedOrder('PAID'),
      SaleEditBlockedReason.notUnpaid,
    );
    await _expectBlocked(
      controller.openClosedOrder('SPLIT'),
      SaleEditBlockedReason.splitBill,
    );
    await _expectBlocked(
      controller.openClosedOrder('DENIED'),
      SaleEditBlockedReason.notAllowed,
    );
    await _expectBlocked(
      controller.openClosedOrder('DELETED'),
      SaleEditBlockedReason.deleted,
    );

    await controller.openClosedOrder('ALLOWED');
    expect(controller.openedSale.value?.name, 'ALLOWED');
    expect(controller.currentSale.totalSplitBill, 0);

    final restrictedController = SellController(
      productService: ProductService(baseUri, client: client),
      customerService: CustomerService(baseUri, client: client),
      saleService: SaleService(baseUri, client: client),
      outletName: 'Main Outlet',
      stationName: 'Cashier 01',
      canEditBillProvider: () => false,
    );
    await _expectBlocked(
      restrictedController.openClosedOrder('EDIT-DENIED'),
      SaleEditBlockedReason.employeePermission,
    );
    await restrictedController.openPendingOrder('DRAFT-ALLOWED');
    expect(restrictedController.openedSale.value?.name, 'DRAFT-ALLOWED');
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

Map<String, dynamic> _sale({
  String status = 'Unpaid',
  String saleStatus = 'Closed',
  int totalSplitBill = 0,
  bool canEditBill = true,
}) {
  return {
    'doctype': 'Sale',
    'outlet': 'Main Outlet',
    'sale_status': saleStatus,
    'status': status,
    'total_split_bill': totalSplitBill,
    'can_edit_bill': canEditBill ? 1 : 0,
    'sale_products': <dynamic>[],
  };
}

Future<void> _expectBlocked(
  Future<void> operation,
  SaleEditBlockedReason reason,
) async {
  await expectLater(
    operation,
    throwsA(
      isA<SaleEditBlockedException>().having(
        (error) => error.reason,
        'reason',
        reason,
      ),
    ),
  );
}
