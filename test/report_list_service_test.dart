import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/services/report_list_service.dart';

void main() {
  test('loads filtered seller reports ordered by sort order', () async {
    late http.Request sentRequest;
    final service = ReportListService(
      Uri.parse('http://127.0.0.1:8888/'),
      client: MockClient((request) async {
        sentRequest = request;
        return http.Response(
          jsonEncode({
            'data': [
              {
                'report_title': 'Daily Sales',
                'report_url': '/Sales Report/Daily Sales',
                'description': 'Daily sales by outlet',
              },
            ],
          }),
          200,
        );
      }),
    );

    final reports = await service.getSellerReports();

    expect(sentRequest.method, 'GET');
    expect(sentRequest.url.path, '/api/resource/System%20Report');
    expect(jsonDecode(sentRequest.url.queryParameters['fields']!), [
      'report_title',
      'report_url',
      'description',
    ]);
    expect(jsonDecode(sentRequest.url.queryParameters['filters']!), [
      ['is_seller_report', '=', 1],
      ['is_group', '=', 0],
    ]);
    expect(sentRequest.url.queryParameters['order_by'], 'sort_order asc');
    expect(reports, hasLength(1));
    expect(reports.single.key, 'daily_sales');
    expect(reports.single.title, 'Daily Sales');
    expect(reports.single.reportPath, '/Sales Report/Daily Sales');
    expect(reports.single.description, 'Daily sales by outlet');
  });
}
