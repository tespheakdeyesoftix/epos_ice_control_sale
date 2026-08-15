import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app/api_endpoint.dart';
import '../features/sell/product.dart';

class ProductService {
  ProductService(this.baseUri, {required http.Client client})
    : _client = client;

  final Uri baseUri;
  final http.Client _client;

  Future<List<Product>> getProducts(String outlet) async {
    final response = await _client
        .post(
          baseUri.resolve(ApiEndpoint.products),
          headers: const {'Accept': 'application/json'},
          body: {'outlet': outlet},
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const ProductServiceException();
    }

    dynamic payload = jsonDecode(response.body);
    if (payload is Map<String, dynamic> && payload.containsKey('message')) {
      payload = payload['message'];
    }
    if (payload is String) payload = jsonDecode(payload);

    final List<dynamic> rows;
    if (payload is List) {
      rows = payload;
    } else if (payload is Map<String, dynamic>) {
      final data = payload['data'] ?? payload['products'];
      rows = data is List ? data : [payload];
    } else {
      rows = const [];
    }

    return rows
        .whereType<Map>()
        .map((row) => Product.fromJson(Map<String, dynamic>.from(row)))
        .where((product) => product.code.isNotEmpty)
        .toList();
  }
}

class ProductServiceException implements Exception {
  const ProductServiceException();
}
