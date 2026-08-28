import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/app/app_theme.dart';
import 'package:ice_control_sale/features/closed_sales/closed_sale.dart';
import 'package:ice_control_sale/features/closed_sales/sale_detail_controller.dart';
import 'package:ice_control_sale/features/closed_sales/sale_detail_sreen.dart';

void main() {
  testWidgets('deleted sale shows notice and restricts destructive actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final summary = ClosedSale(
      name: 'SALE-DELETED-1',
      postingDate: '2026-08-28',
      saleStatus: 'Deleted',
      deletedBy: 'អ្នកគិតលុយ ១',
      deletedDate: DateTime(2026, 8, 28, 10, 30),
      deleteNote: 'បង្កើតបុងស្ទួន',
    );
    final controller = SaleDetailController(
      summary: summary,
      saleService: null,
    );
    addTearDown(controller.onClose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SaleDetailScreen(sale: summary, controller: controller),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('deleted-sale-notice-card')),
      findsOneWidget,
    );
    expect(find.textContaining('អ្នកគិតលុយ ១'), findsOneWidget);
    expect(find.textContaining('បង្កើតបុងស្ទួន'), findsOneWidget);
    expect(find.text('លុបការកុម្ម៉ង់'), findsNothing);

    final reprint = tester.widget<PopupMenuButton<int>>(
      find.byKey(const ValueKey('reprint-receipt-copies')),
    );
    expect(reprint.enabled, isFalse);

    final previewText = find.text('មើលមុនពេលបោះពុម្ព');
    final previewButton = tester.widget<OutlinedButton>(
      find.ancestor(of: previewText, matching: find.byType(OutlinedButton)),
    );
    expect(previewButton.onPressed, isNull);
  });
}
