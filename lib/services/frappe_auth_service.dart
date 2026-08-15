import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app/api_endpoint.dart';
import 'frappe_session_client.dart';

class FrappeAuthService {
  FrappeAuthService(this.baseUri, {http.Client? client})
    : _client = client ?? http.Client();

  final Uri baseUri;
  final http.Client _client;

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final response = await _client
        .post(
          baseUri.resolve(ApiEndpoint.login),
          headers: const {'Accept': 'application/json'},
          body: {'usr': username, 'pwd': password},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const AuthException(
        'ឈ្មោះអ្នកប្រើប្រាស់ ឬពាក្យសម្ងាត់មិនត្រឹមត្រូវទេ។',
      );
    }

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['exc'] != null) {
        throw const AuthException(
          'ឈ្មោះអ្នកប្រើប្រាស់ ឬពាក្យសម្ងាត់មិនត្រឹមត្រូវទេ។',
        );
      }
    } on FormatException {
      // A successful Frappe proxy may return an empty/non-JSON response.
    }
  }

  Future<void> logout() async {
    try {
      await _client
          .post(
            baseUri.resolve(ApiEndpoint.logout),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 8));
    } finally {
      if (_client case final FrappeSessionClient sessionClient) {
        sessionClient.clearSession();
      }
    }
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}
