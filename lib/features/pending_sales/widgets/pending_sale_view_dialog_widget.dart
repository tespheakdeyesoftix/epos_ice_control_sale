import 'package:flutter/material.dart';

import '../../../services/sale_service.dart';
import '../../../utils/helpers.dart';
import '../../sell/sale.dart';

Future<void> showPendingSaleViewDialog(
  BuildContext context, {
  required SaleService saleService,
  required String name,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) =>
        PendingSaleViewDialogWidget(saleService: saleService, name: name),
  );
}

class PendingSaleViewDialogWidget extends StatefulWidget {
  const PendingSaleViewDialogWidget({
    super.key,
    required this.saleService,
    required this.name,
  });

  final SaleService saleService;
  final String name;

  @override
  State<PendingSaleViewDialogWidget> createState() =>
      _PendingSaleViewDialogWidgetState();
}

class _PendingSaleViewDialogWidgetState
    extends State<PendingSaleViewDialogWidget> {
  late Future<Sale> _saleFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _saleFuture = widget.saleService.getSale(widget.name);
  }

  void _retry() => setState(_load);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      key: const ValueKey('pending-sale-view-dialog'),
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: 900,
        height: 650,
        child: Column(
          children: [
            Container(
              height: 58,
              padding: const EdgeInsets.only(left: 20),
              color: colors.inverseSurface,
              child: Row(
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    color: colors.onInverseSurface,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'មើលបុងលក់ ${widget.name}',
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
                    key: const ValueKey('refresh-pending-sale-view'),
                    tooltip: 'ផ្ទុកឡើងវិញ',
                    onPressed: _retry,
                    color: colors.onInverseSurface,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                  SizedBox(
                    width: 58,
                    height: 58,
                    child: IconButton(
                      key: const ValueKey('close-pending-sale-view'),
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
            Expanded(
              child: FutureBuilder<Sale>(
                future: _saleFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_off_outlined,
                            color: colors.onSurfaceVariant,
                            size: 44,
                          ),
                          const SizedBox(height: 12),
                          const Text('មិនអាចទាញយកព័ត៌មានបុងលក់បានទេ។'),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('ព្យាយាមម្ដងទៀត'),
                          ),
                        ],
                      ),
                    );
                  }
                  return _SaleDetails(sale: snapshot.data!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleDetails extends StatelessWidget {
  const _SaleDetails({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          child: Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              _Info(label: 'កាលបរិច្ឆេទ', value: _date(sale.postingDate)),
              _Info(
                label: 'អតិថិជន',
                value: _party(sale.customer, sale.customerName),
              ),
              _Info(
                label: 'អ្នកបើកបរ',
                value: _party(sale.driver, sale.driverName),
              ),
              _Info(label: 'ស្លាកលេខឡាន', value: _fallback(sale.plateNumber)),
              _Info(label: 'លេខយោង', value: _fallback(sale.referenceNumber)),
            ],
          ),
        ),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          color: colors.surfaceContainer,
          child: const Row(
            children: [
              _Header('ទំនិញ', flex: 34),
              _Header('ចំនួន', flex: 14, align: TextAlign.right),
              _Header('តម្លៃ', flex: 18, align: TextAlign.right),
              _Header('ឯកតា', flex: 14),
              _Header('សរុប', flex: 20, align: TextAlign.right),
            ],
          ),
        ),
        Expanded(
          child: sale.saleProducts.isEmpty
              ? Center(
                  child: Text(
                    'មិនមានទំនិញក្នុងបុងនេះទេ។',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                )
              : ListView.separated(
                  itemCount: sale.saleProducts.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: colors.outlineVariant),
                  itemBuilder: (context, index) {
                    final item = sale.saleProducts[index];
                    return Container(
                      key: ValueKey('pending-sale-product-${item.productCode}'),
                      constraints: const BoxConstraints(minHeight: 52),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 9,
                      ),
                      color: index.isOdd
                          ? colors.surfaceContainerLow
                          : colors.surface,
                      child: Row(
                        children: [
                          _Cell(
                            '${item.productCode} - ${item.productName}',
                            flex: 34,
                            emphasized: true,
                          ),
                          _Cell(
                            formatQuantity(item.totalSaleQuantity),
                            flex: 14,
                            align: TextAlign.right,
                          ),
                          _Cell(
                            formatMoney(item.price),
                            flex: 18,
                            align: TextAlign.right,
                          ),
                          _Cell(_fallback(item.unit), flex: 14),
                          _Cell(
                            formatMoney(item.totalAmount),
                            flex: 20,
                            align: TextAlign.right,
                            emphasized: true,
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.45),
            border: Border(top: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            children: [
              Text(
                'ចំនួនសរុប: ${formatQuantity(sale.totalSaleQuantity)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                'ទឹកប្រាក់សរុប: ${formatMoney(sale.totalAmount)} រៀល',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 245,
    child: Row(
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
        Expanded(
          child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header(this.text, {required this.flex, this.align});

  final String text;
  final int flex;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Text(
      text,
      textAlign: align,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
  );
}

class _Cell extends StatelessWidget {
  const _Cell(
    this.text, {
    required this.flex,
    this.align,
    this.emphasized = false,
  });

  final String text;
  final int flex;
  final TextAlign? align;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: align,
      style: TextStyle(fontWeight: emphasized ? FontWeight.w700 : null),
    ),
  );
}

String _fallback(String value) => value.trim().isEmpty ? '-' : value.trim();

String _party(String code, String name) {
  if (code.trim().isEmpty) return _fallback(name);
  if (name.trim().isEmpty) return code.trim();
  return '${code.trim()} - ${name.trim()}';
}

String _date(DateTime? date) {
  if (date == null) return '-';
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day / $month / ${date.year}';
}
