import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app/api_endpoint.dart';
import '../features/sell/pending_order.dart';
import '../features/sell/sale.dart';

class PendingOrderPage {
  const PendingOrderPage({required this.items, required this.hasMore});

  final List<PendingOrder> items;
  final bool hasMore;
}

class SaleService {
  SaleService(this.baseUri, {required http.Client client}) : _client = client;

  final Uri baseUri;
  final http.Client _client;

  static const pendingOrderPageSize = 30;
  static const _pendingOrderFields = [
    'name',
    'posting_date',
    'customer',
    'customer_name',
    'phone_number',
    'driver_name',
    'total_sale_quantity',
    'total_amount',
  ];

  Future<PendingOrderPage> getPendingOrders({
    required String outlet,
    String search = '',
    String postingDate = '',
    int offset = 0,
    int limit = pendingOrderPageSize,
  }) async {
    final endpoint = baseUri.resolve(ApiEndpoint.sales);
    final filters = <List<dynamic>>[
      ['sale_status', '=', 'Draft'],
      ['outlet', '=', outlet],
      if (postingDate.trim().isNotEmpty)
        ['posting_date', '=', postingDate.trim()],
    ];
    final queryParameters = <String, String>{
      'fields': jsonEncode(_pendingOrderFields),
      'filters': jsonEncode(filters),
      'order_by': 'posting_date desc, modified desc',
      'limit_start': '$offset',
      'limit_page_length': '$limit',
    };
    final trimmedSearch = search.trim();
    if (trimmedSearch.isNotEmpty) {
      queryParameters['or_filters'] = jsonEncode([
        for (final field in const [
          'name',
          'customer_name',
          'customer',
          'phone_number',
        ])
          [field, 'like', '%$trimmedSearch%'],
      ]);
    }
    final response = await _client
        .get(
          endpoint.replace(queryParameters: queryParameters),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SaleServiceException(response.statusCode);
    }

    final payload = jsonDecode(response.body);
    final rows = payload is Map && payload['data'] is List
        ? payload['data'] as List<dynamic>
        : const <dynamic>[];
    final orders = rows
        .whereType<Map>()
        .map((row) => PendingOrder.fromJson(Map<String, dynamic>.from(row)))
        .where((order) => order.name.isNotEmpty)
        .toList(growable: false);
    return PendingOrderPage(items: orders, hasMore: rows.length == limit);
  }

  Future<int> getTotalPendingOrder(String outlet) async {
    final endpoint = baseUri.resolve(ApiEndpoint.totalPendingOrder);
    final response = await _client
        .get(
          endpoint.replace(queryParameters: {'outlet': outlet}),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SaleServiceException(response.statusCode);
    }

    dynamic payload = jsonDecode(response.body);
    if (payload is Map && payload.containsKey('message')) {
      payload = payload['message'];
    }
    if (payload is Map) {
      payload = payload['total_pending_order'] ?? payload['count'];
    }
    final count = payload is num
        ? payload.toInt()
        : int.tryParse(payload?.toString().trim() ?? '');
    if (count == null) throw const SaleServiceException(200);
    return count < 0 ? 0 : count;
  }

  Future<Map<String, dynamic>> saveOrder(
    Sale sale, {
    String saleStatus = 'Closed',
  }) async {
    final salePayload = sale.toJson()..['sale_status'] = saleStatus;
    final response = await _client
        .post(
          baseUri.resolve(ApiEndpoint.saveOrder),
          headers: const {'Accept': 'application/json'},
          body: {
            'data': jsonEncode({'doc': salePayload}),
          },
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SaleServiceException(response.statusCode);
    }

    dynamic payload = jsonDecode(response.body);
    if (payload is Map<String, dynamic> && payload.containsKey('message')) {
      payload = payload['message'];
    }
    if (payload is String) payload = jsonDecode(payload);
    if (payload is Map<String, dynamic> && payload['doc'] is Map) {
      payload = payload['doc'];
    }
    if (payload is! Map) throw const SaleServiceException(200);
    return Map<String, dynamic>.from(payload);
  }
}

class SaleServiceException implements Exception {
  const SaleServiceException(this.statusCode);

  final int statusCode;
}
