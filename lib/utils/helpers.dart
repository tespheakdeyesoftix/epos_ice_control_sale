import 'package:flutter/material.dart';

double toDoubleValue(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

String formatMoney(num value) {
  return value
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
}

String formatQuantity(num value) {
  final decimal = value.toDouble();
  return decimal == decimal.truncateToDouble()
      ? decimal.toInt().toString()
      : decimal.toString();
}

Color colorFromHex(String value, {required Color fallback}) {
  final hex = value.replaceFirst('#', '');
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) return fallback;
  return Color(hex.length == 6 ? 0xFF000000 | parsed : parsed);
}
