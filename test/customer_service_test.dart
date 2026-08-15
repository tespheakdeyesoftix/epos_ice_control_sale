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
}
