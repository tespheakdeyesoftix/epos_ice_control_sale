import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/app/app_theme.dart';
import 'package:ice_control_sale/features/sale_summary/widgets/sale_summary_kpi_widget.dart';
import 'package:ice_control_sale/services/sale_service.dart';

void main() {
  testWidgets('shows completed orders with amount and pending orders', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: SaleSummaryKpiWidget(
            summary: DailySaleSummary(
              totalOrder: 2,
              totalAmount: 6300000,
              totalPendingOrder: 3,
              totalPendingAmount: 1470000,
              totalDeletedOrder: 2,
              totalDeletedAmount: 320000,
              totalDeletedQuantity: 8,
            ),
            isLoading: false,
          ),
        ),
      ),
    );

    expect(find.text('6,300,000 រៀល'), findsOneWidget);
    expect(find.text('2 ការលក់បានបញ្ចប់'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1,470,000 រៀល'), findsOneWidget);
    expect(find.byKey(const ValueKey('daily-sales-kpi')), findsOneWidget);
    expect(find.byKey(const ValueKey('pending-orders-kpi')), findsOneWidget);
    expect(find.byKey(const ValueKey('deleted-orders-kpi')), findsOneWidget);
    expect(find.text('320,000 រៀល'), findsOneWidget);
    expect(find.text('2 ការលក់'), findsOneWidget);
    expect(find.text('8 បរិមាណ'), findsOneWidget);
  });

  testWidgets('renders in an unbounded vertical scroll view', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: SaleSummaryKpiWidget(
                summary: DailySaleSummary(
                  totalOrder: 2,
                  totalAmount: 6300000,
                  totalPendingOrder: 3,
                  totalPendingAmount: 1470000,
                  totalDeletedOrder: 2,
                  totalDeletedAmount: 320000,
                  totalDeletedQuantity: 8,
                ),
                isLoading: false,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('daily-sales-kpi')), findsOneWidget);
    expect(find.byKey(const ValueKey('pending-orders-kpi')), findsOneWidget);
    expect(find.byKey(const ValueKey('deleted-orders-kpi')), findsOneWidget);
  });

  testWidgets('invokes completed and pending KPI actions', (tester) async {
    var salesTapped = false;
    var pendingTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SaleSummaryKpiWidget(
            summary: const DailySaleSummary(
              totalOrder: 2,
              totalAmount: 6300000,
              totalPendingOrder: 3,
              totalPendingAmount: 1470000,
              totalDeletedOrder: 2,
              totalDeletedAmount: 320000,
              totalDeletedQuantity: 8,
            ),
            isLoading: false,
            onSalesTap: () => salesTapped = true,
            onPendingTap: () => pendingTapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('daily-sales-kpi')));
    await tester.tap(find.byKey(const ValueKey('pending-orders-kpi')));

    expect(salesTapped, isTrue);
    expect(pendingTapped, isTrue);
  });
}
