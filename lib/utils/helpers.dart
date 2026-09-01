import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/app_theme.dart';

void showSuccess(String message) {
  final context = Get.overlayContext ?? Get.context;
  if (context == null) return;
  final colors = Theme.of(context).extension<AppSemanticColors>();
  _showToast(
    message,
    backgroundColor: colors?.success ?? const Color(0xFF168A45),
    foregroundColor: colors?.onSuccess ?? Colors.white,
    icon: Icons.check_circle_outline_rounded,
  );
}

void showWarning(String message) {
  _showToast(
    message,
    backgroundColor: const Color(0xFFF79009),
    foregroundColor: Colors.white,
    icon: Icons.warning_amber_rounded,
  );
}

void showError(String message) {
  final context = Get.overlayContext ?? Get.context;
  if (context == null) return;
  final colors = Theme.of(context).colorScheme;
  _showToast(
    message,
    backgroundColor: colors.error,
    foregroundColor: colors.onError,
    icon: Icons.error_outline_rounded,
  );
}

void _showToast(
  String message, {
  required Color backgroundColor,
  required Color foregroundColor,
  required IconData icon,
}) {
  if (message.trim().isEmpty || (Get.overlayContext ?? Get.context) == null) {
    return;
  }
  Get.rawSnackbar(
    messageText: Text(
      message,
      style: TextStyle(
        color: foregroundColor,
        fontFamily: AppTheme.fontFamily,
        fontWeight: FontWeight.w700,
      ),
    ),
    icon: Icon(icon, color: foregroundColor),
    snackPosition: SnackPosition.TOP,
    snackStyle: SnackStyle.FLOATING,
    maxWidth: 560,
    margin: const EdgeInsets.fromLTRB(16, 18, 16, 0),
    borderRadius: 12,
    backgroundColor: backgroundColor,
    duration: const Duration(seconds: 4),
  );
}

String textValue(Object? value) => value?.toString().trim() ?? '';

double toDoubleValue(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

String formatMoney(num value) {
  return value
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
}

String formatCurrency(num value, String currencySymbol) {
  final symbol = currencySymbol.trim();
  return symbol.isEmpty ? formatMoney(value) : '${formatMoney(value)} $symbol';
}

String formatQuantity(num value) {
  final decimal = value.toDouble();
  if (!decimal.isFinite) return value.toString();
  if (decimal == 0) return '0';

  var text = value.toString();
  if (text.contains('e') || text.contains('E')) {
    text = decimal.toStringAsFixed(20);
  }
  if (text.contains('.')) {
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
  }

  final isNegative = text.startsWith('-');
  final unsigned = isNegative ? text.substring(1) : text;
  final parts = unsigned.split('.');
  final groupedInteger = parts.first.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  final fraction = parts.length > 1 ? '.${parts[1]}' : '';
  return '${isNegative ? '-' : ''}$groupedInteger$fraction';
}

String formatDate(Object? value) {
  final source = textValue(value);
  if (source.isEmpty) return '-';
  final date = value is DateTime ? value : DateTime.tryParse(source);
  if (date == null) return source;
  final local = date.isUtc ? date.toLocal() : date;
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year}';
}

String formatTimeAgo(DateTime? value, {DateTime? now}) {
  if (value == null) return '-';
  final current = now ?? DateTime.now();
  final created = value.isUtc ? value.toLocal() : value;
  final difference = current.difference(created);
  if (difference.isNegative || difference.inMinutes < 1) return 'ឥឡូវនេះ';
  if (difference.inHours < 1) return '${difference.inMinutes} នាទីមុន';
  if (difference.inDays < 1) return '${difference.inHours} ម៉ោងមុន';
  if (difference.inDays < 30) return '${difference.inDays} ថ្ងៃមុន';
  if (difference.inDays < 365) {
    return '${difference.inDays ~/ 30} ខែមុន';
  }
  return '${difference.inDays ~/ 365} ឆ្នាំមុន';
}

String formatExactDateTime(DateTime? value) {
  if (value == null) return '-';
  final local = value.isUtc ? value.toLocal() : value;
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}:'
      '${twoDigits(local.second)}';
}

Color colorFromHex(String value, {required Color fallback}) {
  final hex = value.replaceFirst('#', '');
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) return fallback;
  return Color(hex.length == 6 ? 0xFF000000 | parsed : parsed);
}
