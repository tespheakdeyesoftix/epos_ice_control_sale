import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/features/sell/customer.dart';
import 'package:ice_control_sale/features/sell/product.dart';
import 'package:ice_control_sale/features/sell/sell_controller.dart';
import 'package:ice_control_sale/services/customer_service.dart';
import 'package:ice_control_sale/services/product_service.dart';
import 'package:ice_control_sale/services/sale_service.dart';

void main() {
  test('reprices existing and new products for selected customer', () async {
    var requestedCustomer = '';
    final client = MockClient((request) async {
      if (request.url.path.endsWith('get_customer_product_prices')) {
        requestedCustomer = request.url.queryParameters['customer'] ?? '';
        return http.Response(
          jsonEncode(
            requestedCustomer == 'C457'
                ? [
                    {'product_code': '01', 'unit': 'ដើម', 'price': 12500},
                  ]
                : const [],
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response('{}', 200);
    });
    final baseUri = Uri.parse('http://127.0.0.1:8888/');
    final controller = SellController(
      productService: ProductService(baseUri, client: client),
      customerService: CustomerService(baseUri, client: client),
      saleService: SaleService(baseUri, client: client),
      outletName: 'ទឹកកកដើម',
      stationName: 'Cashier 01',
    );
    const product = Product(
      code: '01',
      name: 'ទឹកកកដើមធំ',
      category: 'ទឹកកកដើម',
      unit: 'ដើម',
      price: 15000,
      color: '#ECAD4B',
      photo: '',
    );
    const unmatchedUnit = Product(
      code: '01-OTHER',
      name: 'ទឹកកកគីឡូ',
      category: 'ទឹកកកដើម',
      unit: 'គីឡូ',
      price: 3000,
      color: '#1677FF',
      photo: '',
    );
    const customer = Customer(name: 'C457', customerName: 'Customer 457');

    expect(controller.addProduct(product, quantity: 2), isTrue);
    expect(controller.saleProducts.single.price, 15000);

    await controller.selectCustomer(customer);

    expect(requestedCustomer, 'C457');
    expect(controller.saleProducts.single.price, 12500);
    expect(controller.saleProducts.single.productPrice, 15000);

    controller.clearCart();
    expect(controller.addProduct(product), isTrue);
    expect(controller.saleProducts.single.price, 12500);
    expect(controller.saleProducts.single.productPrice, 15000);

    expect(controller.addProduct(unmatchedUnit), isTrue);
    expect(controller.saleProducts.last.price, 3000);
    expect(controller.saleProducts.last.productPrice, 3000);

    await controller.selectCustomer(
      const Customer(name: 'C458', customerName: 'Customer 458'),
    );
    expect(controller.saleProducts.first.price, 15000);
    expect(controller.saleProducts.last.price, 3000);
  });
}
