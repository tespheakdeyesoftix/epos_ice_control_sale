import 'dart:io';

import 'package:screen_retriever/screen_retriever.dart';

import 'report_file_service.dart';

typedef ReportProcessStarter =
    Future<void> Function(String executable, List<String> arguments);
typedef ReportFileExists = bool Function(String path);
typedef ReportWindowBoundsProvider = Future<ReportWindowBounds?> Function();

class ReportWindowBounds {
  const ReportWindowBounds({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;
}

class EdgeReportLauncher {
  EdgeReportLauncher({
    String? edgeExecutablePath,
    Map<String, String>? environment,
    ReportFileExists? fileExists,
    ReportProcessStarter? processStarter,
    ReportWindowBoundsProvider? windowBoundsProvider,
  }) : _edgeExecutablePath = edgeExecutablePath,
       _environment = environment ?? Platform.environment,
       _fileExists = fileExists ?? _defaultFileExists,
       _processStarter = processStarter ?? _startDetached,
       _windowBoundsProvider = windowBoundsProvider ?? _getCurrentScreenBounds;

  final String? _edgeExecutablePath;
  final Map<String, String> _environment;
  final ReportFileExists _fileExists;
  final ReportProcessStarter _processStarter;
  final ReportWindowBoundsProvider _windowBoundsProvider;

  Future<void> open(ReportLaunchRequest request) async {
    if (!Platform.isWindows) {
      throw const ReportBrowserLaunchException(
        'The external report window is supported on Windows only.',
      );
    }

    final executable = _findEdgeExecutable();
    if (executable == null) {
      throw const ReportBrowserLaunchException(
        'Microsoft Edge was not found. Install Edge to open reports.',
      );
    }

    try {
      ReportWindowBounds? bounds;
      try {
        bounds = await _windowBoundsProvider();
      } on Exception {
        // Fullscreen can still succeed if display discovery is unavailable.
      }

      await _processStarter(executable, [
        '--app=${request.viewerUri}',
        '--new-window',
        '--start-fullscreen',
        if (bounds != null) ...[
          '--window-position=${bounds.x},${bounds.y}',
          '--window-size=${bounds.width},${bounds.height}',
        ],
      ]);
    } on ProcessException catch (error) {
      throw ReportBrowserLaunchException(
        'Unable to open the report in Microsoft Edge: ${error.message}',
      );
    } on FileSystemException catch (error) {
      throw ReportBrowserLaunchException(
        'Unable to open the report in Microsoft Edge: ${error.message}',
      );
    }
  }

  String? _findEdgeExecutable() {
    final configuredPath = _edgeExecutablePath;
    if (configuredPath != null && _fileExists(configuredPath)) {
      return configuredPath;
    }

    final candidates = <String>[
      if (_environmentValue('PROGRAMFILES(X86)') case final root?)
        '$root\\Microsoft\\Edge\\Application\\msedge.exe',
      if (_environmentValue('PROGRAMFILES') case final root?)
        '$root\\Microsoft\\Edge\\Application\\msedge.exe',
      if (_environmentValue('LOCALAPPDATA') case final root?)
        '$root\\Microsoft\\Edge\\Application\\msedge.exe',
    ];

    for (final candidate in candidates) {
      if (_fileExists(candidate)) return candidate;
    }
    return null;
  }

  String? _environmentValue(String name) {
    for (final entry in _environment.entries) {
      if (entry.key.toUpperCase() == name) return entry.value;
    }
    return null;
  }

  static Future<void> _startDetached(
    String executable,
    List<String> arguments,
  ) async {
    await Process.start(executable, arguments, mode: ProcessStartMode.detached);
  }

  static bool _defaultFileExists(String path) => File(path).existsSync();

  static Future<ReportWindowBounds?> _getCurrentScreenBounds() async {
    final displays = await screenRetriever.getAllDisplays();
    final cursor = await screenRetriever.getCursorScreenPoint();
    Display? selected;

    for (final display in displays) {
      final position = display.visiblePosition;
      if (position == null) continue;
      final right = position.dx + display.size.width;
      final bottom = position.dy + display.size.height;
      if (cursor.dx >= position.dx &&
          cursor.dx < right &&
          cursor.dy >= position.dy &&
          cursor.dy < bottom) {
        selected = display;
        break;
      }
    }

    selected ??= await screenRetriever.getPrimaryDisplay();
    final position = selected.visiblePosition;
    return ReportWindowBounds(
      x: (position?.dx ?? 0).round(),
      y: (position?.dy ?? 0).round(),
      width: selected.size.width.round(),
      height: selected.size.height.round(),
    );
  }
}

class ReportBrowserLaunchException implements Exception {
  const ReportBrowserLaunchException(this.message);

  final String message;

  @override
  String toString() => message;
}
