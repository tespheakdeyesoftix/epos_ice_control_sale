import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app/api_endpoint.dart';
import '../features/report/report_definition.dart';

class ReportListService {
  ReportListService(this.baseUri, {required http.Client client})
    : _client = client;

  static const _fields = ['report_title', 'report_url', 'description'];

  final Uri baseUri;
  final http.Client _client;

  Future<List<ReportDefinition>> getSellerReports() async {
    final endpoint = baseUri
        .resolve(ApiEndpoint.resource('System Report'))
        .replace(
          queryParameters: {
            'fields': jsonEncode(_fields),
            'filters': jsonEncode([
              ['is_seller_report', '=', 1],
              ['is_group', '=', 0],
            ]),
            'order_by': 'sort_order asc',
            'limit_page_length': '500',
          },
        );
    final response = await _client
        .get(endpoint, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ReportListServiceException(response.statusCode);
    }

    dynamic payload;
    try {
      payload = jsonDecode(response.body);
    } on FormatException {
      throw const ReportListServiceException(200);
    }
    final rows = payload is Map && payload['data'] is List
        ? payload['data'] as List
        : const <dynamic>[];
    return List.unmodifiable(
      rows
          .whereType<Map>()
          .map(
            (row) => ReportDefinition.fromJson(Map<String, dynamic>.from(row)),
          )
          .where(
            (report) =>
                report.title.isNotEmpty && report.reportPath.startsWith('/'),
          ),
    );
  }
}

class ReportListServiceException implements Exception {
  const ReportListServiceException(this.statusCode);

  final int statusCode;
}
