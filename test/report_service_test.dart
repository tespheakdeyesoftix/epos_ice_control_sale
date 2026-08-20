import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/app/api_endpoint.dart';
import 'package:ice_control_sale/services/report_service.dart';

void main() {
  test('creates a report embed session through the authenticated API', () async {
    late http.Request sentRequest;
    final service = ReportService(
      Uri.parse('https://example.com/'),
      client: MockClient((request) async {
        sentRequest = request;
        return http.Response(
          jsonEncode({
            'message': {
              'viewer_url':
                  'https://report-server-dev.aagj7.com/reporting/site/ice-dev-report/reports/id?isembed=true',
              'expires_at': DateTime.now()
                  .toUtc()
                  .add(const Duration(minutes: 5))
                  .toIso8601String(),
            },
          }),
          200,
        );
      }),
    );

    final session = await service.createEmbedSession(
      reportKey: 'daily_sale_orders',
      outlet: 'Main Outlet',
      reportDate: DateTime(2026, 8, 20),
    );

    expect(sentRequest.method, 'POST');
    expect(sentRequest.url.path, '/${ApiEndpoint.createReportEmbedUrl}');
    expect(sentRequest.bodyFields, {
      'report_key': 'daily_sale_orders',
      'outlet': 'Main Outlet',
      'report_date': '2026-08-20',
    });
    expect(session.viewerUrl.scheme, 'https');
    expect(session.viewerUrl.host, 'report-server-dev.aagj7.com');
    expect(session.isExpired(), isFalse);
  });

  test('rejects expired report embed sessions', () async {
    final service = ReportService(
      Uri.parse('https://example.com/'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message': {
              'viewer_url': 'https://reports.example.com/report',
              'expires_at': DateTime.now()
                  .toUtc()
                  .subtract(const Duration(minutes: 1))
                  .toIso8601String(),
            },
          }),
          200,
        ),
      ),
    );

    expect(
      () => service.createEmbedSession(reportKey: 'financial_analysis'),
      throwsA(isA<ReportEmbedSessionExpiredException>()),
    );
  });

  test('rejects insecure viewer URLs', () {
    expect(
      () => ReportEmbedSession.fromJson({
        'viewer_url': 'http://reports.example.com/report',
        'expires_at': '2026-08-20T03:00:00Z',
      }),
      throwsFormatException,
    );
  });
}
