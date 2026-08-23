import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/features/sell/customer.dart';
import 'package:ice_control_sale/services/customer_service.dart';

void main() {
  test('ទាញអតិថិជនតាម Frappe resource និង OR filters', () async {
    late http.Request sentRequest;
    final client = MockClient((request) async {
      sentRequest = request;
      return http.Response(
        jsonEncode({
          'data': [
            {
              'name': 'CU.0001',
              'customer_name': 'អតិថិជន សុខា',
              'phone_number_1': '012345678',
              'phone_number_2': '098765432',
              'customer_group': 'លក់រាយ',
              'keyword': 'ពចន',
              'plate_number': '2AB-1234',
              'photo': '/files/customer.jpg',
              'can_edit_bill': 1,
              'can_show_price': 1,
              'can_split_bill': 0,
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = CustomerService(
      Uri.parse('http://127.0.0.1:8888/'),
      client: client,
    );

    final page = await service.getCustomers(
      search: 'ពច',
      offset: 30,
      limit: 30,
    );

    expect(sentRequest.url.path, '/api/resource/Customer');
    expect(sentRequest.url.queryParameters['limit_start'], '30');
    expect(sentRequest.url.queryParameters['limit_page_length'], '30');
    expect(sentRequest.url.queryParameters['order_by'], 'customer_name asc');
    final filters = jsonDecode(sentRequest.url.queryParameters['filters']!);
    expect(
      filters,
      equals([
        ['enabled', '=', 1],
        ['is_customer', '=', 1],
      ]),
    );
    final orFilters =
        jsonDecode(sentRequest.url.queryParameters['or_filters']!)
            as List<dynamic>;
    expect(orFilters, hasLength(5));
    for (final field in [
      'customer_name',
      'name',
      'keyword',
      'phone_number_1',
      'phone_number_2',
    ]) {
      final filter = orFilters.cast<List<dynamic>>().singleWhere(
        (item) => item[0] == field,
      );
      expect(filter, equals([field, 'like', '%ពច%']));
    }
    expect(
      sentRequest.url.queryParameters['or_filters'],
      isNot(contains('customer_code')),
    );

    expect(page.items, hasLength(1));
    expect(page.hasMore, isFalse);
    final customer = page.items.single;
    expect(customer.name, 'CU.0001');
    expect(customer.customerName, 'អតិថិជន សុខា');
    expect(customer.phoneNumber1, '012345678');
    expect(customer.customerGroup, 'លក់រាយ');
    expect(customer.plateNumber, '2AB-1234');
    expect(customer.photo, '/files/customer.jpg');
    expect(customer.canEditBill, isTrue);
    expect(customer.canShowPrice, isTrue);
    expect(customer.canSplitBill, isFalse);
    expect(
      service.customerImage(customer).toString(),
      'http://127.0.0.1:8888/files/customer.jpg',
    );

    await service.getCustomers(selectionType: CustomerSelectionType.driver);
    final driverFilters = jsonDecode(
      sentRequest.url.queryParameters['filters']!,
    );
    expect(
      driverFilters,
      equals([
        ['enabled', '=', 1],
        ['is_driver', '=', 1],
      ]),
    );
    final requestedFields = jsonDecode(
      sentRequest.url.queryParameters['fields']!,
    );
    expect(requestedFields, contains('plate_number'));
  });

  test('loads customer product prices with customer name', () async {
    late http.Request sentRequest;
    final client = MockClient((request) async {
      sentRequest = request;
      return http.Response(
        jsonEncode([
          {'product_code': '01', 'unit': 'ដើម', 'price': 15500},
          {'product_code': '03', 'unit': 'គីឡូ', 'price': 1500},
        ]),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final service = CustomerService(
      Uri.parse('http://127.0.0.1:8888/'),
      client: client,
    );

    final prices = await service.getCustomerProductPrices('C457');

    expect(
      sentRequest.url.path,
      '/api/method/ice_control.api.v1.customer.get_customer_product_prices',
    );
    expect(sentRequest.method, 'GET');
    expect(sentRequest.url.queryParameters['customer'], 'C457');
    expect(prices, hasLength(2));
    expect(prices.first.productCode, '01');
    expect(prices.first.unit, 'ដើម');
    expect(prices.first.price, 15500);
  });

  test('loads valid free products from the full Customer document', () async {
    late http.Request sentRequest;
    final client = MockClient((request) async {
      sentRequest = request;
      return http.Response(
        jsonEncode({
          'data': {
            'name': 'Customer / One',
            'free_products': [
              {
                'product_code': '01',
                'product_name': 'ទឹកកកដើមធំ',
                'unit': 'ដើម',
                'quantity': 2,
                'multiplier': 1,
              },
              {
                'product_code': '',
                'product_name': 'Invalid',
                'unit': 'ដើម',
                'quantity': 1,
              },
              {
                'product_code': '02',
                'product_name': 'Invalid quantity',
                'unit': 'ដើម',
                'quantity': 0,
              },
            ],
          },
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final service = CustomerService(
      Uri.parse('http://127.0.0.1:8888/'),
      client: client,
    );

    final freeProducts = await service.getCustomerFreeProducts(
      'Customer / One',
    );

    expect(sentRequest.method, 'GET');
    expect(sentRequest.url.pathSegments.last, 'Customer / One');
    expect(freeProducts, hasLength(1));
    expect(freeProducts.single.productCode, '01');
    expect(freeProducts.single.productName, 'ទឹកកកដើមធំ');
    expect(freeProducts.single.unit, 'ដើម');
    expect(freeProducts.single.quantity, 2);
    expect(freeProducts.single.multiplier, 1);
  });
}
