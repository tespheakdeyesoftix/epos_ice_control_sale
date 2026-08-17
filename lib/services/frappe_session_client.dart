import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'frappe_response_handler.dart';

/// Keeps the Frappe `sid` cookie so calls after login share one session.
class FrappeSessionClient extends http.BaseClient {
  FrappeSessionClient({
    http.Client? inner,
    void Function(FrappeServerMessage message)? onServerMessage,
  }) : _inner = inner ?? http.Client(),
       _onServerMessage = onServerMessage ?? FrappeResponseHandler.show;

  final http.Client _inner;
  final void Function(FrappeServerMessage message) _onServerMessage;
  String? _sessionCookie;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final cookie = _sessionCookie;
    if (cookie != null) request.headers['Cookie'] = cookie;

    final response = await _inner.send(request);
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null) {
      final sid = RegExp(r'(?:^|[,;]\s*)sid=([^;,\s]+)').firstMatch(setCookie);
      if (sid != null) _sessionCookie = 'sid=${sid.group(1)}';
    }
    final bytes = await response.stream.toBytes();
    final responseBody = utf8.decode(bytes, allowMalformed: true);
    final serverMessages = FrappeResponseHandler.parse(responseBody);
    for (final message in serverMessages) {
      _onServerMessage(message);
    }
    final hasServerFailure =
        response.statusCode < 200 ||
        response.statusCode >= 300 ||
        serverMessages.any((message) => message.raiseException);
    if (serverMessages.isNotEmpty && hasServerFailure) {
      throw FrappeServerMessageException(serverMessages);
    }

    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      response.statusCode,
      contentLength: bytes.length,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  void clearSession() => _sessionCookie = null;

  @override
  void close() => _inner.close();
}
