import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/services/sale_service.dart';

void main() {
  test('loads daily sale summary for outlet', () async {
    late http.Request sentRequest;
    final service = SaleService(
      Uri.parse('https://example.com/'),
      client: MockClient((request) async {
        sentRequest = request;
        return http.Response(
          jsonEncode({
            'message': {
              'total_order': 2,
              'total_amount': 6300000,
              'total_pending_order': 3,
              'total_pending_amount': 1470000,
            },
          }),
          200,
        );
      }),
    );

    final summary = await service.getDailySaleSummary('សាខាទី១');

    expect(sentRequest.method, 'GET');
    expect(sentRequest.url.queryParameters['outlet'], 'សាខាទី១');
    expect(summary.totalOrder, 2);
    expect(summary.totalAmount, 6300000);
    expect(summary.totalPendingOrder, 3);
  });
}
