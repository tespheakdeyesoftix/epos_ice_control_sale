import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:ice_control_sale/app/session_outlet_controller.dart';
import 'package:ice_control_sale/features/report/report_controller.dart';
import 'package:ice_control_sale/features/report/report_screen.dart';
import 'package:ice_control_sale/features/report/report_viewer_dialog.dart';
import 'package:ice_control_sale/services/report_file_service.dart';

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
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ReportViewerDialog(
          definition: Get.put(
            ReportController(
              outletController: SessionOutletController(
                configuredOutlet: 'Main',
              ),
              fileService: service,
            ),
          ).reports.single,
          initialRequest: initial,
          loadRequest: () async {
            reloads++;
            return service.createLaunchRequest(
              reportPath: '/Sales Report/test report',
              outlet: 'Reloaded',
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
  );
  Get.put(controller);
  return controller;
}
