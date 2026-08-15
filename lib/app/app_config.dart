import 'dart:convert';
import 'dart:io';

class AppConfig {
  const AppConfig(this.baseUri, {this.stationName = '', this.outletName = ''});

  final Uri baseUri;
  final String stationName;
  final String outletName;

  static Future<AppConfig> loadFromExecutableDirectory() async {
    final executableDirectory = File(Platform.resolvedExecutable).parent;
    final settingsFile = File(
      '${executableDirectory.path}${Platform.pathSeparator}setting.json',
    );

    if (!await settingsFile.exists()) {
      throw const FormatException(
        'រកមិនឃើញឯកសារ setting.json នៅជាប់កម្មវិធីទេ។',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(await settingsFile.readAsString());
    } on FormatException {
      throw const FormatException('ទម្រង់ឯកសារ setting.json មិនត្រឹមត្រូវទេ។');
    }

    final rawUrl = decoded is Map<String, dynamic>
        ? (decoded['baseUrl'] ?? decoded['url'])?.toString().trim()
        : null;
    if (rawUrl == null || rawUrl.isEmpty) {
      throw const FormatException(
        'សូមកំណត់ baseUrl នៅក្នុងឯកសារ setting.json។',
      );
    }

    final normalizedUrl = rawUrl.endsWith('/') ? rawUrl : '$rawUrl/';
    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw const FormatException(
        'អាសយដ្ឋានម៉ាស៊ីនមេនៅក្នុង setting.json មិនត្រឹមត្រូវទេ។',
      );
    }
    return AppConfig(
      uri,
      stationName: decoded['stationName']?.toString().trim() ?? '',
      outletName: decoded['outlet']?.toString().trim() ?? '',
    );
  }
}
