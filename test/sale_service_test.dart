import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/features/sell/sale.dart';
import 'package:ice_control_sale/features/sell/sale_product.dart';
import 'package:ice_control_sale/services/sale_service.dart';

void main() {
  test('ទាញ Sale document និង sale_products សម្រាប់កែប្រែ', () async {
    late http.Request sentRequest;
    final client = MockClient((request) async {
      sentRequest = request;
      return http.Response(
        jsonEncode({
          'data': {
            'name': 'SO-DRAFT-0001',
            'doctype': 'Sale',
            'posting_date': '2026-08-15',
            'outlet': 'ទឹកកកដើម',
            'customer': 'CUST-001',
            'customer_name': 'Customer A',
            'sale_status': 'Draft',
            'sale_products': [
              {
                'product_code': '01',
                'product_name': 'Product A',
                'product_category': 'Ice',
                'unit': 'Unit',
                'price': 15000,
                'quantity': 2,
              },
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

    final sale = await service.getSale('SO-DRAFT-0001');

    expect(sentRequest.method, 'GET');
    expect(sentRequest.url.path, '/api/resource/Sale/SO-DRAFT-0001');
    expect(sale.name, 'SO-DRAFT-0001');
    expect(sale.saleStatus, 'Draft');
    expect(sale.customer, 'CUST-001');
    expect(sale.saleProducts, hasLength(1));
    expect(sale.saleProducts.single.quantity, 2);
  });

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

  test('ទាញចំនួនការលក់ Closed របស់ថ្ងៃនេះតាមសាខា', () async {
    late http.Request sentRequest;
    final client = MockClient((request) async {
      sentRequest = request;
      return http.Response(
        jsonEncode({'message': 9}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = SaleService(
      Uri.parse('http://127.0.0.1:8888/'),
      client: client,
    );

    final count = await service.getTodayClosedSaleCount('ទឹកកកដើម');

    expect(
      sentRequest.url.path,
      '/api/method/frappe.desk.reportview.get_count',
    );
    expect(sentRequest.url.queryParameters['doctype'], 'Sale');
    expect(sentRequest.url.queryParameters['fields'], '[]');
    expect(sentRequest.url.queryParameters['distinct'], 'false');
    final filters = jsonDecode(sentRequest.url.queryParameters['filters']!);
    expect(filters[0], ['Sale', 'outlet', '=', 'ទឹកកកដើម']);
    expect(filters[1], ['Sale', 'sale_status', '=', 'Closed']);
    expect(filters[2], ['Sale', 'posting_date', 'Timespan', 'today']);
    expect(count, 9);
  });

  test('ទាញបញ្ជីការលក់ Closed តាមសាខាជាមួយព័ត៌មានអ្នកបង្កើត', () async {
    late http.Request sentRequest;
    final client = MockClient((request) async {
      sentRequest = request;
      return http.Response(
        jsonEncode({
          'data': [
            {
              'name': 'SO-CLOSED-0001',
              'posting_date': '2026-08-18',
              'customer': 'C457',
              'customer_name': 'Customer A',
              'sale_status': 'Closed',
              'owner': 'Administrator',
              'creation': '2026-08-18 08:30:00',
              'total_sale_quantity': 12,
              'total_amount': 180000,
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

    final page = await service.getClosedSales(
      outlet: 'ទឹកកកដើម',
      search: 'C457',
      startDate: '2026-08-17',
      endDate: '2026-08-18',
      offset: 30,
    );

    final filters = jsonDecode(sentRequest.url.queryParameters['filters']!);
    expect(filters[0], ['sale_status', '=', 'Closed']);
    expect(filters[1], ['outlet', '=', 'ទឹកកកដើម']);
    expect(filters[2], ['posting_date', '>=', '2026-08-17']);
    expect(filters[3], ['posting_date', '<=', '2026-08-18']);
    expect(sentRequest.url.queryParameters['limit_start'], '30');
    final fields = jsonDecode(sentRequest.url.queryParameters['fields']!);
    expect(fields, containsAll(['sale_status', 'owner', 'creation']));
    expect(
      sentRequest.url.queryParameters['order_by'],
      'posting_date desc, creation desc',
    );
    expect(page.items.single.name, 'SO-CLOSED-0001');
    expect(page.items.single.saleStatus, 'Closed');
    expect(page.items.single.owner, 'Administrator');
    expect(page.items.single.creation, DateTime(2026, 8, 18, 8, 30));
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

  test('លុប Sale ជាមួយកំណត់ចំណាំ', () async {
    late http.Request sentRequest;
    final client = MockClient((request) async {
      sentRequest = request;
      return http.Response(
        jsonEncode({
          'message': {'name': 'SO-CLOSED-0001'},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = SaleService(
      Uri.parse('http://127.0.0.1:8888/'),
      client: client,
    );

    await service.deleteSale(
      docName: 'SO-CLOSED-0001',
      deletedNote: 'បញ្ចូលខុស',
    );

    expect(sentRequest.method, 'POST');
    expect(
      sentRequest.url.path,
      '/api/method/ice_control.api.v1.sale.delete_sale',
    );
    expect(sentRequest.bodyFields['doc_name'], 'SO-CLOSED-0001');
    expect(sentRequest.bodyFields['deleted_note'], 'បញ្ចូលខុស');
  });
}
