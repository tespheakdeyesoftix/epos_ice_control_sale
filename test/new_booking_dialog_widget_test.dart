import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/features/booking/widgets/new_booking_dialog_widget.dart';
import 'package:ice_control_sale/features/sell/product.dart';
import 'package:ice_control_sale/services/booking_service.dart';

void main() {
  testWidgets('validates required booking metadata fields', (tester) async {
    final service = BookingService(
      Uri.parse('https://ice.test/'),
      client: MockClient((_) async => http.Response('{}', 200)),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () =>
                  showNewBookingDialog(context, dataSource: service),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('submit-new-booking')));
    await tester.pump();

    expect(find.text('សូមបញ្ចូលលេខទូរស័ព្ទ'), findsOneWidget);
    expect(find.text('សូមជ្រើសរើសថ្ងៃដឹកជញ្ជូន'), findsOneWidget);
    expect(find.text('សូមជ្រើសរើសកម្មវិធីកក់'), findsOneWidget);
    expect(find.text('សូមបន្ថែមផលិតផលយ៉ាងតិចមួយ'), findsOneWidget);
  });

  testWidgets('loads booking products from Product resource without outlet', (
    tester,
  ) async {
    Uri? requestedUri;
    Product? selected;
    final service = BookingService(
      Uri.parse('https://ice.test/'),
      client: MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({
            'data': [
              {
                'name': 'P-01',
                'product_code': 'P-01',
                'product_name': 'Ice',
                'unit': 'Bag',
                'price': 1500,
                'default_sale_transaction_type': 'Sale',
              },
            ],
          }),
          200,
        );
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                selected = await showBookingProductSelector(
                  context,
                  dataSource: service,
                );
              },
              child: const Text('Products'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Products'));
    await tester.pumpAndSettle();
    expect(requestedUri?.path, '/api/resource/Product');
    expect(requestedUri?.queryParameters.containsKey('outlet'), isFalse);
    expect(
      jsonDecode(requestedUri!.queryParameters['fields']!),
      contains('allow_sum_qty'),
    );
    await tester.tap(find.byKey(const ValueKey('select-booking-product-P-01')));
    await tester.pumpAndSettle();
    expect(selected?.code, 'P-01');
  });

  testWidgets('accepts comma-formatted booking prices', (tester) async {
    final service = BookingService(
      Uri.parse('https://ice.test/'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'data': [
              {
                'name': 'P-01',
                'product_code': 'P-01',
                'product_name': 'Ice',
                'unit': 'Bag',
                'price': 1500,
                'default_sale_transaction_type': 'Sale',
              },
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
              onPressed: () =>
                  showNewBookingDialog(context, dataSource: service),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final addProduct = find.byKey(const ValueKey('add-booking-product'));
    await tester.ensureVisible(addProduct);
    await tester.tap(addProduct);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('select-booking-product-P-01')));
    await tester.pumpAndSettle();

    final price = find.byKey(const ValueKey('booking-product-price-P-01'));
    await tester.ensureVisible(price);
    expect(
      tester
          .widget<EditableText>(
            find.descendant(of: price, matching: find.byType(EditableText)),
          )
          .controller
          .text,
      '0',
    );
    await tester.enterText(price, '10,000');
    await tester.pump();

    expect(find.text('10,000'), findsWidgets);
    expect(find.text('សរុប 10,000 រៀល'), findsOneWidget);
  });
}
