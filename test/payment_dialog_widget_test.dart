import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/features/sell/widgets/payment_dialog_widget.dart';
import 'package:ice_control_sale/services/sale_service.dart';

void main() {
  testWidgets('selects one payment type and returns payment action', (
    tester,
  ) async {
    PaymentDialogResult? result;
    final service = SaleService(
      Uri.parse('https://ice.test/'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message': [
              {'name': 'Cash USD', 'currency': 'USD', 'exchange_rate': 4000},
              {'name': 'Cash KHR', 'currency': 'KHR', 'exchange_rate': 1},
            ],
          }),
          200,
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await showPaymentDialog(
                  context,
                  service: service,
                  totalAmount: 40000,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('payment-dialog')), findsOneWidget);
    expect(find.textContaining('10 USD'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('confirm-payment')))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('payment-type-Cash USD')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('confirm-payment')));
    await tester.pumpAndSettle();

    expect(result?.paymentType.name, 'Cash USD');
    expect(result?.action, PaymentDialogAction.payment);
  });
}
