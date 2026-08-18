import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/services/setting_service.dart';

void main() {
  test('ទាញការកំណត់សកលតាមឈ្មោះស្ថានីយ', () async {
    late http.Request sentRequest;
    final client = MockClient((request) async {
      sentRequest = request;
      return http.Response(
        jsonEncode({
          'message': {
            'business_name_en': 'Heang Hok Kheang I',
            'business_name_kh': 'រោងចក្រទឹកកក ហ៊ាងហុកឃាង',
            'address': 'ខេត្តសៀមរាប',
            'phone_number_1': '0125457774',
            'photo': '/files/hhklogo.jpg',
            'outlet': 'ទឹកកកដើម',
            'default_unit': 'ដើម',
            'default_stock_location': 'ឃ្លាំងទឹកកកដើម',
            'default_currency': 'KHR',
            'currency_symbol': '៛',
            'exchange_rate': 1,
            'payment_types': [
              {'name': 'Riel', 'currency': 'KHR', 'exchange_rate': 1},
            ],
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = SettingService(
      Uri.parse('http://127.0.0.1:8888/'),
      client: client,
    );

    final setting = await service.getSetting(
      'Cashier 01',
      outlet: 'កន្លែងលក់ទី១',
    );

    expect(sentRequest.method, 'GET');
    expect(
      sentRequest.url.path,
      '/api/method/ice_control.api.v1.utils.get_setting',
    );
    expect(sentRequest.url.queryParameters['station_name'], 'Cashier 01');
    expect(sentRequest.url.queryParameters['outlet'], 'កន្លែងលក់ទី១');
    expect(setting.businessNameEn, 'Heang Hok Kheang I');
    expect(setting.businessNameKh, 'រោងចក្រទឹកកក ហ៊ាងហុកឃាង');
    expect(setting.address, 'ខេត្តសៀមរាប');
    expect(setting.phoneNumber1, '0125457774');
    expect(setting.outlet, 'ទឹកកកដើម');
    expect(setting.defaultStockLocation, 'ឃ្លាំងទឹកកកដើម');
    expect(setting.paymentTypes, hasLength(1));
    expect(setting.raw['default_unit'], 'ដើម');
    expect(
      service.resolveImage(setting.photo).toString(),
      'http://127.0.0.1:8888/files/hhklogo.jpg',
    );
  });
}
