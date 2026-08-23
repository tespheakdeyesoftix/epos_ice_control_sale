import 'dart:convert';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/features/sell/customer.dart';
import 'package:ice_control_sale/features/sell/customer_free_product.dart';
import 'package:ice_control_sale/features/sell/product.dart';
import 'package:ice_control_sale/features/sell/sell_controller.dart';
import 'package:ice_control_sale/services/customer_service.dart';
import 'package:ice_control_sale/services/product_service.dart';
import 'package:ice_control_sale/services/sale_service.dart';

void main() {
  const block = Product(
    code: '01',
    name: 'ទឹកកកដើមធំ',
    category: 'ទឹកកក',
    unit: 'ដើម',
    price: 15000,
    color: '#1677FF',
    photo: '',
  );
  const small = Product(
    code: '02',
    name: 'ទឹកកកដើមតូច',
    category: 'ទឹកកក',
    unit: 'ដើម',
    price: 2500,
    color: '#1677FF',
    photo: '',
  );

  test('applies free products to newly added matching products', () async {
    final controller = _controller(
      (customer) => [
        _freeProduct('01', 'ទឹកកកដើមធំ', 'ដើម', 2),
        _freeProduct('02', 'ទឹកកកដើមតូច', 'ដើម', 3),
      ],
    );
    await controller.selectCustomer(
      const Customer(name: 'C457', customerName: 'Customer 457'),
    );

    final applied = controller.addProduct(block, quantity: 2);
    final insufficient = controller.addProduct(small, quantity: 2);

    expect(applied.added, isTrue);
    expect(
      applied.freeProductEvaluation?.status,
      FreeProductEvaluationStatus.applied,
    );
    expect(controller.saleProducts.first.freeQuantity, 2);
    expect(
      insufficient.freeProductEvaluation?.status,
      FreeProductEvaluationStatus.insufficientQuantity,
    );
    expect(controller.saleProducts.last.quantity, 2);
    expect(controller.saleProducts.last.freeQuantity, 0);
  });

  test('matches both product code and trimmed unit', () async {
    final controller = _controller(
      (customer) => [_freeProduct('01', 'ទឹកកកដើមធំ', 'គីឡូ', 1)],
    );
    await controller.selectCustomer(
      const Customer(name: 'C457', customerName: 'Customer 457'),
    );

    final result = controller.addProduct(block, quantity: 5);

    expect(result.freeProductEvaluation, isNull);
    expect(controller.saleProducts.single.freeQuantity, 0);
  });

  test(
    'customer changes clear all freebies and override matching lines',
    () async {
      final controller = _controller(
        (customer) => switch (customer) {
          'C1' => [_freeProduct('01', 'ទឹកកកដើមធំ', 'ដើម', 2)],
          'C2' => [_freeProduct('01', 'ទឹកកកដើមធំ', 'ដើម', 3)],
          _ => const [],
        },
      );
      controller.addProduct(block, quantity: 5);
      controller.addProduct(small, quantity: 5);

      final firstResult = await controller.selectCustomer(
        const Customer(name: 'C1', customerName: 'Customer One'),
      );
      expect(firstResult.freeProductEvaluations, hasLength(1));
      expect(controller.saleProducts.first.freeQuantity, 2);
      controller.updateSaleProduct(
        controller.saleProducts.last.copyWith(freeQuantity: 1),
      );

      final secondResult = await controller.selectCustomer(
        const Customer(name: 'C2', customerName: 'Customer Two'),
      );
      expect(secondResult.freeProductEvaluations, hasLength(1));
      expect(controller.saleProducts.first.freeQuantity, 3);
      expect(controller.saleProducts.last.freeQuantity, 0);

      controller.clearCustomer();
      expect(controller.customerFreeProducts, isEmpty);
      expect(
        controller.saleProducts.every((item) => item.freeQuantity == 0),
        isTrue,
      );
    },
  );

  test('failed free-product loading keeps prior freebies cleared', () async {
    final controller = _controller(
      (customer) => [_freeProduct('01', 'ទឹកកកដើមធំ', 'ដើម', 2)],
      failingCustomer: 'FAIL',
    );
    controller.addProduct(block, quantity: 5);
    await controller.selectCustomer(
      const Customer(name: 'C1', customerName: 'Customer One'),
    );
    expect(controller.saleProducts.single.freeQuantity, 2);

    final result = await controller.selectCustomer(
      const Customer(name: 'FAIL', customerName: 'Failing Customer'),
    );

    expect(result.freeProductEvaluations, isEmpty);
    expect(controller.selectedCustomer.value?.name, 'FAIL');
    expect(controller.customerFreeProducts, isEmpty);
    expect(controller.saleProducts.single.freeQuantity, 0);
  });

  test(
    'stale customer response cannot overwrite the latest customer',
    () async {
      final firstResponse = Completer<http.Response>();
      final client = MockClient((request) async {
        if (request.url.path.endsWith('get_customer_product_prices')) {
          return http.Response('[]', 200);
        }
        if (request.url.path.endsWith('/C1')) return firstResponse.future;
        if (request.url.path.endsWith('/C2')) {
          return _customerResponse([
            _freeProduct('01', 'ទឹកកកដើមធំ', 'ដើម', 3),
          ]);
        }
        return http.Response('{}', 200);
      });
      final baseUri = Uri.parse('http://127.0.0.1:8888/');
      final controller = SellController(
        productService: ProductService(baseUri, client: client),
        customerService: CustomerService(baseUri, client: client),
        saleService: SaleService(baseUri, client: client),
        outletName: 'Main Outlet',
        stationName: 'Cashier 01',
      );
      controller.addProduct(block, quantity: 5);

      final firstSelection = controller.selectCustomer(
        const Customer(name: 'C1', customerName: 'Customer One'),
      );
      final secondResult = await controller.selectCustomer(
        const Customer(name: 'C2', customerName: 'Customer Two'),
      );
      firstResponse.complete(
        _customerResponse([_freeProduct('01', 'ទឹកកកដើមធំ', 'ដើម', 1)]),
      );
      final firstResult = await firstSelection;

      expect(
        secondResult.freeProductEvaluations.single.configuredFreeQuantity,
        3,
      );
      expect(firstResult.freeProductEvaluations, isEmpty);
      expect(controller.selectedCustomer.value?.name, 'C2');
      expect(controller.saleProducts.single.freeQuantity, 3);
    },
  );
}

