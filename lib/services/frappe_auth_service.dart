import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app/api_endpoint.dart';
import 'frappe_session_client.dart';

class AuthSession {
  const AuthSession({
    required this.raw,
    this.fullName = '',
    this.user = '',
    this.email = '',
    this.username = '',
    this.userType = '',
    this.userImage = '',
    this.userImageUrl = '',
    this.roles = const [],
    this.employee = const {},
  });

  factory AuthSession.fromJson(
    Map<String, dynamic> json, {
    required Uri baseUri,
  }) {
    final rawImage = _text(json['user_image']);
    final roles = json['roles'];
    final employee = json['employee'];
    return AuthSession(
      raw: Map<String, dynamic>.unmodifiable(json),
      fullName: _text(json['full_name']),
      user: _text(json['user']),
      email: _text(json['email']),
      username: _text(json['username']),
      userType: _text(json['user_type']),
      userImage: rawImage,
      userImageUrl: rawImage.isEmpty
          ? ''
          : baseUri.resolve(rawImage).toString(),
      roles: roles is List
          ? roles.map((role) => role.toString()).toList(growable: false)
          : const [],
      employee: employee is Map
          ? Map<String, dynamic>.unmodifiable(
              Map<String, dynamic>.from(employee),
            )
          : const {},
    );
  }

  final Map<String, dynamic> raw;
  final String fullName;
  final String user;
  final String email;
  final String username;
  final String userType;
  final String userImage;
  final String userImageUrl;
  final List<String> roles;
  final Map<String, dynamic> employee;

  bool get canChangeCustomer => _flag(employee['change_customer']);
  bool get canChangeSaleDate => _flag(employee['change_sale_date']);
}

class FrappeAuthService {
  FrappeAuthService(this.baseUri, {http.Client? client})
    : _client = client ?? http.Client();

  final Uri baseUri;
  final http.Client _client;

  Future<AuthSession> login({
    required String username,
    required String password,
    required String outlet,
  }) async {
    final response = await _client
        .post(
          baseUri.resolve(ApiEndpoint.login),
          headers: const {'Accept': 'application/json'},
          body: {'usr': username, 'pwd': password, 'outlet': outlet},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const AuthException(
        'ឈ្មោះអ្នកប្រើប្រាស់ ឬពាក្យសម្ងាត់មិនត្រឹមត្រូវទេ។',
      );
    }

    try {
      dynamic body = jsonDecode(response.body);
      if (body is Map && body['exc'] != null) {
        throw const AuthException(
          'ឈ្មោះអ្នកប្រើប្រាស់ ឬពាក្យសម្ងាត់មិនត្រឹមត្រូវទេ។',
        );
      }
      if (body is Map && body['message'] is Map) body = body['message'];
      if (body is! Map) throw const FormatException();
      return AuthSession.fromJson(
        Map<String, dynamic>.from(body),
        baseUri: baseUri,
      );
    } on FormatException {
      throw const AuthException(
        'មិនអាចអានព័ត៌មានអ្នកប្រើប្រាស់ពីម៉ាស៊ីនមេបានទេ។',
      );
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

String _text(dynamic value) => value == null ? '' : value.toString().trim();

bool _flag(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value == 1;
  return value?.toString().trim() == '1';
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}
