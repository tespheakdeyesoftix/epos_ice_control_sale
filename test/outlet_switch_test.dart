import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/app/session_outlet_controller.dart';
import 'package:ice_control_sale/app/app_theme.dart';
import 'package:ice_control_sale/app/app_setting_controller.dart';
import 'package:ice_control_sale/app/theme_controller.dart';
import 'package:ice_control_sale/features/closed_sales/closed_sale_controller.dart';
import 'package:ice_control_sale/features/login/login_controller.dart';
import 'package:ice_control_sale/features/navigation/app_shell_controller.dart';
import 'package:ice_control_sale/features/navigation/app_shell_screen.dart';
import 'package:ice_control_sale/features/sell/product.dart';
import 'package:ice_control_sale/features/sell/sale.dart';
import 'package:ice_control_sale/features/sell/sell_controller.dart';
import 'package:ice_control_sale/services/customer_service.dart';
import 'package:ice_control_sale/services/frappe_auth_service.dart';
import 'package:ice_control_sale/services/product_service.dart';
import 'package:ice_control_sale/services/sale_service.dart';
import 'package:ice_control_sale/services/setting_service.dart';

void main() {
  test('session outlet resets to configured value on logout', () {
    final outletSession = SessionOutletController(
      configuredOutlet: 'កន្លែងលក់ទី១',
    );
    outletSession.startSession(
      const AuthSession(raw: {}, outlets: ['កន្លែងលក់ទី១', 'កន្លែងលក់ទី២']),
    );

    expect(outletSession.canChangeOutlet, isTrue);
    outletSession.commitOutlet('កន្លែងលក់ទី២');
    expect(outletSession.currentOutlet.value, 'កន្លែងលក់ទី២');

    outletSession.reset();
    expect(outletSession.currentOutlet.value, 'កន្លែងលក់ទី១');
    expect(outletSession.availableOutlets, isEmpty);
  });

  test('switching outlet reloads products and updates new Sale data', () async {
    final requestedOutlets = <String>[];
    final requestedSettingOutlets = <String>[];
    final client = MockClient((request) async {
      if (request.url.path.endsWith('get_products')) {
        final outlet = request.bodyFields['outlet']!;
        requestedOutlets.add(outlet);
        if (outlet == 'កន្លែងលក់ខូច') {
          return http.Response('{}', 500);
        }
        return _productsResponse(outlet);
      }
      if (request.url.path.endsWith('get_setting')) {
        requestedSettingOutlets.add(request.url.queryParameters['outlet']!);
        return http.Response(
          jsonEncode({
            'message': {
              'outlet': request.url.queryParameters['outlet'],
              'default_stock_location': 'ឃ្លាំងថ្មី',
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response('{}', 200);
    });
    final outletSession =
        SessionOutletController(configuredOutlet: 'កន្លែងលក់ទី១')..startSession(
          const AuthSession(
            raw: {},
            outlets: ['កន្លែងលក់ទី១', 'កន្លែងលក់ទី២', 'កន្លែងលក់ខូច'],
          ),
        );
    final baseUri = Uri.parse('http://127.0.0.1:8888/');
    final controller = SellController(
      productService: ProductService(baseUri, client: client),
      customerService: CustomerService(baseUri, client: client),
      saleService: SaleService(baseUri, client: client),
      outletName: 'កន្លែងលក់ទី១',
      stationName: 'Cashier 01',
      sessionOutletController: outletSession,
      appSettingController: AppSettingController(
        stationName: 'Cashier 01',
        settingService: SettingService(baseUri, client: client),
      ),
    );

    await controller.changeOutlet('កន្លែងលក់ទី២');

    expect(requestedOutlets, ['កន្លែងលក់ទី២']);
    expect(requestedSettingOutlets, ['កន្លែងលក់ទី២']);
    expect(controller.activeOutletName, 'កន្លែងលក់ទី២');
    expect(controller.products.single.name, 'ទំនិញ កន្លែងលក់ទី២');
    expect(controller.currentSale.outlet, 'កន្លែងលក់ទី២');
    expect(controller.currentSale.stockLocation, 'ឃ្លាំងថ្មី');
    expect(controller.addProduct(controller.products.single), isTrue);
    expect(controller.saleProducts.single.outlet, 'កន្លែងលក់ទី២');

    controller.startNewSale();
    await expectLater(
      controller.changeOutlet('កន្លែងលក់ខូច'),
      throwsA(isA<Exception>()),
    );
    expect(controller.activeOutletName, 'កន្លែងលក់ទី២');
    expect(controller.products.single.name, 'ទំនិញ កន្លែងលក់ទី២');
  });

  test('dirty and opened Sales block outlet switching', () async {
    var productRequests = 0;
    final client = MockClient((request) async {
      productRequests++;
      return _productsResponse('កន្លែងលក់ទី២');
    });
    final outletSession =
        SessionOutletController(configuredOutlet: 'កន្លែងលក់ទី១')..startSession(
          const AuthSession(raw: {}, outlets: ['កន្លែងលក់ទី១', 'កន្លែងលក់ទី២']),
        );
    final baseUri = Uri.parse('http://127.0.0.1:8888/');
    final controller = SellController(
      productService: ProductService(baseUri, client: client),
      customerService: CustomerService(baseUri, client: client),
      saleService: SaleService(baseUri, client: client),
      outletName: 'កន្លែងលក់ទី១',
      stationName: 'Cashier 01',
      sessionOutletController: outletSession,
    );
    const product = Product(
      code: 'P001',
      name: 'ទំនិញទី១',
      category: 'ទូទៅ',
      unit: 'មុខ',
      price: 1000,
      color: '#1677FF',
      photo: '',
    );

    controller.addProduct(product);
    await expectLater(
      controller.changeOutlet('កន្លែងលក់ទី២'),
      throwsA(isA<OutletChangeBlockedException>()),
    );
    controller.startNewSale();
    controller.openedSale.value = const Sale(
      name: 'SO-DRAFT-0001',
      outlet: 'កន្លែងលក់ទី១',
      saleStatus: 'Draft',
      saleProducts: [],
    );
    await expectLater(
      controller.changeOutlet('កន្លែងលក់ទី២'),
      throwsA(isA<OutletChangeBlockedException>()),
    );

    expect(productRequests, 0);
    expect(controller.activeOutletName, 'កន្លែងលក់ទី១');
  });

  testWidgets('Sale app bar changes outlet when multiple outlets are allowed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      Get.reset();
    });
    final requestedOutlets = <String>[];
    final client = MockClient((request) async {
      if (request.url.path.endsWith('get_products')) {
        final outlet = request.bodyFields['outlet']!;
        requestedOutlets.add(outlet);
        return _productsResponse(outlet);
      }
      if (request.url.path.endsWith('get_total_pending_order')) {
        return http.Response(jsonEncode({'message': 0}), 200);
      }
      return http.Response(
        jsonEncode({'data': <dynamic>[]}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final outletSession =
        SessionOutletController(configuredOutlet: 'កន្លែងលក់ទី១')..startSession(
          const AuthSession(raw: {}, outlets: ['កន្លែងលក់ទី១', 'កន្លែងលក់ទី២']),
        );
    final login = LoginController(
      authService: null,
      stationName: 'Cashier 01',
      outletName: 'កន្លែងលក់ទី១',
      sessionOutletController: outletSession,
    );
    login.currentUsername.value = 'Administrator';
    Get.put<LoginController>(login);
    Get.put<ThemeController>(ThemeController());
    final baseUri = Uri.parse('http://127.0.0.1:8888/');
    final sell = SellController(
      productService: ProductService(baseUri, client: client),
      customerService: CustomerService(baseUri, client: client),
      saleService: SaleService(baseUri, client: client),
      outletName: 'កន្លែងលក់ទី១',
      stationName: 'Cashier 01',
      sessionOutletController: outletSession,
    );
    Get.put<SellController>(sell);
    final shell = AppShellController(sellController: sell);
    Get.put<AppShellController>(shell);
    Get.lazyPut<ClosedSaleController>(
      () =>
          ClosedSaleController(sellController: sell, appShellController: shell),
    );

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.light, home: const AppShellScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('change-outlet-button')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('change-outlet-button')));
    await tester.pumpAndSettle();
    expect(find.text('ជ្រើសរើសកន្លែងលក់'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('outlet-option-កន្លែងលក់ទី២')));
    await tester.pumpAndSettle();

    expect(sell.activeOutletName, 'កន្លែងលក់ទី២');
    expect(requestedOutlets.last, 'កន្លែងលក់ទី២');
    expect(find.text('កន្លែងលក់ទី២'), findsWidgets);
  });
}

http.Response _productsResponse(String outlet) => http.Response(
  jsonEncode({
    'message': [
      {
        'product_code': 'P-$outlet',
        'product_name': 'ទំនិញ $outlet',
        'product_category': 'ទូទៅ',
        'unit': 'មុខ',
        'price': 1000,
        'color': '#1677FF',
        'photo': '',
      },
    ],
  }),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
