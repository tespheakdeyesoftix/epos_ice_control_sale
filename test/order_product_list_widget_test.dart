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
    expect(
      find.byKey(const ValueKey('sale-note-dashed-border')),
      findsOneWidget,
    );
    expect(find.text('បញ្ជូលចំណាំ'), findsOneWidget);

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

  testWidgets('masks unit prices and totals without removing their widgets', (
    tester,
  ) async {
    const product = SaleProduct(
      productCode: 'PRIVATE-01',
      productName: 'Private price product',
      productCategory: 'Ice',
      unit: 'Unit',
      price: 15000,
      quantity: 2,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 520,
            child: OrderProductListWidget(
              lines: const [product],
              imageUriBuilder: (_) => null,
              onRemove: (_) {},
              onEdit: (_) {},
              onDateTap: () {},
              onReferenceTap: () {},
              referenceNumber: '',
              onNoteTap: () {},
              note: '',
              showPrices: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 x *** / Unit'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('order-product-total-PRIVATE-01')),
      findsOneWidget,
    );
    expect(find.text('***'), findsOneWidget);
    expect(find.textContaining('15,000'), findsNothing);
    expect(find.textContaining('30,000'), findsNothing);
  });
}
