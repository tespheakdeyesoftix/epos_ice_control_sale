import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/app/app_theme.dart';
import 'package:ice_control_sale/features/sell/product.dart';
import 'package:ice_control_sale/features/sell/sale_product.dart';
import 'package:ice_control_sale/features/sell/widgets/edit_sale_order_widget.dart';

void main() {
  testWidgets('changes unit, price, and multiplier for multi-unit product', (
    tester,
  ) async {
    SaleProduct? updated;
    const product = Product(
      code: 'P-UNIT',
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
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              updated = await showEditSaleOrderDialog(
                context,
                product: product,
                saleProduct: const SaleProduct(
                  productCode: 'P-UNIT',
                  productName: 'Block Ice',
                  productCategory: 'Ice',
                  unit: 'Block',
                  baseUnit: 'Block',
                  price: 15000,
                  productPrice: 15000,
                ),
              );
            },
            child: const Text('Edit'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('edit-sale-unit')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('edit-sale-unit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('select-product-unit-Case')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('edit-sale-unit')),
        matching: find.text('Case'),
      ),
      findsOneWidget,
    );
    expect(find.text('700,000'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('save-sale-order-edit')));
    await tester.pumpAndSettle();

    expect(updated?.unit, 'Case');
    expect(updated?.baseUnit, 'Block');
    expect(updated?.price, 700000);
    expect(updated?.productPrice, 700000);
    expect(updated?.multiplier, 6);
  });

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

  testWidgets('customer price permission hides and locks the price', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: EditSaleOrderWidget(
            canShowPrice: false,
            customerName: 'អតិថិជន សុខា',
            saleProduct: SaleProduct(
              productCode: 'P-PRIVATE',
              productName: 'Private Price Product',
              productCategory: 'Test',
              unit: 'Unit',
              price: 15500,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('***'), findsOneWidget);
    expect(find.text('15,500'), findsNothing);
    expect(
      find.text('អតិថិជន សុខា មិនអនុញ្ញាតឱ្យកែប្រែតម្លៃទេ។'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('price-edit-permission-message')),
      findsOneWidget,
    );
    final priceInkWell = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const ValueKey('edit-sale-price')),
        matching: find.byType(InkWell),
      ),
    );
    expect(priceInkWell.onTap, isNull);
  });

  testWidgets('allowed product can switch between Borrow and Sale', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: EditSaleOrderWidget(
            saleProduct: SaleProduct(
              productCode: 'CHANGE-TYPE',
              productName: 'Change Type Product',
              productCategory: 'Test',
              unit: 'Unit',
              price: 0,
              productPrice: 1000,
              saleTransactionType: 'Borrow',
              allowChangeSaleType: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final statusChip = find.byKey(
      const ValueKey('edit-sale-transaction-status'),
    );
    expect(find.text('ខ្ចី'), findsOneWidget);
    await tester.tap(statusChip);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sale-type-option-sale')));
    await tester.pumpAndSettle();

    expect(find.text('លក់'), findsOneWidget);
    expect(find.text('1,000'), findsOneWidget);
    var priceInkWell = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const ValueKey('edit-sale-price')),
        matching: find.byType(InkWell),
      ),
    );
    expect(priceInkWell.onTap, isNotNull);

    await tester.tap(statusChip);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sale-type-option-borrow')));
    await tester.pumpAndSettle();

    expect(find.text('ខ្ចី'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
    priceInkWell = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const ValueKey('edit-sale-price')),
        matching: find.byType(InkWell),
      ),
    );
    expect(priceInkWell.onTap, isNull);
  });

  testWidgets('employee permission locks product price editing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: EditSaleOrderWidget(
            canChangePrice: false,
            saleProduct: SaleProduct(
              productCode: 'P-NO-PRICE',
              productName: 'Restricted Product',
              productCategory: 'Test',
              unit: 'Unit',
              price: 15500,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('15,500'), findsOneWidget);
    expect(find.text('អ្នកមិនមានសិទ្ធិកែប្រែតម្លៃទំនិញទេ។'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('product-price-change-permission-message')),
      findsOneWidget,
    );
    final priceInkWell = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const ValueKey('edit-sale-price')),
        matching: find.byType(InkWell),
      ),
    );
    expect(priceInkWell.onTap, isNull);
  });
}
