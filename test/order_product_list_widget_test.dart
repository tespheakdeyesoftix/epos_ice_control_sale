import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/app/app_theme.dart';
import 'package:ice_control_sale/features/sell/sale_product.dart';
import 'package:ice_control_sale/features/sell/widgets/order_product_list_widget.dart';

void main() {
  testWidgets('shows Sale and Borrow transaction chips in Khmer', (
    tester,
  ) async {
    const saleProduct = SaleProduct(
      productCode: 'SALE-01',
      productName: 'Sale product',
      productCategory: 'Ice',
      unit: 'Unit',
      price: 1000,
      saleTransactionType: 'Sale',
    );
    const borrowProduct = SaleProduct(
      productCode: 'BORROW-01',
      productName: 'Borrow product',
      productCategory: 'Ice',
      unit: 'Unit',
      price: 1000,
      saleTransactionType: 'Borrow',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              height: 520,
              child: OrderProductListWidget(
                lines: const [saleProduct, borrowProduct],
                imageUriBuilder: (_) => null,
                onRemove: (_) {},
                onEdit: (_) {},
                onDateTap: () {},
                onReferenceTap: () {},
                referenceNumber: '',
                onNoteTap: () {},
                note: '',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('លក់'), findsOneWidget);
    expect(find.text('ខ្ចី'), findsOneWidget);

    final saleChip = tester.widget<Container>(
      find.byKey(const ValueKey('sale-transaction-type-SALE-01')),
    );
    final borrowChip = tester.widget<Container>(
      find.byKey(const ValueKey('sale-transaction-type-BORROW-01')),
    );
    expect(
      (saleChip.decoration! as BoxDecoration).color,
      const Color(0xFF168A45),
    );
    expect(
      (borrowChip.decoration! as BoxDecoration).color,
      const Color(0xFFF79009),
    );
  });
}
