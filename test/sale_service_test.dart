import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/features/sell/sale.dart';
import 'package:ice_control_sale/features/sell/sale_product.dart';
import 'package:ice_control_sale/services/sale_service.dart';

void main() {
  test('ទាញបញ្ជីការលក់ Draft តាមសាខាពី Frappe resource', () async {
    late http.Request sentRequest;
    final client = MockClient((request) async {
      sentRequest = request;
      return http.Response(
        jsonEncode({
          'data': [
            {
              'name': 'SO-DRAFT-0001',
              'posting_date': '2026-08-15',
              'customer_name': 'Customer A',
              'driver_name': 'Driver A',
              'total_sale_quantity': 10,
              'total_amount': 150000,
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = SaleService(
      Uri.parse('http://127.0.0.1:8888/'),
      client: client,
    );

    final page = await service.getPendingOrders(
      outlet: 'ទឹកកកដើម',
      search: 'CUST-001',
      postingDate: '2026-08-15',
      offset: 30,
    );

    expect(sentRequest.method, 'GET');
    expect(sentRequest.url.path, '/api/resource/Sale');
    expect(sentRequest.url.queryParameters['limit_start'], '30');
    final filters = jsonDecode(sentRequest.url.queryParameters['filters']!);
    expect(filters[0], ['sale_status', '=', 'Draft']);
    expect(filters[1], ['outlet', '=', 'ទឹកកកដើម']);
    expect(filters[2], ['posting_date', '=', '2026-08-15']);
    final fields = jsonDecode(sentRequest.url.queryParameters['fields']!);
    expect(fields, contains('customer'));
    expect(fields, contains('phone_number'));
    final orFilters = jsonDecode(
      sentRequest.url.queryParameters['or_filters']!,
    );
    expect(orFilters[0], ['name', 'like', '%CUST-001%']);
    expect(orFilters[1], ['customer_name', 'like', '%CUST-001%']);
    expect(orFilters[2], ['customer', 'like', '%CUST-001%']);
    expect(orFilters[3], ['phone_number', 'like', '%CUST-001%']);
    expect(page.items, hasLength(1));
    expect(page.items.single.name, 'SO-DRAFT-0001');
    expect(page.items.single.totalSaleQuantity, 10);
    expect(page.items.single.totalAmount, 150000);
    expect(page.hasMore, isFalse);
  });

  test('ទាញចំនួនការលក់ដែលបានផ្អាកតាមសាខា', () async {
    late http.Request sentRequest;
    final client = MockClient((request) async {
      sentRequest = request;
      return http.Response(
        jsonEncode({'message': 7}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = SaleService(
      Uri.parse('http://127.0.0.1:8888/'),
      client: client,
    );

    final count = await service.getTotalPendingOrder('ទឹកកកដើម');

    expect(sentRequest.method, 'GET');
    expect(
      sentRequest.url.path,
      '/api/method/ice_control.api.v1.sale.get_total_pending_order',
    );
    expect(sentRequest.url.queryParameters['outlet'], 'ទឹកកកដើម');
    expect(count, 7);
  });

  test('រក្សាទុក Sale និង sale_products តាម Frappe API', () async {
    late http.Request sentRequest;
    final client = MockClient((request) async {
      sentRequest = request;
      return http.Response(
        jsonEncode({
          'message': {
            'name': 'SO-0001',
            'customer': 'CU.0001',
            'sale_products': [
              {'product_code': '01', 'quantity': 2},
            ],
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = SaleService(
      Uri.parse('http://127.0.0.1:8888/'),
      client: client,
    );
    final sale = Sale(
      outlet: 'ទឹកកកដើម',
      customer: 'CU.0001',
      customerName: 'អតិថិជន សុខា',
      postingDate: DateTime(2026, 8, 14),
      saleProducts: const [
        SaleProduct(
          productCode: '01',
          productName: 'ទឹកកកដើមធំ',
          productCategory: 'ទឹកកកដើម',
          unit: 'ដើម',
          price: 15000,
          quantity: 2,
        ),
      ],
    );

    final savedOrder = await service.saveOrder(sale);

    expect(sentRequest.method, 'POST');
    expect(
      sentRequest.url.path,
      '/api/method/ice_control.api.v1.sale.save_order',
    );
    final payload = jsonDecode(sentRequest.bodyFields['data']!);
    expect(payload, contains('doc'));
    expect(payload['doc']['doctype'], 'Sale');
    expect(payload['doc']['sale_status'], 'Closed');
    expect(payload['doc']['customer'], 'CU.0001');
    expect(payload['doc']['posting_date'], '2026-08-14');
    expect(payload['doc']['sale_products'], hasLength(1));
    expect(payload['doc']['sale_products'][0]['product_code'], '01');
    expect(savedOrder['name'], 'SO-0001');
    expect(savedOrder['sale_products'], hasLength(1));
  });
}
