import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/features/sell/product.dart';
import 'package:ice_control_sale/features/sell/widgets/select_product_unit_dialog_widget.dart';

void main() {
  const product = Product(
    code: '01',
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

  testWidgets('shows product name, unit, and price for every unit option', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SelectProductUnitDialogWidget(product: product)),
      ),
    );

    expect(find.byKey(const ValueKey('select-product-unit-dialog')), findsOne);
    expect(find.text('Block Ice'), findsNWidgets(2));
    expect(find.text('Case'), findsOne);
    expect(find.text('Block'), findsOne);
    expect(find.text('700,000 រៀល'), findsOne);
    expect(find.text('15,000 រៀល'), findsOne);
  });

  testWidgets('returns a product configured with the selected unit', (
    tester,
  ) async {
    Product? selectedProduct;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              selectedProduct = await showSelectProductUnitDialog(
                context,
                product: product,
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('select-product-unit-Case')));
    await tester.pumpAndSettle();

    expect(selectedProduct?.unit, 'Case');
    expect(selectedProduct?.price, 700000);
    expect(selectedProduct?.multiplier, 6);
    expect(selectedProduct?.resolvedBaseUnit, 'Block');
  });

  testWidgets('can hide unit prices for customers without price access', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SelectProductUnitDialogWidget(
            product: product,
            showPrices: false,
          ),
        ),
      ),
    );

    expect(find.text('***'), findsNWidgets(2));
    expect(find.text('700,000 រៀល'), findsNothing);
    expect(find.text('15,000 រៀល'), findsNothing);
  });
}
