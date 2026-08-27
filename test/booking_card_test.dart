import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/features/booking/booking.dart';
import 'package:ice_control_sale/features/booking/booking_controller.dart';
import 'package:ice_control_sale/features/booking/booking_list.dart';
import 'package:ice_control_sale/features/booking/widgets/booking_card_widget.dart';
import 'package:ice_control_sale/services/booking_service.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('renders booking as a tappable card', (tester) async {
    var tapped = false;
    final booking = Booking.fromJson({
      'name': 'BK2026-0001',
      'delivery_date': '2026-08-25',
      'booking_event': 'កម្មវិធីការ',
      'customer_name': 'Dara',
      'phone_number': '012545976',
      'booking_products_description':
          'ទឹកកកដើមធំ - (50 ដើម)\nទឹកកកដើមតូច - (70 ដើម)',
      'total_amount': 75000,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 380,
            height: 270,
            child: BookingCardWidget(
              booking: booking,
              isToday: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('booking-card-BK2026-0001')),
      findsOneWidget,
    );
    expect(find.text('Dara'), findsOneWidget);
    expect(
      find.text('ទឹកកកដើមធំ - (50 ដើម)\nទឹកកកដើមតូច - (70 ដើម)'),
      findsOneWidget,
    );
    expect(find.text('75,000 រៀល'), findsOneWidget);
    expect(find.text('ថ្ងៃនេះ'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('booking-card-BK2026-0001')));
    expect(tapped, isTrue);
  });

  testWidgets('tapping a list card opens the booking detail dialog', (
    tester,
  ) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final deliveryDate =
        '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-'
        '${tomorrow.day.toString().padLeft(2, '0')}';
    final service = BookingService(
      Uri.parse('https://ice.test/'),
      client: MockClient((request) async {
        final isDetail = request.url.path.endsWith('/BK2026-0002');
        return http.Response(
          jsonEncode({
            'data': isDetail
                ? {
                    'name': 'BK2026-0002',
                    'delivery_date': deliveryDate,
                    'customer_name': 'Sokha',
                    'booking_products': const [],
                  }
                : [
                    {
                      'name': 'BK2026-0002',
                      'delivery_date': deliveryDate,
                      'customer_name': 'Sokha',
                    },
                  ],
          }),
          200,
        );
      }),
    );
    Get.put(BookingController(service: service));

    await tester.pumpWidget(const GetMaterialApp(home: BookingListScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('booking-card-BK2026-0002')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('booking-detail-dialog-BK2026-0002')),
      findsOneWidget,
    );
    expect(find.text('ព័ត៌មានលម្អិតការកក់'), findsOneWidget);
  });

  testWidgets('new booking FAB opens the customer details dialog', (
    tester,
  ) async {
    final service = BookingService(
      Uri.parse('https://ice.test/'),
      client: MockClient(
        (_) async => http.Response(jsonEncode({'data': const []}), 200),
      ),
    );
    Get.put(BookingController(service: service));

    await tester.pumpWidget(const GetMaterialApp(home: BookingListScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('new-booking-fab')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('new-booking-dialog')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('new-booking-customer-name')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('new-booking-phone-number')),
      findsOneWidget,
    );
  });

  testWidgets('searches bookings by number, phone, and customer', (
    tester,
  ) async {
    var listRequestCount = 0;
    final rows = [
      {
        'name': 'BK2026-0101',
        'delivery_date': '2030-01-01',
        'customer_name': 'Dara',
        'phone_number': '012111111',
      },
      {
        'name': 'BK2026-0102',
        'delivery_date': '2030-01-02',
        'customer_name': 'Sokha',
        'phone_number': '097222222',
      },
      {
        'name': 'BK2026-0103',
        'delivery_date': '2030-01-03',
        'customer_name': 'Chantha',
        'phone_number': '088333333',
      },
    ];
    final service = BookingService(
      Uri.parse('https://ice.test/'),
      client: MockClient((request) async {
        listRequestCount++;
        final encodedFilters = request.url.queryParameters['or_filters'];
        var result = rows;
        if (encodedFilters != null) {
          final filters = jsonDecode(encodedFilters) as List<dynamic>;
          final pattern = (filters.first as List<dynamic>)[2] as String;
          final query = pattern.replaceAll('%', '').toLowerCase();
          result = rows.where((row) {
            return row['name']!.toLowerCase().contains(query) ||
                row['phone_number']!.toLowerCase().contains(query) ||
                row['customer_name']!.toLowerCase().contains(query);
          }).toList();
        }
        return http.Response(jsonEncode({'data': result}), 200);
      }),
    );
    Get.put(BookingController(service: service));
    await tester.pumpWidget(const GetMaterialApp(home: BookingListScreen()));
    await tester.pumpAndSettle();

    final search = find.byKey(const ValueKey('booking-search-input'));
    expect(search, findsOneWidget);
    expect(listRequestCount, 1);

    await tester.enterText(search, '0102');
    await tester.pump(const Duration(milliseconds: 999));
    expect(listRequestCount, 1);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(listRequestCount, 2);
    expect(
      find.byKey(const ValueKey('booking-card-BK2026-0102')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('booking-card-BK2026-0101')),
      findsNothing,
    );

    await tester.enterText(search, '088333333');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('booking-card-BK2026-0103')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('booking-card-BK2026-0102')),
      findsNothing,
    );

    await tester.enterText(search, 'dara');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('booking-card-BK2026-0101')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('booking-card-BK2026-0103')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('clear-booking-search')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('booking-card-BK2026-0101')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('booking-card-BK2026-0102')),
      findsOneWidget,
    );
    final controller = Get.find<BookingController>();
    expect(controller.searchQuery.value, isEmpty);
    expect(controller.filteredBookings, hasLength(3));
    expect(listRequestCount, 5);
  });
}
