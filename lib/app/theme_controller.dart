import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  ThemeController({SharedPreferences? preferences, bool initialIsDark = false})
    : _preferences = preferences,
      isDark = (preferences?.getBool(preferenceKey) ?? initialIsDark).obs;

  static const preferenceKey = 'theme_mode_dark';

  final SharedPreferences? _preferences;
  final RxBool isDark;

  ThemeMode get themeMode => isDark.value ? ThemeMode.dark : ThemeMode.light;

  Future<void> toggleTheme() async {
    isDark.toggle();
    Get.changeThemeMode(themeMode);
    await _preferences?.setBool(preferenceKey, isDark.value);
  }
}
