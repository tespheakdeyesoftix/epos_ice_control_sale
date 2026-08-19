import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/app/app_theme.dart';
import 'package:ice_control_sale/features/sell/widgets/save_order_success_widget.dart';

void main() {
  testWidgets('success countdown pauses while retry dialog is above it', (
    tester,
  ) async {
    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) {
            pageContext = context;
            return const Scaffold(body: SizedBox());
          },
        ),
      ),
    );

    var printPending = true;
    unawaited(
      showSaveOrderSuccessDialog(
        pageContext,
        savedOrder: const {'name': 'SO-TEST'},
        pauseCountdown: () => printPending,
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('save-order-success-dialog')),
      findsOneWidget,
    );

    unawaited(
      showDialog<void>(
        context: pageContext,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          key: const ValueKey('test-print-retry-dialog'),
          title: const Text('Print failed'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close retry'),
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));

    expect(
      find.byKey(const ValueKey('test-print-retry-dialog')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('save-order-success-dialog')),
      findsOneWidget,
    );

    await tester.tap(find.text('Close retry'));
    await tester.pumpAndSettle();
    printPending = false;
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('save-order-success-dialog')),
      findsNothing,
    );
  });
}
