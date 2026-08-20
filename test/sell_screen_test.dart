import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ice_control_sale/app/app_theme.dart';
import 'package:ice_control_sale/app/app_setting.dart';
import 'package:ice_control_sale/app/app_setting_controller.dart';
import 'package:ice_control_sale/app/theme_controller.dart';
import 'package:ice_control_sale/features/closed_sales/closed_sale_controller.dart';
import 'package:ice_control_sale/features/login/login_controller.dart';
import 'package:ice_control_sale/features/navigation/app_destination.dart';
import 'package:ice_control_sale/features/navigation/app_shell_controller.dart';
import 'package:ice_control_sale/features/navigation/app_shell_screen.dart';
import 'package:ice_control_sale/features/sell/customer.dart';
import 'package:ice_control_sale/features/sell/sell_controller.dart';
import 'package:ice_control_sale/features/sell/sell_screen.dart';
import 'package:ice_control_sale/services/customer_service.dart';
import 'package:ice_control_sale/services/product_service.dart';
import 'package:ice_control_sale/services/sale_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('បង្ហាញទំនិញ និងបន្ថែមទៅការលក់', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      Get.reset();
    });

    Map<String, dynamic>? submittedSale;
    String? deletedSaleName;
    String? deletedSaleNote;
    String? searchedBillKeyword;
    var productRequestCount = 0;
    var pendingOrderCount = 3;
    var pendingOrderRequestCount = 0;
    var pendingOrderListRequestCount = 0;
    var customerProductPriceRequestCount = 0;
    final client = MockClient((request) async {
      if (request.url.path ==
          '/api/method/ice_control.api.v1.customer.get_customer_product_prices') {
        customerProductPriceRequestCount++;
        expect(request.url.queryParameters['customer'], 'CU.0001');
        return http.Response(
          jsonEncode([
            {'product_code': '01', 'unit': 'ដើម', 'price': 15000},
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      if (request.url.path == '/api/resource/Customer') {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'name': 'CU.0001',
                'customer_name': 'អតិថិជន សុខា',
                'phone_number_1': '012345678',
                'phone_number_2': '098765432',
                'customer_group': 'លក់រាយ',
                'keyword': 'សុខា',
                'plate_number': '2AB-1234',
                'photo': '',
                'can_edit_bill': 1,
                'can_show_price': 1,
                'can_split_bill': 0,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      if (request.url.path == '/api/resource/Sale/SO-DRAFT-0001') {
        return http.Response(
          jsonEncode({
            'data': {
              'name': 'SO-DRAFT-0001',
              'doctype': 'Sale',
              'posting_date': '2026-08-15',
              'reference_number': 'DRAFT-REF-001',
              'outlet': 'ទឹកកកដើម',
              'stock_location': 'ឃ្លាំងទឹកកកដើម',
              'customer': 'CUST-001',
              'customer_name': 'អតិថិជន ក',
              'phone_number': '012000001',
              'driver': 'DRIVER-001',
              'driver_name': 'អ្នកបើកបរ ក',
              'driver_phone_number': '099000001',
              'plate_number': '2AB-1001',
              'sale_status': 'Draft',
              'status': 'Unpaid',
              'total_split_bill': 0,
              'can_edit_bill': 1,
              'note': 'Draft note',
              'sale_products': [
                {
                  'product_code': '01',
                  'product_name': 'ទឹកកកដើមធំ',
                  'product_category': 'ទឹកកកដើម',
                  'outlet': 'ទឹកកកដើម',
                  'unit': 'ដើម',
                  'price': 15000,
                  'quantity': 2,
                  'free_quantity': 0,
                  'return_quantity': 0,
                  'split_quantity': 0,
                },
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      if (request.url.path ==
          '/api/method/ice_control.api.v1.sale.search_bill_for_edit') {
        searchedBillKeyword = request.url.queryParameters['keyword'];
        expect(request.url.queryParameters['outlet'], 'ទឹកកកដើម');
        return http.Response(
          jsonEncode({
            'message': {
              'name': 'SO-SEARCH-0001',
              'doctype': 'Sale',
              'posting_date': '2026-08-18',
              'outlet': 'ទឹកកកដើម',
              'customer': 'CUST-SEARCH',
              'customer_name': 'អតិថិជនស្វែងរក',
              'can_edit_bill': 1,
              'can_show_price': 1,
              'sale_status': 'Closed',
              'status': 'Unpaid',
              'total_split_bill': 0,
              'sale_products': [
                {
                  'product_code': '01',
                  'product_name': 'ទឹកកកដើមធំ',
                  'product_category': 'ទឹកកកដើម',
                  'unit': 'ដើម',
                  'price': 15000,
                  'quantity': 2,
                },
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      if (request.url.path == '/api/resource/Sale') {
        pendingOrderListRequestCount++;
        return http.Response(
          jsonEncode({
            'data': [
              {
                'name': 'SO-DRAFT-0002',
                'posting_date': '2026-08-16',
                'customer': '',
                'customer_name': '',
                'phone_number': '012000002',
                'can_show_price': 0,
                'driver_name': 'អ្នកបើកបរ ខ',
                'total_sale_quantity': 15,
                'total_amount': 225000,
              },
              {
                'name': 'SO-DRAFT-0001',
                'posting_date': '2026-08-15',
                'customer': 'CUST-001',
                'customer_name': 'អតិថិជន ក',
                'phone_number': '012000001',
                'can_show_price': 1,
                'driver_name': '',
                'total_sale_quantity': 10,
                'total_amount': 150000,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      if (request.url.path ==
          '/api/method/ice_control.api.v1.sale.save_order') {
        final payload = jsonDecode(request.bodyFields['data']!);
        submittedSale = Map<String, dynamic>.from(payload['doc'] as Map);
        if (submittedSale?['sale_status'] == 'Draft') {
          pendingOrderCount++;
        }
        return http.Response(
          jsonEncode({
            'message': {...submittedSale!, 'name': 'SO-0001'},
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      if (request.url.path ==
          '/api/method/ice_control.api.v1.sale.delete_sale') {
        deletedSaleName = request.bodyFields['doc_name'];
        deletedSaleNote = request.bodyFields['deleted_note'];
        pendingOrderCount--;
        return http.Response(
          jsonEncode({
            'message': {'name': deletedSaleName},
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      if (request.url.path ==
          '/api/method/ice_control.api.v1.sale.get_total_pending_order') {
        pendingOrderRequestCount++;
        return http.Response(
          jsonEncode({'message': pendingOrderCount}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      productRequestCount++;
      return http.Response(
        jsonEncode({
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
            {
              'product_code': '02',
              'product_name': 'ទឹកកកដប',
              'product_category': 'ទឹកកកដប',
              'unit': 'ដប',
              'price': 5000,
              'color': '#1677FF',
              'photo': '',
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final login = LoginController(
      authService: null,
      stationName: 'Cashier 01',
      outletName: 'ទឹកកកដើម',
    );
    login.currentUsername.value = 'Administrator';
    Get.put<LoginController>(login);
    final themeController = ThemeController(preferences: preferences);
    Get.put<ThemeController>(themeController);
    final sellController = SellController(
      productService: ProductService(
        Uri.parse('http://127.0.0.1:8888/'),
        client: client,
      ),
      customerService: CustomerService(
        Uri.parse('http://127.0.0.1:8888/'),
        client: client,
      ),
      saleService: SaleService(
        Uri.parse('http://127.0.0.1:8888/'),
        client: client,
      ),
      outletName: 'ទឹកកកដើម',
      stationName: 'Cashier 01',
      appSettingController: AppSettingController(
        stationName: 'Cashier 01',
        initialSetting: const AppSetting(
          raw: {},
          defaultStockLocation: 'ឃ្លាំងទឹកកកដើម',
        ),
      ),
    );
    Get.put<SellController>(sellController);
    final shellController = AppShellController(sellController: sellController);
    Get.put<AppShellController>(shellController);
    Get.lazyPut<ClosedSaleController>(
      () => ClosedSaleController(
        sellController: sellController,
        appShellController: shellController,
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeController.themeMode,
        home: const AppShellScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const ValueKey('app-navigation-rail'))).width,
      64,
    );
    final railLogo = tester.widget<Container>(
      find.byKey(const ValueKey('rail-company-logo')),
    );
    expect((railLogo.decoration! as BoxDecoration).shape, BoxShape.circle);
    for (final destination in AppDestination.values) {
      final tooltip = tester.widget<Tooltip>(
        find.byKey(ValueKey('nav-destination-${destination.name}')),
      );
      expect(tooltip.message, destination.label);
    }

    expect(find.text('ទឹកកកដើមធំ'), findsOneWidget);
    final newSaleDeleteButton = tester.widget<OutlinedButton>(
      find.descendant(
        of: find.byKey(const ValueKey('delete-sale-button')),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(newSaleDeleteButton.onPressed, isNull);
    expect(find.byKey(const ValueKey('cancel-new-sale-button')), findsNothing);
    expect(find.byKey(const ValueKey('sale-note-button')), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('sale-bill-search-input')),
      'QR-SO-SEARCH-0001',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(searchedBillKeyword, 'QR-SO-SEARCH-0001');
    expect(sellController.currentSale.name, 'SO-SEARCH-0001');
    expect(sellController.saleProducts, hasLength(1));
    expect(
      find.byKey(const ValueKey('opened-sale-document-banner')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('cancel-sale-edit-button')));
    await tester.pumpAndSettle();
    expect(sellController.isNewSale, isTrue);
    expect(sellController.saleProducts, isEmpty);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('sale-bill-search-input')),
          )
          .controller!
          .text,
      isEmpty,
    );
    sellController.updateReferenceNumber('TEMP-NEW-SALE');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('cancel-new-sale-button')),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('cancel-new-sale-button')),
        matching: find.byKey(const ValueKey('order-product-scroll-view')),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('sale-note-button')), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('sale-note-button'))).dy,
      greaterThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('cancel-new-sale-button')))
            .dy,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('cancel-new-sale-button')));
    await tester.pumpAndSettle();
    expect(sellController.currentSale.referenceNumber, isEmpty);
    expect(sellController.isNewSaleDirty, isFalse);
    expect(find.byKey(const ValueKey('cancel-new-sale-button')), findsNothing);
    expect(find.byKey(const ValueKey('sale-note-button')), findsNothing);
    expect(find.byKey(const ValueKey('product-category-all')), findsOneWidget);
    expect(find.text('ទាំងអស់ (2)'), findsOneWidget);
    expect(find.text('ទឹកកកដើម (1)'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('product-category-ទឹកកកដើម')),
      findsOneWidget,
    );
    await tester.drag(
      find.byKey(const ValueKey('product-category-list')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('product-category-ទឹកកកដប')),
      findsOneWidget,
    );
    expect(find.text('ទឹកកកដប (1)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('product-category-ទឹកកកដប')));
    await tester.pumpAndSettle();
    final selectedCategoryChip = tester.widget<Material>(
      find.byKey(const ValueKey('product-category-ទឹកកកដប')),
    );
    expect(
      selectedCategoryChip.color,
      Theme.of(
        tester.element(find.byKey(const ValueKey('product-category-ទឹកកកដប'))),
      ).colorScheme.primary,
    );
    final allCategoryChip = tester.widget<Material>(
      find.byKey(const ValueKey('product-category-all')),
    );
    expect(
      allCategoryChip.color,
      Theme.of(
        tester.element(find.byKey(const ValueKey('product-category-all'))),
      ).colorScheme.surfaceContainerLow,
    );
    expect(find.text('ទឹកកកដើមធំ'), findsNothing);
    expect(sellController.filteredProducts, hasLength(1));
    expect(sellController.filteredProducts.single.name, 'ទឹកកកដប');
    await tester.drag(
      find.byKey(const ValueKey('product-category-list')),
      const Offset(300, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('product-category-all')));
    await tester.pumpAndSettle();
    expect(find.text('ទឹកកកដើមធំ'), findsOneWidget);
    expect(productRequestCount, 1);
    expect(pendingOrderRequestCount, 1);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('pending-order-count')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('open-pending-orders-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('pending-order-list-dialog')),
      findsOneWidget,
    );
    expect(pendingOrderListRequestCount, 1);
    expect(find.text('SO-DRAFT-0002'), findsOneWidget);
    expect(find.text('SO-DRAFT-0001'), findsOneWidget);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('pending-order-total-SO-DRAFT-0002')),
          )
          .data,
      '225,000 រៀល',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('pending-order-total-SO-DRAFT-0001')),
          )
          .data,
      '150,000 រៀល',
    );
    expect(find.text('CUST-001 - អតិថិជន ក'), findsOneWidget);
    expect(find.text('012000001'), findsNothing);
    expect(
      find.byKey(const ValueKey('pending-order-date-2026-08-16')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('pending-order-date-2026-08-15')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('pending-order-search-input')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('pending-order-search-input')),
      'CUST-001',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(pendingOrderListRequestCount, 2);
    await tester.tap(find.byKey(const ValueKey('pending-order-date-filter')));
    await tester.pumpAndSettle();
    expect(find.text('ជ្រើសរើសកាលបរិច្ឆេទ'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('confirm-posting-date')));
    await tester.pumpAndSettle();
    expect(pendingOrderListRequestCount, 3);
    expect(
      find.byKey(const ValueKey('view-pending-order-SO-DRAFT-0001')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('edit-pending-order-SO-DRAFT-0001')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('view-pending-order-SO-DRAFT-0001')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('pending-sale-view-dialog')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('close-pending-sale-view')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('edit-pending-order-SO-DRAFT-0001')),
    );
    await tester.pumpAndSettle();
    expect(sellController.openedSale.value?.name, 'SO-DRAFT-0001');
    expect(sellController.isNewSale, isFalse);
    expect(sellController.saleProducts, hasLength(1));
    expect(sellController.currentSale.name, 'SO-DRAFT-0001');
    expect(
      find.byKey(const ValueKey('opened-sale-document-banner')),
      findsOneWidget,
    );
    expect(find.text('SO-DRAFT-0001'), findsWidgets);
    expect(sellController.currentSale.referenceNumber, 'DRAFT-REF-001');
    expect(sellController.currentSale.customer, 'CUST-001');
    expect(sellController.currentSale.driver, 'DRIVER-001');
    final editSaleDeleteButton = tester.widget<OutlinedButton>(
      find.descendant(
        of: find.byKey(const ValueKey('delete-sale-button')),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(editSaleDeleteButton.onPressed, isNotNull);
    expect(
      find.byKey(const ValueKey('cancel-sale-edit-button')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('cancel-sale-edit-button')));
    await tester.pumpAndSettle();
    expect(sellController.isNewSale, isTrue);
    expect(sellController.saleProducts, isEmpty);
    expect(
      find.byKey(const ValueKey('opened-sale-document-banner')),
      findsNothing,
    );

    await sellController.openPendingOrder('SO-DRAFT-0001');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-sale-button')));
    await tester.pumpAndSettle();
    expect(find.text('មូលហេតុដែលលុបបុង SO-DRAFT-0001'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('note-dialog-input')),
      'បញ្ចូលបុងខុស',
    );
    await tester.tap(find.byKey(const ValueKey('confirm-note-dialog')));
    await tester.pumpAndSettle();
    expect(deletedSaleName, 'SO-DRAFT-0001');
    expect(deletedSaleNote, 'បញ្ចូលបុងខុស');
    expect(sellController.isNewSale, isTrue);
    expect(sellController.saleProducts, isEmpty);
    expect(
      find.byKey(const ValueKey('opened-sale-document-banner')),
      findsNothing,
    );
    expect(pendingOrderRequestCount, 2);
    expect(
      find.byKey(const ValueKey('reload-products-button')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('reload-products-button')));
    await tester.pumpAndSettle();
    expect(productRequestCount, 2);
    expect(find.text('0 រៀល'), findsWidgets);
    expect(find.text('បិទការលក់'), findsOneWidget);
    expect(find.text('បោះពុម្ព\nវិក្កយបត្រ'), findsOneWidget);
    expect(find.text('អ្នកបើកបរ'), findsOneWidget);
    expect(find.text('ជ្រើសរើសអ្នកបើកបរ'), findsOneWidget);
    expect(find.text('ប្រភេទការលក់'), findsNothing);
    expect(find.text('សង្ខេបការលក់'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('payment-button'))).width,
      tester.getSize(find.byKey(const ValueKey('customer-card'))).width,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('order-product-column'))).width,
      320,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('product-list-column'))).width,
      greaterThanOrEqualTo(340),
    );
    expect(sellController.currentSale.doctype, 'Sale');
    expect(sellController.currentSale.station, 'Cashier 01');
    expect(sellController.currentSale.lastUpdateStation, 'Cashier 01');
    expect(sellController.currentSale.stockLocation, 'ឃ្លាំងទឹកកកដើម');

    await tester.tap(find.byKey(const ValueKey('posting-date-button')));
    await tester.pumpAndSettle();
    expect(find.text('ជ្រើសរើសកាលបរិច្ឆេទ'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm-posting-date')));
    await tester.pumpAndSettle();
    final postingDate = sellController.currentSale.postingDate!;
    final expectedPostingDate =
        '${postingDate.year}-${postingDate.month.toString().padLeft(2, '0')}-${postingDate.day.toString().padLeft(2, '0')}';
    expect(
      sellController.currentSale.toJson()['posting_date'],
      expectedPostingDate,
    );
    final originalPostingDate = sellController.postingDate.value;
    sellController.updatePostingDate(
      DateTime.now().add(const Duration(days: 2)),
    );
    expect(sellController.postingDate.value, originalPostingDate);

    await tester.tap(find.byKey(const ValueKey('reference-number-button')));
    await tester.pumpAndSettle();
    expect(find.text('លេខយោង'), findsWidgets);
    await tester.enterText(
      find.byKey(const ValueKey('reference-number-input')),
      'REF-2026-001',
    );
    await tester.tap(find.byKey(const ValueKey('confirm-reference-number')));
    await tester.pumpAndSettle();
    expect(find.text('REF-2026-001'), findsOneWidget);
    expect(sellController.currentSale.referenceNumber, 'REF-2026-001');

    expect(find.text('បញ្ជូលចំណាំ'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('sale-note-button')));
    await tester.pumpAndSettle();
    expect(find.text('កំណត់ចំណាំ'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('note-dialog-input')),
      'ដឹកជញ្ជូនមុនម៉ោង ១០ ព្រឹក',
    );
    await tester.tap(find.byKey(const ValueKey('confirm-note-dialog')));
    await tester.pumpAndSettle();
    expect(find.text('ដឹកជញ្ជូនមុនម៉ោង ១០ ព្រឹក'), findsOneWidget);
    expect(find.text('បញ្ជូលចំណាំ'), findsNothing);
    expect(sellController.currentSale.note, 'ដឹកជញ្ជូនមុនម៉ោង ១០ ព្រឹក');

    expect(sellController.addProduct(sellController.products.first), isTrue);
    await tester.pumpAndSettle();
    await tester.tap(find.text('បិទការលក់'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('missing-customer-dialog')),
      findsOneWidget,
    );
    expect(find.text('មិនទាន់ជ្រើសរើសអតិថិជន'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    await tester.tap(find.byKey(const ValueKey('select-customer-now')));
    await tester.pumpAndSettle();
    expect(find.text('ជ្រើសរើសអតិថិជន'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('close-customer-dialog')));
    await tester.pumpAndSettle();
    expect(sellController.selectedCustomer.value, isNull);
    sellController.clearCart();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('customer-card')));
    await tester.pumpAndSettle();
    expect(find.text('ជ្រើសរើសអតិថិជន'), findsOneWidget);
    expect(find.byKey(const ValueKey('customer-search-input')), findsOneWidget);
    expect(find.byKey(const ValueKey('customer-letter-ក')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('customer-row-CU.0001')));
    await tester.pumpAndSettle();

    expect(find.text('CU.0001 - អតិថិជន សុខា'), findsOneWidget);
    expect(find.text('012345678'), findsOneWidget);
    expect(sellController.currentSale.customer, 'CU.0001');
    expect(sellController.currentSale.customerName, 'អតិថិជន សុខា');
    expect(sellController.currentSale.phoneNumber, '012345678');
    expect(sellController.currentSale.customerGroup, 'លក់រាយ');
    expect(sellController.currentSale.customerPhoto, '');
    expect(sellController.currentSale.canEditBill, isTrue);
    expect(sellController.currentSale.canShowPrice, isTrue);
    expect(sellController.currentSale.canSplitBill, isFalse);
    expect(customerProductPriceRequestCount, 1);
    expect(
      find.byKey(const ValueKey('clear-selected-customer')),
      findsOneWidget,
    );

    await tester.tap(find.text('អ្នកបើកបរ'));
    await tester.pumpAndSettle();
    expect(find.text('ជ្រើសរើសអ្នកបើកបរ'), findsWidgets);
    expect(find.text('ស្លាកលេខ'), findsOneWidget);
    expect(find.text('2AB-1234'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('customer-row-CU.0001')));
    await tester.pumpAndSettle();

    expect(sellController.currentSale.driver, 'CU.0001');
    expect(sellController.currentSale.driverName, 'អតិថិជន សុខា');
    expect(sellController.currentSale.driverPhoneNumber, '012345678');
    expect(sellController.currentSale.plateNumber, '2AB-1234');
    expect(find.text('CU.0001 - អតិថិជន សុខា'), findsNWidgets(2));
    expect(find.text('ស្លាកលេខ: 2AB-1234'), findsOneWidget);
    expect(find.text('ប្តូរស្លាក់លេខឡាន'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('change-plate-number-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('plate-number-input')),
      '2CD-5678',
    );
    await tester.tap(find.byKey(const ValueKey('confirm-plate-number')));
    await tester.pumpAndSettle();
    expect(sellController.currentSale.plateNumber, '2CD-5678');
    expect(find.text('ស្លាកលេខ: 2CD-5678'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('clear-selected-driver')));
    await tester.pumpAndSettle();
    expect(sellController.currentSale.driver, isEmpty);
    expect(sellController.currentSale.plateNumber, isEmpty);
    expect(find.text('ជ្រើសរើសអ្នកបើកបរ'), findsOneWidget);

    await tester.tap(find.text('ទឹកកកដើមធំ'));
    await tester.pumpAndSettle();

    expect(find.text('បញ្ចូលចំនួន'), findsOneWidget);
    expect(find.byKey(const ValueKey('backspace-number')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('number-key-1')));
    await tester.tap(find.byKey(const ValueKey('decimal-number')));
    await tester.tap(find.byKey(const ValueKey('number-key-5')));
    await tester.pump();
    expect(find.text('1.5'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('accept-number')));
    await tester.pumpAndSettle();

    expect(find.text('ទឹកកកដើមធំ'), findsNWidgets(2));
    expect(find.text('1.5 x 15,000 / ដើម'), findsOneWidget);
    expect(find.text('22,500 រៀល'), findsWidgets);
    final visibleCustomer = sellController.selectedCustomer.value!;
    sellController.selectedCustomer.value = const Customer(
      name: 'PRIVATE-CUSTOMER',
      customerName: 'អតិថិជនតម្លៃសម្ងាត់',
      canShowPrice: false,
    );
    await tester.pumpAndSettle();
    expect(sellController.currentSale.canShowPrice, isFalse);
    expect(sellController.currentSale.toJson()['can_show_price'], 0);
    expect(find.text('1.5 x *** / ដើម'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('order-product-total-01')))
          .data,
      '***',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('sale-summary-total-amount')))
          .data,
      '***',
    );
    sellController.selectedCustomer.value = visibleCustomer;
    await tester.pumpAndSettle();
    expect(find.text('1.5 x 15,000 / ដើម'), findsOneWidget);
    expect(find.text('22,500 រៀល'), findsWidgets);
    final productNameCenter = tester.getCenter(
      find.byKey(const ValueKey('order-product-name-01')),
    );
    final productTotalCenter = tester.getCenter(
      find.byKey(const ValueKey('order-product-total-01')),
    );
    final removeButtonCenter = tester.getCenter(
      find.byKey(const ValueKey('remove-order-product-01')),
    );
    final orderCardRect = tester.getRect(
      find.byKey(const ValueKey('order-product-card-01')),
    );
    final productTotalRect = tester.getRect(
      find.byKey(const ValueKey('order-product-total-01')),
    );
    final removeButtonRect = tester.getRect(
      find.byKey(const ValueKey('remove-order-product-01')),
    );
    expect(productTotalCenter.dx, greaterThan(productNameCenter.dx));
    expect(removeButtonCenter.dy, greaterThan(productTotalCenter.dy));
    expect(orderCardRect.right - productTotalRect.right, 13);
    expect(orderCardRect.right - removeButtonRect.right, 13);
    final photoAreaRect = tester.getRect(
      find.byKey(const ValueKey('order-product-photo-area-01')),
    );
    expect(photoAreaRect.left, orderCardRect.left);
    expect(photoAreaRect.top, orderCardRect.top);
    expect(photoAreaRect.bottom, orderCardRect.bottom);

    await tester.tap(find.text('ទឹកកកដើមធំ').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('បញ្ចូលចំនួន'), findsNothing);
    expect(
      find.text('ទំនិញ «ទឹកកកដើមធំ» ត្រូវបានជ្រើសរើសរួចហើយ។'),
      findsOneWidget,
    );
    expect(find.text('1.5 x 15,000 / ដើម'), findsOneWidget);
    expect(find.text('22,500 រៀល'), findsWidgets);
    expect(sellController.saleProducts.single.quantity, 1.5);
    await expectLater(
      sellController.openPendingOrder('SO-DRAFT-0001'),
      throwsA(isA<PendingOrderOpenValidationException>()),
    );

    await tester.tap(find.byKey(const ValueKey('order-product-card-01')));
    await tester.pumpAndSettle();

    expect(find.text('កែប្រែទំនិញលក់'), findsOneWidget);
    expect(find.text('ចំនួន'), findsOneWidget);
    expect(find.text('តម្លៃ'), findsOneWidget);
    expect(find.text('ចំនួនសល់មកវិញ'), findsOneWidget);
    expect(find.text('ចំនួនថែម/Free'), findsOneWidget);
    expect(find.text('កំណត់ចំណាំ'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('edit-sale-price')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('clear-number')));
    await tester.tap(find.byKey(const ValueKey('number-key-2')));
    for (var index = 0; index < 4; index++) {
      await tester.tap(find.byKey(const ValueKey('number-key-0')));
    }
    await tester.tap(find.byKey(const ValueKey('accept-number')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('edit-sale-free-quantity')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('clear-number')));
    await tester.tap(find.byKey(const ValueKey('number-key-1')));
    await tester.tap(find.byKey(const ValueKey('accept-number')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-sale-note')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('sale-product-note-input')),
      'ដឹកជញ្ជូនពេលព្រឹក',
    );
    await tester.tap(find.byKey(const ValueKey('accept-sale-product-note')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-sale-order-edit')));
    await tester.pumpAndSettle();

    expect(find.text('0.5 x 20,000 / ដើម'), findsOneWidget);
    expect(find.text('10,000 រៀល'), findsWidgets);
    expect(Get.find<SellController>().saleProducts.single.price, 20000);
    expect(Get.find<SellController>().saleProducts.single.freeQuantity, 1);
    expect(
      Get.find<SellController>().saleProducts.single.note,
      'ដឹកជញ្ជូនពេលព្រឹក',
    );
    expect(find.textContaining('ថែម/Free: 1'), findsOneWidget);
    expect(find.textContaining('សល់មកវិញ:'), findsNothing);
    expect(
      find.textContaining('កំណត់ចំណាំ: ដឹកជញ្ជូនពេលព្រឹក'),
      findsOneWidget,
    );

    await tester.tap(find.text('បិទការលក់'));
    await tester.pumpAndSettle();
    expect(
      find.text('តើអ្នកប្រាកដថាចង់រក្សាទុកការលក់នេះមែនទេ?'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('confirm-save-order')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.byKey(const ValueKey('save-order-success-dialog')),
      findsOneWidget,
    );
    expect(find.text('រក្សាទុកការលក់បានជោគជ័យ'), findsOneWidget);
    expect(find.text('លេខការលក់៖ SO-0001'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('close-save-order-success')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('close-save-order-success-button')),
      findsOneWidget,
    );
    expect(submittedSale?['customer'], 'CU.0001');
    expect(submittedSale?['can_show_price'], 1);
    expect(submittedSale?['sale_status'], 'Closed');
    expect(submittedSale?['reference_number'], 'REF-2026-001');
    expect(submittedSale?['note'], 'ដឹកជញ្ជូនមុនម៉ោង ១០ ព្រឹក');
    expect(submittedSale?['sale_products'], isA<List<dynamic>>());
    expect(submittedSale?['sale_products'], hasLength(1));
    expect(sellController.saleProducts, isEmpty);
    expect(sellController.selectedCustomer.value, isNull);
    expect(sellController.selectedDriver.value, isNull);
    expect(sellController.currentSale.stockLocation, 'ឃ្លាំងទឹកកកដើម');
    expect(sellController.currentSale.referenceNumber, isEmpty);
    expect(sellController.currentSale.note, isEmpty);

    await tester.tap(
      find.byKey(const ValueKey('close-save-order-success-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('save-order-success-dialog')),
      findsNothing,
    );

    expect(sellController.selectedCustomer.value, isNull);
    await tester.tap(find.text('ទឹកកកដើមធំ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('preset-10')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pause-sale-button')));
    await tester.pumpAndSettle();
    expect(
      find.text('តើអ្នកប្រាកដថាចង់ដាក់ការលក់នេះក្នុងរង់ចាំមែនទេ?'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('confirm-pause-sale')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('ដាក់ការលក់ក្នុងរង់ចាំបានជោគជ័យ'), findsOneWidget);
    expect(submittedSale?['sale_status'], 'Draft');
    expect(submittedSale?['customer'], isEmpty);
    expect(submittedSale?['sale_products'], hasLength(1));
    expect(sellController.saleProducts, isEmpty);
    expect(sellController.pendingOrderCount.value, 4);
    await tester.tap(
      find.byKey(const ValueKey('close-save-order-success-button')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Administrator'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('រចនាប័ទ្មភ្លឺ'));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.byType(SellScreen))).brightness,
      Brightness.dark,
    );
    expect(preferences.getBool(ThemeController.preferenceKey), isTrue);
  });
}
