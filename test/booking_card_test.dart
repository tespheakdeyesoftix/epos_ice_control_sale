import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/features/booking/booking.dart';
import 'package:ice_control_sale/features/booking/booking_controller.dart';
import 'package:ice_control_sale/features/booking/booking_list.dart';
import 'package:ice_control_sale/features/booking/widgets/booking_card_widget.dart';
import 'package:ice_control_sale/features/booking/widgets/booking_detail_dialog_widget.dart';
import 'package:ice_control_sale/services/booking_service.dart';
import 'package:ice_control_sale/services/sale_service.dart';

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
                    'phone_number': '012345678',
                    'booking_event': 'Wedding',
                    'address': 'Phnom Penh',
                    'note': 'Call first',
                    'booking_products': const [
                      {
                        'product_code': 'P-01',
                        'product_name': 'Ice',
                        'unit': 'Bag',
                        'quantity': 50,
                        'price': 10000,
                        'transaction_type': 'Sale',
                      },
                    ],
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
    expect(find.byKey(const ValueKey('booking-detail-note')), findsOneWidget);
    expect(find.text('Call first'), findsOneWidget);
    expect(find.byKey(const ValueKey('delete-booking')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('delete-booking')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('delete-booking-confirmation')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('cancel-delete-booking')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('edit-booking')));
    await tester.pumpAndSettle();
    expect(find.text('កែប្រែការកក់'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('new-booking-customer-name')),
          )
          .controller
          ?.text,
      'Sokha',
    );
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('new-booking-phone-number')),
          )
          .controller
          ?.text,
      '012345678',
    );
    expect(find.byKey(const ValueKey('booking-product-P-01')), findsOneWidget);
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

  testWidgets('today delivery is not duplicated in all bookings', (
    tester,
  ) async {
    final today = DateTime.now();
    final deliveryDate =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    final service = BookingService(
      Uri.parse('https://ice.test/'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'data': [
              {
                'name': 'BK-TODAY',
                'delivery_date': deliveryDate,
                'customer_name': 'Today Customer',
              },
            ],
          }),
          200,
        ),
      ),
    );
    Get.put(BookingController(service: service));

    await tester.pumpWidget(const GetMaterialApp(home: BookingListScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('booking-card-BK-TODAY')), findsOneWidget);
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
        if (request.url.path ==
            '/api/method/frappe.desk.reportview.get_count') {
          return http.Response(jsonEncode({'message': 0}), 200);
        }
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

  testWidgets('shows every Sale issued from the booking and opens it', (
    tester,
  ) async {
    const bookingName = 'BK2026-0200';
    final now = DateTime.now();
    final deliveryDate =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final booking = Booking.fromJson({
      'name': bookingName,
      'customer_name': 'Dara',
      'delivery_date': deliveryDate,
      'booking_products': const [],
    });
    final bookingService = BookingService(
      Uri.parse('https://ice.test/'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'data': {
              'name': bookingName,
              'customer_name': 'Dara',
              'delivery_date': deliveryDate,
              'booking_products': const [],
            },
          }),
          200,
        ),
      ),
    );
    final saleService = SaleService(
      Uri.parse('https://ice.test/'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'data': const [
              {
                'name': 'SALE-0201',
                'posting_date': '2026-08-27',
                'sale_status': 'Closed',
              },
              {
                'name': 'SALE-0202',
                'posting_date': '2026-08-27',
                'sale_status': 'Draft',
              },
            ],
          }),
          200,
        ),
      ),
    );
    String? openedSale;

    await tester.pumpWidget(
      GetMaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showBookingDetailDialog(
                context,
                booking: booking,
                service: bookingService,
                saleService: saleService,
                outlet: 'Main Outlet',
                onCreateSale: (_) async => false,
                onOpenSale: (sale) async => openedSale = sale.name,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('booking-issued-sales-card')),
      findsOneWidget,
    );
    expect(find.text('SALE-0201'), findsOneWidget);
    expect(find.text('SALE-0202'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('create-sale-from-booking')),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('open-booking-sale-SALE-0202')));
    await tester.pump();
    expect(openedSale, 'SALE-0202');
  });

  testWidgets('enables Create Sale only on the booking delivery date', (
    tester,
  ) async {
    String dateText(DateTime date) =>
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final bookingDates = {
      'BK-TODAY': dateText(today),
      'BK-FUTURE': dateText(tomorrow),
    };
    Booking booking(String name) => Booking.fromJson({
      'name': name,
      'delivery_date': bookingDates[name],
      'booking_products': const [],
    });
    final service = BookingService(
      Uri.parse('https://ice.test/'),
      client: MockClient((request) async {
        final name = Uri.decodeComponent(request.url.pathSegments.last);
        return http.Response(
          jsonEncode({
            'data': {
              'name': name,
              'delivery_date': bookingDates[name],
              'booking_products': const [],
            },
          }),
          200,
        );
      }),
    );
    var createSaleCalls = 0;

    await tester.pumpWidget(
      GetMaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                FilledButton(
                  key: const ValueKey('open-future-booking'),
                  onPressed: () => showBookingDetailDialog(
                    context,
                    booking: booking('BK-FUTURE'),
                    service: service,
                    onCreateSale: (_) async {
                      createSaleCalls++;
                      return false;
                    },
                  ),
                  child: const Text('Future'),
                ),
                FilledButton(
                  key: const ValueKey('open-today-booking'),
                  onPressed: () => showBookingDetailDialog(
                    context,
                    booking: booking('BK-TODAY'),
                    service: service,
                    onCreateSale: (_) async {
                      createSaleCalls++;
                      return false;
                    },
                  ),
                  child: const Text('Today'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open-future-booking')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('create-sale-from-booking')),
          )
          .onPressed,
      isNull,
    );

    final touch = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('close-booking-detail'))),
      kind: PointerDeviceKind.touch,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('booking-detail-dialog-BK-FUTURE')),
      findsNothing,
    );
    await touch.up();
    await tester.tap(find.byKey(const ValueKey('open-today-booking')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('create-sale-from-booking')),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const ValueKey('create-sale-from-booking')));
    await tester.pump();
    expect(createSaleCalls, 1);
  });
}
