import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/features/sell/customer_free_product.dart';
import 'package:ice_control_sale/features/sell/widgets/customer_free_product_info_dialog.dart';

void main() {
  testWidgets('shows applied and insufficient free products in one dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () => showCustomerFreeProductInfoDialog(
              context,
              evaluations: const [
                FreeProductEvaluation(
                  productCode: '01',
                  productName: 'ទឹកកកដើមធំ',
                  unit: 'ដើម',
                  configuredFreeQuantity: 2,
                  orderQuantity: 5,
                  status: FreeProductEvaluationStatus.applied,
                ),
                FreeProductEvaluation(
                  productCode: '02',
                  productName: 'ទឹកកកដើមតូច',
                  unit: 'ដើម',
                  configuredFreeQuantity: 3,
                  orderQuantity: 1,
                  status: FreeProductEvaluationStatus.insufficientQuantity,
                ),
              ],
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('customer-free-product-info-dialog')),
      findsOneWidget,
    );
    expect(find.text('ព័ត៌មានទំនិញថែម'), findsOneWidget);
    expect(find.textContaining('«ទឹកកកដើមធំ» បានថែម 2 ដើម'), findsOneWidget);
    expect(find.textContaining('ចំនួនទិញ 1 ដើម'), findsOneWidget);
    expect(find.textContaining('មិនបានអនុវត្តទេ'), findsOneWidget);
    expect(find.text('យល់ព្រម'), findsOneWidget);
  });
}
