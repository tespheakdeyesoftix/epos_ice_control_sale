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
import 'package:ice_control_sale/features/login/login_controller.dart';
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
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      Get.reset();
    });

    Map<String, dynamic>? submittedSale;
    var productRequestCount = 0;
    var pendingOrderCount = 3;
    var pendingOrderRequestCount = 0;
    final client = MockClient((request) async {
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

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeController.themeMode,
        home: const SellScreen(),
      ),
    );
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
    await tester.tap(
      find.byKey(const ValueKey('reload-pending-orders-button')),
    );
    await tester.pumpAndSettle();
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
    expect(find.text('សង្ខេបការលក់'), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('payment-button'))).width,
      tester.getSize(find.byKey(const ValueKey('customer-card'))).width,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('order-product-column'))).width,
      360,
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

    await tester.tap(find.byKey(const ValueKey('sale-note-button')));
    await tester.pumpAndSettle();
    expect(find.text('កំណត់ចំណាំ'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('sale-note-input')),
      'ដឹកជញ្ជូនមុនម៉ោង ១០ ព្រឹក',
    );
    await tester.tap(find.byKey(const ValueKey('confirm-sale-note')));
    await tester.pumpAndSettle();
    expect(find.text('ដឹកជញ្ជូនមុនម៉ោង ១០ ព្រឹក'), findsOneWidget);
    expect(sellController.currentSale.note, 'ដឹកជញ្ជូនមុនម៉ោង ១០ ព្រឹក');

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
    expect(find.text('012345678 • 2AB-1234'), findsOneWidget);
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
    expect(find.text('012345678 • 2CD-5678'), findsOneWidget);
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
    expect(find.text('តើអ្នកប្រាកដថាចង់ផ្អាកការលក់នេះមែនទេ?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm-pause-sale')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('ផ្អាកការលក់បានជោគជ័យ'), findsOneWidget);
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
