import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app/api_endpoint.dart';
import '../features/booking/booking.dart';
import 'doctype_data_source.dart';

class BookingService implements DoctypeDataSource {
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
    'booking_products_description',
    'total_amount',
    'created_by',
    'owner',
    'creation',
  ];

  @override
  final Uri baseUri;
  final http.Client _client;

  @override
  Future<Map<String, dynamic>> getDoctypeMeta(String doctype) async {
    final response = await _client
        .get(
          baseUri
              .resolve(ApiEndpoint.doctypeMeta)
              .replace(queryParameters: {'doctype': doctype.trim()}),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BookingServiceException(response.statusCode);
    }

    dynamic payload = jsonDecode(response.body);
    if (payload is Map && payload.containsKey('message')) {
      payload = payload['message'];
    }
    if (payload is String) payload = jsonDecode(payload);
    if (payload is Map && payload['data'] is Map) payload = payload['data'];
    if (payload is! Map) throw const BookingServiceException(200);
    return Map<String, dynamic>.from(payload);
  }

  @override
  Future<List<Map<String, dynamic>>> getDoctypeRows({
    required String doctype,
    required List<String> fields,
    List<List<dynamic>> filters = const [],
    List<List<dynamic>> orFilters = const [],
    String orderBy = 'name asc',
    int offset = 0,
    int limit = 20,
  }) async {
    final query = <String, String>{
      'fields': jsonEncode(fields),
      'filters': jsonEncode(filters),
      'order_by': orderBy,
      'limit_start': '$offset',
      'limit_page_length': '$limit',
    };
    if (orFilters.isNotEmpty) query['or_filters'] = jsonEncode(orFilters);
    final response = await _client
        .get(
          baseUri
              .resolve(ApiEndpoint.resource(doctype))
              .replace(queryParameters: query),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BookingServiceException(response.statusCode);
    }
    final payload = jsonDecode(response.body);
    final rows = payload is Map && payload['data'] is List
        ? payload['data'] as List
        : const [];
    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

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

  Future<Booking> createBooking(Map<String, dynamic> booking) async {
    final response = await _client
        .post(
          baseUri.resolve(ApiEndpoint.bookings),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(booking),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BookingServiceException(response.statusCode);
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map || payload['data'] is! Map) {
      throw const BookingServiceException(200);
    }
    final saved = Booking.fromJson(
      Map<String, dynamic>.from(payload['data'] as Map),
    );
    if (saved.name.isEmpty) throw const BookingServiceException(200);
    return saved;
  }

  Future<Booking> updateBooking(
    String name,
    Map<String, dynamic> booking,
  ) async {
    final response = await _client
        .put(
          baseUri.resolve(ApiEndpoint.booking(name)),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(booking),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BookingServiceException(response.statusCode);
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map || payload['data'] is! Map) {
      throw const BookingServiceException(200);
    }
    final saved = Booking.fromJson(
      Map<String, dynamic>.from(payload['data'] as Map),
    );
    if (saved.name.isEmpty) throw const BookingServiceException(200);
    return saved;
  }
}

class BookingServiceException implements Exception {
  const BookingServiceException(this.statusCode);

  final int statusCode;
}
