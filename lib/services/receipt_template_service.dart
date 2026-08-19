import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../app/api_endpoint.dart';
import '../shared/receipts/receipt_template.dart';

class ReceiptTemplateService {
  ReceiptTemplateService(
    this.baseUri, {
    required http.Client client,
    SharedPreferences? preferences,
  }) : _client = client,
       _preferences = preferences;

  final Uri baseUri;
  final http.Client _client;
  final SharedPreferences? _preferences;
  final Map<String, Uint8List> _logoCache = {};

  String get _cacheKey =>
      'receipt_templates::${Uri.encodeComponent(baseUri.toString())}';

  Future<List<ReceiptTemplate>> listTemplates() async {
    try {
      final endpoint = baseUri
          .resolve(ApiEndpoint.printTemplates)
          .replace(
            queryParameters: {
              'fields': jsonEncode(['*']),
              'filters': jsonEncode([
                ['enabled', '=', 1],
              ]),
              'order_by': 'template_name asc',
              'limit_page_length': '100',
            },
          );
      final response = await _client.get(
        endpoint,
        headers: const {'Accept': 'application/json'},
      );
      _ensureSuccess(response);
      final body = jsonDecode(response.body);
      final rows = body is Map ? body['data'] : null;
      if (rows is! List) return const [ReceiptTemplate.standardA6];
      final templates = rows
          .whereType<Map>()
          .map(
            (row) => ReceiptTemplate.fromJson(Map<String, dynamic>.from(row)),
          )
          .where((template) => template.enabled)
          .toList(growable: true);
      if (!templates.any(
        (item) => item.name == ReceiptTemplate.standardA6.name,
      )) {
        templates.insert(0, ReceiptTemplate.standardA6);
      }
      await _preferences?.setString(
        _cacheKey,
        jsonEncode([
          for (final template in templates)
            {
              ...template.raw,
              'name': template.name,
              ...template.toFrappeJson(),
            },
        ]),
      );
      return List.unmodifiable(templates);
    } on Exception {
      final cached = _preferences?.getString(_cacheKey);
      if (cached == null || cached.isEmpty) rethrow;
      final rows = jsonDecode(cached);
      if (rows is! List) rethrow;
      return List.unmodifiable(
        rows
            .whereType<Map>()
            .map(
              (row) => ReceiptTemplate.fromJson(Map<String, dynamic>.from(row)),
            )
            .toList(growable: false),
      );
    }
  }

  Future<ReceiptTemplate> saveTemplate(ReceiptTemplate template) async {
    if (template.name.trim().isEmpty || template.isBuiltIn) {
      throw const ReceiptTemplateServiceException(400);
    }
    final payload = jsonEncode(template.toFrappeJson());
    final headers = const {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final response = await _client.put(
      baseUri.resolve(ApiEndpoint.printTemplate(template.name)),
      headers: headers,
      body: payload,
    );
    _ensureSuccess(response);
    final body = jsonDecode(response.body);
    final data = body is Map ? body['data'] : null;
    if (data is! Map) throw const ReceiptTemplateServiceException(200);
    return ReceiptTemplate.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Uint8List?> loadLogo(String path) async {
    if (path.trim().isEmpty) return null;
    final cached = _logoCache[path.trim()];
    if (cached != null) return cached;
    final response = await _client.get(baseUri.resolve(path.trim()));
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    final bytes = response.bodyBytes;
    _logoCache[path.trim()] = bytes;
    return bytes;
  }

  Future<Map<String, Uint8List>> loadImages(Map<String, String> sources) async {
    final result = <String, Uint8List>{};
    for (final entry in sources.entries) {
      final bytes = await loadLogo(entry.value);
      if (bytes != null && bytes.isNotEmpty) result[entry.key] = bytes;
    }
    return result;
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ReceiptTemplateServiceException(response.statusCode);
    }
  }
}

class ReceiptTemplateServiceException implements Exception {
  const ReceiptTemplateServiceException(this.statusCode);

  final int statusCode;
}
