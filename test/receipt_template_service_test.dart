import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/services/receipt_template_service.dart';
import 'package:ice_control_sale/shared/receipts/receipt_template.dart';

void main() {
  test('lists enabled POS Print Template documents', () async {
    late http.Request sentRequest;
    final service = ReceiptTemplateService(
      Uri.parse('https://example.test/'),
      client: MockClient((request) async {
        sentRequest = request;
        return http.Response(
          jsonEncode({
            'data': [
              {
                'name': 'Compact A5',
                'template_name': 'Compact A5',
                'paper_size': 'A5',
                'orientation': 'Portrait',
                'enabled': 1,
                'schema_version': 1,
                'layout_json': {
                  'version': 1,
                  'blocks': [
                    {'id': 'title', 'type': 'text', 'text': 'INVOICE'},
                  ],
                },
              },
            ],
          }),
          200,
        );
      }),
    );

    final templates = await service.listTemplates();

    expect(sentRequest.method, 'GET');
    expect(sentRequest.url.path, '/api/resource/POS%20Print%20Template');
    expect(sentRequest.url.queryParameters['filters'], contains('enabled'));
    expect(templates.first, ReceiptTemplate.standardA6);
    expect(templates.last.templateName, 'Compact A5');
  });

  test(
    'updates an existing template through the Frappe resource endpoint',
    () async {
      late http.Request sentRequest;
      final service = ReceiptTemplateService(
        Uri.parse('https://example.test/'),
        client: MockClient((request) async {
          sentRequest = request;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'data': {'name': body['template_name'], ...body},
            }),
            200,
          );
        }),
      );

      final saved = await service.saveTemplate(
        ReceiptTemplate.standardA6.copyWith(
          name: 'New A6',
          templateName: 'New A6',
          isBuiltIn: false,
        ),
      );

      expect(sentRequest.method, 'PUT');
      expect(
        sentRequest.url.path,
        '/api/resource/POS%20Print%20Template/New%20A6',
      );
      expect(saved.name, 'New A6');
      expect(saved.templateName, 'New A6');
    },
  );
}
