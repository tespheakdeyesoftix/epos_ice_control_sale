import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app/api_endpoint.dart';
import '../features/booking/booking.dart';

class BookingService {
  BookingService(this.baseUri, {required http.Client client})
    : _client = client;

  static const _pageSize = 100;
  static const _listFields = [
    'name',
    'posting_date',
    'delivery_date',
    'booking_event',
    'customer_name',
    'phone_number',
    'address',
    'total_amount',
    'created_by',
    'owner',
    'creation',
  ];

  final Uri baseUri;
  final http.Client _client;

  Future<List<Booking>> getBookings({String search = ''}) async {
    final bookings = <Booking>[];
    final trimmedSearch = search.trim();
    var offset = 0;
    while (true) {
      final queryParameters = <String, String>{
        'fields': jsonEncode(_listFields),
        'order_by': 'delivery_date asc, creation desc',
        'limit_start': '$offset',
        'limit_page_length': '$_pageSize',
      };
      if (trimmedSearch.isNotEmpty) {
        queryParameters['or_filters'] = jsonEncode([
          ['name', 'like', '%$trimmedSearch%'],
          ['phone_number', 'like', '%$trimmedSearch%'],
          ['customer_name', 'like', '%$trimmedSearch%'],
        ]);
      }
      final endpoint = baseUri
          .resolve(ApiEndpoint.bookings)
          .replace(queryParameters: queryParameters);
      final response = await _client
          .get(endpoint, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw BookingServiceException(response.statusCode);
      }

      final payload = jsonDecode(response.body);
      final rows = payload is Map && payload['data'] is List
          ? payload['data'] as List
          : const <dynamic>[];
      bookings.addAll(
        rows
            .whereType<Map>()
            .map((row) => Booking.fromJson(Map<String, dynamic>.from(row)))
            .where((booking) => booking.name.isNotEmpty),
      );
      if (rows.length < _pageSize) break;
      offset += _pageSize;
    }
    return bookings;
  }

  Future<Booking> getBooking(String name) async {
    final endpoint = baseUri.resolve(ApiEndpoint.booking(name));
    final response = await _client
        .get(endpoint, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BookingServiceException(response.statusCode);
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map || payload['data'] is! Map) {
      throw const BookingServiceException(200);
    }
    final booking = Booking.fromJson(
      Map<String, dynamic>.from(payload['data'] as Map),
    );
    if (booking.name.isEmpty) throw const BookingServiceException(200);
    return booking;
  }
}

class BookingServiceException implements Exception {
  const BookingServiceException(this.statusCode);

  final int statusCode;
}
