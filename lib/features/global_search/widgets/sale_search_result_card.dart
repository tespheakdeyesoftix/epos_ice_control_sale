import 'package:flutter/material.dart';

import '../../../utils/helpers.dart';
import '../../closed_sales/closed_sale.dart';

class SaleSearchResultCard extends StatelessWidget {
  const SaleSearchResultCard({
    super.key,
    required this.sale,
    required this.onTap,
  });

  final ClosedSale sale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final customer = sale.customerName.trim().isNotEmpty
        ? sale.customerName.trim()
        : sale.customer.trim().isNotEmpty
        ? sale.customer.trim()
        : '-';
    final timestamp = sale.modified ?? sale.creation;
    return Card(
      key: ValueKey('global-search-sale-${sale.name}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          customer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PaymentStatus(status: sale.status),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: colors.outlineVariant),
              const SizedBox(height: 12),
              Wrap(
                spacing: 18,
                runSpacing: 8,
                children: [
                  _Fact(
                    icon: Icons.calendar_today_outlined,
                    label: formatDate(sale.postingDate),
                  ),
                  _Fact(
                    key: ValueKey('global-search-quantity-${sale.name}'),
                    icon: Icons.inventory_2_outlined,
                    label:
                        'ចំនួន ${formatQuantity(sale.totalSaleQuantity)}'
                        '${sale.outletUnit.trim().isEmpty ? '' : ' ${sale.outletUnit.trim()}'}',
                  ),
                  _Fact(
                    icon: Icons.payments_outlined,
                    label: '${formatMoney(sale.totalAmount)} រៀល',
                  ),
                  if (timestamp != null)
                    _Fact(
                      icon: Icons.schedule_rounded,
                      label: formatExactDateTime(timestamp),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    key: key,
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: Theme.of(context).colorScheme.outline),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );
}

class _PaymentStatus extends StatelessWidget {
  const _PaymentStatus({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final (label, color) = switch (normalized) {
      'paid' => ('បានបង់ប្រាក់', const Color(0xFF16803A)),
      'unpaid' => ('មិនទាន់បង់ប្រាក់', Theme.of(context).colorScheme.error),
      'partially paid' ||
      'partly paid' => ('បានបង់ប្រាក់ខ្លះ', const Color(0xFFB45F06)),
      _ => (
        status.trim().isEmpty ? 'បានបិទ' : status.trim(),
        Theme.of(context).colorScheme.primary,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
