import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app/api_endpoint.dart';
import '../app/app_setting.dart';

class SettingService {
  SettingService(this.baseUri, {required http.Client client})
    : _client = client;

  final Uri baseUri;
  final http.Client _client;

  Future<AppSetting> getSetting(String stationName) async {
    final endpoint = baseUri
        .resolve(ApiEndpoint.setting)
        .replace(queryParameters: {'station_name': stationName});
    final response = await _client
        .get(endpoint, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SettingServiceException(response.statusCode);
    }

    dynamic payload = jsonDecode(response.body);
    if (payload is Map<String, dynamic> && payload.containsKey('message')) {
      payload = payload['message'];
    }
    if (payload is String) payload = jsonDecode(payload);
    if (payload is! Map) throw const SettingServiceException(200);
    return AppSetting.fromJson(Map<String, dynamic>.from(payload));
  }

  Uri? resolveImage(String path) {
    if (path.trim().isEmpty) return null;
    return baseUri.resolve(path.trim());
  }
}

class SettingServiceException implements Exception {
  const SettingServiceException(this.statusCode);

  final int statusCode;
}
