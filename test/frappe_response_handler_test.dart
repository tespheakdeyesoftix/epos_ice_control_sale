import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/services/frappe_response_handler.dart';
import 'package:ice_control_sale/services/frappe_session_client.dart';

void main() {
  test('extracts Frappe server message and indicator', () {
    final responseBody = jsonEncode({
      'session_expired': 1,
      'exc_type': 'AuthenticationError',
      '_server_messages': jsonEncode([
        jsonEncode({
          'message': 'ឈ្មោះអ្នកប្រើប្រាស់ ឬលេខសម្ងាត់មិនត្រឹមត្រូវ',
          'title': 'Message',
          'indicator': 'red',
          'raise_exception': 1,
        }),
      ]),
    });

    final messages = FrappeResponseHandler.parse(responseBody);

    expect(messages, hasLength(1));
    expect(
      messages.single.message,
      'ឈ្មោះអ្នកប្រើប្រាស់ ឬលេខសម្ងាត់មិនត្រឹមត្រូវ',
    );
    expect(messages.single.indicator, 'red');
    expect(messages.single.raiseException, isTrue);
  });

  test('uses a normal message when indicator is missing', () {
    final responseBody = jsonEncode({
      '_server_messages': jsonEncode([
        jsonEncode({'message': 'សារធម្មតា'}),
      ]),
    });

    final messages = FrappeResponseHandler.parse(responseBody);

    expect(messages.single.message, 'សារធម្មតា');
    expect(messages.single.indicator, isEmpty);
  });

  test('converts linked Frappe errors to readable plain text', () {
    final responseBody = jsonEncode({
      '_server_messages': jsonEncode([
        jsonEncode({
          'message':
              'Cannot delete or cancel because Booking '
              '<a href="https://example.test/booking/BK2026-0002" '
              'rel="noopener noreferrer">BK2026-0002</a> is linked with '
              'Sale <a href="https://example.test/sale/SO2026-0249" '
              'rel="noopener noreferrer">SO2026-0249</a> &amp; cannot be removed.',
          'indicator': 'red',
          'raise_exception': 1,
        }),
      ]),
    });

    final messages = FrappeResponseHandler.parse(responseBody);

    expect(
      messages.single.message,
      'Cannot delete or cancel because Booking BK2026-0002 is linked with '
      'Sale SO2026-0249 & cannot be removed.',
    );
    expect(messages.single.message, isNot(contains('<a')));
    expect(messages.single.message, isNot(contains('href=')));
  });

  test(
    'session client handles messages globally and preserves response',
    () async {
      final responseBody = jsonEncode({
        '_server_messages': jsonEncode([
          jsonEncode({'message': 'រក្សាទុកបានជោគជ័យ', 'indicator': 'green'}),
        ]),
        'message': {'name': 'SO-0001'},
      });
      final handledMessages = <FrappeServerMessage>[];
      final client = FrappeSessionClient(
        inner: MockClient(
          (_) async => http.Response(
            responseBody,
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
        onServerMessage: handledMessages.add,
      );

      final response = await client.get(Uri.parse('http://127.0.0.1/api/test'));

      expect(response.body, responseBody);
      expect(handledMessages, hasLength(1));
      expect(handledMessages.single.message, 'រក្សាទុកបានជោគជ័យ');
      expect(handledMessages.single.indicator, 'green');
    },
  );

  test(
    'session client marks server-message failures for UI suppression',
    () async {
      final responseBody = jsonEncode({
        'exc_type': 'ValidationError',
        '_server_messages': jsonEncode([
          jsonEncode({
            'message': 'Invalid outlet name',
            'indicator': 'red',
            'raise_exception': 1,
          }),
        ]),
      });
      final handledMessages = <FrappeServerMessage>[];
      final client = FrappeSessionClient(
        inner: MockClient(
          (_) async => http.Response(
            responseBody,
            417,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
        onServerMessage: handledMessages.add,
      );

      await expectLater(
        client.get(Uri.parse('http://127.0.0.1/api/save')),
        throwsA(isA<FrappeServerMessageException>()),
      );
      expect(handledMessages.single.message, 'Invalid outlet name');
      expect(handledMessages.single.raiseException, isTrue);
    },
  );
}
