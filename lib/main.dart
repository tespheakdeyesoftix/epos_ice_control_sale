import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app_config.dart';
import 'app/app_routes.dart';
import 'app/app_setting_controller.dart';
import 'app/app_theme.dart';
import 'app/theme_controller.dart';
import 'app/session_outlet_controller.dart';
import 'features/closed_sales/closed_sale_controller.dart';
import 'features/login/login_controller.dart';
import 'features/login/login_screen.dart';
import 'features/navigation/app_shell_controller.dart';
import 'features/navigation/app_shell_screen.dart';
import 'features/sell/sell_controller.dart';
import 'services/frappe_auth_service.dart';
import 'services/frappe_session_client.dart';
import 'services/note_preset_repository.dart';
import 'services/customer_service.dart';
import 'services/sale_service.dart';
import 'services/setting_service.dart';
import 'services/product_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init(NotePresetRepository.containerName);
  final preferences = await SharedPreferences.getInstance();

  AppConfig? config;
  String? configurationError;
  try {
    config = await AppConfig.loadFromExecutableDirectory();
  } on FormatException catch (error) {
    configurationError = error.message;
  } on Exception {
    configurationError = 'មិនអាចអានឯកសារ setting.json បានទេ។';
  }

  runApp(
    IceSaleApp(
      config: config,
      configurationError: configurationError,
      themeController: ThemeController(preferences: preferences),
    ),
  );
}

class IceSaleApp extends StatelessWidget {
  const IceSaleApp({
    super.key,
    this.config,
    this.configurationError,
    this.themeController,
    this.appSettingController,
  });

  final AppConfig? config;
  final String? configurationError;
  final ThemeController? themeController;
  final AppSettingController? appSettingController;

  @override
  Widget build(BuildContext context) {
    final sessionClient = FrappeSessionClient();
    final appThemeController = themeController ?? ThemeController();
    final sessionOutletController = SessionOutletController(
      configuredOutlet: config?.outletName ?? '',
    );
    final globalSettingController =
        appSettingController ??
        AppSettingController(
          stationName: config?.stationName ?? '',
          outletNameProvider: () => sessionOutletController.currentOutlet.value,
          settingService: config == null
              ? null
              : SettingService(config!.baseUri, client: sessionClient),
        );
    final controller = LoginController(
      authService: config == null
          ? null
          : FrappeAuthService(config!.baseUri, client: sessionClient),
      configurationError: configurationError,
      stationName: config?.stationName ?? '',
      outletName: config?.outletName ?? '',
      sessionOutletController: sessionOutletController,
    );

    return GetMaterialApp(
      title: 'ប្រព័ន្ធគ្រប់គ្រងការលក់ទឹកកក',
      debugShowCheckedModeBanner: false,
      initialBinding: BindingsBuilder(() {
        Get.put<ThemeController>(appThemeController, permanent: true);
        Get.put<AppSettingController>(globalSettingController, permanent: true);
        Get.put<LoginController>(controller, permanent: true);
        Get.put<SessionOutletController>(
          sessionOutletController,
          permanent: true,
        );
      }),
      initialRoute: AppRoutes.login,
      getPages: [
        GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
        GetPage(
          name: AppRoutes.authenticated,
          page: () => const AppShellScreen(),
          binding: BindingsBuilder(() {
            final appConfig = config;
            if (appConfig != null) {
              Get.lazyPut<SellController>(
                () => SellController(
                  productService: ProductService(
                    appConfig.baseUri,
                    client: sessionClient,
                  ),
                  customerService: CustomerService(
                    appConfig.baseUri,
                    client: sessionClient,
                  ),
                  saleService: SaleService(
                    appConfig.baseUri,
                    client: sessionClient,
                  ),
                  outletName: appConfig.outletName,
                  sessionOutletController: sessionOutletController,
                  stationName: appConfig.stationName,
                  appSettingController: globalSettingController,
                  canChangeCustomerProvider: () =>
                      controller.currentSession.value?.canChangeCustomer ??
                      false,
                  canChangeSaleDateProvider: () =>
                      controller.currentSession.value?.canChangeSaleDate ??
                      false,
                  canRemoveSaleProductProvider: () =>
                      controller.currentSession.value?.canRemoveSaleProduct ??
                      false,
                  canChangeProductPriceProvider: () =>
                      controller.currentSession.value?.canChangeProductPrice ??
                      false,
                  canUsePosPaymentProvider: () =>
                      controller.currentSession.value?.canUsePosPayment ??
                      false,
                  canEditBillProvider: () =>
                      controller.currentSession.value?.canEditBill ?? false,
                  canDeleteBillProvider: () =>
                      controller.currentSession.value?.canDeleteBill ?? false,
                ),
              );
              Get.lazyPut<AppShellController>(
                () => AppShellController(
                  sellController: Get.find<SellController>(),
                ),
              );
              Get.lazyPut<ClosedSaleController>(
                () => ClosedSaleController(
                  sellController: Get.find<SellController>(),
                  appShellController: Get.find<AppShellController>(),
                ),
              );
            }
          }),
        ),
      ],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: appThemeController.themeMode,
    );
  }
}
