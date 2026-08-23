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
    required this.totalQuantity,
    required this.totalPendingOrder,
    required this.totalPendingAmount,
    required this.totalPendingQuantity,
    required this.totalDeletedOrder,
    required this.totalDeletedAmount,
    required this.totalDeletedQuantity,
    required this.defaultUnit,
    this.saleProductSummary = const [],
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
      totalQuantity: decimal(json['total_quantity']),
      totalPendingOrder: integer(json['total_pending_order']),
      totalPendingAmount: decimal(json['total_pending_amount']),
      totalPendingQuantity: decimal(json['total_pending_quantity']),
      totalDeletedOrder: integer(json['total_deleted_order']),
      totalDeletedAmount: decimal(json['total_deleted_amount']),
      totalDeletedQuantity: decimal(json['total_deleted_quantity']),
      defaultUnit: json['default_unit']?.toString().trim() ?? '',
      saleProductSummary: _parseDailySaleProductSummary(
        json['sale_product_summary'],
      ),
    );
  }

  final int totalOrder;
  final double totalAmount;
  final double totalQuantity;
  final int totalPendingOrder;
  final double totalPendingAmount;
  final double totalPendingQuantity;
  final int totalDeletedOrder;
  final double totalDeletedAmount;
  final double totalDeletedQuantity;
  final String defaultUnit;
  final List<DailySaleProductSummary> saleProductSummary;
}

class DailySaleProductSummary {
  const DailySaleProductSummary({
    required this.productCode,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.freeQuantity,
    required this.returnQuantity,
    required this.splitQuantity,
    required this.totalSaleQuantity,
    required this.totalAmount,
  });

  factory DailySaleProductSummary.fromJson(Map<String, dynamic> json) {
    double decimal(Object? value) => value is num
        ? value.toDouble()
        : double.tryParse(value?.toString().trim() ?? '') ?? 0;
    String text(Object? value) => value?.toString().trim() ?? '';

    return DailySaleProductSummary(
      productCode: text(json['product_code']),
      productName: text(json['product_name']),
      unit: text(json['unit']),
      quantity: decimal(json['quantity']),
      freeQuantity: decimal(json['free_quantity']),
      returnQuantity: decimal(json['return_quantity']),
      splitQuantity: decimal(json['split_quantity']),
      totalSaleQuantity: decimal(json['total_sale_quantity']),
      totalAmount: decimal(json['total_amount']),
    );
  }

  final String productCode;
  final String productName;
  final String unit;
  final double quantity;
  final double freeQuantity;
  final double returnQuantity;
  final double splitQuantity;
  final double totalSaleQuantity;
  final double totalAmount;
}

List<DailySaleProductSummary> _parseDailySaleProductSummary(Object? value) {
  dynamic rows = value;
  if (rows is String && rows.trim().isNotEmpty) {
    try {
      rows = jsonDecode(rows);
    } on FormatException {
      return const [];
    }
  }
  if (rows is Map) {
    rows = rows['data'] ?? rows['items'] ?? rows['rows'];
  }
  if (rows is! List) return const [];
  return rows
      .whereType<Map>()
      .map(
        (row) =>
            DailySaleProductSummary.fromJson(Map<String, dynamic>.from(row)),
      )
      .toList(growable: false);
}

class PendingOrderWarningInfo {
  const PendingOrderWarningInfo({
    required this.pendingDate,
    required this.totalPendingOrder,
    required this.pendingOrderAmount,
  });

  final DateTime? pendingDate;
  final int totalPendingOrder;
  final double pendingOrderAmount;

  bool shouldWarn({DateTime? now}) {
    final date = pendingDate;
    if (totalPendingOrder <= 0 || date == null) return false;
    final current = now ?? DateTime.now();
    return current.difference(date).compareTo(const Duration(hours: 1)) > 0;
  }
}

class SaleService {
  SaleService(this.baseUri, {required http.Client client}) : _client = client;

  final Uri baseUri;
  final http.Client _client;

