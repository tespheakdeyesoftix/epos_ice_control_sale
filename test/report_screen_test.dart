import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:get/get.dart';
import 'package:ice_control_sale/app/session_outlet_controller.dart';
import 'package:ice_control_sale/features/report/report_controller.dart';
import 'package:ice_control_sale/features/report/report_definition.dart';
import 'package:ice_control_sale/features/report/report_screen.dart';
import 'package:ice_control_sale/features/report/report_viewer_dialog.dart';
import 'package:ice_control_sale/services/report_file_service.dart';
import 'package:ice_control_sale/services/report_config_service.dart';
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
    Get.testMode = true;
    directory = await Directory.systemTemp.createTemp('report-screen-test-');
    await File(
      '${directory.path}${Platform.pathSeparator}report_viewer.html',
    ).writeAsString('<html></html>');
  });

  tearDown(() async {
    Get.reset();
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('recognizes expected export and print navigation aborts', () {
    expect(
      isExpectedWebViewNavigationAbort(
        WebResourceError(
          type: WebResourceErrorType.CONNECTION_ABORTED,
          description: 'connection stopped',
        ),
      ),
      isTrue,
    );
    expect(
      isExpectedWebViewNavigationAbort(
        WebResourceError(
          type: WebResourceErrorType.CANCELLED,
          description: 'cancelled',
        ),
      ),
      isTrue,
    );
    expect(
      isExpectedWebViewNavigationAbort(
        WebResourceError(
          type: WebResourceErrorType.HOST_LOOKUP,
          description: 'host not found',
        ),
      ),
      isFalse,
    );
  });

  test(
    'loads report configuration once and reuses it for card opens',
    () async {
      var configRequests = 0;
      final configService = ReportConfigService(
        Uri.parse('http://127.0.0.1:8888/'),
        client: MockClient((_) async {
          configRequests++;
          return http.Response(
            jsonEncode({
              'message': {
                'report_server_url': _config.reportServerUrl,
                'report_service_url': _config.reportServiceUrl,
                'report_token': _config.reportToken,
              },
            }),
            200,
          );
        }),
      );
      final controller = ReportController(
        outletController: SessionOutletController(configuredOutlet: 'Main'),
        fileService: ReportFileService(executableDirectory: directory),
        configService: configService,
        listService: _listService(),
      );

      await controller.loadScreen();
      final report = controller.reports.single;
      expect(await controller.createLaunchRequest(report), isNotNull);
      expect(await controller.createLaunchRequest(report), isNotNull);

      expect(configRequests, 1);
    },
  );

  testWidgets('opens a full-screen dialog with session outlet context', (
    tester,
  ) async {
    final controller = _registerController(directory, outlet: 'កន្លែងលក់ ដើម');

    await tester.pumpWidget(
      GetMaterialApp(
        home: ReportScreen(
          dialogBuilder: (_, definition, request, reload) => Dialog.fullscreen(
            key: const ValueKey('fake-report-dialog'),
            child: Text('${definition.key}:${_contextFrom(request)['outlet']}'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('report-card-test_report')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('fake-report-dialog')), findsOneWidget);
    expect(find.text('test_report:កន្លែងលក់ ដើម'), findsOneWidget);
    expect(controller.errorMessage.value, isNull);
  });

  testWidgets('shows an error when the external HTML is missing', (
    tester,
  ) async {
    await File(
      '${directory.path}${Platform.pathSeparator}report_viewer.html',
    ).delete();
    _registerController(directory, outlet: 'Main');

    await tester.pumpWidget(const GetMaterialApp(home: ReportScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('report-card-test_report')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('report-error-banner')), findsOneWidget);
    expect(find.byKey(const ValueKey('report-viewer-dialog')), findsNothing);
  });

  testWidgets('viewer reload rereads the external launch request', (
    tester,
  ) async {
    var reloads = 0;
    final service = ReportFileService(executableDirectory: directory);
    final initial = await service.createLaunchRequest(
      reportPath: '/Sales Report/test report',
      outlet: 'First',
      config: _config,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ReportViewerDialog(
          definition: const ReportDefinition(
            key: 'test_report',
            title: 'Test Report',
            description: 'Test report description',
            icon: Icons.description_outlined,
            reportPath: '/Sales Report/test report',
          ),
          initialRequest: initial,
          loadRequest: () async {
            reloads++;
            return service.createLaunchRequest(
              reportPath: '/Sales Report/test report',
              outlet: 'Reloaded',
              config: _config,
            );
          },
          webViewBuilder: (_, request) => Center(
            child: Text(
              _contextFrom(request)['outlet'] ?? '',
              key: const ValueKey('fake-webview'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('First'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reload-report-viewer')));
    await tester.pumpAndSettle();

    expect(reloads, 1);
    expect(find.text('Reloaded'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('close-report-viewer')));
    await tester.pumpAndSettle();
  });
}

Map<String, String> _contextFrom(ReportLaunchRequest request) {
  return Uri.splitQueryString(request.viewerUri.fragment);
}

ReportController _registerController(
  Directory directory, {
  required String outlet,
}) {
  final controller = ReportController(
    outletController: SessionOutletController(configuredOutlet: outlet),
    fileService: ReportFileService(executableDirectory: directory),
    configService: _configService(),
    listService: _listService(),
  );
  Get.put(controller);
  return controller;
}

ReportConfigService _configService() => ReportConfigService(
  Uri.parse('http://127.0.0.1:8888/'),
  client: MockClient(
    (_) async => http.Response(
      jsonEncode({
        'message': {
          'report_server_url': _config.reportServerUrl,
          'report_service_url': _config.reportServiceUrl,
          'report_token': _config.reportToken,
        },
      }),
      200,
    ),
  ),
);

ReportListService _listService() => ReportListService(
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
);
