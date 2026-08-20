import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/app/app_theme.dart';
import 'package:ice_control_sale/app/session_outlet_controller.dart';
import 'package:ice_control_sale/app/theme_controller.dart';
import 'package:ice_control_sale/features/closed_sales/closed_sale_controller.dart';
import 'package:ice_control_sale/features/login/login_controller.dart';
import 'package:ice_control_sale/features/navigation/app_destination.dart';
import 'package:ice_control_sale/features/navigation/app_shell_controller.dart';
import 'package:ice_control_sale/features/navigation/app_shell_screen.dart';
import 'package:ice_control_sale/features/report/report_controller.dart';
import 'package:ice_control_sale/features/sell/sell_controller.dart';
import 'package:ice_control_sale/services/customer_service.dart';
import 'package:ice_control_sale/services/frappe_response_handler.dart';
import 'package:ice_control_sale/services/frappe_session_client.dart';
import 'package:ice_control_sale/services/product_service.dart';
import 'package:ice_control_sale/services/report_file_service.dart';
import 'package:ice_control_sale/services/sale_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('compact user profile remains visible on every destination', (
    tester,
  ) async {
    await _pumpShell(tester);

    for (final destination in AppDestination.values) {
      await _tapDestination(tester, destination);
      expect(find.byKey(const ValueKey('global-user-profile')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('rail-settings-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('rail-profile-separator')),
        findsOneWidget,
      );
    }

    final settingsButton = tester.widget<IconButton>(
      find.byKey(const ValueKey('rail-settings-button')),
    );
    expect(settingsButton.tooltip, 'ការកំណត់');

    final profileButton = tester.widget<PopupMenuButton>(
      find.byType(PopupMenuButton),
    );
    expect(profileButton.tooltip, 'Administrator');
    expect(
      tester
          .getBottomLeft(find.byKey(const ValueKey('global-user-profile')))
          .dy,
      greaterThan(690),
    );
  });

  testWidgets('pending screen views and opens a Draft order for editing', (
    tester,
  ) async {
    final harness = await _pumpShell(tester);

    expect(find.byKey(const ValueKey('pending-rail-badge')), findsOneWidget);
    expect(find.byKey(const ValueKey('pending-rail-count')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('closed-sale-rail-badge')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('closed-sale-rail-count')))
          .data,
      '4',
    );

    await _tapDestination(tester, AppDestination.pendingSales);
    expect(
      find.byKey(const ValueKey('pending-order-list-screen')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('pending-screen-app-bar')))
          .height,
      82,
    );
    final pendingSearchCenter = tester.getCenter(
      find.byKey(const ValueKey('pending-order-search-input')),
    );
    final pendingDateCenter = tester.getCenter(
      find.byKey(const ValueKey('pending-order-date-filter')),
    );
    final pendingRefreshCenter = tester.getCenter(
      find.byKey(const ValueKey('refresh-pending-order-list')),
    );
    expect(pendingSearchCenter.dy, closeTo(pendingRefreshCenter.dy, 1));
    expect(pendingDateCenter.dy, closeTo(pendingRefreshCenter.dy, 1));
    expect(
      find.byKey(const ValueKey('view-pending-order-SO-DRAFT-0001')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('edit-pending-order-SO-DRAFT-0001')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('pending-order-total-SO-DRAFT-0001')),
          )
          .data,
      '***',
    );

    await tester.tap(
      find.byKey(const ValueKey('view-pending-order-SO-DRAFT-0001')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('pending-sale-view-dialog')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('pending-sale-product-01')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('close-pending-sale-view')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('edit-pending-order-SO-DRAFT-0001')),
    );
    await tester.pumpAndSettle();
    expect(harness.shell.selectedDestination.value, AppDestination.sale);
    expect(harness.sell.openedSale.value?.name, 'SO-DRAFT-0001');
  });

  testWidgets('closed sales screen lists metadata and opens sale details', (
    tester,
  ) async {
    final harness = await _pumpShell(
      tester,
      physicalSize: const Size(1500, 900),
    );

    await _tapDestination(tester, AppDestination.closedSales);
    final closedSaleController = Get.find<ClosedSaleController>();
    expect(closedSaleController.sales.single.name, 'SO-CLOSED-0001');
    expect(closedSaleController.sales.single.totalSplitBill, 2);
    expect(closedSaleController.totalRecords.value, 4);
    expect(find.text('1 of 4'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('closed-sale-pager-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('closed-sale-split-icon-SO-CLOSED-0001')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('closed-sale-list-screen')),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('closed-sale-app-bar'))).height,
      82,
    );
    final searchHeight = tester
        .getSize(find.byKey(const ValueKey('closed-sale-search-input')))
        .height;
    expect(
      tester
          .getSize(find.byKey(const ValueKey('closed-sale-start-date-filter')))
          .height,
      searchHeight,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('closed-sale-end-date-filter')))
          .height,
      searchHeight,
    );
    expect(
      find.byKey(const ValueKey('closed-sale-SO-CLOSED-0001')),
      findsOneWidget,
    );
    expect(find.text('Administrator'), findsOneWidget);
    expect(find.text('មិនទាន់បង់ប្រាក់'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('closed-sale-customer-avatar-SO-CLOSED-0001')),
      findsOneWidget,
    );

    await tester.tapAt(
      tester.getCenter(
        find.byKey(const ValueKey('closed-sale-SO-CLOSED-0001')),
      ),
      buttons: kSecondaryButton,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('closed-sale-context-view-detail')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('closed-sale-context-view-detail')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sale-detail-screen')), findsOneWidget);
    Navigator.of(
      tester.element(find.byKey(const ValueKey('sale-detail-screen'))),
    ).pop();
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('open-closed-sale-detail-SO-CLOSED-0001')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sale-detail-screen')), findsOneWidget);
    Navigator.of(
      tester.element(find.byKey(const ValueKey('sale-detail-screen'))),
    ).pop();
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('closed-sale-sort-total_amount')),
    );
    await tester.pumpAndSettle();
    expect(
      closedSaleController.sortField.value,
      ClosedSaleSortField.totalAmount,
    );
    expect(closedSaleController.sortAscending.value, isTrue);
    expect(
      harness.preferences.getString(
        ClosedSaleController.sortFieldPreferenceKey,
      ),
      'total_amount',
    );
    expect(
      harness.preferences.getBool(
        ClosedSaleController.sortAscendingPreferenceKey,
      ),
      isTrue,
    );

    final viewButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('view-closed-sale-SO-CLOSED-0001')),
    );
    expect(viewButton.onPressed, isNotNull);
    await tester.ensureVisible(
      find.byKey(const ValueKey('view-closed-sale-SO-CLOSED-0001')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('view-closed-sale-SO-CLOSED-0001')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('pending-sale-view-dialog')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('close-pending-sale-view')));
    await tester.pumpAndSettle();
  });

  testWidgets('empty navigation and unfinished Continue and Clear actions', (
    tester,
  ) async {
    final harness = await _pumpShell(tester);

    await _tapDestination(tester, AppDestination.saleSummary);
    expect(harness.shell.selectedDestination.value, AppDestination.saleSummary);
    expect(
      find.byKey(const ValueKey('destination-screen-saleSummary')),
      findsOneWidget,
    );

    await _tapDestination(tester, AppDestination.sale);
    expect(harness.sell.addProduct(harness.sell.products.single), isTrue);
    await tester.pumpAndSettle();

    await _tapDestination(tester, AppDestination.saleSummary);
    expect(
      find.byKey(const ValueKey('unfinished-sale-navigation-dialog')),
      findsOneWidget,
    );
    final closeAndPrint = find.byKey(
      const ValueKey('leave-sale-close-and-print'),
    );
    expect(closeAndPrint, findsOneWidget);
    expect(
      tester.getTopLeft(closeAndPrint).dy,
      greaterThan(
        tester.getTopLeft(find.byKey(const ValueKey('leave-sale-close'))).dy,
      ),
    );
    expect(
      tester.getTopLeft(closeAndPrint).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('leave-sale-hold'))).dy,
      ),
    );
    expect(
      tester
          .widget<InkWell>(
            find.descendant(of: closeAndPrint, matching: find.byType(InkWell)),
          )
          .onTap,
      isNotNull,
    );
    await tester.tap(find.byKey(const ValueKey('leave-sale-continue')));
    await tester.pumpAndSettle();
    expect(harness.shell.selectedDestination.value, AppDestination.sale);
    expect(harness.sell.saleProducts, hasLength(1));

    await _tapDestination(tester, AppDestination.saleSummary);
    await tester.tap(find.byKey(const ValueKey('leave-sale-clear')));
    await tester.pumpAndSettle();
    expect(harness.shell.selectedDestination.value, AppDestination.saleSummary);
    expect(harness.sell.saleProducts, isEmpty);
  });

  testWidgets('Hold saves Draft before navigating', (tester) async {
    final harness = await _pumpShell(tester);
    expect(harness.sell.addProduct(harness.sell.products.single), isTrue);
    await tester.pumpAndSettle();

    await _tapDestination(tester, AppDestination.pendingSales);
    await tester.tap(find.byKey(const ValueKey('leave-sale-hold')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.byKey(const ValueKey('save-order-success-dialog')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('close-save-order-success-button')),
    );
    await tester.pumpAndSettle();

    expect(harness.savedStatuses, ['Draft']);
    expect(
      harness.shell.selectedDestination.value,
      AppDestination.pendingSales,
    );
    expect(harness.sell.saleProducts, isEmpty);
  });

  testWidgets('Close requests a customer then saves Closed', (tester) async {
    final harness = await _pumpShell(tester);
    expect(harness.sell.addProduct(harness.sell.products.single), isTrue);
    await tester.pumpAndSettle();

    await _tapDestination(tester, AppDestination.closedSales);
    await tester.tap(find.byKey(const ValueKey('leave-sale-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('customer-search-input')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('customer-row-C457')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.byKey(const ValueKey('save-order-success-dialog')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('close-save-order-success-button')),
    );
    await tester.pumpAndSettle();

    expect(harness.savedStatuses, ['Closed']);
    expect(harness.shell.selectedDestination.value, AppDestination.closedSales);
    expect(harness.sell.saleProducts, isEmpty);
  });

  testWidgets('server failure keeps unfinished Sale open', (tester) async {
    final harness = await _pumpShell(tester, failSave: true);
    expect(harness.sell.addProduct(harness.sell.products.single), isTrue);
    await tester.pumpAndSettle();

    await _tapDestination(tester, AppDestination.report);
    await tester.tap(find.byKey(const ValueKey('leave-sale-hold')));
    await tester.pumpAndSettle();

    expect(harness.shell.selectedDestination.value, AppDestination.sale);
    expect(harness.sell.saleProducts, hasLength(1));
    expect(harness.serverMessages.single.message, 'Invalid outlet name');
  });
}

Future<void> _tapDestination(
  WidgetTester tester,
  AppDestination destination,
) async {
  await tester.tap(find.byKey(ValueKey('nav-destination-${destination.name}')));
  await tester.pumpAndSettle();
}

Future<_ShellHarness> _pumpShell(
  WidgetTester tester, {
  bool failSave = false,
  Size physicalSize = const Size(1024, 768),
}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    Get.reset();
  });

  final savedStatuses = <String>[];
  final serverMessages = <FrappeServerMessage>[];
  final mockClient = MockClient((request) async {
    if (request.url.path ==
        '/api/method/ice_control.api.v1.product.get_products') {
      return _jsonResponse({
        'message': [
          {
            'product_code': '01',
            'product_name': 'ទឹកកកដើមធំ',
            'product_category': 'ទឹកកកដើម',
            'unit': 'ដើម',
            'price': 15000,
            'color': '#ECAD4B',
            'photo': '',
          },
        ],
      });
    }
    if (request.url.path ==
        '/api/method/ice_control.api.v1.sale.get_total_pending_order') {
      return _jsonResponse({'message': 1});
    }
    if (request.url.path == '/api/method/frappe.desk.reportview.get_count') {
      return _jsonResponse({'message': 4});
    }
    if (request.url.path == '/api/resource/Sale') {
      final filters = request.url.queryParameters['filters'] ?? '';
      if (filters.contains('Closed')) {
        return _jsonResponse({
          'data': [
            {
              'name': 'SO-CLOSED-0001',
              'posting_date': '2026-08-18',
              'customer': 'C457',
              'customer_name': 'អតិថិជន C457',
              'phone_number': '012345678',
              'driver_name': 'អ្នកបើកបរ 01',
              'total_split_bill': 2,
              'total_sale_quantity': 2,
              'total_amount': 30000,
              'sale_status': 'Closed',
              'status': 'Unpaid',
              'owner': 'Administrator',
              'creation': '2026-08-18 08:30:00',
            },
          ],
        });
      }
      return _jsonResponse({
        'data': [
          {
            'name': 'SO-DRAFT-0001',
            'posting_date': '2026-08-18',
            'customer': 'C457',
            'customer_name': 'អតិថិជន C457',
            'phone_number': '012345678',
            'can_show_price': 0,
            'driver_name': 'អ្នកបើកបរ 01',
            'total_sale_quantity': 2,
            'total_amount': 30000,
          },
        ],
      });
    }
    if (request.url.path == '/api/resource/Sale/SO-DRAFT-0001') {
      return _jsonResponse({
        'data': {
          'name': 'SO-DRAFT-0001',
          'outlet': 'ទឹកកកដើម',
          'posting_date': '2026-08-18',
          'sale_status': 'Draft',
          'status': 'Unpaid',
          'total_split_bill': 0,
          'can_edit_bill': 1,
          'customer': 'C457',
          'customer_name': 'អតិថិជន C457',
          'phone_number': '012345678',
          'sale_products': [
            {
              'product_code': '01',
              'product_name': 'ទឹកកកដើមធំ',
              'product_category': 'ទឹកកកដើម',
              'unit': 'ដើម',
              'quantity': 2,
              'price': 15000,
              'allow_sum_qty': 1,
            },
          ],
        },
      });
    }
    if (request.url.path == '/api/resource/Sale/SO-CLOSED-0001') {
      return _jsonResponse({
        'data': {
          'name': 'SO-CLOSED-0001',
          'outlet': 'ទឹកកកដើម',
          'posting_date': '2026-08-18',
          'sale_status': 'Closed',
          'status': 'Unpaid',
          'total_split_bill': 0,
          'can_edit_bill': 1,
          'customer': 'C457',
          'customer_name': 'អតិថិជន C457',
          'phone_number': '012345678',
          'sale_products': [
            {
              'product_code': '01',
              'product_name': 'ទឹកកកដើមធំ',
              'product_category': 'ទឹកកកដើម',
              'unit': 'ដើម',
              'quantity': 2,
              'price': 15000,
              'allow_sum_qty': 1,
            },
          ],
        },
      });
    }
    if (request.url.path == '/api/resource/Customer') {
      return _jsonResponse({
        'data': [
          {
            'name': 'C457',
            'customer_name': 'អតិថិជន C457',
            'phone_number_1': '012345678',
            'is_customer': 1,
          },
        ],
      });
    }
    if (request.url.path.endsWith('get_customer_product_prices')) {
      return _jsonResponse(const []);
    }
    if (request.url.path == '/api/method/ice_control.api.v1.sale.save_order') {
      if (failSave) {
        return _jsonResponse({
          '_server_messages': jsonEncode([
            jsonEncode({
              'message': 'Invalid outlet name',
              'indicator': 'red',
              'raise_exception': 1,
            }),
          ]),
        }, statusCode: 417);
      }
      final payload = jsonDecode(request.bodyFields['data']!) as Map;
      final doc = Map<String, dynamic>.from(payload['doc'] as Map);
      savedStatuses.add(doc['sale_status'].toString());
      return _jsonResponse({
        'message': {...doc, 'name': 'SO-TEST-0001'},
      });
    }
    return _jsonResponse({});
  });
  final sessionClient = FrappeSessionClient(
    inner: mockClient,
    onServerMessage: serverMessages.add,
  );
  final baseUri = Uri.parse('http://127.0.0.1:8888/');
  final login = LoginController(
    authService: null,
    stationName: 'Cashier 01',
    outletName: 'ទឹកកកដើម',
  );
  login.currentUsername.value = 'Administrator';
  Get.put<LoginController>(login);
  final theme = ThemeController(preferences: preferences);
  Get.put<ThemeController>(theme);
  final sell = SellController(
    productService: ProductService(baseUri, client: sessionClient),
    customerService: CustomerService(baseUri, client: sessionClient),
    saleService: SaleService(baseUri, client: sessionClient),
    outletName: 'ទឹកកកដើម',
    stationName: 'Cashier 01',
  );
  Get.put<SellController>(sell);
  final shell = AppShellController(sellController: sell);
  Get.put<AppShellController>(shell);
  final outletController = SessionOutletController(
    configuredOutlet: 'áž‘áž¹áž€áž€áž€ážŠáž¾áž˜',
  );
  Get.put<SessionOutletController>(outletController);
  Get.lazyPut<ReportController>(
    () => ReportController(
      outletController: outletController,
      fileService: ReportFileService(),
    ),
  );
  Get.lazyPut<ClosedSaleController>(
    () => ClosedSaleController(
      sellController: sell,
      appShellController: shell,
      preferences: preferences,
    ),
  );

  await tester.pumpWidget(
    GetMaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const AppShellScreen(),
    ),
  );
  await tester.pumpAndSettle();
  return _ShellHarness(
    sell: sell,
    shell: shell,
    preferences: preferences,
    savedStatuses: savedStatuses,
    serverMessages: serverMessages,
  );
}

http.Response _jsonResponse(Object body, {int statusCode = 200}) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

class _ShellHarness {
  const _ShellHarness({
    required this.sell,
    required this.shell,
    required this.preferences,
    required this.savedStatuses,
    required this.serverMessages,
  });

  final SellController sell;
  final AppShellController shell;
  final SharedPreferences preferences;
  final List<String> savedStatuses;
  final List<FrappeServerMessage> serverMessages;
}
