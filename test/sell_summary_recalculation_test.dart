import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/features/sell/payment_type.dart';
import 'package:ice_control_sale/features/sell/product.dart';
import 'package:ice_control_sale/features/sell/sale_product.dart';
import 'package:ice_control_sale/features/sell/sell_controller.dart';
import 'package:ice_control_sale/services/customer_service.dart';
import 'package:ice_control_sale/services/product_service.dart';
import 'package:ice_control_sale/services/sale_service.dart';

void main() {
  test('recalculates a draft line using current product summary metadata', () {
    final client = MockClient((_) async => http.Response('{}', 200));
    final baseUri = Uri.parse('http://127.0.0.1:8888/');
    final controller = SellController(
      productService: ProductService(baseUri, client: client),
      customerService: CustomerService(baseUri, client: client),
      saleService: SaleService(baseUri, client: client),
      outletName: 'Main Outlet',
      stationName: 'Cashier 01',
    );
    controller.products.add(
      const Product(
        code: 'P001',
        name: 'Ice',
        category: 'Ice',
        unit: 'Bag',
        price: 1500,
        color: '#1677FF',
        photo: '',
        allowSumQuantity: true,
      ),
    );
    controller.saleProducts.add(
      const SaleProduct(
        productCode: 'P001',
        productName: 'Ice',
        productCategory: 'Ice',
        unit: 'Bag',
        price: 1500,
        quantity: 100,
      ),
    );

    expect(controller.grandTotal, 0);

    controller.recalculateSummary();

    expect(controller.totalSaleQuantity, 100);
    expect(controller.grandTotal, 150000);
    expect(controller.saleProducts.single.allowSumQuantity, isTrue);
  });

  test('payment selection uses the recalculated amount', () {
    final client = MockClient((_) async => http.Response('{}', 200));
    final baseUri = Uri.parse('http://127.0.0.1:8888/');
    final controller = SellController(
      productService: ProductService(baseUri, client: client),
      customerService: CustomerService(baseUri, client: client),
      saleService: SaleService(baseUri, client: client),
      outletName: 'Main Outlet',
      stationName: 'Cashier 01',
    );
    controller.products.add(
      const Product(
        code: 'P001',
        name: 'Ice',
        category: 'Ice',
        unit: 'Bag',
        price: 1500,
        color: '#1677FF',
        photo: '',
        allowSumQuantity: true,
      ),
    );
    controller.saleProducts.add(
      const SaleProduct(
        productCode: 'P001',
        productName: 'Ice',
        productCategory: 'Ice',
        unit: 'Bag',
        price: 1500,
        quantity: 100,
      ),
    );

    controller.selectPaymentType(
      const PaymentType(name: 'Cash', currency: 'KHR', exchangeRate: 1),
    );

    expect(controller.payments.single.inputAmount, 150000);
  });
}
