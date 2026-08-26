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
      requestedUri.queryParameters['order_by'],
      'delivery_date asc, creation desc',
    );
    expect(jsonDecode(requestedUri.queryParameters['or_filters']!), [
      ['name', 'like', '%Dara%'],
      ['phone_number', 'like', '%Dara%'],
      ['customer_name', 'like', '%Dara%'],
    ]);
    expect(bookings.single.name, 'BK2026-0001');
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

  test('recognizes delivery dates using calendar date only', () {
    final booking = Booking.fromJson({
      'name': 'BK2026-0001',
      'delivery_date': '2026-08-25',
    });

    expect(booking.isDeliveredOn(DateTime(2026, 8, 25, 23, 59)), isTrue);
    expect(booking.isDeliveredOn(DateTime(2026, 8, 26)), isFalse);
  });
}