  Future<Map<String, dynamic>> getDoctypeMeta(String doctype) async {
    final response = await _client
        .get(
          baseUri
              .resolve(ApiEndpoint.doctypeMeta)
              .replace(queryParameters: {'doctype': doctype.trim()}),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 20));
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
    return Map<String, dynamic>.from(payload);
  }

  Future<List<Map<String, dynamic>>> getDoctypeRows({
    required String doctype,
    required List<String> fields,
    List<List<dynamic>> filters = const [],
    List<List<dynamic>> orFilters = const [],
    String orderBy = 'name asc',
    int offset = 0,
    int limit = 20,
  }) async {
    final query = <String, String>{
      'fields': jsonEncode(fields),
      'filters': jsonEncode(filters),
      'order_by': orderBy,
      'limit_start': '$offset',
      'limit_page_length': '$limit',
    };
    if (orFilters.isNotEmpty) query['or_filters'] = jsonEncode(orFilters);
    final response = await _client
        .get(
          baseUri
              .resolve(ApiEndpoint.resource(doctype))
              .replace(queryParameters: query),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SaleServiceException(response.statusCode);
    }
    final payload = jsonDecode(response.body);
    final rows = payload is Map && payload['data'] is List
        ? payload['data'] as List
        : const [];
    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  static const pendingOrderPageSize = 30;
  static const closedSalePageSize = 20;
  static const _pendingOrderFields = [
    'name',
    'posting_date',
    'customer',
    'customer_name',
    'customer_photo',
    'phone_number',
    'reference_number',
    'can_show_price',
    'driver',
    'driver_name',
    'plate_number',
    'total_sale_quantity',
    'outlet_unit',
    'total_amount',
  ];
  static const _closedSaleFields = [
    ..._pendingOrderFields,
    'total_split_bill',
    'sale_status',
    'status',
    'owner',
    'seller',
    'creation',
    'modified',
  ];
  static const closedSaleSortFields = {
    'name',
    'posting_date',
    'customer_name',
    'driver_name',
    'total_split_bill',
    'total_sale_quantity',
    'total_amount',
    'creation',
    'modified',
  };

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

  Future<List<Map<String, dynamic>>> getSalePaymentHistory(
    String saleName,
  ) async {
    final response = await _client
        .get(
          baseUri
              .resolve(ApiEndpoint.salePaymentHistory)
              .replace(queryParameters: {'sale_name': saleName.trim()}),
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
    if (payload is Map && payload['data'] is List) payload = payload['data'];
    if (payload is! List) return const [];
    return payload
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> loadSaleDocument(String name) async {
    final response = await _client
        .get(
          baseUri
              .resolve(ApiEndpoint.loadDocument)
              .replace(
                queryParameters: {'doctype': 'Sale', 'name': name.trim()},
              ),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SaleServiceException(response.statusCode);
    }
    final payload = jsonDecode(response.body);
    if (payload is! Map) throw const SaleServiceException(200);
    return Map<String, dynamic>.from(payload);
  }

  Future<void> addSaleComment({
    required String saleName,
    required String content,
    required String email,
    required String author,
  }) async {
    final response = await _client
        .post(
          baseUri.resolve(ApiEndpoint.addComment),
          headers: const {'Accept': 'application/json'},
          body: {
            'reference_doctype': 'Sale',
            'reference_name': saleName.trim(),
            'content': content.trim(),
            'comment_email': email.trim(),
            'comment_by': author.trim(),
          },
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SaleServiceException(response.statusCode);
    }
  }

  Future<void> updateSaleComment({
    required String commentName,
    required String content,
  }) async {
    final response = await _client
        .post(
          baseUri.resolve(ApiEndpoint.updateComment),
          headers: const {'Accept': 'application/json'},
          body: {'name': commentName.trim(), 'content': content.trim()},
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SaleServiceException(response.statusCode);
    }
  }

  Future<void> updateSaleNote({
    required String saleName,
    required String note,
  }) => updateSaleField(saleName: saleName, fieldName: 'note', value: note);

  Future<void> updateSaleReferenceNumber({
    required String saleName,
    required String referenceNumber,
  }) => updateSaleField(
    saleName: saleName,
    fieldName: 'reference_number',
    value: referenceNumber,
  );

  Future<void> updateSaleField({
    required String saleName,
    required String fieldName,
    required Object? value,
  }) async {
    final response = await _client
        .post(
          baseUri.resolve(ApiEndpoint.updateDocument),
          headers: const {'Accept': 'application/json'},
          body: {
            'doctype': 'Sale',
            'name': saleName.trim(),
            'data': jsonEncode({fieldName: value}),
            'doc_flags': jsonEncode({
              'ignore_permissions': true,
              'ignore_validate': true,
              'ignore_update': true,
              'ignore_validate_update_after_submit': true,
            }),
          },
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SaleServiceException(response.statusCode);
    }
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
    String sortField = 'posting_date',
    bool sortAscending = false,
    String customer = '',
    String driver = '',
    String status = '',
    bool splitBillOnly = false,
    String productCode = '',
    String productChildDoctype = 'Sale Product',
    int offset = 0,
    int limit = closedSalePageSize,
  }) async {
    final endpoint = baseUri.resolve(ApiEndpoint.sales);
    final filters = _closedSaleFilters(
      outlet: outlet,
      startDate: startDate,
      endDate: endDate,
      customer: customer,
      driver: driver,
      status: status,
      splitBillOnly: splitBillOnly,
      productCode: productCode,
      productChildDoctype: productChildDoctype,
    );
    final safeSortField = closedSaleSortFields.contains(sortField)
        ? sortField
        : 'posting_date';
    final sortDirection = sortAscending ? 'asc' : 'desc';
    final secondaryOrder = safeSortField == 'posting_date'
        ? 'creation $sortDirection'
        : 'name $sortDirection';
    final queryParameters = <String, String>{
      'fields': jsonEncode(_closedSaleFields),
      'filters': jsonEncode(filters),
      'order_by': '$safeSortField $sortDirection, $secondaryOrder',
      'limit_start': '$offset',
      'limit_page_length': '$limit',
    };
    final searchFilters = _closedSaleSearchFilters(search);
    if (searchFilters.isNotEmpty) {
      queryParameters['or_filters'] = jsonEncode(searchFilters);
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

  Future<ClosedSale?> findSaleByDocumentName({
    required String outlet,
    required String documentName,
  }) async {
    final response = await _client
        .get(
          baseUri
              .resolve(ApiEndpoint.sales)
              .replace(
                queryParameters: {
                  'fields': jsonEncode(_closedSaleFields),
                  'filters': jsonEncode([
                    ['outlet', '=', outlet.trim()],
                    ['name', '=', documentName.trim()],
                  ]),
                  'limit_start': '0',
                  'limit_page_length': '1',
                },
              ),
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
    for (final row in rows.whereType<Map>()) {
      final sale = ClosedSale.fromJson(Map<String, dynamic>.from(row));
      if (sale.name.isNotEmpty) return sale;
    }
    return null;
  }

  Future<List<ClosedSale>> getSplitBills({
    required String parentBillNumber,
  }) async {
    final rows = await getDoctypeRows(
      doctype: 'Sale',
      fields: const [..._closedSaleFields, 'parent_bill_number'],
      filters: [
        ['parent_bill_number', '=', parentBillNumber.trim()],
      ],
      orderBy: 'posting_date desc, creation desc',
      limit: 200,
    );
    return rows
        .map(ClosedSale.fromJson)
        .where((sale) => sale.name.isNotEmpty)
        .toList(growable: false);
  }

  Future<int> getClosedSaleCount({
    required String outlet,
    String search = '',
    String startDate = '',
    String endDate = '',
    String customer = '',
    String driver = '',
    String status = '',
    bool splitBillOnly = false,
    String productCode = '',
    String productChildDoctype = 'Sale Product',
  }) async {
    final queryParameters = <String, String>{
      'doctype': 'Sale',
      'filters': jsonEncode(
        _closedSaleFilters(
          outlet: outlet,
          startDate: startDate,
          endDate: endDate,
          customer: customer,
          driver: driver,
          status: status,
          splitBillOnly: splitBillOnly,
          productCode: productCode,
          productChildDoctype: productChildDoctype,
        ),
      ),
      'fields': '[]',
      'distinct': 'false',
    };
    final searchFilters = _closedSaleSearchFilters(search);
    if (searchFilters.isNotEmpty) {
      queryParameters['or_filters'] = jsonEncode(searchFilters);
    }
    final response = await _client
        .get(
          baseUri
              .resolve(ApiEndpoint.reportViewCount)
              .replace(queryParameters: queryParameters),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SaleServiceException(response.statusCode);
    }
    return _parseCountResponse(response.body);
  }

  Future<List<ClosedSale>> getRecentClosedSales({
    required String outlet,
    int limit = 5,
    DateTime? postingDate,
  }) async {
    final selectedDate = postingDate ?? DateTime.now();
    final formattedPostingDate = [
      selectedDate.year.toString().padLeft(4, '0'),
      selectedDate.month.toString().padLeft(2, '0'),
      selectedDate.day.toString().padLeft(2, '0'),
    ].join('-');
    final response = await _client
        .get(
          baseUri
              .resolve(ApiEndpoint.sales)
              .replace(
                queryParameters: {
                  'fields': jsonEncode(_closedSaleFields),
                  'filters': jsonEncode([
                    ['sale_status', '=', 'Closed'],
                    ['posting_date', '=', formattedPostingDate],
                    ['outlet', '=', outlet.trim()],
                  ]),
                  'order_by': 'modified desc',
                  'limit_start': '0',
                  'limit_page_length': '$limit',
                },
              ),
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
    return rows
        .whereType<Map>()
        .map((row) => ClosedSale.fromJson(Map<String, dynamic>.from(row)))
        .where((sale) => sale.name.isNotEmpty)
        .take(limit)
        .toList(growable: false);
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
          baseUri
              .resolve(ApiEndpoint.dailySaleSummary)
              .replace(queryParameters: {'outlet': outlet.trim()}),
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

  Future<PendingOrderWarningInfo> getMaxPendingOrderDate(String outlet) async {
    final endpoint = baseUri.resolve(ApiEndpoint.maxPendingOrderDate);
    final response = await _client
        .get(
          endpoint.replace(queryParameters: {'outlet': outlet.trim()}),
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

    final countValue = payload['total_pending_order'];
    final amountValue = payload['pending_order_amount'];
    final count = countValue is num
        ? countValue.toInt()
        : int.tryParse(countValue?.toString().trim() ?? '');
    final amount = amountValue is num
        ? amountValue.toDouble()
        : double.tryParse(amountValue?.toString().trim() ?? '');
    if (count == null || amount == null) {
      throw const SaleServiceException(200);
    }

    final pendingDateText = payload['pending_date']?.toString().trim() ?? '';
    final pendingDate = pendingDateText.isEmpty
        ? null
        : DateTime.tryParse(pendingDateText);
    if (pendingDateText.isNotEmpty && pendingDate == null) {
      throw const SaleServiceException(200);
    }
    return PendingOrderWarningInfo(
      pendingDate: pendingDate,
      totalPendingOrder: count < 0 ? 0 : count,
      pendingOrderAmount: amount < 0 ? 0 : amount,
    );
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

    return _parseCountResponse(response.body);
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

List<List<dynamic>> _closedSaleFilters({
  required String outlet,
  required String startDate,
  required String endDate,
  String customer = '',
  String driver = '',
  String status = '',
  bool splitBillOnly = false,
  String productCode = '',
  String productChildDoctype = 'Sale Product',
}) {
  return [
    ['sale_status', '=', 'Closed'],
    ['outlet', '=', outlet],
    if (startDate.trim().isNotEmpty) ['posting_date', '>=', startDate.trim()],
    if (endDate.trim().isNotEmpty) ['posting_date', '<=', endDate.trim()],
    if (customer.trim().isNotEmpty) ['customer', '=', customer.trim()],
    if (driver.trim().isNotEmpty) ['driver', '=', driver.trim()],
    if (status.trim().isNotEmpty) ['status', '=', status.trim()],
    if (splitBillOnly) ['total_split_bill', '>', 1],
    if (productCode.trim().isNotEmpty)
      [
        productChildDoctype.trim().isEmpty
            ? 'Sale Product'
            : productChildDoctype.trim(),
        'product_code',
        '=',
        productCode.trim(),
      ],
  ];
}

List<List<dynamic>> _closedSaleSearchFilters(String search) {
  final trimmedSearch = search.trim();
  if (trimmedSearch.isEmpty) return const [];
  return [
    for (final field in const [
      'name',
      'customer_name',
      'customer',
      'phone_number',
      'driver',
      'driver_name',
      'reference_number',
    ])
      [field, 'like', '%$trimmedSearch%'],
  ];
}

int _parseCountResponse(String body) {
  dynamic payload = jsonDecode(body);
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

class SaleServiceException implements Exception {
  const SaleServiceException(this.statusCode);

  final int statusCode;
}
