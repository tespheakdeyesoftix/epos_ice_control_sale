import 'package:flutter/material.dart';

import '../../../utils/helpers.dart';

typedef SalePaymentHistoryLoader =
    Future<List<Map<String, dynamic>>> Function({bool force});

Future<void> showSalePaymentHistoryDialog(
  BuildContext context, {
  required SalePaymentHistoryLoader loadHistory,
  required String saleName,
  required bool canShowPrice,
  required String currencySymbol,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => SalePaymentHistoryDialogWidget(
      loadHistory: loadHistory,
      saleName: saleName,
      canShowPrice: canShowPrice,
      currencySymbol: currencySymbol,
    ),
  );
}

class SalePaymentHistoryDialogWidget extends StatefulWidget {
  const SalePaymentHistoryDialogWidget({
    super.key,
    required this.loadHistory,
    required this.saleName,
    required this.canShowPrice,
    required this.currencySymbol,
  });

  final SalePaymentHistoryLoader loadHistory;
  final String saleName;
  final bool canShowPrice;
  final String currencySymbol;

  @override
  State<SalePaymentHistoryDialogWidget> createState() =>
      _SalePaymentHistoryDialogWidgetState();
}

class _SalePaymentHistoryDialogWidgetState
    extends State<SalePaymentHistoryDialogWidget> {
  List<Map<String, dynamic>> _rows = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final rows = await widget.loadHistory(force: force);
      if (!mounted) return;
      setState(() => _rows = rows);
    } on Exception {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'មិនអាចទាញយកប្រវត្តិការទូទាត់បានទេ។';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _money(Object? value) {
    if (!widget.canShowPrice) return '••••';
    return formatCurrency(toDoubleValue(value), widget.currencySymbol);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      key: const ValueKey('sale-payment-history-dialog'),
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: 1240,
        height: 620,
        child: Column(
          children: [
            Container(
              height: 58,
              padding: const EdgeInsets.only(left: 20),
              color: colors.inverseSurface,
              child: Row(
                children: [
                  Icon(Icons.payments_outlined, color: colors.onInverseSurface),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ប្រវត្តិការទូទាត់ · ${widget.saleName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onInverseSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'ផ្ទុកឡើងវិញ',
                    onPressed: _isLoading ? null : () => _load(force: true),
                    color: colors.onInverseSurface,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 58,
                    height: 58,
                    child: IconButton(
                      key: const ValueKey('close-sale-payment-history'),
                      tooltip: 'បិទ',
                      onPressed: () => Navigator.of(context).pop(),
                      color: colors.onError,
                      style: IconButton.styleFrom(
                        backgroundColor: colors.error,
                        shape: const RoundedRectangleBorder(),
                      ),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const _PaymentHistoryTableHeader(),
            Expanded(child: _buildBody(colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme colors) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 38, color: colors.error),
            const SizedBox(height: 10),
            Text(_errorMessage!),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _load(force: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('ព្យាយាមម្ដងទៀត'),
            ),
          ],
        ),
      );
    }
    if (_rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 40, color: colors.outline),
            const SizedBox(height: 10),
            Text(
              'មិនមានប្រវត្តិការទូទាត់ទេ។',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: _rows.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, color: colors.outlineVariant),
      itemBuilder: (context, index) =>
          _PaymentHistoryRow(index: index, row: _rows[index], money: _money),
    );
  }
}

class _PaymentHistoryTableHeader extends StatelessWidget {
  const _PaymentHistoryTableHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      color: colors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: const Row(
        children: [
          SizedBox(width: 38, child: Text('#')),
          Expanded(flex: 2, child: Text('ឯកសារ / កាលបរិច្ឆេទ')),
          Expanded(flex: 2, child: Text('ប្រភេទការទូទាត់')),
          Expanded(child: Text('សរុប / បានទូទាត់', textAlign: TextAlign.right)),
          Expanded(child: Text('ទឹកប្រាក់ទូទាត់', textAlign: TextAlign.right)),
          Expanded(child: Text('កាត់ចោល', textAlign: TextAlign.right)),
          Expanded(
            child: Text('សមតុល្យមុន / នៅសល់', textAlign: TextAlign.right),
          ),
          Expanded(flex: 2, child: Text('កំណត់ចំណាំ')),
          Expanded(flex: 2, child: Text('អ្នកបង្កើត / កាលបរិច្ឆេទ')),
        ],
      ),
    );
  }
}

class _PaymentHistoryRow extends StatelessWidget {
  const _PaymentHistoryRow({
    required this.index,
    required this.row,
    required this.money,
  });

  final int index;
  final Map<String, dynamic> row;
  final String Function(Object? value) money;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final note = textValue(row['note']);
    final createdBy = textValue(row['created_by']);
    final creation = DateTime.tryParse(textValue(row['creation']));
    return Container(
      color: index.isOdd
          ? colors.surfaceContainerLow.withValues(alpha: .55)
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 38, child: Text('${index + 1}')),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  textValue(row['name']),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  formatDate(textValue(row['posting_date'])),
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(textValue(row['payment_type']))),
          Expanded(
            child: _MoneyPair(
              primary: money(row['total_amount']),
              secondary: money(row['paid_amount']),
            ),
          ),
          Expanded(
            child: Text(
              money(row['payment_amount']),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: Text(
              money(row['write_off_amount']),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: _MoneyPair(
              primary: money(row['sale_balance']),
              secondary: money(row['balance']),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              note.isEmpty ? '-' : note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  createdBy.isEmpty ? '-' : createdBy,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Tooltip(
                  message: formatExactDateTime(creation),
                  child: Text(
                    formatTimeAgo(creation),
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyPair extends StatelessWidget {
  const _MoneyPair({required this.primary, required this.secondary});

  final String primary;
  final String secondary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(primary, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(
          secondary,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
        ),
      ],
    );
  }
}
