import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/features/sell/customer.dart';
import 'package:ice_control_sale/features/sell/product.dart';
import 'package:ice_control_sale/features/sell/sale.dart';
import 'package:ice_control_sale/features/sell/sale_product.dart';
import 'package:ice_control_sale/features/sell/sell_controller.dart';
import 'package:ice_control_sale/services/customer_service.dart';
import 'package:ice_control_sale/services/product_service.dart';
import 'package:ice_control_sale/services/sale_service.dart';

void main() {
  test('uses product code and unit together as the order-line identity', () {
    final client = MockClient((_) async => http.Response('{}', 200));
    final baseUri = Uri.parse('http://127.0.0.1:8888/');
    final controller = SellController(
      productService: ProductService(baseUri, client: client),
      customerService: CustomerService(baseUri, client: client),
      saleService: SaleService(baseUri, client: client),
      outletName: 'Main Outlet',
      stationName: 'Cashier 01',
    );
    const product = Product(
      code: 'P001',
      name: 'Block Ice',
      category: 'Ice',
      unit: 'Block',
      price: 15000,
      color: '#1677FF',
      photo: '',
      productUnits: [
        ProductUnit(unit: 'Case', price: 700000, multiplier: 6),
        ProductUnit(unit: 'Block', price: 15000, isBaseUnit: true),
      ],
    );
    final caseProduct = product.forUnit(product.productUnits.first);
    final blockProduct = product.forUnit(product.productUnits.last);

    expect(controller.addProduct(caseProduct), isTrue);
    expect(controller.addProduct(blockProduct), isTrue);
    expect(controller.addProduct(caseProduct), isFalse);
    expect(controller.saleProducts, hasLength(2));

    final caseLine = controller.saleProducts.first;
    final blockLine = controller.saleProducts.last;
    controller.updateSaleProduct(blockLine.copyWith(quantity: 3));
    expect(controller.saleProducts.first.quantity, 1);
    expect(controller.saleProducts.last.quantity, 3);

    expect(
      () => controller.updateSaleProduct(
        caseLine.copyWith(unit: 'Block'),
        originalItem: caseLine,
      ),
      throwsA(isA<SaleProductUnitAlreadySelectedException>()),
    );

    controller.remove(caseLine);
    expect(controller.saleProducts, hasLength(1));
    expect(controller.saleProducts.single.unit, 'Block');
  });

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
    const borrowProduct = Product(
      code: '01',
      name: 'Borrow ice',
      category: 'ទឹកកកដើម',
      unit: 'ដើម',
      price: 15000,
      color: '#F79009',
      photo: '',
      saleTransactionType: 'Borrow',
    );
    const customer = Customer(name: 'C457', customerName: 'Customer 457');

    expect(controller.addProduct(product, quantity: 2), isTrue);
    expect(controller.saleProducts.single.price, 15000);

    await controller.selectCustomer(customer);

    expect(requestedCustomer, 'C457');
    expect(controller.saleProducts.single.price, 12500);
    expect(controller.saleProducts.single.productPrice, 15000);

    controller.clearCart();
    expect(controller.addProduct(borrowProduct), isTrue);
    expect(controller.saleProducts.single.price, 0);
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

    await controller.selectCustomer(customer);
    expect(controller.saleProducts.first.price, 12500);
    controller.clearCustomer();
    expect(controller.selectedCustomer.value, isNull);
    expect(controller.customerProductPrices, isEmpty);
    expect(controller.saleProducts.first.price, 15000);
  });

  test('change_customer permission applies only while editing', () async {
    var hasPermission = false;
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode(<dynamic>[]),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
    final baseUri = Uri.parse('http://127.0.0.1:8888/');
    final controller = SellController(
      productService: ProductService(baseUri, client: client),
      customerService: CustomerService(baseUri, client: client),
      saleService: SaleService(baseUri, client: client),
      outletName: 'Main Outlet',
      stationName: 'Cashier 01',
      canChangeCustomerProvider: () => hasPermission,
    );
    const first = Customer(name: 'C001', customerName: 'Customer One');
    const second = Customer(name: 'C002', customerName: 'Customer Two');

    await controller.selectCustomer(first);
    expect(controller.selectedCustomer.value?.name, 'C001');

    controller.openedSale.value = const Sale(
      name: 'SO-EDIT-001',
      outlet: 'Main Outlet',
      saleStatus: 'Closed',
      saleProducts: [],
    );
    await expectLater(
      controller.selectCustomer(second),
      throwsA(isA<CustomerChangePermissionException>()),
    );
    expect(
      controller.clearCustomer,
      throwsA(isA<CustomerChangePermissionException>()),
    );
    expect(controller.selectedCustomer.value?.name, 'C001');

    controller.openedSale.value = const Sale(
      name: 'SO-DRAFT-001',
      outlet: 'Main Outlet',
      saleStatus: 'Draft',
      saleProducts: [],
    );
    await controller.selectCustomer(second);
    expect(controller.selectedCustomer.value?.name, 'C002');
    controller.clearCustomer();
    expect(controller.selectedCustomer.value, isNull);

    hasPermission = true;
    controller.openedSale.value = const Sale(
      name: 'SO-EDIT-001',
      outlet: 'Main Outlet',
      saleStatus: 'Closed',
      saleProducts: [],
    );
    await controller.selectCustomer(first);
    expect(controller.selectedCustomer.value?.name, 'C001');
  });

  test('change_sale_date permission applies only while editing', () {
    var hasPermission = false;
    final client = MockClient((_) async => http.Response('{}', 200));
    final baseUri = Uri.parse('http://127.0.0.1:8888/');
    final controller = SellController(
      productService: ProductService(baseUri, client: client),
      customerService: CustomerService(baseUri, client: client),
      saleService: SaleService(baseUri, client: client),
      outletName: 'Main Outlet',
      stationName: 'Cashier 01',
      canChangeSaleDateProvider: () => hasPermission,
    );
    final newOrderDate = DateTime.now().subtract(const Duration(days: 1));

    controller.updatePostingDate(newOrderDate);
    expect(controller.postingDate.value, _dateOnly(newOrderDate));

    controller.openedSale.value = const Sale(
      name: 'SO-EDIT-002',
      outlet: 'Main Outlet',
      saleStatus: 'Closed',
      saleProducts: [],
    );
    final blockedDate = DateTime.now();
    expect(
      () => controller.updatePostingDate(blockedDate),
      throwsA(isA<SaleDateChangePermissionException>()),
    );
    expect(controller.postingDate.value, _dateOnly(newOrderDate));

    controller.openedSale.value = const Sale(
      name: 'SO-DRAFT-002',
      outlet: 'Main Outlet',
      saleStatus: 'Draft',
      saleProducts: [],
    );
    controller.updatePostingDate(blockedDate);
    expect(controller.postingDate.value, _dateOnly(blockedDate));

    hasPermission = true;
    controller.openedSale.value = const Sale(
      name: 'SO-EDIT-002',
      outlet: 'Main Outlet',
      saleStatus: 'Closed',
      saleProducts: [],
    );
    controller.updatePostingDate(blockedDate);
    expect(controller.postingDate.value, _dateOnly(blockedDate));
  });

  test('remove_sale_product permission applies only while editing', () {
    var hasPermission = false;
    final client = MockClient((_) async => http.Response('{}', 200));
    final baseUri = Uri.parse('http://127.0.0.1:8888/');
    final controller = SellController(
      productService: ProductService(baseUri, client: client),
      customerService: CustomerService(baseUri, client: client),
      saleService: SaleService(baseUri, client: client),
      outletName: 'Main Outlet',
      stationName: 'Cashier 01',
      canRemoveSaleProductProvider: () => hasPermission,
    );
    const product = Product(
      code: 'P001',
      name: 'Product One',
      category: 'Test',
      unit: 'Unit',
      price: 1000,
      color: '#1677FF',
      photo: '',
    );

    expect(controller.addProduct(product), isTrue);
    controller.remove(controller.saleProducts.single);
    expect(controller.saleProducts, isEmpty);
    controller.openedSale.value = const Sale(
      name: 'SO-EDIT-003',
      outlet: 'Main Outlet',
      saleStatus: 'Closed',
      saleProducts: [],
    );

    expect(controller.addProduct(product), isTrue);
    controller.remove(controller.saleProducts.single);
    expect(controller.saleProducts, isEmpty);

    const line = SaleProduct(
      name: 'SALE-PRODUCT-ROW-001',
      productCode: 'P001',
      productName: 'Product One',
      productCategory: 'Test',
      unit: 'Unit',
      price: 1000,
    );
    controller.saleProducts.add(line);
    expect(
      () => controller.remove(line),
      throwsA(isA<SaleProductRemovePermissionException>()),
    );
    expect(controller.saleProducts, hasLength(1));

    controller.openedSale.value = const Sale(
      name: 'SO-DRAFT-003',
      outlet: 'Main Outlet',
      saleStatus: 'Draft',
      saleProducts: [],
    );
    controller.remove(line);
    expect(controller.saleProducts, isEmpty);

    hasPermission = true;
    controller.openedSale.value = const Sale(
      name: 'SO-EDIT-003',
      outlet: 'Main Outlet',
      saleStatus: 'Closed',
      saleProducts: [],
    );
    controller.saleProducts.add(line);
    controller.remove(line);
    expect(controller.saleProducts, isEmpty);
  });

  test('change_product_price permission applies to new and edited Sales', () {
    var hasPermission = false;
    final client = MockClient((_) async => http.Response('{}', 200));
    final baseUri = Uri.parse('http://127.0.0.1:8888/');
    final controller = SellController(
      productService: ProductService(baseUri, client: client),
      customerService: CustomerService(baseUri, client: client),
      saleService: SaleService(baseUri, client: client),
      outletName: 'Main Outlet',
      stationName: 'Cashier 01',
      canChangeProductPriceProvider: () => hasPermission,
    );
    const product = Product(
      code: 'P001',
      name: 'Product One',
      category: 'Test',
      unit: 'Unit',
      price: 1000,
      color: '#1677FF',
      photo: '',
    );
    expect(controller.addProduct(product), isTrue);

    expect(
      () => controller.updateSaleProduct(
        controller.saleProducts.single.copyWith(price: 2000),
      ),
      throwsA(isA<ProductPriceChangePermissionException>()),
    );
    expect(controller.saleProducts.single.price, 1000);

    hasPermission = true;
    controller.updateSaleProduct(
      controller.saleProducts.single.copyWith(price: 2000),
    );
    expect(controller.saleProducts.single.price, 2000);

    controller.openedSale.value = const Sale(
      name: 'SO-EDIT-004',
      outlet: 'Main Outlet',
      saleProducts: [],
    );
    hasPermission = false;
    expect(
      () => controller.updateSaleProduct(
        controller.saleProducts.single.copyWith(price: 3000),
      ),
      throwsA(isA<ProductPriceChangePermissionException>()),
    );
    expect(controller.saleProducts.single.price, 2000);
  });

  test('pos_payment permission applies to new and edited Sales', () {
    var hasPermission = false;
    final client = MockClient((_) async => http.Response('{}', 200));
    final baseUri = Uri.parse('http://127.0.0.1:8888/');
    final controller = SellController(
      productService: ProductService(baseUri, client: client),
      customerService: CustomerService(baseUri, client: client),
      saleService: SaleService(baseUri, client: client),
      outletName: 'Main Outlet',
      stationName: 'Cashier 01',
      canUsePosPaymentProvider: () => hasPermission,
    );

    expect(
      controller.requestPayment,
      throwsA(isA<PosPaymentPermissionException>()),
    );

    controller.openedSale.value = const Sale(
      name: 'SO-EDIT-005',
      outlet: 'Main Outlet',
      saleProducts: [],
    );
    expect(
      controller.requestPayment,
      throwsA(isA<PosPaymentPermissionException>()),
    );

    hasPermission = true;
    expect(controller.requestPayment, returnsNormally);
  });
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
