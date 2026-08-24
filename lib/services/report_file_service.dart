import 'dart:io';

import 'report_config_service.dart';

typedef ReportFileReader = Future<void> Function(File file);
typedef ReportDateProvider = DateTime Function();

class ReportLaunchRequest {
  const ReportLaunchRequest({required this.viewerUri});

  final Uri viewerUri;
}

class ReportFileService {
  ReportFileService({
    Directory? executableDirectory,
    ReportFileReader? fileReader,
    ReportDateProvider? dateProvider,
  }) : _fileReader = fileReader ?? _defaultFileReader,
       _dateProvider = dateProvider ?? DateTime.now,
       _executableDirectory =
           executableDirectory ?? File(Platform.resolvedExecutable).parent;

  final Directory _executableDirectory;
  final ReportFileReader _fileReader;
  final ReportDateProvider _dateProvider;

  File get viewerFile => File(
    '${_executableDirectory.path}${Platform.pathSeparator}report_viewer.html',
  );

  Future<ReportLaunchRequest> createLaunchRequest({
    required String reportPath,
    required String outlet,
    required String username,
    required BoldReportConfig config,
  }) async {
    final normalizedPath = reportPath.trim();
    if (!normalizedPath.startsWith('/')) {
      throw const ReportFileException.invalidReportPath();
    }

    final file = viewerFile;
    if (!await file.exists()) {
      throw const ReportFileException.missing();
    }
    try {
      await _fileReader(file);
    } on FileSystemException {
      throw const ReportFileException.unreadable();
    }

    final currentDate = _formatDate(_dateProvider());
    final query = <String, String>{
      'report_path': normalizedPath,
      if (outlet.trim().isNotEmpty) 'outlet': outlet.trim(),
      if (username.trim().isNotEmpty) 'username': username.trim(),
      'start_date': currentDate,
      'end_date': currentDate,
      'report_server_url': config.reportServerUrl,
      'report_service_url': config.reportServiceUrl,
      'report_token': config.reportToken,
    };
    final viewerUri = Uri.file(
      file.absolute.path,
      windows: Platform.isWindows,
    ).replace(fragment: Uri(queryParameters: query).query);
    return ReportLaunchRequest(viewerUri: viewerUri);
  }
}

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

Future<void> _defaultFileReader(File file) => file.openRead().drain<void>();

enum ReportFileError { missing, unreadable, invalidReportPath }

class ReportFileException implements Exception {
  const ReportFileException.missing() : error = ReportFileError.missing;
  const ReportFileException.unreadable() : error = ReportFileError.unreadable;
  const ReportFileException.invalidReportPath()
    : error = ReportFileError.invalidReportPath;

  final ReportFileError error;
}
