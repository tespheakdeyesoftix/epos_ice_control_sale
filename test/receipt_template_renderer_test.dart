import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/app/app_setting.dart';
import 'package:ice_control_sale/features/sell/sale.dart';
import 'package:ice_control_sale/features/sell/sale_product.dart';
import 'package:ice_control_sale/shared/receipts/receipt_template.dart';
import 'package:ice_control_sale/shared/receipts/receipt_template_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders a configurable A5 receipt with repeated copies', () async {
    final template = ReceiptTemplate.standardA6.copyWith(
      name: 'A5 Test',
      templateName: 'A5 Test',
      pageSize: ReceiptPageSize.a5,
      isBuiltIn: false,
      blocks: const [
        ReceiptBlock(
          id: 'header_row',
          type: ReceiptBlockType.row,
          position: ReceiptPositionMode.absolute,
          xMm: 5,
          yMm: 5,
          widthMm: 80,
          heightMm: 18,
          repeat: ReceiptPageRepeat.everyPage,
          overflow: ReceiptBlockOverflow.shrink,
          gapMm: 2,
          padding: ReceiptInsetsMm(1, 2, 3, 4),
          children: [
            ReceiptBlock(
              id: 'customer_column',
              type: ReceiptBlockType.column,
              flex: 2,
              child: ReceiptBlock(
                id: 'customer',
                type: ReceiptBlockType.text,
                fieldname: 'customer_name',
                label: 'Customer: ',
                bold: true,
              ),
            ),
            ReceiptBlock(
              id: 'phone',
              type: ReceiptBlockType.text,
              fieldname: 'phone_number',
              label: 'Phone: ',
            ),
            ReceiptBlock(
              id: 'posting_date',
              type: ReceiptBlockType.date,
              fieldname: 'sale.posting_date',
              showIf: 'sale.posting_date',
              alignment: 'right',
            ),
          ],
        ),
        ReceiptBlock(
          id: 'products',
          type: ReceiptBlockType.productTable,
          properties: {
            'columns': [
              {'key': 'index', 'label': 'No.'},
              {'key': 'product_category', 'label': 'Category'},
              {'key': 'sale_transaction_type', 'label': 'Type'},
              {'key': 'split_quantity', 'label': 'Split'},
              {'key': 'total_cost', 'label': 'Cost'},
            ],
          },
        ),
        ReceiptBlock(id: 'totals', type: ReceiptBlockType.totals),
      ],
    );
    final sale = Sale(
      name: 'SO-0001',
      outlet: 'Main',
      postingDate: DateTime(2026, 8, 15),
      customerName: 'Customer',
      phoneNumber: '012345678',
      canShowPrice: true,
      saleProducts: [
        SaleProduct(
          productCode: 'ICE',
          productName: 'Ice',
          productCategory: 'Ice',
          unit: 'Bag',
          price: 5000,
          quantity: 2,
          allowSumQuantity: true,
        ),
      ],
    );

    final bytes = await ReceiptTemplateRenderer.buildPdf(
      sale: sale,
      business: const AppSetting(raw: {}, currencySymbol: '៛'),
      sellerFallback: 'Administrator',
      template: template,
      copies: 2,
    );

    expect(bytes, isNotEmpty);
    expect(bytes.take(4), orderedEquals('%PDF'.codeUnits));
  });

  test('long product tables continue across pages without shrinking', () async {
    final products = List.generate(
      80,
      (index) => SaleProduct(
        productCode: 'ICE-$index',
        productName: 'Ice product $index',
        productCategory: 'Ice',
        unit: 'Bag',
        price: 1000,
        quantity: 1,
        allowSumQuantity: true,
      ),
    );
    final template = ReceiptTemplate.standardA6.copyWith(
      name: 'Paged A6',
      templateName: 'Paged A6',
      isBuiltIn: false,
      blocks: const [
        ReceiptBlock(id: 'products', type: ReceiptBlockType.productTable),
      ],
    );

    final bytes = await ReceiptTemplateRenderer.buildPdf(
      sale: Sale(
        name: 'SO-LONG',
        outlet: 'Main',
        saleProducts: products,
        canShowPrice: true,
      ),
      business: const AppSetting(raw: {}),
      sellerFallback: '',
      template: template,
    );

    expect(bytes, isNotEmpty);
  });

  test('resolves image fieldnames from the template document', () {
    final template = ReceiptTemplate.standardA6.copyWith(
      raw: const {'template_logo': '/files/customer-logo.png'},
      blocks: const [
        ReceiptBlock(
          id: 'logo',
          type: ReceiptBlockType.image,
          fieldname: 'print_template.template_logo',
        ),
      ],
    );

    final sources = ReceiptTemplateRenderer.resolveImageSources(
      sale: const Sale(outlet: 'Main', saleProducts: []),
      business: const AppSetting(raw: {}),
      template: template,
      sellerFallback: '',
    );

    expect(sources, {
      'print_template.template_logo': '/files/customer-logo.png',
    });
  });
}
