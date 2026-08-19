import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ice_control_sale/features/login/login_controller.dart';
import 'package:ice_control_sale/app/app_setting.dart';
import 'package:ice_control_sale/app/app_setting_controller.dart';
import 'package:ice_control_sale/features/setting/setting_controller.dart';
import 'package:ice_control_sale/features/setting/setting_screen.dart';
import 'package:ice_control_sale/services/frappe_auth_service.dart';
import 'package:ice_control_sale/services/receipt_print_service.dart';

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  testWidgets(
    'cashiers can see print settings but template editing is locked',
    (tester) async {
      _registerLogin('cashier@example.com');

      await tester.pumpWidget(const GetMaterialApp(home: SettingScreen()));

      expect(find.byKey(const ValueKey('print-settings-card')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('receipt-template-settings-card')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    },
  );

  testWidgets('the exact Administrator user can open template editing', (
    tester,
  ) async {
    _registerLogin('Administrator');

    await tester.pumpWidget(const GetMaterialApp(home: SettingScreen()));

    expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
    expect(find.textContaining('A6, A5'), findsOneWidget);
  });
}

void _registerLogin(String user) {
  final controller = LoginController(
    authService: null,
    stationName: 'Cashier 01',
    outletName: 'Main',
  );
  controller.currentSession.value = AuthSession(raw: const {}, user: user);
  Get.put<LoginController>(controller);
  final appSettingController = AppSettingController(
    stationName: 'Cashier 01',
    initialSetting: const AppSetting(raw: {}, outlet: 'Main'),
  );
  Get.put<AppSettingController>(appSettingController);
  Get.put<SettingController>(
    SettingController(
      loginController: controller,
      appSettingController: appSettingController,
      printService: ReceiptPrintService(),
    ),
  );
}
