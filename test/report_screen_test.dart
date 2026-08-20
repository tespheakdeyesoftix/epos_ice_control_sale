import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ice_control_sale/app/session_outlet_controller.dart';
import 'package:ice_control_sale/features/report/report_controller.dart';
import 'package:ice_control_sale/features/report/report_definition.dart';
import 'package:ice_control_sale/features/report/report_screen.dart';
import 'package:ice_control_sale/features/report/report_viewer_dialog.dart';
import 'package:ice_control_sale/services/report_service.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('shows report card and opens the returned secure viewer', (
    tester,
  ) async {
    final provider = _FakeReportSessionProvider();
    final outletController = SessionOutletController(
      configuredOutlet: 'Main Outlet',
    );
    Get.put(
      ReportController(
        reportService: provider,
        outletController: outletController,
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        home: ReportScreen(
          dialogBuilder: (_, definition, session, retry) => Dialog.fullscreen(
            key: const ValueKey('fake-report-dialog'),
            child: Text('${definition.key}:${session.viewerUrl.host}'),
          ),
        ),
      ),
    );

    expect(find.text('Financial Analysis'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('report-card-financial_analysis')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('fake-report-dialog')), findsOneWidget);
    expect(
      find.text('financial_analysis:report-server-dev.aagj7.com'),
      findsOneWidget,
    );
    expect(provider.reportKeys, ['financial_analysis']);
    expect(provider.outlets, [null]);
    expect(provider.reportDates, [null]);
  });

  testWidgets('shows a recoverable error when session creation fails', (
    tester,
  ) async {
    final provider = _FakeReportSessionProvider(error: Exception('offline'));
    Get.put(
      ReportController(
        reportService: provider,
        outletController: SessionOutletController(
          configuredOutlet: 'Main Outlet',
        ),
      ),
    );

    await tester.pumpWidget(const GetMaterialApp(home: ReportScreen()));
    await tester.tap(
      find.byKey(const ValueKey('report-card-financial_analysis')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('report-error-banner')), findsOneWidget);
    expect(find.byKey(const ValueKey('report-viewer-dialog')), findsNothing);
  });

  testWidgets('viewer retry replaces an expired secure URL', (tester) async {
    var retryCount = 0;
    final first = _session(path: 'first');
    final second = _session(path: 'second');

    await tester.pumpWidget(
      MaterialApp(
        home: ReportViewerDialog(
          definition: ReportRegistry.financialAnalysis,
          initialSession: first,
          allowedHosts: const {'report-server-dev.aagj7.com'},
          loadSession: () async {
            retryCount++;
            return second;
          },
          webViewBuilder: (_, url) => Center(
            child: Text(url.path, key: const ValueKey('fake-webview')),
          ),
        ),
      ),
    );

    expect(find.text('/first'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('retry-report-viewer')));
    await tester.pumpAndSettle();

    expect(retryCount, 1);
    expect(find.text('/second'), findsOneWidget);
  });
}

class _FakeReportSessionProvider implements ReportSessionProvider {
  _FakeReportSessionProvider({this.error});

  final Object? error;
  final reportKeys = <String>[];
  final outlets = <String?>[];
  final reportDates = <DateTime?>[];

  @override
  Future<ReportEmbedSession> createEmbedSession({
    required String reportKey,
    String? outlet,
    DateTime? reportDate,
  }) async {
    reportKeys.add(reportKey);
    outlets.add(outlet);
    reportDates.add(reportDate);
    final failure = error;
    if (failure != null) throw failure;
    return _session(path: reportKey);
  }
}

ReportEmbedSession _session({required String path}) => ReportEmbedSession(
  viewerUrl: Uri.parse('https://report-server-dev.aagj7.com/$path'),
  expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
);
