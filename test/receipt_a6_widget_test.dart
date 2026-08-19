import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/app/app_setting.dart';
import 'package:ice_control_sale/features/sell/sale.dart';
import 'package:ice_control_sale/features/sell/sale_product.dart';
import 'package:ice_control_sale/shared/receipts/receipt_a6_widget.dart';
import 'package:ice_control_sale/shared/receipts/receipt_raster_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shapes one Khmer text run', () async {
    final widget = await ReceiptRasterText.create('វិក្កយបត្រ');
    expect(widget, isNotNull);
  });

  test('builds an A6 PDF with Khmer and optional sale details', () async {
    final bytes = await ReceiptA6Widget.buildPdf(
      sale: _sale(canShowPrice: true, productCount: 1),
      business: _business,
      sellerFallback: 'Administrator',
    );

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('many products still build as one fitted A6 page', () async {
    final bytes = await ReceiptA6Widget.buildPdf(
      sale: _sale(canShowPrice: false, productCount: 35),
      business: _business,
      sellerFallback: 'Administrator',
    );

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}

const _business = AppSetting(
  raw: <String, dynamic>{'phone_number_2': '012 345 678'},
  businessNameKh: 'រោងចក្រទឹកកកសាកល្បង',
  businessNameEn: 'Test Ice Factory',
  address: 'Phnom Penh',
  phoneNumber1: '010 111 222',
);

Sale _sale({required bool canShowPrice, required int productCount}) {
  return Sale(
    name: 'SO2026-0001',
    outlet: 'Main Outlet',
    saleStatus: 'Closed',
    canShowPrice: canShowPrice,
    customer: 'C457',
    customerName: 'អតិថិជនសាកល្បង',
    phoneNumber: '012 675 782',
    driverName: 'អ្នកបើកបរ',
    driverPhoneNumber: '099 111 222',
    plateNumber: '2AB-1234',
    station: 'Cashier 01',
    postingDate: DateTime(2026, 8, 18),
    referenceNumber: 'REF-001',
    note: 'ចំណាំលើការលក់',
    saleProducts: List.generate(
      productCount,
      (index) => SaleProduct(
        productCode: 'P$index',
        productName: 'ទឹកកកដើម ${index + 1}',
        productCategory: 'Ice',
        unit: 'ដើម',
        price: 15000,
        quantity: 10,
        freeQuantity: index == 0 ? 1 : 0,
        returnQuantity: index == 0 ? 1 : 0,
        note: index == 0 ? 'សាកល្បងចំណាំទំនិញ' : '',
        allowSumQuantity: true,
      ),
    ),
  );
}
