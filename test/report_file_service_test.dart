import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/services/report_file_service.dart';
import 'package:ice_control_sale/services/report_config_service.dart';

const config = BoldReportConfig(
  reportServerUrl: 'https://reports.example.com/reporting/api/site/ice',
  reportServiceUrl:
      'https://reports.example.com/reporting/reportservice/api/Viewer',
  reportToken: 'bearer test-token',
);

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('report-file-test-');
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('resolves the external HTML and encodes report context', () async {
    await File(
      '${directory.path}${Platform.pathSeparator}report_viewer.html',
    ).writeAsString(
      '<script src="https://cdn.example.com/viewer.js"></script>',
    );
    final service = ReportFileService(
      executableDirectory: directory,
      dateProvider: () => DateTime(2026, 8, 24),
    );

    final request = await service.createLaunchRequest(
      reportPath: '/Sales Report/test report',
      username: 'Test User',
      outlet: 'កន្លែងលក់ ដើម',
      config: config,
    );

    expect(request.viewerUri.scheme, 'file');
    final context = Uri.splitQueryString(request.viewerUri.fragment);
    expect(context['report_path'], '/Sales Report/test report');
    expect(context['username'], 'Test User');
    expect(context['outlet'], 'កន្លែងលក់ ដើម');
    expect(context['start_date'], '2026-08-24');
    expect(context['end_date'], '2026-08-24');
    expect(context['report_server_url'], config.reportServerUrl);
    expect(context['report_service_url'], config.reportServiceUrl);
    expect(context['report_token'], config.reportToken);
    expect(request.viewerUri.toString(), contains('report_viewer.html#'));
  });

  test('reports a missing external HTML file', () async {
    final service = ReportFileService(executableDirectory: directory);

    expect(
      () => service.createLaunchRequest(
        reportPath: '/Sales Report/test report',
        outlet: 'Main',
        username: 'Test User',
        config: config,
      ),
      throwsA(
        isA<ReportFileException>().having(
          (error) => error.error,
          'error',
          ReportFileError.missing,
        ),
      ),
    );
  });

  test('reports an unreadable external HTML file', () async {
    await File(
      '${directory.path}${Platform.pathSeparator}report_viewer.html',
    ).writeAsString('<html></html>');
    final service = ReportFileService(
      executableDirectory: directory,
      fileReader: (_) async => throw const FileSystemException('denied'),
    );

    expect(
      () => service.createLaunchRequest(
        reportPath: '/Sales Report/test report',
        outlet: 'Main',
        username: 'Test User',
        config: config,
      ),
      throwsA(
        isA<ReportFileException>().having(
          (error) => error.error,
          'error',
          ReportFileError.unreadable,
        ),
      ),
    );
  });
}
