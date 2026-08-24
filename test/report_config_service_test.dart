import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/services/report_config_service.dart';

void main() {
  test('loads Bold Reports configuration from the Frappe message', () async {
    late http.Request sentRequest;
    final service = ReportConfigService(
      Uri.parse('http://127.0.0.1:8888/'),
      client: MockClient((request) async {
        sentRequest = request;
        return http.Response(
          jsonEncode({
            'message': {
              'report_server_url':
                  'https://reports.example.com/reporting/api/site/ice',
              'report_service_url':
                  'https://reports.example.com/reporting/reportservice/api/Viewer',
              'report_token': 'bearer fresh-token',
            },
          }),
          200,
        );
      }),
    );

    final config = await service.getConfig();

    expect(sentRequest.method, 'POST');
    expect(
      sentRequest.url.path,
      '/api/method/ice_control.api.v1.utils.get_bold_report_config',
    );
    expect(config.reportServerUrl, contains('/reporting/api/site/ice'));
    expect(config.reportServiceUrl, endsWith('/api/Viewer'));
    expect(config.reportToken, 'bearer fresh-token');
  });

  test('rejects incomplete report configuration', () async {
    final service = ReportConfigService(
      Uri.parse('http://127.0.0.1:8888/'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message': {
              'report_server_url': 'https://reports.example.com/site/ice',
              'report_service_url': '',
              'report_token': '',
            },
          }),
          200,
        ),
      ),
    );

    expect(
      service.getConfig(),
      throwsA(
        isA<ReportConfigServiceException>().having(
          (error) => error.error,
          'error',
          ReportConfigError.invalidResponse,
        ),
      ),
    );
  });
}
