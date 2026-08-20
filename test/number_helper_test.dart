import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/utils/helpers.dart';

void main() {
  test('បម្លែងតម្លៃទៅជាលេខទសភាគ', () {
    expect(toDoubleValue(15000), 15000);
    expect(toDoubleValue('12.5'), 12.5);
    expect(toDoubleValue(null), 0);
    expect(toDoubleValue('មិនមែនលេខ', fallback: -1), -1);
  });

  test('រៀបចំតម្លៃប្រាក់ និងពណ៌សម្រាប់ធាតុលក់', () {
    expect(formatMoney(15000), '15,000');
    expect(formatQuantity(1), '1');
    expect(formatQuantity(1.5), '1.5');
    expect(formatQuantity(1000), '1,000');
    expect(formatQuantity(1234567.25), '1,234,567.25');
    expect(formatQuantity(2500.0), '2,500');
    expect(formatQuantity(-12345.75), '-12,345.75');
    expect(
      colorFromHex('#ECAD4B', fallback: Colors.blue),
      const Color(0xFFECAD4B),
    );
    expect(colorFromHex('invalid', fallback: Colors.blue), Colors.blue);
  });

  test('បង្ហាញរយៈពេលចាប់ពីពេលបង្កើតជាភាសាខ្មែរ', () {
    final now = DateTime(2026, 8, 18, 12);
    expect(formatTimeAgo(now, now: now), 'ឥឡូវនេះ');
    expect(
      formatTimeAgo(now.subtract(const Duration(minutes: 15)), now: now),
      '15 នាទីមុន',
    );
    expect(
      formatTimeAgo(now.subtract(const Duration(hours: 3)), now: now),
      '3 ម៉ោងមុន',
    );
    expect(
      formatTimeAgo(now.subtract(const Duration(days: 2)), now: now),
      '2 ថ្ងៃមុន',
    );
    expect(
      formatExactDateTime(DateTime(2026, 8, 18, 14, 5, 9)),
      '18/08/2026 14:05:09',
    );
  });
}
