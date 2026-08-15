import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app/api_endpoint.dart';
import '../features/sell/sale.dart';

class SaleService {
  SaleService(this.baseUri, {required http.Client client}) : _client = client;

  final Uri baseUri;
  final http.Client _client;

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
