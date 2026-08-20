import 'package:flutter/material.dart';

import '../features/pending_sales/widgets/pending_sale_view_dialog_widget.dart';
import '../features/sell/widgets/pending_order_list_dialog_widget.dart';
import '../services/sale_service.dart';
import '../utils/helpers.dart';

class PendingOrderWarningLauncher extends StatefulWidget {
  const PendingOrderWarningLauncher({
    super.key,
    required this.saleService,
    required this.outlet,
    required this.onEdit,
  });

  final SaleService saleService;
  final String outlet;
  final ValueChanged<String> onEdit;

  @override
  State<PendingOrderWarningLauncher> createState() =>
      _PendingOrderWarningLauncherState();
}

class _PendingOrderWarningLauncherState
    extends State<PendingOrderWarningLauncher> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPendingOrders());
  }

  Future<void> _checkPendingOrders() async {
    if (_checked || widget.outlet.trim().isEmpty) return;
    _checked = true;
    try {
      final info = await widget.saleService.getMaxPendingOrderDate(
        widget.outlet,
      );
      if (!mounted || !info.shouldWarn()) return;
      final viewPendingOrders = await showWarningPendingOrderDialog(
        context,
        info: info,
      );
      if (!mounted || !viewPendingOrders) return;
      await showPendingOrderListDialog(
        context,
        saleService: widget.saleService,
        outlet: widget.outlet,
        onView: (name) => showPendingSaleViewDialog(
          context,
          saleService: widget.saleService,
          name: name,
        ),
        onEdit: widget.onEdit,
      );
    } on Exception {
      // A warning check must never interrupt the authenticated app startup.
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

Future<bool> showWarningPendingOrderDialog(
  BuildContext context, {
  required PendingOrderWarningInfo info,
}) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => WarningPendingOrderWidget(info: info),
      ) ??
      false;
}

class WarningPendingOrderWidget extends StatelessWidget {
  const WarningPendingOrderWidget({super.key, required this.info});

  final PendingOrderWarningInfo info;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pendingDate = info.pendingDate;
    return Dialog(
      key: const ValueKey('warning-pending-order-dialog'),
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 570),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: colors.errorContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: colors.onErrorContainer,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ការព្រមាន៖ មានបុងរង់ចាំយូរ',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 5),
                        Tooltip(
                          message: formatExactDateTime(pendingDate),
                          child: Text(
                            pendingDate == null
                                ? 'មានបុងរងចាំដែលមិនទាន់បានបិទ។'
                                : 'បុងរង់យូជាងគេបំផុតត្រូវបានដាក់រង់ចាំ ${formatTimeAgo(pendingDate)}។',
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    key: const ValueKey('close-pending-order-warning'),
                    tooltip: 'បិទ',
                    onPressed: () => Navigator.of(context).pop(false),
                    style: IconButton.styleFrom(
                      foregroundColor: colors.onSurfaceVariant,
                      backgroundColor: colors.surfaceContainerHighest,
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.errorContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'ការដាក់បុងរង់ចាំគឺសម្រាប់រក្សាទុកបណ្ដោះអាសន្នក្នុងរយៈពេលខ្លីប៉ុណ្ណោះ មិនមែនសម្រាប់ទុករយៈពេលយូរទេ។ សូមព្យាយាមពិនិត្យ និងបិទការលក់ទាំងនេះឱ្យបានឆាប់បំផុត។',
                  key: const ValueKey('pending-order-warning-message'),
                  style: TextStyle(
                    color: colors.onErrorContainer,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _WarningInfoCard(
                      label: 'ចំនួនបុងរង់ចាំ',
                      value: '${info.totalPendingOrder}',
                      valueKey: const ValueKey('warning-pending-order-count'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _WarningInfoCard(
                      label: 'ទឹកប្រាក់សរុប',
                      value: '${formatMoney(info.pendingOrderAmount)} រៀល',
                      valueKey: const ValueKey('warning-pending-order-amount'),
                    ),
                  ),
                ],
              ),
              if (pendingDate != null) ...[
                const SizedBox(height: 12),
                _WarningInfoCard(
                  label: 'កាលបរិច្ឆេទបុងរង់ចាំយូបំផុត',
                  value: _formatDateTime(pendingDate),
                  valueKey: const ValueKey('warning-pending-order-date'),
                ),
              ],
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: const ValueKey('dismiss-pending-order-warning'),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('បិទ'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    key: const ValueKey('view-pending-orders-warning'),
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.pending_actions_rounded),
                    label: const Text('មើលបញ្ជីបុងរង់ចាំ'),
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

class _WarningInfoCard extends StatelessWidget {
  const _WarningInfoCard({
    required this.label,
    required this.value,
    required this.valueKey,
  });

  final String label;
  final String value;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            key: valueKey,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final local = value.isUtc ? value.toLocal() : value;
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final period = local.hour < 12 ? 'ព្រឹក' : 'ល្ងាច';
  return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
      '${twoDigits(hour)}:${twoDigits(local.minute)} $period';
}
