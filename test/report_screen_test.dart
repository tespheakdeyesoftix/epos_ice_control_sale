import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/app/session_outlet_controller.dart';
import 'package:ice_control_sale/features/report/report_controller.dart';
import 'package:ice_control_sale/services/report_config_service.dart';
import 'package:ice_control_sale/services/report_file_service.dart';
import 'package:ice_control_sale/services/report_list_service.dart';

const _config = BoldReportConfig(
  reportServerUrl: 'https://reports.example.com/reporting/api/site/ice',
  reportServiceUrl:
      'https://reports.example.com/reporting/reportservice/api/Viewer',
  reportToken: 'bearer test-token',
);

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('report-screen-test-');
    await File(
      '${directory.path}${Platform.pathSeparator}report_viewer.html',
    ).writeAsString('<html></html>');
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test(
    'loads configuration once and creates complete launch context',
    () async {
      var configRequests = 0;
      final controller = _controller(
        directory,
        configClient: MockClient((_) async {
          configRequests++;
          return _configResponse();
        }),
      );

      await controller.loadScreen();
      final report = controller.reports.single;
      final first = await controller.createLaunchRequest(report);
      final second = await controller.createLaunchRequest(report);

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(configRequests, 1);
      final context = Uri.splitQueryString(first!.viewerUri.fragment);
      expect(context['outlet'], 'Main');
      expect(context['username'], 'Test User');
    },
  );

  test('reports an error when the external viewer HTML is missing', () async {
    await File(
      '${directory.path}${Platform.pathSeparator}report_viewer.html',
    ).delete();
    final controller = _controller(directory);

    await controller.loadScreen();
    final request = await controller.createLaunchRequest(
      controller.reports.single,
    );

    expect(request, isNull);
    expect(
      controller.errorMessage.value,
      'report_viewer.html was not found beside the application.',
    );
  });
}

ReportController _controller(Directory directory, {http.Client? configClient}) {
  return ReportController(
    outletController: SessionOutletController(configuredOutlet: 'Main'),
    fileService: ReportFileService(executableDirectory: directory),
    configService: ReportConfigService(
      Uri.parse('http://127.0.0.1:8888/'),
      client: configClient ?? MockClient((_) async => _configResponse()),
    ),
    listService: ReportListService(
      Uri.parse('http://127.0.0.1:8888/'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'data': [
              {
                'report_title': 'Test Report',
                'report_url': '/Sales Report/test report',
                'description': 'Test report description',
              },
            ],
          }),
          200,
        ),
      ),
    ),
    usernameProvider: () => 'Test User',
  );
}

http.Response _configResponse() => http.Response(
  jsonEncode({
    'message': {
      'report_server_url': _config.reportServerUrl,
      'report_service_url': _config.reportServiceUrl,
      'report_token': _config.reportToken,
    },
  }),
  200,
);
