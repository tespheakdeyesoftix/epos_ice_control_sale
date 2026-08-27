import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/features/sell/sale.dart';
import 'package:ice_control_sale/features/sell/sale_product.dart';
import 'package:ice_control_sale/services/sale_service.dart';

void main() {
  test('loads payment types from the payment type API', () async {
    late Uri requestedUri;
    final service = SaleService(
      Uri.parse('https://ice.test/'),
      client: MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({
            'message': [
              {'name': 'Cash USD', 'currency': 'USD', 'exchange_rate': 4000},
            ],
          }),
          200,
        );
      }),
    );

    final paymentTypes = await service.getPaymentTypes();

    expect(
      requestedUri.path,
      '/api/method/ice_control.api.v1.utils.get_payment_types',
    );
    expect(paymentTypes.single.name, 'Cash USD');
    expect(paymentTypes.single.currency, 'USD');
    expect(paymentTypes.single.exchangeRate, 4000);
  });

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
              'can_show_price': 0,
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
    expect(sentRequest.url.queryParameters['limit_page_length'], '30');
    final filters = jsonDecode(sentRequest.url.queryParameters['filters']!);
    expect(filters[0], ['sale_status', '=', 'Draft']);
    expect(filters[1], ['outlet', '=', 'ទឹកកកដើម']);
    expect(filters[2], ['posting_date', '=', '2026-08-15']);
    final fields = jsonDecode(sentRequest.url.queryParameters['fields']!);
    expect(fields, contains('customer'));
    expect(fields, contains('phone_number'));
    expect(fields, contains('can_show_price'));
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
    expect(page.items.single.canShowPrice, isFalse);
    expect(page.hasMore, isFalse);
  });

  test('closed order selector filters closed unpaid sales by outlet', () async {
    late http.Request sentRequest;
    final client = MockClient((request) async {
      sentRequest = request;
      return http.Response(
        jsonEncode({'data': <dynamic>[]}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = SaleService(
      Uri.parse('http://127.0.0.1:8888/'),
      client: client,
    );

    await service.getPendingOrders(
      outlet: 'Main Outlet',
      saleStatus: 'Closed',
      status: 'Unpaid',
    );

    final filters = jsonDecode(sentRequest.url.queryParameters['filters']!);
    expect(filters[0], ['sale_status', '=', 'Closed']);
    expect(filters[1], ['outlet', '=', 'Main Outlet']);
    expect(filters[2], ['status', '=', 'Unpaid']);
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

  test('ទាញកាលបរិច្ឆេទ និងសរុបការលក់ដែលបានផ្អាក', () async {
    late http.Request sentRequest;
    final client = MockClient((request) async {
      sentRequest = request;
      return http.Response(
        jsonEncode({
          'message': {
            'pending_date': '2026-08-15 11:39:07.917715',
            'total_pending_order': 3,
            'pending_order_amount': 1470000.0,
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

    final info = await service.getMaxPendingOrderDate('ទឹកកកដើម');

    expect(sentRequest.method, 'GET');
    expect(
      sentRequest.url.path,
      '/api/method/ice_control.api.v1.sale.get_max_pending_order_date',
    );
    expect(sentRequest.url.queryParameters['outlet'], 'ទឹកកកដើម');
    expect(info.pendingDate, DateTime(2026, 8, 15, 11, 39, 7, 917, 715));
    expect(info.totalPendingOrder, 3);
    expect(info.pendingOrderAmount, 1470000);
    expect(info.shouldWarn(now: DateTime(2026, 8, 15, 12, 39, 8)), isTrue);
    expect(info.shouldWarn(now: DateTime(2026, 8, 15, 12, 39, 7)), isFalse);
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
              'total_split_bill': 3,
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
    expect(sentRequest.url.queryParameters['limit_page_length'], '20');
    final fields = jsonDecode(sentRequest.url.queryParameters['fields']!);
    expect(
      fields,
      containsAll(['sale_status', 'total_split_bill', 'owner', 'creation']),
    );
    expect(
      sentRequest.url.queryParameters['order_by'],
      'posting_date desc, creation desc',
    );
    expect(page.items.single.name, 'SO-CLOSED-0001');
    expect(page.items.single.saleStatus, 'Closed');
    expect(page.items.single.totalSplitBill, 3);
    expect(page.items.single.owner, 'Administrator');
    expect(page.items.single.creation, DateTime(2026, 8, 18, 8, 30));
  });

  test('sorts closed sales through Frappe order_by', () async {
    late http.Request sentRequest;
    final client = MockClient((request) async {
      sentRequest = request;
      return http.Response(
        jsonEncode({'data': <Object>[]}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = SaleService(
      Uri.parse('http://127.0.0.1:8888/'),
      client: client,
    );

    await service.getClosedSales(
      outlet: 'ទឹកកកដើម',
      sortField: 'total_amount',
      sortAscending: true,
    );

    expect(
      sentRequest.url.queryParameters['order_by'],
      'total_amount asc, name asc',
    );
  });

  test('global search can request latest modified closed sales', () async {
    late http.Request sentRequest;
    final client = MockClient((request) async {
      sentRequest = request;
      return http.Response(
        jsonEncode({'data': <Object>[]}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = SaleService(
      Uri.parse('http://127.0.0.1:8888/'),
      client: client,
    );

    await service.getClosedSales(
      outlet: 'OUTLET-1',
      search: 'C457',
      sortField: 'modified',
      limit: 10,
    );

    expect(
      sentRequest.url.queryParameters['order_by'],
      'modified desc, name desc',
    );
    expect(sentRequest.url.queryParameters['limit_page_length'], '10');
    final fields = jsonDecode(sentRequest.url.queryParameters['fields']!);
    expect(
      fields,
      containsAll([
        'customer',
        'driver',
        'driver_name',
        'plate_number',
        'reference_number',
      ]),
    );
    final filters = jsonDecode(sentRequest.url.queryParameters['filters']!);
    expect(filters, contains(equals(['sale_status', '=', 'Closed'])));
    expect(filters, contains(equals(['outlet', '=', 'OUTLET-1'])));
    final searchFilters = jsonDecode(
      sentRequest.url.queryParameters['or_filters']!,
    );
    expect(searchFilters, contains(equals(['name', 'like', '%C457%'])));
    expect(
      searchFilters,
      contains(equals(['customer_name', 'like', '%C457%'])),
    );
    expect(searchFilters, contains(equals(['customer', 'like', '%C457%'])));
    expect(searchFilters, contains(equals(['phone_number', 'like', '%C457%'])));
    expect(searchFilters, contains(equals(['driver', 'like', '%C457%'])));
    expect(searchFilters, contains(equals(['driver_name', 'like', '%C457%'])));
    expect(
      searchFilters,
      contains(equals(['reference_number', 'like', '%C457%'])),
    );
  });

  test('closed sale count uses the same filters as the record list', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.url.path == '/api/resource/Sale') {
        return http.Response(jsonEncode({'data': <Object>[]}), 200);
      }
      return http.Response(jsonEncode({'message': 750}), 200);
    });
    final service = SaleService(
      Uri.parse('http://127.0.0.1:8888/'),
      client: client,
    );

    await service.getClosedSales(
      outlet: 'ទឹកកកដើម',
      search: 'C457',
      startDate: '2026-08-17',
      endDate: '2026-08-18',
    );
    final total = await service.getClosedSaleCount(
      outlet: 'ទឹកកកដើម',
      search: 'C457',
      startDate: '2026-08-17',
      endDate: '2026-08-18',
    );

    expect(requests, hasLength(2));
    expect(
      requests[1].url.path,
      '/api/method/frappe.desk.reportview.get_count',
    );
    expect(
      requests[1].url.queryParameters['filters'],
      requests[0].url.queryParameters['filters'],
    );
    expect(
      requests[1].url.queryParameters['or_filters'],
      requests[0].url.queryParameters['or_filters'],
    );
    expect(total, 750);
  });

  test('advanced closed-sale filters include child product filter', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      return request.url.path == '/api/resource/Sale'
          ? http.Response(jsonEncode({'data': <Object>[]}), 200)
          : http.Response(jsonEncode({'message': 4}), 200);
    });
    final service = SaleService(
      Uri.parse('http://127.0.0.1:8888/'),
      client: client,
    );

    await service.getClosedSales(
      outlet: 'OUTLET-1',
      customer: 'CUS-1',
      driver: 'DRIVER-1',
      status: 'Partially Paid',
      splitBillOnly: true,
      productCode: 'ICE-10KG',
      productChildDoctype: 'Sale Product',
    );
    await service.getClosedSaleCount(
      outlet: 'OUTLET-1',
      customer: 'CUS-1',
      driver: 'DRIVER-1',
      status: 'Partially Paid',
      splitBillOnly: true,
      productCode: 'ICE-10KG',
      productChildDoctype: 'Sale Product',
    );

    final filters = jsonDecode(requests.first.url.queryParameters['filters']!);
    expect(filters[2], ['customer', '=', 'CUS-1']);
    expect(filters[3], ['driver', '=', 'DRIVER-1']);
    expect(filters[4], ['status', '=', 'Partially Paid']);
    expect(filters[5], ['total_split_bill', '>', 1]);
    expect(filters[6], ['Sale Product', 'product_code', '=', 'ICE-10KG']);
    expect(
      requests.last.url.queryParameters['filters'],
      requests.first.url.queryParameters['filters'],
    );
  });

  test('loads doctype meta and generic resource rows', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.url.path.endsWith('get_doctype_meta')) {
        return http.Response(
          jsonEncode({
            'message': {
              'title_field': 'customer_name',
              'search_fields': 'phone_number_1,keyword',
              'image_field': 'photo',
              'fields': <Object>[],
            },
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'data': [
            {'name': 'CUS-1', 'customer_name': 'Customer One'},
          ],
        }),
        200,
      );
    });
    final service = SaleService(
      Uri.parse('http://127.0.0.1:8888/'),
      client: client,
    );

    final meta = await service.getDoctypeMeta('Customer');
    final rows = await service.getDoctypeRows(
      doctype: 'Customer',
      fields: const ['name', 'customer_name'],
      orFilters: const [
        ['customer_name', 'like', '%One%'],
      ],
    );

    expect(requests.first.url.queryParameters['doctype'], 'Customer');
    expect(requests.last.url.path, '/api/resource/Customer');
    expect(meta['title_field'], 'customer_name');
    expect(rows.single['name'], 'CUS-1');
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
      stationName: 'Cashier 01',
    );

    expect(sentRequest.method, 'POST');
    expect(
      sentRequest.url.path,
      '/api/method/ice_control.api.v1.sale.delete_sale',
    );
    expect(sentRequest.bodyFields['doc_name'], 'SO-CLOSED-0001');
    expect(sentRequest.bodyFields['deleted_note'], 'បញ្ចូលខុស');
    expect(sentRequest.bodyFields['station_name'], 'Cashier 01');
  });

  test('loads a server-validated Sale for editing', () async {
    late http.Request sentRequest;
    final client = MockClient((request) async {
      sentRequest = request;
      return http.Response(
        jsonEncode({
          'message': {
            'name': 'SO-SEARCH-0001',
            'doctype': 'Sale',
            'outlet': 'ទឹកកកដើម',
            'sale_status': 'Closed',
            'sale_products': const [],
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

    final sale = await service.getSaleForEdit(
      name: ' SO-SEARCH-0001 ',
      stationName: ' Cashier 01 ',
    );

    expect(sentRequest.method, 'GET');
    expect(
      sentRequest.url.path,
      '/api/method/ice_control.selling.doctype.sale.sale.get_sale_for_edit',
    );
    expect(sentRequest.url.queryParameters['name'], 'SO-SEARCH-0001');
    expect(sentRequest.url.queryParameters['station_name'], 'Cashier 01');
    expect(sale.name, 'SO-SEARCH-0001');
    expect(sale.saleStatus, 'Closed');
  });

  test('finds one Sale by exact outlet and scanned document name', () async {
    late http.Request sentRequest;
    final client = MockClient((request) async {
      sentRequest = request;
      return http.Response(
        jsonEncode({
          'data': [
            {
              'name': 'SO-SCAN-0001',
              'posting_date': '2026-08-23',
              'outlet': 'OUTLET-1',
              'sale_status': 'Closed',
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

    final sale = await service.findSaleByDocumentName(
      outlet: ' OUTLET-1 ',
      documentName: ' SO-SCAN-0001 ',
    );

    final filters = jsonDecode(sentRequest.url.queryParameters['filters']!);
    expect(sentRequest.url.path, '/api/resource/Sale');
    expect(filters, [
      ['outlet', '=', 'OUTLET-1'],
      ['name', '=', 'SO-SCAN-0001'],
    ]);
    expect(sentRequest.url.queryParameters['limit_page_length'], '1');
    expect(sale?.name, 'SO-SCAN-0001');
  });
}
