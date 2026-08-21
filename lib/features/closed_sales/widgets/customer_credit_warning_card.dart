import 'package:flutter/material.dart';

import '../../../features/sell/sale.dart';
import '../../../utils/helpers.dart';

/// Compact overdue-credit warning displayed beside the invoice status.
class CustomerCreditWarningCard extends StatelessWidget {
  const CustomerCreditWarningCard({
    super.key,
    required this.sale,
    required this.currencySymbol,
  });

  final Sale sale;
  final String currencySymbol;

  static int creditDurationDays(Sale sale, {DateTime? currentDate}) {
    final postingDate = sale.postingDate;
    if (postingDate == null) return 0;
    final today = DateUtils.dateOnly(currentDate ?? DateTime.now());
    final posted = DateUtils.dateOnly(postingDate);
    return today.difference(posted).inDays.clamp(0, 999999);
  }

  static bool shouldShow(Sale sale, {DateTime? currentDate}) {
    return sale.balance > 0 &&
        creditDurationDays(sale, currentDate: currentDate) >= 7;
  }

  @override
  Widget build(BuildContext context) {
    final duration = creditDurationDays(sale);
    if (sale.balance <= 0 || duration < 7) return const SizedBox.shrink();
    final level = _CreditWarningLevel.fromDays(duration);
    final balance = sale.canShowPrice
        ? formatCurrency(sale.balance, currencySymbol)
        : '••••';

    return Tooltip(
      message: '${level.label} · $duration ថ្ងៃ · $balance',
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: level.background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: level.accent.withValues(alpha: .5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(level.icon, size: 17, color: level.accent),
            const SizedBox(width: 6),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${level.label} $duration ថ្ងៃ',
                      style: TextStyle(
                        color: level.foreground,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 14,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: level.accent.withValues(alpha: .3),
                    ),
                    Text(
                      balance,
                      style: TextStyle(
                        color: level.foreground,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Text(
                  'សូមពិនិត្យ និងទាក់ទងអតិថិជន',
                  style: TextStyle(
                    color: level.foreground.withValues(alpha: .78),
                    fontSize: 10,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreditWarningLevel {
  const _CreditWarningLevel({
    required this.background,
    required this.accent,
    required this.foreground,
    required this.icon,
    required this.label,
  });

  final Color background;
  final Color accent;
  final Color foreground;
  final IconData icon;
  final String label;

  static _CreditWarningLevel fromDays(int days) {
    if (days >= 60) {
      return const _CreditWarningLevel(
        background: Color(0xFFFFEBEE),
        accent: Color(0xFFC62828),
        foreground: Color(0xFF7F1D1D),
        icon: Icons.report_gmailerrorred_rounded,
        label: 'ឥណទានយឺតខ្លាំង',
      );
    }
    if (days >= 30) {
      return const _CreditWarningLevel(
        background: Color(0xFFFBE9E7),
        accent: Color(0xFFD84315),
        foreground: Color(0xFF7C2D12),
        icon: Icons.warning_amber_rounded,
        label: 'ព្រមានឥណទាន',
      );
    }
    if (days >= 14) {
      return const _CreditWarningLevel(
        background: Color(0xFFFFF3E0),
        accent: Color(0xFFEF6C00),
        foreground: Color(0xFF7C3A00),
        icon: Icons.schedule_rounded,
        label: 'ឥណទានយឺត',
      );
    }
    return const _CreditWarningLevel(
      background: Color(0xFFFFF8E1),
      accent: Color(0xFFF9A825),
      foreground: Color(0xFF6D4C00),
      icon: Icons.info_outline_rounded,
      label: 'រំលឹកឥណទាន',
    );
  }
}
