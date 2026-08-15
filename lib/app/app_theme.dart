import 'package:flutter/material.dart';

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({required this.success, required this.onSuccess});

  final Color success;
  final Color onSuccess;

  static AppSemanticColors of(BuildContext context) {
    return Theme.of(context).extension<AppSemanticColors>()!;
  }

  @override
  AppSemanticColors copyWith({Color? success, Color? onSuccess}) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
    );
  }

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
    );
  }
}

abstract final class AppTheme {
  static const _seed = Color(0xFF1677FF);
  static const fontFamily = 'NotoSansKhmer';

  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final generated = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final colors = generated.copyWith(
      primary: isDark ? const Color(0xFF7DB2FF) : _seed,
      onPrimary: isDark ? const Color(0xFF002F65) : Colors.white,
      surface: isDark ? const Color(0xFF142238) : Colors.white,
      onSurface: isDark ? const Color(0xFFF2F6FC) : const Color(0xFF14253D),
      surfaceContainerLowest: isDark ? const Color(0xFF0B1422) : Colors.white,
      surfaceContainerLow: isDark
          ? const Color(0xFF101C2E)
          : const Color(0xFFF4F7FB),
      surfaceContainer: isDark
          ? const Color(0xFF192A42)
          : const Color(0xFFEAF3FF),
      onSurfaceVariant: isDark
          ? const Color(0xFFB7C4D6)
          : const Color(0xFF68758A),
      outline: isDark ? const Color(0xFF58708D) : const Color(0xFFB6C2D0),
      outlineVariant: isDark
          ? const Color(0xFF2A3B52)
          : const Color(0xFFE1E8F0),
      error: isDark ? const Color(0xFFFFB4AB) : const Color(0xFFD92D20),
      onError: isDark ? const Color(0xFF690005) : Colors.white,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
      fontFamily: fontFamily,
      fontFamilyFallback: const ['Khmer UI', 'Leelawadee UI', 'Segoe UI'],
      scaffoldBackgroundColor: colors.surfaceContainerLowest,
    );

    return base.copyWith(
      extensions: [
        AppSemanticColors(
          success: isDark ? const Color(0xFF5DD68A) : const Color(0xFF168A45),
          onSuccess: isDark ? const Color(0xFF003919) : Colors.white,
        ),
      ],
      textTheme: base.textTheme.apply(
        bodyColor: colors.onSurface,
        displayColor: colors.onSurface,
        fontFamily: fontFamily,
      ),
      iconTheme: IconThemeData(color: colors.onSurfaceVariant),
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant,
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: colors.onSurface, fontFamily: fontFamily),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        hintStyle: TextStyle(color: colors.onSurfaceVariant),
        prefixIconColor: colors.onSurfaceVariant,
        suffixIconColor: colors.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          disabledBackgroundColor: colors.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: colors.onSurface.withValues(alpha: 0.38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.primary),
    );
  }
}
