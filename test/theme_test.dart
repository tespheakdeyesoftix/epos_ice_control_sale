import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/app/app_theme.dart';
import 'package:ice_control_sale/app/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ផ្ដល់រចនាប័ទ្មភ្លឺ និងងងឹតជាមួយពុម្ពអក្សរខ្មែរ', () {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(
      AppTheme.light.textTheme.bodyMedium?.fontFamily,
      AppTheme.fontFamily,
    );
    expect(AppTheme.dark.textTheme.bodyMedium?.fontFamily, AppTheme.fontFamily);
    expect(
      AppTheme.light.extension<AppSemanticColors>()?.success,
      const Color(0xFF168A45),
    );
    expect(
      AppTheme.dark.extension<AppSemanticColors>()?.success,
      const Color(0xFF5DD68A),
    );
  });

  test('ស្ដារ និងរក្សាទុកជម្រើសរចនាប័ទ្ម', () async {
    SharedPreferences.setMockInitialValues({
      ThemeController.preferenceKey: true,
    });
    final preferences = await SharedPreferences.getInstance();
    final controller = ThemeController(preferences: preferences);

    expect(controller.isDark.value, isTrue);
    expect(controller.themeMode, ThemeMode.dark);

    await controller.toggleTheme();

    expect(controller.isDark.value, isFalse);
    expect(preferences.getBool(ThemeController.preferenceKey), isFalse);
  });
}
