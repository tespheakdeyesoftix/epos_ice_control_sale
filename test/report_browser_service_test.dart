import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/services/report_browser_service.dart';
import 'package:ice_control_sale/services/report_file_service.dart';

void main() {
  test('opens the report in a detached Edge app window', () async {
    const edgePath =
        r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe';
    String? startedExecutable;
    List<String>? startedArguments;
    final launcher = EdgeReportLauncher(
      environment: const {'ProgramFiles(x86)': r'C:\Program Files (x86)'},
      fileExists: (path) => path == edgePath,
      processStarter: (executable, arguments) async {
        startedExecutable = executable;
        startedArguments = arguments;
      },
      windowBoundsProvider: () async =>
          const ReportWindowBounds(x: 0, y: 0, width: 1920, height: 1080),
    );
    final request = ReportLaunchRequest(
      viewerUri: Uri.parse(
        'file:///C:/app/report_viewer.html#report_path=%2FSales%20Report',
      ),
    );

    await launcher.open(request);

    expect(startedExecutable, edgePath);
    expect(startedArguments, [
      '--app=${request.viewerUri}',
      '--new-window',
      '--start-fullscreen',
      '--window-position=0,0',
      '--window-size=1920,1080',
    ]);
  });

  test('reports when Microsoft Edge is unavailable', () async {
    final launcher = EdgeReportLauncher(
      environment: const {},
      fileExists: (_) => false,
      processStarter: (_, _) async {},
    );

    expect(
      () => launcher.open(
        ReportLaunchRequest(viewerUri: Uri.parse('file:///report_viewer.html')),
      ),
      throwsA(
        isA<ReportBrowserLaunchException>().having(
          (error) => error.message,
          'message',
          contains('Microsoft Edge was not found'),
        ),
      ),
    );
  });
}
