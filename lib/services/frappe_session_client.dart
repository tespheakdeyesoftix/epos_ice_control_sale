import 'package:http/http.dart' as http;

/// Keeps the Frappe `sid` cookie so calls after login share one session.
class FrappeSessionClient extends http.BaseClient {
  FrappeSessionClient({http.Client? inner}) : _inner = inner ?? http.Client();

  final http.Client _inner;
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
    return response;
  }

  void clearSession() => _sessionCookie = null;

  @override
  void close() => _inner.close();
}
