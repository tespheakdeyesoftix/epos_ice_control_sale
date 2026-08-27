import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/features/booking/booking.dart';
import 'package:ice_control_sale/services/booking_service.dart';

void main() {
  test('loads Booking list through the Frappe resource endpoint', () async {
    late Uri requestedUri;
    final service = BookingService(
      Uri.parse('https://ice.test/'),
      client: MockClient((request) async {
        requestedUri = request.url;
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'data': [
                {
                  'name': 'BK2026-0001',
                  'delivery_date': '2026-08-25',
                  'customer_name': 'Dara',
                  'booking_products_description': 'Ice - (50 Bag)',
                  'total_amount': 75000,
                },
              ],
            }),
          ),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final bookings = await service.getBookings(search: 'Dara');

    expect(requestedUri.path, '/api/resource/Booking');
    expect(
      jsonDecode(requestedUri.queryParameters['fields']!),
      contains('delivery_date'),
    );
    expect(
      jsonDecode(requestedUri.queryParameters['fields']!),
      contains('booking_products_description'),
    );
    expect(
      requestedUri.queryParameters['order_by'],
      'delivery_date asc, creation desc',
    );
    expect(jsonDecode(requestedUri.queryParameters['or_filters']!), [
      ['name', 'like', '%Dara%'],
      ['phone_number', 'like', '%Dara%'],
      ['customer_name', 'like', '%Dara%'],
    ]);
    expect(bookings.single.name, 'BK2026-0001');
    expect(bookings.single.productsDescription, 'Ice - (50 Bag)');
    expect(bookings.single.totalAmount, 75000);
  });

  test('loads a complete Booking resource with booking products', () async {
    late Uri requestedUri;
    final service = BookingService(
      Uri.parse('https://ice.test/'),
      client: MockClient((request) async {
        requestedUri = request.url;
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'data': {
                'name': 'BK2026/0001',
                'delivery_date': '2026-08-25',
                'total_amount': 75000,
                'booking_products': [
                  {
                    'product_code': '01',
                    'product_name': 'ទឹកកកដើមធំ',
                    'unit': 'ដើម',
                    'quantity': 50,
                    'price': 1500,
                    'total_amount': 75000,
                  },
                ],
              },
            }),
          ),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final booking = await service.getBooking('BK2026/0001');

    expect(requestedUri.path, '/api/resource/Booking/BK2026%2F0001');
    expect(booking.products.single.productCode, '01');
    expect(booking.totalQuantity, 50);
  });

  test('counts today delivery bookings through reportViewCount', () async {
    late Uri requestedUri;
    final service = BookingService(
      Uri.parse('https://ice.test/'),
      client: MockClient((request) async {
        requestedUri = request.url;
        return http.Response(jsonEncode({'message': 7}), 200);
      }),
    );

    final count = await service.getTodayDeliveryCount();

    expect(requestedUri.path, '/api/method/frappe.desk.reportview.get_count');
    expect(requestedUri.queryParameters['doctype'], 'Booking');
    expect(jsonDecode(requestedUri.queryParameters['filters']!), [
      ['Booking', 'delivery_date', 'Timespan', 'today'],
    ]);
    expect(requestedUri.queryParameters['fields'], '[]');
    expect(requestedUri.queryParameters['distinct'], 'false');
    expect(count, 7);
  });

  test('creates a Booking through the Frappe resource endpoint', () async {
    late http.Request sentRequest;
    final service = BookingService(
      Uri.parse('https://ice.test/'),
      client: MockClient((request) async {
        sentRequest = request;
        return http.Response(
          jsonEncode({
            'data': {
              'name': 'BK2026-0002',
              'customer_name': 'Dara',
              'phone_number': '012345678',
            },
          }),
          201,
        );
      }),
    );

    final saved = await service.createBooking({
      'delivery_date': '2026-08-30',
      'booking_event': 'Wedding',
      'customer_name': 'Dara',
      'phone_number': '012345678',
      'booking_products': [
        {'product_code': '01', 'quantity': 2, 'price': 1500},
      ],
    });

    expect(sentRequest.method, 'POST');
    expect(sentRequest.url.path, '/api/resource/Booking');
    expect(sentRequest.headers['content-type'], 'application/json');
    final body = jsonDecode(sentRequest.body) as Map<String, dynamic>;
    expect(body['booking_event'], 'Wedding');
    expect(body['booking_products'], hasLength(1));
    expect(saved.name, 'BK2026-0002');
  });

  test('updates an encoded Booking resource with PUT', () async {
    late http.Request sentRequest;
    final service = BookingService(
      Uri.parse('https://ice.test/'),
      client: MockClient((request) async {
        sentRequest = request;
        return http.Response(
          jsonEncode({
            'data': {
              'name': 'BK2026/0002',
              'booking_event': 'Wedding',
              'phone_number': '012345678',
            },
          }),
          200,
        );
      }),
    );

    final saved = await service.updateBooking('BK2026/0002', {
      'booking_event': 'Wedding',
      'phone_number': '012345678',
    });

    expect(sentRequest.method, 'PUT');
    expect(sentRequest.url.path, '/api/resource/Booking/BK2026%2F0002');
    expect(jsonDecode(sentRequest.body)['booking_event'], 'Wedding');
    expect(saved.name, 'BK2026/0002');
  });

  test('deletes an encoded Booking resource with DELETE', () async {
    late http.Request sentRequest;
    final service = BookingService(
      Uri.parse('https://ice.test/'),
      client: MockClient((request) async {
        sentRequest = request;
        return http.Response('{}', 202);
      }),
    );

    await service.deleteBooking('BK2026/0002');

    expect(sentRequest.method, 'DELETE');
    expect(sentRequest.url.path, '/api/resource/Booking/BK2026%2F0002');
  });

  test('recognizes delivery dates using calendar date only', () {
    final booking = Booking.fromJson({
      'name': 'BK2026-0001',
      'delivery_date': '2026-08-25',
    });

    expect(booking.isDeliveredOn(DateTime(2026, 8, 25, 23, 59)), isTrue);
    expect(booking.isDeliveredOn(DateTime(2026, 8, 26)), isFalse);
  });
}
