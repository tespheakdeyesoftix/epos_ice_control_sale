import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app/api_endpoint.dart';
import '../features/sell/customer.dart';

class CustomerPage {
  const CustomerPage({required this.items, required this.hasMore});

  final List<Customer> items;
  final bool hasMore;
}

class CustomerService {
  CustomerService(this.baseUri, {required http.Client client})
    : _client = client;

  static const pageSize = 30;
  static const _fields = [
    'name',
    'customer_name',
    'phone_number_1',
    'phone_number_2',
    'customer_group',
    'keyword',
    'plate_number',
    'photo',
    'can_edit_bill',
    'can_show_price',
    'can_split_bill',
  ];
  static const _searchFields = [
    'customer_name',
    'name',
    'keyword',
    'phone_number_1',
    'phone_number_2',
  ];

  final Uri baseUri;
  final http.Client _client;

  Future<CustomerPage> getCustomers({
    String search = '',
    int offset = 0,
    int limit = pageSize,
    CustomerSelectionType selectionType = CustomerSelectionType.customer,
  }) async {
    final trimmedSearch = search.trim();
    final queryParameters = <String, String>{
      'fields': jsonEncode(_fields),
      'filters': jsonEncode([
        ['enabled', '=', 1],
        [
          selectionType == CustomerSelectionType.customer
              ? 'is_customer'
              : 'is_driver',
          '=',
          1,
        ],
      ]),
      'order_by': 'customer_name asc',
      'limit_start': '$offset',
      'limit_page_length': '$limit',
    };
    if (trimmedSearch.isNotEmpty) {
      queryParameters['or_filters'] = jsonEncode(
        _searchFields
            .map((field) => [field, 'like', '%$trimmedSearch%'])
            .toList(),
      );
    }

    final endpoint = baseUri.resolve(ApiEndpoint.customers);
    final response = await _client
        .get(
          endpoint.replace(queryParameters: queryParameters),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CustomerServiceException(response.statusCode);
    }

    final payload = jsonDecode(response.body);
    final rows = payload is Map<String, dynamic> && payload['data'] is List
        ? payload['data'] as List<dynamic>
        : const <dynamic>[];
    final customers = rows
        .whereType<Map>()
        .map((row) => Customer.fromJson(Map<String, dynamic>.from(row)))
        .where((customer) => customer.name.isNotEmpty)
        .toList();
    return CustomerPage(items: customers, hasMore: rows.length == limit);
  }

  Uri? customerImage(Customer customer) {
    if (customer.photo.isEmpty) return null;
    return baseUri.resolve(customer.photo);
  }
}

class CustomerServiceException implements Exception {
  const CustomerServiceException(this.statusCode);

  final int statusCode;
}
