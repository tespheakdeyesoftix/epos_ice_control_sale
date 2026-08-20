import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app/api_endpoint.dart';
import '../features/closed_sales/closed_sale.dart';
import '../features/sell/pending_order.dart';
import '../features/sell/sale.dart';

class PendingOrderPage {
  const PendingOrderPage({required this.items, required this.hasMore});

  final List<PendingOrder> items;
  final bool hasMore;
}

class ClosedSalePage {
  const ClosedSalePage({required this.items, required this.hasMore});

  final List<ClosedSale> items;
  final bool hasMore;
}

class DailySaleSummary {
  const DailySaleSummary({
    required this.totalOrder,
    required this.totalAmount,
    required this.totalPendingOrder,
    required this.totalPendingAmount,
  });

  factory DailySaleSummary.fromJson(Map<String, dynamic> json) {
    int integer(Object? value) => value is num
        ? value.toInt()
        : int.tryParse(value?.toString().trim() ?? '') ?? 0;
    double decimal(Object? value) => value is num
        ? value.toDouble()
        : double.tryParse(value?.toString().trim() ?? '') ?? 0;
    return DailySaleSummary(
      totalOrder: integer(json['total_order']),
      totalAmount: decimal(json['total_amount']),
      totalPendingOrder: integer(json['total_pending_order']),
      totalPendingAmount: decimal(json['total_pending_amount']),
    );
  }

  final int totalOrder;
  final double totalAmount;
  final int totalPendingOrder;
  final double totalPendingAmount;
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
    'can_show_price',
    'driver_name',
    'total_sale_quantity',
    'total_amount',
  ];
  static const _closedSaleFields = [
    ..._pendingOrderFields,
    'sale_status',
    'owner',
    'creation',
  ];

  Future<Sale> getSale(String name) async {
    final response = await _client
        .get(
          baseUri.resolve(ApiEndpoint.sale(name)),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SaleServiceException(response.statusCode);
    }

    final payload = jsonDecode(response.body);
    final data = payload is Map && payload['data'] is Map
        ? payload['data'] as Map
        : null;
    if (data == null) throw const SaleServiceException(200);
    return Sale.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Sale> searchBillForEdit({
    required String keyword,
    required String outlet,
  }) async {
    final response = await _client
        .get(
          baseUri
              .resolve(ApiEndpoint.searchBillForEdit)
              .replace(
                queryParameters: {
                  'keyword': keyword.trim(),
                  'outlet': outlet.trim(),
                },
              ),
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
    if (payload is String) payload = jsonDecode(payload);
    if (payload is Map && payload['doc'] is Map) payload = payload['doc'];
    if (payload is Map && payload['data'] is Map) payload = payload['data'];
    if (payload is! Map) throw const SaleServiceException(200);
    final sale = Sale.fromJson(Map<String, dynamic>.from(payload));
    if (sale.name.isEmpty) throw const SaleServiceException(200);
    return sale;
  }

  Future<PendingOrderPage> getPendingOrders({
    required String outlet,
    String search = '',
    String postingDate = '',
    String saleStatus = 'Draft',
    String status = '',
    int offset = 0,
    int limit = pendingOrderPageSize,
  }) async {
    final endpoint = baseUri.resolve(ApiEndpoint.sales);
    final filters = <List<dynamic>>[
      ['sale_status', '=', saleStatus],
      ['outlet', '=', outlet],
      if (status.trim().isNotEmpty) ['status', '=', status.trim()],
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

  Future<ClosedSalePage> getClosedSales({
    required String outlet,
    String search = '',
    String startDate = '',
    String endDate = '',
    int offset = 0,
    int limit = pendingOrderPageSize,
  }) async {
    final endpoint = baseUri.resolve(ApiEndpoint.sales);
    final filters = <List<dynamic>>[
      ['sale_status', '=', 'Closed'],
      ['outlet', '=', outlet],
      if (startDate.trim().isNotEmpty) ['posting_date', '>=', startDate.trim()],
      if (endDate.trim().isNotEmpty) ['posting_date', '<=', endDate.trim()],
    ];
    final queryParameters = <String, String>{
      'fields': jsonEncode(_closedSaleFields),
      'filters': jsonEncode(filters),
      'order_by': 'posting_date desc, creation desc',
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
    final sales = rows
        .whereType<Map>()
        .map((row) => ClosedSale.fromJson(Map<String, dynamic>.from(row)))
        .where((sale) => sale.name.isNotEmpty)
        .toList(growable: false);
    return ClosedSalePage(items: sales, hasMore: rows.length == limit);
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

  Future<DailySaleSummary> getDailySaleSummary(String outlet) async {
    final response = await _client
        .get(
          baseUri.resolve(ApiEndpoint.dailySaleSummary).replace(
            queryParameters: {'outlet': outlet.trim()},
          ),
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
    if (payload is String) payload = jsonDecode(payload);
    if (payload is Map && payload['data'] is Map) payload = payload['data'];
    if (payload is! Map) throw const SaleServiceException(200);
    return DailySaleSummary.fromJson(Map<String, dynamic>.from(payload));
  }

  Future<int> getTodayClosedSaleCount(String outlet) async {
    final endpoint = baseUri.resolve(ApiEndpoint.reportViewCount);
    final filters = <List<dynamic>>[
      ['Sale', 'outlet', '=', outlet],
      ['Sale', 'sale_status', '=', 'Closed'],
      ['Sale', 'posting_date', 'Timespan', 'today'],
    ];
    final response = await _client
        .get(
          endpoint.replace(
            queryParameters: {
              'doctype': 'Sale',
              'filters': jsonEncode(filters),
              'fields': '[]',
              'distinct': 'false',
            },
          ),
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
    if (payload is Map) payload = payload['count'];
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

  Future<void> deleteSale({
    required String docName,
    required String deletedNote,
    required String stationName,
  }) async {
    final response = await _client
        .post(
          baseUri.resolve(ApiEndpoint.deleteSale),
          headers: const {'Accept': 'application/json'},
          body: {
            'doc_name': docName,
            'deleted_note': deletedNote,
            'station_name': stationName.trim(),
          },
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SaleServiceException(response.statusCode);
    }
  }
}

class SaleServiceException implements Exception {
  const SaleServiceException(this.statusCode);

  final int statusCode;
}
