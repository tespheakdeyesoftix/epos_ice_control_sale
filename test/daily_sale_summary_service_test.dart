import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/services/sale_service.dart';

void main() {
  test('loads daily sale summary for outlet', () async {
    late http.Request sentRequest;
    final service = SaleService(
      Uri.parse('https://example.com/'),
      client: MockClient((request) async {
        sentRequest = request;
        return http.Response(
          jsonEncode({
            'message': {
              'total_order': 2,
              'total_amount': 6300000,
              'total_quantity': 20.5,
              'total_pending_order': 3,
              'total_pending_amount': 1470000,
              'total_pending_quantity': 12,
              'total_deleted_order': 2,
              'total_deleted_amount': 320000,
              'total_deleted_quantity': 8.5,
              'default_unit': 'កេស',
              'sale_product_summary': [
                {
                  'product_code': 'P-01',
                  'product_name': 'ទឹកកកដើម',
                  'unit': 'ដើម',
                  'quantity': 12,
                  'free_quantity': 1,
                  'return_quantity': 2,
                  'split_quantity': 0,
                  'total_sale_quantity': 11,
                  'total_amount': 165000,
                },
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final summary = await service.getDailySaleSummary('សាខាទី១');

    expect(sentRequest.method, 'GET');
    expect(sentRequest.url.queryParameters['outlet'], 'សាខាទី១');
    expect(summary.totalOrder, 2);
    expect(summary.totalAmount, 6300000);
    expect(summary.totalQuantity, 20.5);
    expect(summary.totalPendingOrder, 3);
    expect(summary.totalPendingQuantity, 12);
    expect(summary.totalDeletedOrder, 2);
    expect(summary.totalDeletedAmount, 320000);
    expect(summary.totalDeletedQuantity, 8.5);
    expect(summary.defaultUnit, 'កេស');
    expect(summary.saleProductSummary, hasLength(1));
    expect(summary.saleProductSummary.single.productCode, 'P-01');
    expect(summary.saleProductSummary.single.productName, 'ទឹកកកដើម');
    expect(summary.saleProductSummary.single.quantity, 12);
    expect(summary.saleProductSummary.single.freeQuantity, 1);
    expect(summary.saleProductSummary.single.returnQuantity, 2);
    expect(summary.saleProductSummary.single.totalSaleQuantity, 11);
    expect(summary.saleProductSummary.single.totalAmount, 165000);
  });

  test(
    'loads today\'s 10 most recently modified closed sales for outlet',
    () async {
      late http.Request sentRequest;
      final service = SaleService(
        Uri.parse('https://example.com/'),
        client: MockClient((request) async {
          sentRequest = request;
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'name': 'SALE-0010',
                  'posting_date': '2026-08-20',
                  'customer_name': 'Customer',
                  'customer_photo': '/files/customer.jpg',
                  'total_sale_quantity': 4,
                  'outlet_unit': 'Case',
                  'total_amount': 120000,
                  'sale_status': 'Closed',
                  'status': 'Paid',
                  'modified': '2026-08-20 10:30:00',
                },
              ],
            }),
            200,
          );
        }),
      );

      final orders = await service.getRecentClosedSales(
        outlet: 'Main Outlet',
        postingDate: DateTime(2026, 8, 20),
      );

      expect(sentRequest.url.path, '/api/resource/Sale');
      expect(jsonDecode(sentRequest.url.queryParameters['filters']!), [
        ['sale_status', '=', 'Closed'],
        ['posting_date', '=', '2026-08-20'],
        ['outlet', '=', 'Main Outlet'],
      ]);
      expect(sentRequest.url.queryParameters['order_by'], 'modified desc');
      expect(sentRequest.url.queryParameters['limit_page_length'], '10');
      expect(orders, hasLength(1));
      expect(orders.single.name, 'SALE-0010');
      expect(orders.single.customerPhoto, '/files/customer.jpg');
      expect(orders.single.totalSaleQuantity, 4);
      expect(orders.single.outletUnit, 'Case');
      expect(orders.single.status, 'Paid');
      expect(orders.single.modified, DateTime(2026, 8, 20, 10, 30));
    },
  );
}
