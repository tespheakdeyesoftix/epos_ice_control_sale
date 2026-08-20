import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../app/app_theme.dart';
import 'closed_sale.dart';

class SaleDetailScreen extends StatelessWidget {
  const SaleDetailScreen({super.key, required this.sale});

  final ClosedSale sale;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      key: const ValueKey('sale-detail-screen'),
      appBar: AppBar(title: Text(sale.name)),
      backgroundColor: colors.surfaceContainerLow,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 52,
              color: colors.primary,
            ),
            const SizedBox(height: 14),
            Text(
              sale.name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'ព័ត៌មានលម្អិតនឹងបន្ថែមនៅពេលក្រោយ',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

@Preview(name: 'Basic sale detail', size: Size(720, 520))
Widget saleDetailScreenPreview() => MaterialApp(
  theme: AppTheme.light,
  home: const SaleDetailScreen(
    sale: ClosedSale(
      name: 'SALE-00010',
      postingDate: '2026-08-20',
      customerName: 'Sample Customer',
      totalAmount: 125000,
      saleStatus: 'Closed',
      status: 'Paid',
    ),
  ),
);
