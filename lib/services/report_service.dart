import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app/api_endpoint.dart';

class ReportEmbedSession {
  const ReportEmbedSession({required this.viewerUrl, required this.expiresAt});

  factory ReportEmbedSession.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['viewer_url']?.toString().trim() ?? '';
    final viewerUrl = Uri.tryParse(rawUrl);
    final expiresAt = _parseExpiry(json['expires_at']);
    if (viewerUrl == null ||
        viewerUrl.scheme != 'https' ||
        viewerUrl.host.isEmpty ||
        expiresAt == null) {
      throw const FormatException('Invalid report embed session response.');
    }
    return ReportEmbedSession(viewerUrl: viewerUrl, expiresAt: expiresAt);
  }

  final Uri viewerUrl;
  final DateTime expiresAt;

  bool isExpired({DateTime? now}) =>
      !expiresAt.isAfter((now ?? DateTime.now()).toUtc());
}

abstract interface class ReportSessionProvider {
  Future<ReportEmbedSession> createEmbedSession({
    required String reportKey,
    String? outlet,
    DateTime? reportDate,
  });
}

class ReportService implements ReportSessionProvider {
  ReportService(this.baseUri, {required http.Client client}) : _client = client;

  final Uri baseUri;
  final http.Client _client;

  @override
  Future<ReportEmbedSession> createEmbedSession({
    required String reportKey,
    String? outlet,
    DateTime? reportDate,
  }) async {
    final normalizedKey = reportKey.trim();
    if (normalizedKey.isEmpty) {
      throw ArgumentError.value('', 'reportKey', 'Must not be empty.');
    }
    final response = await _client
        .post(
          baseUri.resolve(ApiEndpoint.createReportEmbedUrl),
          headers: const {'Accept': 'application/json'},
          body: {
            'report_key': normalizedKey,
            if (outlet?.trim().isNotEmpty == true) 'outlet': outlet!.trim(),
            if (reportDate != null) 'report_date': _apiDate(reportDate),
          },
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ReportServiceException(response.statusCode);
    }

    try {
      dynamic payload = jsonDecode(response.body);
      if (payload is Map && payload.containsKey('message')) {
        payload = payload['message'];
      }
      if (payload is String) payload = jsonDecode(payload);
      if (payload is Map && payload['data'] is Map) payload = payload['data'];
      if (payload is! Map) throw const FormatException();
      final session = ReportEmbedSession.fromJson(
        Map<String, dynamic>.from(payload),
      );
      if (session.isExpired()) throw const ReportEmbedSessionExpiredException();
      return session;
    } on ReportEmbedSessionExpiredException {
      rethrow;
    } on FormatException {
      throw const ReportServiceException(200);
    }
  }
}

class ReportServiceException implements Exception {
  const ReportServiceException(this.statusCode);

  final int statusCode;
}

class ReportEmbedSessionExpiredException implements Exception {
  const ReportEmbedSessionExpiredException();
}

DateTime? _parseExpiry(Object? value) {
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(
      value.toInt() * 1000,
      isUtc: true,
    );
  }
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  final numeric = int.tryParse(text);
  if (numeric != null) {
    return DateTime.fromMillisecondsSinceEpoch(numeric * 1000, isUtc: true);
  }
  return DateTime.tryParse(text)?.toUtc();
}

String _apiDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
