import 'dart:io';

typedef ReportFileReader = Future<void> Function(File file);

class ReportLaunchRequest {
  const ReportLaunchRequest({required this.viewerUri});

  final Uri viewerUri;
}

class ReportFileService {
  ReportFileService({
    Directory? executableDirectory,
    ReportFileReader? fileReader,
  }) : _fileReader = fileReader ?? _defaultFileReader,
       _executableDirectory =
           executableDirectory ?? File(Platform.resolvedExecutable).parent;

  final Directory _executableDirectory;
  final ReportFileReader _fileReader;

  File get viewerFile => File(
    '${_executableDirectory.path}${Platform.pathSeparator}report_viewer.html',
  );

  Future<ReportLaunchRequest> createLaunchRequest({
    required String reportPath,
    required String outlet,
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

    final query = <String, String>{
      'report_path': normalizedPath,
      if (outlet.trim().isNotEmpty) 'outlet': outlet.trim(),
    };
    final viewerUri = Uri.file(
      file.absolute.path,
      windows: Platform.isWindows,
    ).replace(fragment: Uri(queryParameters: query).query);
    return ReportLaunchRequest(viewerUri: viewerUri);
  }
}

Future<void> _defaultFileReader(File file) => file.openRead().drain<void>();

enum ReportFileError { missing, unreadable, invalidReportPath }

class ReportFileException implements Exception {
  const ReportFileException.missing() : error = ReportFileError.missing;
  const ReportFileException.unreadable() : error = ReportFileError.unreadable;
  const ReportFileException.invalidReportPath()
    : error = ReportFileError.invalidReportPath;

  final ReportFileError error;
}
