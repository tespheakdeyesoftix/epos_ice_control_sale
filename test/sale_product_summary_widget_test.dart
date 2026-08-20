import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/app/app_theme.dart';
import 'package:ice_control_sale/features/sale_summary/widgets/sale_product_summary_widget.dart';
import 'package:ice_control_sale/services/sale_service.dart';

void main() {
  testWidgets('renders daily sale product summary as a table', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: SaleProductSummaryWidget(
            isLoading: false,
            products: [
              DailySaleProductSummary(
                productCode: 'P-01',
                productName: 'ទឹកកកដើម',
                unit: 'ដើម',
                quantity: 12,
                freeQuantity: 1,
                returnQuantity: 2,
                splitQuantity: 0,
                totalSaleQuantity: 11,
                totalAmount: 165000,
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('daily-sale-product-summary')),
      findsOneWidget,
    );
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('ទឹកកកដើម'), findsOneWidget);
    expect(find.text('សរុបលក់'), findsOneWidget);
    expect(find.text('165,000 រៀល'), findsOneWidget);
  });

  testWidgets('shows an empty state when no products were sold', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: SaleProductSummaryWidget(products: [], isLoading: false),
        ),
      ),
    );

    expect(find.text('មិនមានទំនិញលក់នៅថ្ងៃនេះទេ'), findsOneWidget);
  });
}
