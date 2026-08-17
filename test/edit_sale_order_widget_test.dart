import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/app/app_theme.dart';
import 'package:ice_control_sale/features/sell/sale_product.dart';
import 'package:ice_control_sale/features/sell/widgets/edit_sale_order_widget.dart';

void main() {
  testWidgets('return, free and split quantities cannot exceed quantity', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: EditSaleOrderWidget(
            saleProduct: SaleProduct(
              productCode: 'P-001',
              productName: 'Test Product',
              productCategory: 'Test',
              unit: 'Unit',
              price: 1000,
              quantity: 2,
              freeQuantity: 0.75,
              splitQuantity: 0.5,
            ),
          ),
        ),
      ),
    );

    expect(find.text('លក់'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('edit-sale-return-quantity')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('clear-number')));
    await tester.tap(find.byKey(const ValueKey('number-key-1')));
    await tester.tap(find.byKey(const ValueKey('accept-number')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('sale-quantity-validation-error')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('save-sale-order-edit')),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('edit-sale-return-quantity')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('clear-number')));
    await tester.tap(find.byKey(const ValueKey('decimal-number')));
    await tester.tap(find.byKey(const ValueKey('number-key-5')));
    await tester.tap(find.byKey(const ValueKey('accept-number')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('sale-quantity-validation-error')),
      findsNothing,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('save-sale-order-edit')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('Borrow status disables price editing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: EditSaleOrderWidget(
            saleProduct: SaleProduct(
              productCode: 'BORROW-001',
              productName: 'Borrow Product',
              productCategory: 'Test',
              unit: 'Unit',
              price: 0,
              productPrice: 1000,
              saleTransactionType: 'Borrow',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ខ្ចី'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('edit-sale-transaction-status')),
      findsOneWidget,
    );
    final priceInkWell = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const ValueKey('edit-sale-price')),
        matching: find.byType(InkWell),
      ),
    );
    expect(priceInkWell.onTap, isNull);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('edit-sale-price')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('quantity-input')), findsNothing);
  });
}
