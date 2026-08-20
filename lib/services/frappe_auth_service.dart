import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app/api_endpoint.dart';
import '../utils/helpers.dart';
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
    this.outlets = const [],
  });

  factory AuthSession.fromJson(
    Map<String, dynamic> json, {
    required Uri baseUri,
  }) {
    final rawImage = textValue(json['user_image']);
    final roles = json['roles'];
    final employee = json['employee'];
    final employeeMap = employee is Map
        ? Map<String, dynamic>.from(employee)
        : <String, dynamic>{};
    return AuthSession(
      raw: Map<String, dynamic>.unmodifiable(json),
      fullName: textValue(json['full_name']),
      user: textValue(json['user']),
      email: textValue(json['email']),
      username: textValue(json['username']),
      userType: textValue(json['user_type']),
      userImage: rawImage,
      userImageUrl: rawImage.isEmpty
          ? ''
          : baseUri.resolve(rawImage).toString(),
      roles: roles is List
          ? roles.map((role) => role.toString()).toList(growable: false)
          : const [],
      employee: Map<String, dynamic>.unmodifiable(employeeMap),
      outlets: _parseOutlets(employeeMap['outlets'] ?? json['outlets']),
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
  final List<String> outlets;

  bool get canChangeCustomer => _flag(employee['change_customer']);
  bool get canChangeSaleDate => _flag(employee['change_sale_date']);
  bool get canRemoveSaleProduct => _flag(employee['remove_sale_product']);
  bool get canChangeProductPrice => _flag(employee['change_product_price']);
  bool get canUsePosPayment => _flag(employee['pos_payment']);
  bool get canEditBill => _flag(employee['edit_bill']);
  bool get canDeleteBill => _flag(employee['delete_bill']);
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

bool _flag(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value == 1;
  return value?.toString().trim() == '1';
}

List<String> _parseOutlets(dynamic value) {
  if (value is! List) return const [];
  final outlets = <String>{};
  for (final item in value) {
    final outlet = item is Map ? textValue(item['outlet']) : textValue(item);
    if (outlet.isNotEmpty) outlets.add(outlet);
  }
  return List<String>.unmodifiable(outlets);
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}
