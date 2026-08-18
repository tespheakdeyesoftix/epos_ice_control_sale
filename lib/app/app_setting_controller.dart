import 'package:get/get.dart';

import '../services/frappe_response_handler.dart';
import '../services/setting_service.dart';
import 'app_setting.dart';

class AppSettingController extends GetxController {
  AppSettingController({
    required this.stationName,
    this.settingService,
    this.outletNameProvider,
    AppSetting? initialSetting,
  }) {
    setting.value = initialSetting;
  }

  static AppSettingController get to => Get.find<AppSettingController>();

  final String stationName;
  final SettingService? settingService;
  final String Function()? outletNameProvider;
  final setting = Rxn<AppSetting>();
  final isLoading = false.obs;
  final errorMessage = RxnString();

  AppSetting? get current => setting.value;

  Uri? get logoUri {
    final currentSetting = current;
    if (currentSetting == null) return null;
    return settingService?.resolveImage(currentSetting.photo);
  }

  @override
  void onInit() {
    super.onInit();
    if (setting.value == null) load();
  }

  Future<void> load({String? outlet}) async {
    final service = settingService;
    if (service == null || stationName.trim().isEmpty || isLoading.value) {
      return;
    }
    isLoading.value = true;
    errorMessage.value = null;
    try {
      setting.value = await service.getSetting(
        stationName,
        outlet: outlet ?? outletNameProvider?.call() ?? '',
      );
    } on FrappeServerMessageException {
      // The shared API client already displayed the server message.
    } on Exception {
      errorMessage.value = 'មិនអាចទាញយកការកំណត់កម្មវិធីបានទេ។';
    } finally {
      isLoading.value = false;
    }
  }
}
