import 'dart:convert';

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
import 'package:ice_control_sale/features/navigation/app_shell_controller.dart';
import 'package:ice_control_sale/features/navigation/app_shell_screen.dart';
import 'package:ice_control_sale/features/notes/note_controller.dart';
import 'package:ice_control_sale/features/sell/sell_controller.dart';
import 'package:ice_control_sale/services/customer_service.dart';
import 'package:ice_control_sale/services/frappe_session_client.dart';
import 'package:ice_control_sale/services/note_service.dart';
import 'package:ice_control_sale/services/product_service.dart';
import 'package:ice_control_sale/services/sale_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('note rail icon is above settings and opens NoteAppScreen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 900);
    tester.view.devicePixelRatio = 1;
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      Get.reset();
    });
    final inner = MockClient((request) async {
      if (request.url.path.endsWith('/get_products')) {
        return _response({'message': []});
      }
      if (request.url.path.endsWith('/get_total_pending_order')) {
        return _response({'message': 0});
      }
      if (request.url.path.endsWith('get_count')) {
        return _response({'message': 3});
      }
      if (request.url.path == '/api/resource/Note') {
        return _response({'data': []});
      }
      return _response({});
    });
    final client = FrappeSessionClient(inner: inner, onServerMessage: (_) {});
    final baseUri = Uri.parse('http://127.0.0.1:8888/');
    final outlet = SessionOutletController(configuredOutlet: 'Outlet A');
    final login = LoginController(
      authService: null,
      stationName: 'Station',
      outletName: 'Outlet A',
    );
    login.currentUsername.value = 'Administrator';
    final sell = SellController(
      productService: ProductService(baseUri, client: client),
      customerService: CustomerService(baseUri, client: client),
      saleService: SaleService(baseUri, client: client),
      outletName: 'Outlet A',
      sessionOutletController: outlet,
      stationName: 'Station',
    );
    final shell = AppShellController(sellController: sell);
    final noteService = NoteService(baseUri, client: client);
    Get.put<LoginController>(login);
    Get.put<ThemeController>(ThemeController(preferences: preferences));
    Get.put<SessionOutletController>(outlet);
    Get.put<SellController>(sell);
    Get.put<AppShellController>(shell);
    Get.put<NoteService>(noteService);
    Get.put<NoteController>(
      NoteController(service: noteService, outletController: outlet),
    );
    Get.put<ClosedSaleController>(
      ClosedSaleController(
        sellController: sell,
        appShellController: shell,
        preferences: preferences,
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.light, home: const AppShellScreen()),
    );
    await tester.pumpAndSettle();

    final notes = find.byKey(const ValueKey('rail-notes-button'));
    final settings = find.byKey(const ValueKey('rail-settings-button'));
    expect(notes, findsOneWidget);
    expect(tester.widget<IconButton>(notes).tooltip, 'កំណត់ចំណាំ');
    expect(
      tester.getTopLeft(notes).dy,
      lessThan(tester.getTopLeft(settings).dy),
    );
    expect(
      find.byKey(const ValueKey('rail-note-reminder-badge')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('rail-note-reminder-count')))
          .data,
      '3',
    );

    await tester.tap(notes);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('note-app-screen')), findsOneWidget);
  });
}

http.Response _response(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
