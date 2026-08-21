import 'package:flutter/material.dart';

import '../../../utils/helpers.dart';
import '../../closed_sales/closed_sale.dart';

class SaleSearchResultCard extends StatelessWidget {
  const SaleSearchResultCard({
    super.key,
    required this.sale,
    required this.onTap,
    this.onEdit,
    this.isEditing = false,
  });

  final ClosedSale sale;
  final VoidCallback onTap;
  final Future<void> Function()? onEdit;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final customerName = sale.customerName.trim();
    final customerCode = sale.customer.trim();
    final customer = [
      if (customerName.isNotEmpty) customerName,
      if (customerCode.isNotEmpty && customerCode != customerName) customerCode,
    ].join(' · ');
    final driverName = sale.driverName.trim().isNotEmpty
        ? sale.driverName.trim()
        : sale.driver.trim();
    final plateNumber = sale.plateNumber.trim();
    final referenceNumber = sale.referenceNumber.trim();
    final driver = [
      if (driverName.isNotEmpty) driverName,
      if (plateNumber.isNotEmpty) plateNumber,
    ].join(' · ');
    return Card(
      key: ValueKey('global-search-sale-${sale.name}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      size: 19,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          customer.isEmpty ? '-' : customer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${formatMoney(sale.totalAmount)} រៀល',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      _PaymentStatus(status: sale.status),
                    ],
                  ),
                ],
              ),
              if (driver.isNotEmpty || referenceNumber.isNotEmpty) ...[
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (driver.isNotEmpty) ...[
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 13,
                        color: colors.outline,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          driver,
                          key: ValueKey('global-search-driver-${sale.name}'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ] else
                      const Spacer(),
                    if (referenceNumber.isNotEmpty) ...[
                      if (driver.isNotEmpty) const SizedBox(width: 8),
                      Icon(Icons.tag_rounded, size: 13, color: colors.outline),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          'Ref: $referenceNumber',
                          key: ValueKey('global-search-reference-${sale.name}'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 3,
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
                      ],
                    ),
                  ),
                  if (onEdit != null) ...[
                    const SizedBox(width: 6),
                    FilledButton.tonalIcon(
                      key: ValueKey('edit-global-search-sale-${sale.name}'),
                      onPressed: isEditing ? null : onEdit,
                      icon: isEditing
                          ? const SizedBox.square(
                              dimension: 13,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.edit_outlined, size: 14),
                      label: const Text('កែបុង'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 28),
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
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
      Icon(icon, size: 14, color: Theme.of(context).colorScheme.outline),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10.5)),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
