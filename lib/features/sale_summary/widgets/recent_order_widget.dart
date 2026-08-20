import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../../app/app_theme.dart';
import '../../../shared/network_image.dart';
import '../../../utils/helpers.dart';
import '../../closed_sales/closed_sale.dart';

class RecentOrderWidget extends StatelessWidget {
  const RecentOrderWidget({
    super.key,
    required this.orders,
    required this.isLoading,
    this.errorMessage,
    this.onRetry,
    this.onViewAll,
    this.onOrderTap,
    this.onEdit,
    this.imageBaseUri,
  });

  final List<ClosedSale> orders;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onViewAll;
  final ValueChanged<ClosedSale>? onOrderTap;
  final ValueChanged<ClosedSale>? onEdit;
  final Uri? imageBaseUri;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currentDate = DateTime.now();
    final currentDateOrders = orders
        .where((order) => _isSameDate(order.postingDate, currentDate))
        .toList(growable: false);
    return Material(
      key: const ValueKey('recent-closed-sales'),
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            isLoading: isLoading,
            onRefresh: onRetry,
            onViewAll: onViewAll,
          ),
          if (isLoading && currentDateOrders.isEmpty)
            const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (errorMessage != null && currentDateOrders.isEmpty)
            _MessageState(
              icon: Icons.cloud_off_outlined,
              message: errorMessage!,
              actionLabel: 'ព្យាយាមម្ដងទៀត',
              onAction: onRetry,
            )
          else if (currentDateOrders.isEmpty)
            const _MessageState(
              icon: Icons.receipt_long_outlined,
              message: 'មិនមានការលក់ដែលបានបិទទេ',
            )
          else
            for (var index = 0; index < currentDateOrders.length; index++)
              _RecentOrderRow(
                order: currentDateOrders[index],
                imageBaseUri: imageBaseUri,
                showDivider: index < currentDateOrders.length - 1,
                onTap: onOrderTap == null
                    ? null
                    : () => onOrderTap!(currentDateOrders[index]),
                onEdit: onEdit == null
                    ? null
                    : () => onEdit!(currentDateOrders[index]),
              ),
          if (errorMessage != null && currentDateOrders.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                errorMessage!,
                style: TextStyle(color: colors.error, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isLoading,
    required this.onRefresh,
    required this.onViewAll,
  });

  final bool isLoading;
  final VoidCallback? onRefresh;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        children: [
          Icon(Icons.history_rounded, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'ការលក់ដែលបានបិទថ្មីៗ',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'ផ្ទុកឡើងវិញ',
            onPressed: isLoading ? null : onRefresh,
            icon: isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          if (onViewAll != null)
            TextButton(
              key: const ValueKey('view-all-closed-sales'),
              onPressed: onViewAll,
              child: const Text('មើលទាំងអស់'),
            ),
        ],
      ),
    );
  }
}

class _RecentOrderRow extends StatelessWidget {
  const _RecentOrderRow({
    required this.order,
    required this.showDivider,
    required this.imageBaseUri,
    this.onTap,
    this.onEdit,
  });

  final ClosedSale order;
  final bool showDivider;
  final Uri? imageBaseUri;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final imageUrl = _resolveImageUrl(order.customerPhoto, imageBaseUri);
    final customer = order.customerName.trim().isNotEmpty
        ? order.customerName.trim()
        : order.customer.trim().isNotEmpty
        ? order.customer.trim()
        : '-';
    return InkWell(
      key: ValueKey('recent-closed-sale-${order.name}'),
      onTap: onTap,
      splashColor: colors.primary.withValues(alpha: 0.16),
      highlightColor: colors.primary.withValues(alpha: 0.07),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: colors.outlineVariant))
              : null,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox.square(
                dimension: 44,
                child: imageUrl == null
                    ? ColoredBox(
                        color: colors.primaryContainer,
                        child: Icon(
                          Icons.receipt_long_outlined,
                          size: 20,
                          color: colors.onPrimaryContainer,
                        ),
                      )
                    : AppNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 88,
                        memCacheHeight: 88,
                        placeholder: ColoredBox(
                          color: colors.surfaceContainerHighest,
                        ),
                        errorWidget: ColoredBox(
                          color: colors.primaryContainer,
                          child: Icon(
                            Icons.receipt_long_outlined,
                            size: 20,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 7,
                    runSpacing: 5,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        order.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (_isPaymentStatus(order.status))
                        _PaymentStatusChip(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    customer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      formatQuantity(order.totalSaleQuantity),
                      order.outletUnit.trim(),
                    ].where((value) => value.isNotEmpty).join(' '),
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${formatMoney(order.totalAmount)} រៀល',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formatTimeAgo(order.modified ?? order.creation),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  if (onEdit != null) ...[
                    const SizedBox(height: 5),
                    FilledButton.tonalIcon(
                      key: ValueKey('edit-recent-sale-${order.name}'),
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      label: const Text('កែបុង'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: colors.outline),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaymentStatusChip extends StatelessWidget {
  const _PaymentStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final Color color;
    final String label;
    if (normalized == 'paid') {
      color = AppSemanticColors.of(context).success;
      label = 'បានបង់ប្រាក់';
    } else if (normalized == 'unpaid') {
      color = Theme.of(context).colorScheme.error;
      label = 'មិនទាន់បង់ប្រាក់';
    } else {
      color = Colors.orange.shade700;
      label = 'បានបង់ប្រាក់មួយផ្នែក';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

bool _isPaymentStatus(String value) {
  final status = value.trim().toLowerCase();
  return status == 'paid' ||
      status == 'unpaid' ||
      status == 'partially paid' ||
      status == 'partly paid';
}

bool _isSameDate(String postingDate, DateTime date) {
  final parsedDate = DateTime.tryParse(postingDate.trim());
  return parsedDate != null &&
      parsedDate.year == date.year &&
      parsedDate.month == date.month &&
      parsedDate.day == date.day;
}

String? _resolveImageUrl(String value, Uri? baseUri) {
  final photo = value.trim();
  if (photo.isEmpty) return null;
  final uri = Uri.tryParse(photo);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    return uri.toString();
  }
  return baseUri?.resolve(photo).toString();
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 180,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 38, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 10),
          Text(message),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    ),
  );
}

@Preview(name: 'Recent closed sales', size: Size(720, 520))
Widget recentOrderWidgetPreview() => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: RecentOrderWidget(
        isLoading: false,
        onEdit: ignoreRecentSaleEdit,
        orders: [
          ClosedSale(
            name: 'SALE-00010',
            postingDate: '2026-08-20',
            customerName: 'Sample Customer',
            customerPhoto: 'https://picsum.photos/100',
            totalSaleQuantity: 4,
            outletUnit: 'កេស',
            totalAmount: 125000,
            saleStatus: 'Closed',
            status: 'Paid',
            modified: DateTime(2026, 8, 20, 10, 30),
          ),
          ClosedSale(
            name: 'SALE-00009',
            postingDate: '2026-08-20',
            customerName: 'Walk-in Customer',
            totalSaleQuantity: 2,
            outletUnit: 'ដុំ',
            totalAmount: 80000,
            saleStatus: 'Closed',
            status: 'Partially Paid',
            modified: DateTime(2026, 8, 20, 9, 45),
          ),
        ],
      ),
    ),
  ),
);

void ignoreRecentSaleEdit(ClosedSale sale) {}
