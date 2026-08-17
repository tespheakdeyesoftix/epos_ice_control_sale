import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/app_routes.dart';
import '../../app/app_setting_controller.dart';
import '../../services/frappe_auth_service.dart';
import '../../services/frappe_response_handler.dart';

class LoginController extends GetxController {
  LoginController({
    required this.authService,
    required this.stationName,
    required this.outletName,
    this.configurationError,
  });

  final FrappeAuthService? authService;
  final String stationName;
  final String outletName;
  final String? configurationError;
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final errorMessage = RxnString();
  final currentUsername = ''.obs;
  final currentUserImageUrl = ''.obs;
  final currentSession = Rxn<AuthSession>();

  Future<void> login() async {
    FocusManager.instance.primaryFocus?.unfocus();
    errorMessage.value = null;
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      errorMessage.value = 'សូមបញ្ចូលឈ្មោះអ្នកប្រើប្រាស់ និងពាក្យសម្ងាត់។';
      return;
    }
    if (authService == null) {
      errorMessage.value =
          configurationError ?? 'ការកំណត់ម៉ាស៊ីនមេមិនត្រឹមត្រូវទេ។';
      return;
    }

    isLoading.value = true;
    try {
      final session = await authService!.login(
        username: username,
        password: password,
        outlet: outletName,
      );
      if (Get.isRegistered<AppSettingController>()) {
        unawaited(AppSettingController.to.load());
      }
      currentSession.value = session;
      currentUsername.value = session.fullName.isEmpty
          ? session.user.isEmpty
                ? username
                : session.user
          : session.fullName;
      currentUserImageUrl.value = session.userImageUrl;
      passwordController.clear();
      Get.offAllNamed(AppRoutes.sell);
    } on TimeoutException {
      errorMessage.value = 'ការតភ្ជាប់ម៉ាស៊ីនមេអស់ពេល។ សូមព្យាយាមម្តងទៀត។';
    } on FrappeServerMessageException {
      // The shared API client already displayed the server message.
    } on AuthException catch (error) {
      errorMessage.value = error.message;
    } on Exception {
      errorMessage.value = 'មិនអាចភ្ជាប់ទៅម៉ាស៊ីនមេបានទេ។';
    } finally {
      isLoading.value = false;
    }
  }

  void togglePasswordVisibility() => obscurePassword.toggle();

  Future<void> logout() async {
    try {
      await authService?.logout();
    } on Exception {
      // The local session is still cleared when the server is unavailable.
    }
    currentUsername.value = '';
    currentUserImageUrl.value = '';
    currentSession.value = null;
    usernameController.clear();
    passwordController.clear();
    errorMessage.value = null;
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
