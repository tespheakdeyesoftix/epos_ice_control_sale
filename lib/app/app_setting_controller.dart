import 'package:get/get.dart';

import '../services/setting_service.dart';
import 'app_setting.dart';

class AppSettingController extends GetxController {
  AppSettingController({
    required this.stationName,
    this.settingService,
    AppSetting? initialSetting,
  }) {
    setting.value = initialSetting;
  }

  static AppSettingController get to => Get.find<AppSettingController>();

  final String stationName;
  final SettingService? settingService;
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

  Future<void> load() async {
    final service = settingService;
    if (service == null || stationName.trim().isEmpty || isLoading.value) {
      return;
    }
    isLoading.value = true;
    errorMessage.value = null;
    try {
      setting.value = await service.getSetting(stationName);
    } on Exception {
      errorMessage.value = 'មិនអាចទាញយកការកំណត់កម្មវិធីបានទេ។';
    } finally {
      isLoading.value = false;
    }
  }
}
