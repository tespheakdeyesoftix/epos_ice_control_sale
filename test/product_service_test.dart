import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/features/sell/sale_product.dart';
import 'package:ice_control_sale/services/product_service.dart';

void main() {
  test('បញ្ជូនឈ្មោះសាខា និងអានបញ្ជីទំនិញពី Frappe', () async {
    late http.Request sentRequest;
    final client = MockClient((request) async {
      sentRequest = request;
      return http.Response(
        jsonEncode({
          'message': [
            {
              'product_code': '01',
              'product_name': 'ទឹកកកដើមធំ',
              'product_category': 'ទឹកកកដើម',
              'unit': 'ដើម',
              'price': 15000,
              'color': '#ECAD4B',
              'photo': '/files/block_ice.jpg',
              'revenue_group': 'ចំណូលទឹកកកដើម',
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = ProductService(
      Uri.parse('http://127.0.0.1:8888/'),
      client: client,
    );

    final products = await service.getProducts('ទឹកកកដើម');

    expect(
      sentRequest.url.path,
      '/api/method/ice_control.api.v1.product.get_products',
    );
    expect(sentRequest.bodyFields['outlet'], 'ទឹកកកដើម');
    expect(products, hasLength(1));
    expect(products.single.name, 'ទឹកកកដើមធំ');
    expect(products.single.price, 15000);
    expect(products.single.photo, '/files/block_ice.jpg');
    expect(products.single.revenueGroup, 'ចំណូលទឹកកកដើម');

    final saleProduct = SaleProduct.fromProduct(
      products.single,
      outlet: 'ទឹកកកដើម',
    );
    expect(saleProduct.photo, '/files/block_ice.jpg');
    expect(saleProduct.revenueGroup, 'ចំណូលទឹកកកដើម');
    expect(saleProduct.toJson()['photo'], '/files/block_ice.jpg');
    expect(saleProduct.toJson()['revenue_group'], 'ចំណូលទឹកកកដើម');
  });
}
