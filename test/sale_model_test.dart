import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/features/sell/sale.dart';
import 'package:ice_control_sale/features/sell/sale_product.dart';

void main() {
  test('គណនាបរិមាណលក់ពិតតាម Sale Products metadata', () {
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
}
