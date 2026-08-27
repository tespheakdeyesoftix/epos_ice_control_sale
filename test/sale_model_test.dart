import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/features/sell/payment_type.dart';
import 'package:ice_control_sale/features/sell/sale.dart';
import 'package:ice_control_sale/features/sell/sale_product.dart';

void main() {
  test('Sale serializes one selected payment with converted input amount', () {
    const paymentType = PaymentType(
      name: 'Cash USD',
      currency: 'USD',
      exchangeRate: 4000,
    );
    final payment = SalePayment.fromPaymentType(
      paymentType,
      totalAmount: 40000,
    );
    final sale = Sale(
      outlet: 'Main',
      saleProducts: const [],
      payments: [payment],
    );

    expect(payment.inputAmount, 10);
    expect(sale.toJson()['payments'], [
      {
        'payment_type': 'Cash USD',
        'currency': 'USD',
        'exchange_rate': 4000.0,
        'input_amount': 10.0,
      },
    ]);
  });

  test('Sale preserves booking number and note', () {
    final sale = Sale.fromJson({
      'outlet': 'Main',
      'booking_number': 'BK2026-0001',
      'note': 'Deliver before noon',
      'sale_products': const [],
    });

    expect(sale.bookingNumber, 'BK2026-0001');
    expect(sale.note, 'Deliver before noon');
    expect(sale.toJson()['booking_number'], 'BK2026-0001');
    expect(sale.toJson()['note'], 'Deliver before noon');
  });

  test('SaleProduct preserves persisted child row name', () {
    final item = SaleProduct.fromJson({
      'name': 'SALE-PRODUCT-ROW-001',
      'product_code': 'P001',
      'product_name': 'Product One',
      'product_category': 'Test',
      'unit': 'Unit',
      'price': 1000,
    });

    expect(item.name, 'SALE-PRODUCT-ROW-001');
    expect(item.copyWith(quantity: 2).name, 'SALE-PRODUCT-ROW-001');
    expect(item.toJson()['name'], 'SALE-PRODUCT-ROW-001');
  });

  test('គណនាចំនួនលក់ពិតតាម Sale Products metadata', () {
    const item = SaleProduct(
      productCode: '01',
      productName: 'ទឹកកកដើមធំ',
      productCategory: 'ទឹកកកដើម',
      unit: 'ដើម',
      price: 15000,
      quantity: 12.5,
      freeQuantity: 1.5,
      returnQuantity: 2,
      splitQuantity: 3,
      cost: 5000,
    );

    expect(item.totalSaleQuantity, 6);
    expect(item.subTotal, 187500);
    expect(item.totalAmount, 90000);
    expect(item.totalCost, 30000);

    final json = item.toJson();
    expect(json['quantity'], 12.5);
    expect(json['free_quantity'], 1.5);
    expect(json['return_quantity'], 2);
    expect(json['split_quantity'], 3);
    expect(json['total_sale_quantity'], 6);
  });

  test('បង្កើត Sale totals និង JSON តាម metadata', () {
    const item = SaleProduct(
      productCode: '01',
      productName: 'ទឹកកកដើមធំ',
      productCategory: 'ទឹកកកដើម',
      unit: 'ដើម',
      price: 15000,
      quantity: 10,
      freeQuantity: 1,
      returnQuantity: 2,
      splitQuantity: 1,
      allowSumQuantity: true,
    );
    final sale = Sale(
      outlet: 'ទឹកកកដើម',
      postingDate: DateTime(2026, 8, 14),
      saleProducts: const [item],
    );

    expect(sale.totalQuantity, 10);
    expect(sale.totalFree, 1);
    expect(sale.totalQuantityReturn, 2);
    expect(sale.totalSplitQuantity, 1);
    expect(sale.totalSaleQuantity, 6);
    expect(sale.totalAmount, 90000);

    final json = sale.toJson();
    expect(json['doctype'], 'Sale');
    expect(json['posting_date'], '2026-08-14');
    expect(json['outlet'], 'ទឹកកកដើម');
    expect(json['total_sale_quantity'], 6);
    expect(json['sale_products'], hasLength(1));
  });

  test(
    'Sale quantity and amount include only products that allow quantity sum',
    () {
      const included = SaleProduct(
        productCode: '01',
        productName: 'ទឹកកកដើម',
        productCategory: 'ទឹកកក',
        unit: 'ដើម',
        price: 15000,
        quantity: 10,
        freeQuantity: 2,
        allowSumQuantity: true,
      );
      const excluded = SaleProduct(
        productCode: '02',
        productName: 'ផលិតផលមិនរាប់ចំនួន',
        productCategory: 'ផ្សេងៗ',
        unit: 'មុខ',
        price: 5000,
        quantity: 20,
        allowSumQuantity: false,
      );
      const sale = Sale(outlet: 'ទឹកកកដើម', saleProducts: [included, excluded]);

      expect(sale.totalSaleQuantity, 8);
      expect(sale.toJson()['total_sale_quantity'], 8);
      expect(sale.totalAmount, 120000);
      expect(sale.toJson()['total_amount'], 120000);
    },
  );
}
