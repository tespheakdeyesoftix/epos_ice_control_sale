import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/app/app_theme.dart';
import 'package:ice_control_sale/app/theme_controller.dart';
import 'package:ice_control_sale/features/login/login_controller.dart';
import 'package:ice_control_sale/features/navigation/app_destination.dart';
import 'package:ice_control_sale/features/navigation/app_shell_controller.dart';
import 'package:ice_control_sale/features/navigation/app_shell_screen.dart';
import 'package:ice_control_sale/features/sell/sell_controller.dart';
import 'package:ice_control_sale/services/customer_service.dart';
import 'package:ice_control_sale/services/frappe_response_handler.dart';
import 'package:ice_control_sale/services/frappe_session_client.dart';
import 'package:ice_control_sale/services/product_service.dart';
import 'package:ice_control_sale/services/sale_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(1024, 768);
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
      return _jsonResponse({'message': 0});
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
    required this.savedStatuses,
    required this.serverMessages,
  });

  final SellController sell;
  final AppShellController shell;
  final List<String> savedStatuses;
  final List<FrappeServerMessage> serverMessages;
}
