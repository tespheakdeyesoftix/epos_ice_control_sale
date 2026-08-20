import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/services/report_file_service.dart';

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
    final service = ReportFileService(executableDirectory: directory);

    final request = await service.createLaunchRequest(
      reportPath: '/Sales Report/test report',
      outlet: 'កន្លែងលក់ ដើម',
    );

    expect(request.viewerUri.scheme, 'file');
    final context = Uri.splitQueryString(request.viewerUri.fragment);
    expect(context['report_path'], '/Sales Report/test report');
    expect(context['outlet'], 'កន្លែងលក់ ដើម');
    expect(request.viewerUri.toString(), contains('report_viewer.html#'));
  });

  test('reports a missing external HTML file', () async {
    final service = ReportFileService(executableDirectory: directory);

    expect(
      () => service.createLaunchRequest(
        reportPath: '/Sales Report/test report',
        outlet: 'Main',
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
