import 'package:flutter/material.dart';

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

String formatQuantity(num value) {
  final decimal = value.toDouble();
  return decimal == decimal.truncateToDouble()
      ? decimal.toInt().toString()
      : decimal.toString();
}

String formatTimeAgo(DateTime? value, {DateTime? now}) {
  if (value == null) return '-';
  final current = now ?? DateTime.now();
  final created = value.isUtc ? value.toLocal() : value;
  final difference = current.difference(created);
  if (difference.isNegative || difference.inMinutes < 1) return 'ឥឡូវនេះ';
  if (difference.inHours < 1) return 'មុន ${difference.inMinutes} នាទី';
  if (difference.inDays < 1) return 'មុន ${difference.inHours} ម៉ោង';
  if (difference.inDays < 30) return 'មុន ${difference.inDays} ថ្ងៃ';
  if (difference.inDays < 365) {
    return 'មុន ${difference.inDays ~/ 30} ខែ';
  }
  return 'មុន ${difference.inDays ~/ 365} ឆ្នាំ';
}

Color colorFromHex(String value, {required Color fallback}) {
  final hex = value.replaceFirst('#', '');
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) return fallback;
  return Color(hex.length == 6 ? 0xFF000000 | parsed : parsed);
}
