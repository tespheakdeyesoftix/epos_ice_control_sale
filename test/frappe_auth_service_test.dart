import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/services/frappe_auth_service.dart';

void main() {
  test('custom login sends outlet and reads the user session', () async {
    late http.Request sentRequest;
    final client = MockClient((request) async {
      sentRequest = request;
      return http.Response(
        jsonEncode({
          'message': 'Logged In',
          'full_name': 'Administrator',
          'user': 'Administrator',
          'email': 'admin@example.com',
          'username': 'administrator',
          'user_type': 'System User',
          'user_image': '/files/administrator.jpg',
          'roles': ['Sales User', 'System Manager'],
          'employee': {
            'name': 'EMP0002',
            'employee_name': 'Administrator',
            'change_customer': 1,
            'change_sale_date': 1,
            'remove_sale_product': 1,
            'change_product_price': 1,
            'pos_payment': 1,
            'edit_bill': 1,
            'delete_bill': 1,
            'outlets': [
              {'outlet': 'កន្លែងលក់ទី១'},
              {'outlet': 'កន្លែងលក់ទី២'},
              {'outlet': 'កន្លែងលក់ទី១'},
            ],
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = FrappeAuthService(
      Uri.parse('http://127.0.0.1:8888/'),
      client: client,
    );

    final session = await service.login(
      username: 'Administrator',
      password: '123456',
      outlet: 'ទឹកកកដើម',
    );

    expect(sentRequest.url.path, '/api/method/ice_control.api.v1.auth.login');
    expect(sentRequest.method, 'POST');
    expect(sentRequest.bodyFields, {
      'usr': 'Administrator',
      'pwd': '123456',
      'outlet': 'ទឹកកកដើម',
    });
    expect(session.fullName, 'Administrator');
    expect(
      session.userImageUrl,
      'http://127.0.0.1:8888/files/administrator.jpg',
    );
    expect(session.roles, ['Sales User', 'System Manager']);
    expect(session.employee['name'], 'EMP0002');
    expect(session.canChangeCustomer, isTrue);
    expect(session.canChangeSaleDate, isTrue);
    expect(session.canRemoveSaleProduct, isTrue);
    expect(session.canChangeProductPrice, isTrue);
    expect(session.canUsePosPayment, isTrue);
    expect(session.canEditBill, isTrue);
    expect(session.canDeleteBill, isTrue);
    expect(session.outlets, ['កន្លែងលក់ទី១', 'កន្លែងលក់ទី២']);
  });

  test('custom login supports null user image', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'full_name': 'Administrator',
          'user': 'Administrator',
          'user_image': null,
        }),
        200,
      ),
    );
    final service = FrappeAuthService(
      Uri.parse('http://127.0.0.1:8888/'),
      client: client,
    );

    final session = await service.login(
      username: 'Administrator',
      password: '123456',
      outlet: 'ទឹកកកដើម',
    );

    expect(session.userImageUrl, isEmpty);
    expect(session.canChangeCustomer, isFalse);
    expect(session.canChangeSaleDate, isFalse);
    expect(session.canRemoveSaleProduct, isFalse);
    expect(session.canChangeProductPrice, isFalse);
    expect(session.canUsePosPayment, isFalse);
    expect(session.canEditBill, isFalse);
    expect(session.canDeleteBill, isFalse);
    expect(session.outlets, isEmpty);
  });
}
