import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app/api_endpoint.dart';
import '../features/notes/note_record.dart';

class NoteService {
  NoteService(this.baseUri, {required http.Client client}) : _client = client;

  static const fields = [
    'name',
    'title',
    'content',
    'custom_color',
    'custom_outlet',
    'custom_is_pin',
    'custom_notify_on',
    'owner',
    'creation',
    'modified',
    '_user_tags',
  ];
  static const regularPageSize = 20;
  static const maximumPinnedNotes = 5;

  final Uri baseUri;
  final http.Client _client;

  Future<List<NoteRecord>> listRegularForOutlet(
    String outlet, {
    int offset = 0,
    int limit = regularPageSize,
  }) => _list(
    filters: [
      ['custom_outlet', '=', outlet.trim()],
      ['custom_is_pin', '=', 0],
    ],
    orderBy: 'modified desc',
    offset: offset,
    limit: limit,
  );

  Future<List<NoteRecord>> listPinnedForOutlet(String outlet) => _list(
    filters: [
      ['custom_outlet', '=', outlet.trim()],
      ['custom_is_pin', '=', 1],
    ],
    orderBy: 'modified desc',
    offset: 0,
    limit: maximumPinnedNotes,
  );

  Future<List<NoteRecord>> dueToday({
    required String outlet,
    required DateTime today,
  }) => _list(
    filters: [
      ['custom_outlet', '=', outlet.trim()],
      ['custom_notify_on', '=', noteDateValue(today)],
    ],
    orderBy: 'custom_is_pin desc, modified desc',
    offset: 0,
    limit: 500,
  );

  Future<int> dueTodayCount({
    required String outlet,
    required DateTime today,
  }) async {
    final response = await _client.get(
      baseUri
          .resolve(ApiEndpoint.reportViewCount)
          .replace(
            queryParameters: {
              'doctype': 'Note',
              'filters': jsonEncode([
                ['Note', 'custom_outlet', '=', outlet.trim()],
                ['Note', 'custom_notify_on', '=', noteDateValue(today)],
              ]),
              'fields': '[]',
              'distinct': 'false',
            },
          ),
      headers: const {'Accept': 'application/json'},
    );
    _ensureSuccess(response);
    dynamic payload = _decode(response.body);
    if (payload is Map && payload.containsKey('message')) {
      payload = payload['message'];
    }
    if (payload is Map && payload.containsKey('count')) {
      payload = payload['count'];
    }
    return payload is num
        ? payload.toInt()
        : int.tryParse(payload?.toString() ?? '') ?? 0;
  }

  Future<List<NoteRecord>> _list({
    required List<List<dynamic>> filters,
    required String orderBy,
    required int offset,
    required int limit,
  }) async {
    final uri = baseUri
        .resolve(ApiEndpoint.notes)
        .replace(
          queryParameters: {
            'fields': jsonEncode(fields),
            'filters': jsonEncode(filters),
            'order_by': orderBy,
            'limit_start': '$offset',
            'limit_page_length': '$limit',
          },
        );
    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );
    _ensureSuccess(response);
    final data = _decode(response.body);
    final rows = data is Map && data['data'] is List
        ? data['data'] as List
        : const [];
    return List.unmodifiable(
      rows.whereType<Map>().map(
        (row) => NoteRecord.fromJson(Map<String, dynamic>.from(row)),
      ),
    );
  }

  Future<NoteRecord> create({
    required String outlet,
    required String title,
    required String content,
    required String color,
    required bool isPinned,
    List<String> tags = const [],
    DateTime? notifyOn,
  }) async {
    final saved = await _save(
      method: 'POST',
      uri: baseUri.resolve(ApiEndpoint.notes),
      values: {
        'title': title.trim(),
        'content': content,
        'custom_color': color,
        'custom_outlet': outlet.trim(),
        'custom_is_pin': isPinned ? 1 : 0,
        'custom_notify_on': notifyOn == null ? null : noteDateValue(notifyOn),
      },
    );
    final normalizedTags = parseNoteTags(tags);
    await _syncTags(saved.name, const [], normalizedTags);
    return saved.copyWithTags(normalizedTags);
  }

  Future<NoteRecord> update({
    required String name,
    required String title,
    required String content,
    required String color,
    required bool isPinned,
    List<String> existingTags = const [],
    List<String> tags = const [],
    DateTime? notifyOn,
  }) async {
    final saved = await _save(
      method: 'PUT',
      uri: baseUri.resolve(ApiEndpoint.note(name)),
      values: {
        'title': title.trim(),
        'content': content,
        'custom_color': color,
        'custom_is_pin': isPinned ? 1 : 0,
        'custom_notify_on': notifyOn == null ? null : noteDateValue(notifyOn),
      },
    );
    final normalizedTags = parseNoteTags(tags);
    await _syncTags(name, parseNoteTags(existingTags), normalizedTags);
    return saved.copyWithTags(normalizedTags);
  }

  Future<NoteRecord> setPinned(NoteRecord note, bool isPinned) => update(
    name: note.name,
    title: note.title,
    content: note.content,
    color: note.color,
    isPinned: isPinned,
    existingTags: note.tags,
    tags: note.tags,
    notifyOn: note.notifyOn,
  );

  Future<void> _syncTags(
    String name,
    List<String> existingTags,
    List<String> desiredTags,
  ) async {
    final existingByKey = {
      for (final tag in existingTags) tag.toLowerCase(): tag,
    };
    final desiredByKey = {
      for (final tag in desiredTags) tag.toLowerCase(): tag,
    };
    for (final entry in existingByKey.entries) {
      if (!desiredByKey.containsKey(entry.key)) {
        await _changeTag(ApiEndpoint.removeTag, name, entry.value);
      }
    }
    for (final entry in desiredByKey.entries) {
      if (!existingByKey.containsKey(entry.key)) {
        await _changeTag(ApiEndpoint.addTag, name, entry.value);
      }
    }
  }

  Future<void> _changeTag(String endpoint, String name, String tag) async {
    final response = await _client.post(
      baseUri.resolve(endpoint),
      headers: const {'Accept': 'application/json'},
      body: {'tag': tag, 'dt': 'Note', 'dn': name},
    );
    _ensureSuccess(response);
  }

  Future<NoteRecord> _save({
    required String method,
    required Uri uri,
    required Map<String, dynamic> values,
  }) async {
    final headers = const {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode(values);
    final response = method == 'POST'
        ? await _client.post(uri, headers: headers, body: body)
        : await _client.put(uri, headers: headers, body: body);
    _ensureSuccess(response);
    final payload = _decode(response.body);
    final data = payload is Map ? payload['data'] : null;
    if (data is! Map) throw const NoteServiceException(200);
    return NoteRecord.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> delete(String name) async {
    final response = await _client.delete(
      baseUri.resolve(ApiEndpoint.note(name)),
      headers: const {'Accept': 'application/json'},
    );
    _ensureSuccess(response);
  }

  dynamic _decode(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      throw const NoteServiceException(200);
    }
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NoteServiceException(response.statusCode);
    }
  }
}

class NoteServiceException implements Exception {
  const NoteServiceException(this.statusCode);

  final int statusCode;
}
