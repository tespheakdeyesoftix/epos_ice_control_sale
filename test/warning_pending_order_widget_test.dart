import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/app/app_theme.dart';
import 'package:ice_control_sale/services/sale_service.dart';
import 'package:ice_control_sale/shared/warning_pending_order_widget.dart';
import 'package:ice_control_sale/features/sell/widgets/pending_order_list_dialog_widget.dart';

void main() {
  testWidgets('formats an afternoon pending date with the Khmer PM label', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: WarningPendingOrderWidget(
            info: PendingOrderWarningInfo(
              pendingDate: DateTime(2020, 8, 15, 13, 5),
              totalPendingOrder: 1,
              pendingOrderAmount: 15000,
            ),
          ),
        ),
      ),
    );

    expect(find.text('15/08/2020 01:05 ល្ងាច'), findsOneWidget);
  });

  testWidgets('shows old pending-order details and can be dismissed', (
    tester,
  ) async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'message': {
            'pending_date': '2020-08-15 11:39:07.917715',
            'total_pending_order': 3,
            'pending_order_amount': 1470000.0,
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
    final service = SaleService(
      Uri.parse('http://127.0.0.1:8888/'),
      client: client,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PendingOrderWarningLauncher(
            saleService: service,
            outlet: 'ទឹកកកដើម',
            onEdit: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('warning-pending-order-dialog')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('pending-order-warning-message')),
      findsOneWidget,
    );
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1,470,000 រៀល'), findsOneWidget);
    expect(find.text('15/08/2020 11:39 ព្រឹក'), findsOneWidget);

    expect(
      find.byKey(const ValueKey('close-pending-order-warning')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('close-pending-order-warning')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('warning-pending-order-dialog')),
      findsNothing,
    );
  });

  testWidgets('does not warn when pending date is less than one hour old', (
    tester,
  ) async {
    final recentDate = DateTime.now().subtract(const Duration(minutes: 30));
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'message': {
            'pending_date': recentDate.toIso8601String(),
            'total_pending_order': 1,
            'pending_order_amount': 15000,
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PendingOrderWarningLauncher(
          saleService: SaleService(
            Uri.parse('http://127.0.0.1:8888/'),
            client: client,
          ),
          outlet: 'Main Outlet',
          onEdit: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('warning-pending-order-dialog')),
      findsNothing,
    );
  });

  testWidgets('shows the warning notice in the embedded pending screen', (
    tester,
  ) async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({'data': <dynamic>[]}),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PendingOrderListDialogWidget(
            saleService: SaleService(
              Uri.parse('http://127.0.0.1:8888/'),
              client: client,
            ),
            outlet: 'Main Outlet',
            embedded: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('pending-order-list-screen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('pending-order-list-warning')),
      findsOneWidget,
    );
  });

  testWidgets('pending list uses explicit detail and edit actions', (
    tester,
  ) async {
    String? editedOrder;
    final client = MockClient((request) async {
      if (request.url.path.endsWith('get_max_pending_order_date')) {
        return http.Response(
          jsonEncode({
            'message': {
              'pending_date': '2020-08-15 11:39:07',
              'total_pending_order': 1,
              'pending_order_amount': 15000,
            },
          }),
          200,
        );
      }
      if (request.url.path == '/api/resource/Sale') {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'name': 'SO-DRAFT-001',
                'posting_date': '2026-08-20',
                'total_sale_quantity': 1,
                'total_amount': 15000,
              },
            ],
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'data': {
            'name': 'SO-DRAFT-001',
            'sale_status': 'Draft',
            'sale_products': <dynamic>[],
          },
        }),
        200,
      );
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PendingOrderWarningLauncher(
          saleService: SaleService(
            Uri.parse('http://127.0.0.1:8888/'),
            client: client,
          ),
          outlet: 'Main Outlet',
          onEdit: (name) => editedOrder = name,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('view-pending-orders-warning')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('pending-order-list-warning')),
      findsOneWidget,
    );
    final row = find.byKey(const ValueKey('pending-order-SO-DRAFT-001'));
    expect(row, findsOneWidget);
    expect(
      find.byKey(const ValueKey('view-pending-order-SO-DRAFT-001')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('edit-pending-order-SO-DRAFT-001')),
      findsOneWidget,
    );
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(row, findsOneWidget);
    expect(editedOrder, isNull);

    await tester.tap(
      find.byKey(const ValueKey('view-pending-order-SO-DRAFT-001')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('pending-sale-view-dialog')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('close-pending-sale-view')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('edit-pending-order-SO-DRAFT-001')),
    );
    await tester.pumpAndSettle();
    expect(editedOrder, 'SO-DRAFT-001');
    expect(row, findsNothing);
  });
}
