import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app/api_endpoint.dart';

class BoldReportConfig {
  const BoldReportConfig({
    required this.reportServerUrl,
    required this.reportServiceUrl,
    required this.reportToken,
  });

  final String reportServerUrl;
  final String reportServiceUrl;
  final String reportToken;

  factory BoldReportConfig.fromJson(Map<String, dynamic> json) {
    final reportServerUrl = json['report_server_url']?.toString().trim() ?? '';
    final reportServiceUrl =
        json['report_service_url']?.toString().trim() ?? '';
    final reportToken = json['report_token']?.toString().trim() ?? '';

    if (!_isHttpUrl(reportServerUrl) ||
        !_isHttpUrl(reportServiceUrl) ||
        reportToken.isEmpty) {
      throw const ReportConfigServiceException.invalidResponse();
    }

    return BoldReportConfig(
      reportServerUrl: reportServerUrl,
      reportServiceUrl: reportServiceUrl,
      reportToken: reportToken,
    );
  }

  static bool _isHttpUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
}

class ReportConfigService {
  ReportConfigService(this.baseUri, {required http.Client client})
    : _client = client;

  final Uri baseUri;
  final http.Client _client;

  Future<BoldReportConfig> getConfig() async {
    final response = await _client
        .post(
          baseUri.resolve(ApiEndpoint.boldReportConfig),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ReportConfigServiceException.http(response.statusCode);
    }

    dynamic payload;
    try {
      payload = jsonDecode(response.body);
      if (payload is Map && payload.containsKey('message')) {
        payload = payload['message'];
      }
      if (payload is String) payload = jsonDecode(payload);
    } on FormatException {
      throw const ReportConfigServiceException.invalidResponse();
    }

    if (payload is! Map) {
      throw const ReportConfigServiceException.invalidResponse();
    }
    return BoldReportConfig.fromJson(Map<String, dynamic>.from(payload));
  }
}

enum ReportConfigError { http, invalidResponse }

class ReportConfigServiceException implements Exception {
  const ReportConfigServiceException.http(this.statusCode)
    : error = ReportConfigError.http;
  const ReportConfigServiceException.invalidResponse()
    : error = ReportConfigError.invalidResponse,
      statusCode = null;

  final ReportConfigError error;
  final int? statusCode;
}
