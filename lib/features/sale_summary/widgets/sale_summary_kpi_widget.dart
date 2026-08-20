import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../../app/app_theme.dart';
import '../../../services/sale_service.dart';
import '../../../utils/helpers.dart';

class SaleSummaryKpiWidget extends StatelessWidget {
  const SaleSummaryKpiWidget({
    super.key,
    required this.summary,
    required this.isLoading,
    this.errorMessage,
    this.onRetry,
    this.onSalesTap,
    this.onPendingTap,
  });

  final DailySaleSummary? summary;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onSalesTap;
  final VoidCallback? onPendingTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading && summary == null) return const _LoadingKpis();
    if (errorMessage != null && summary == null) {
      return _KpiError(message: errorMessage!, onRetry: onRetry);
    }
    final data =
        summary ??
        const DailySaleSummary(
          totalOrder: 0,
          totalAmount: 0,
          totalQuantity: 0,
          totalPendingOrder: 0,
          totalPendingAmount: 0,
          totalPendingQuantity: 0,
          totalDeletedOrder: 0,
          totalDeletedAmount: 0,
          totalDeletedQuantity: 0,
          defaultUnit: '',
        );
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final sales = _SalesKpiCard(
          summary: data,
          isRefreshing: isLoading,
          onTap: onSalesTap,
        );
        final pending = _PendingKpiCard(summary: data, onTap: onPendingTap);
        final deleted = _DeletedKpiCard(summary: data);
        return wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: sales),
                  const SizedBox(width: 16),
                  Expanded(child: pending),
                  const SizedBox(width: 16),
                  Expanded(child: deleted),
                ],
              )
            : Column(
                children: [
                  sales,
                  const SizedBox(height: 14),
                  pending,
                  const SizedBox(height: 14),
                  deleted,
                ],
              );
      },
    );
  }
}

class _SalesKpiCard extends StatelessWidget {
  const _SalesKpiCard({
    required this.summary,
    required this.isRefreshing,
    required this.onTap,
  });
  final DailySaleSummary summary;
  final bool isRefreshing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final success = AppSemanticColors.of(context).success;
    return Material(
      key: const ValueKey('daily-sales-kpi'),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: success.withValues(alpha: 0.16),
        highlightColor: success.withValues(alpha: 0.07),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 150),
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconBadge(icon: Icons.trending_up_rounded, color: success),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ការលក់ប្រចាំថ្ងៃ',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (isRefreshing)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: success,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  '${formatMoney(summary.totalAmount)} រៀល',
                  key: const ValueKey('daily-sale-amount'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _KpiMetric(
                      key: const ValueKey('daily-sale-orders'),
                      icon: Icons.receipt_long_outlined,
                      value: '${summary.totalOrder} បុង',
                      color: success,
                    ),
                    _KpiMetric(
                      key: const ValueKey('daily-sale-quantity'),
                      icon: Icons.inventory_2_outlined,
                      value: _quantityWithUnit(
                        summary.totalQuantity,
                        summary.defaultUnit,
                      ),
                      color: success,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingKpiCard extends StatelessWidget {
  const _PendingKpiCard({required this.summary, required this.onTap});
  final DailySaleSummary summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = colors.tertiary;
    return Material(
      key: const ValueKey('pending-orders-kpi'),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: accent.withValues(alpha: 0.16),
        highlightColor: accent.withValues(alpha: 0.07),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 150),
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.tertiaryContainer.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.tertiary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconBadge(
                      icon: Icons.pending_actions_rounded,
                      color: accent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ការលក់កំពុងរង់ចាំ',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  '${formatMoney(summary.totalPendingAmount)} រៀល',
                  key: const ValueKey('daily-pending-amount'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _KpiMetric(
                      key: const ValueKey('daily-pending-orders'),
                      icon: Icons.receipt_long_outlined,
                      value: '${summary.totalPendingOrder} បុង',
                      color: accent,
                    ),
                    _KpiMetric(
                      key: const ValueKey('daily-pending-quantity'),
                      icon: Icons.inventory_2_outlined,
                      value: _quantityWithUnit(
                        summary.totalPendingQuantity,
                        summary.defaultUnit,
                      ),
                      color: accent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeletedKpiCard extends StatelessWidget {
  const _DeletedKpiCard({required this.summary});

  final DailySaleSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = colors.error;
    return Container(
      key: const ValueKey('deleted-orders-kpi'),
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(icon: Icons.delete_outline_rounded, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ការលក់ដែលបានលុប',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${formatMoney(summary.totalDeletedAmount)} រៀល',
            key: const ValueKey('daily-deleted-amount'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _KpiMetric(
                key: const ValueKey('daily-deleted-orders'),
                icon: Icons.receipt_long_outlined,
                value: '${summary.totalDeletedOrder} បុង',
                color: accent,
              ),
              _KpiMetric(
                key: const ValueKey('daily-deleted-quantity'),
                icon: Icons.inventory_2_outlined,
                value: _quantityWithUnit(
                  summary.totalDeletedQuantity,
                  summary.defaultUnit,
                ),
                color: accent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiMetric extends StatelessWidget {
  const _KpiMetric({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 17, color: color),
      const SizedBox(width: 6),
      Text(
        value,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

String _quantityWithUnit(double quantity, String unit) {
  return [
    formatQuantity(quantity),
    unit.trim(),
  ].where((value) => value.isNotEmpty).join(' ');
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, color: color, size: 21),
  );
}

class _LoadingKpis extends StatelessWidget {
  const _LoadingKpis();

  @override
  Widget build(BuildContext context) => Container(
    height: 190,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: const CircularProgressIndicator(),
  );
}

class _KpiError extends StatelessWidget {
  const _KpiError({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Icon(
          Icons.cloud_off_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('ព្យាយាមម្ដងទៀត')),
      ],
    ),
  );
}

@Preview(name: 'Sale summary KPIs', size: Size(1100, 260))
Widget saleSummaryKpiWidgetPreview() => MaterialApp(
  theme: AppTheme.light,
  home: const Scaffold(
    body: Padding(
      padding: EdgeInsets.all(24),
      child: SaleSummaryKpiWidget(
        summary: DailySaleSummary(
          totalOrder: 12,
          totalAmount: 6300000,
          totalQuantity: 120,
          totalPendingOrder: 3,
          totalPendingAmount: 1470000,
          totalPendingQuantity: 24,
          totalDeletedOrder: 2,
          totalDeletedAmount: 320000,
          totalDeletedQuantity: 8,
          defaultUnit: 'កេស',
        ),
        isLoading: false,
      ),
    ),
  ),
);