SellController _controller(
  List<Map<String, dynamic>> Function(String customer) freeProducts, {
  String? failingCustomer,
}) {
  final client = MockClient((request) async {
    if (request.url.path.endsWith('get_customer_product_prices')) {
      return http.Response('[]', 200);
    }
    if (request.url.path.contains('/api/resource/Customer/')) {
      final customer = request.url.pathSegments.last;
      if (customer == failingCustomer) return http.Response('{}', 500);
      return _customerResponse(freeProducts(customer));
    }
    return http.Response('{}', 200);
  });
  final baseUri = Uri.parse('http://127.0.0.1:8888/');
  return SellController(
    productService: ProductService(baseUri, client: client),
    customerService: CustomerService(baseUri, client: client),
    saleService: SaleService(baseUri, client: client),
    outletName: 'Main Outlet',
    stationName: 'Cashier 01',
  );
}

http.Response _customerResponse(List<Map<String, dynamic>> freeProducts) {
  return http.Response.bytes(
    utf8.encode(
      jsonEncode({
        'data': {'free_products': freeProducts},
      }),
    ),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

Map<String, dynamic> _freeProduct(
  String code,
  String name,
  String unit,
  double quantity,
) => {
  'product_code': code,
  'product_name': name,
  'unit': unit,
  'quantity': quantity,
  'multiplier': 1,
};
