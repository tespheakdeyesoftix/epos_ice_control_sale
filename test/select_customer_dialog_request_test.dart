import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/features/sell/customer.dart';
import 'package:ice_control_sale/services/customer_service.dart';
import 'package:ice_control_sale/shared/select_customer_dialog_widget.dart';

void main() {
  Future<int> pumpDialog(
    WidgetTester tester,
    CustomerSelectionType selectionType,
  ) async {
    var requestCount = 0;
    final client = MockClient((request) async {
      requestCount += 1;
      expect(request.url.path, '/api/resource/Customer');
      expect(request.url.queryParameters['limit_start'], '0');
      return http.Response(
        jsonEncode({
          'data': List.generate(
            CustomerService.pageSize,
            (index) => {
              'name': 'C${index + 1}',
              'customer_name': 'Customer ${index + 1}',
              'phone_number_1': '',
              'phone_number_2': '',
              'customer_group': '',
              'keyword': '',
              'plate_number': '',
              'photo': '',
              'can_edit_bill': 1,
              'can_show_price': 1,
              'can_split_bill': 0,
            },
          ),
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: SelectCustomerDialogWidget(
          customerService: CustomerService(
            Uri.parse('http://localhost:8888/'),
            client: client,
          ),
          selectionType: selectionType,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return requestCount;
  }

  testWidgets('customer dialog loads its initial page once', (tester) async {
    expect(await pumpDialog(tester, CustomerSelectionType.customer), 1);
  });

  testWidgets('driver dialog loads its initial page once', (tester) async {
    expect(await pumpDialog(tester, CustomerSelectionType.driver), 1);
  });
}
