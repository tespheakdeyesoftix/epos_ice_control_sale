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
              'allow_sum_qty': 1,
              'allow_change_sale_type': 1,
              'default_sale_type': 'Borrow',
              'product_units': [
                {
                  'unit': 'Case',
                  'price': 700000,
                  'multiplier': 6,
                  'base_product_unit': 0,
                },
                {
                  'unit': 'Block',
                  'price': 15000,
                  'multiplier': 1,
                  'base_product_unit': 1,
                },
              ],
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
    expect(products.single.allowSumQuantity, isTrue);
    expect(products.single.allowChangeSaleType, isTrue);
    expect(products.single.saleTransactionType, 'Borrow');
    expect(products.single.productUnits, hasLength(2));
    expect(products.single.resolvedBaseUnit, 'Block');

    final caseProduct = products.single.forUnit(
      products.single.productUnits.first,
    );
    expect(caseProduct.unit, 'Case');
    expect(caseProduct.price, 700000);
    expect(caseProduct.multiplier, 6);
    expect(caseProduct.resolvedBaseUnit, 'Block');

    final saleProduct = SaleProduct.fromProduct(
      caseProduct,
      outlet: 'ទឹកកកដើម',
    );
    expect(saleProduct.photo, '/files/block_ice.jpg');
    expect(saleProduct.revenueGroup, 'ចំណូលទឹកកកដើម');
    expect(saleProduct.allowSumQuantity, isTrue);
    expect(saleProduct.allowChangeSaleType, isTrue);
    expect(saleProduct.saleTransactionType, 'Borrow');
    expect(saleProduct.price, 0);
    expect(saleProduct.productPrice, 700000);
    expect(saleProduct.unit, 'Case');
    expect(saleProduct.baseUnit, 'Block');
    expect(saleProduct.multiplier, 6);
    expect(saleProduct.toJson()['photo'], '/files/block_ice.jpg');
    expect(saleProduct.toJson()['revenue_group'], 'ចំណូលទឹកកកដើម');
    expect(saleProduct.toJson()['allow_sum_qty'], 1);
    expect(saleProduct.toJson()['allow_change_sale_type'], 1);
    expect(saleProduct.toJson()['sale_transaction_type'], 'Borrow');
    expect(saleProduct.toJson()['price'], 0);
    expect(saleProduct.toJson()['product_price'], 700000);
  });
}
