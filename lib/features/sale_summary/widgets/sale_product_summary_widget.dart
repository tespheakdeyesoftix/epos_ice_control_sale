import 'package:flutter/material.dart';

import '../../../services/sale_service.dart';
import '../../../utils/helpers.dart';

class SaleProductSummaryWidget extends StatelessWidget {
  const SaleProductSummaryWidget({
    super.key,
    required this.products,
    required this.isLoading,
    this.errorMessage,
  });

  final List<DailySaleProductSummary> products;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      key: const ValueKey('daily-sale-product-summary'),
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'សង្ខេបការលក់តាមទំនិញប្រចាំថ្ងៃ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading && products.isEmpty)
            const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (errorMessage != null && products.isEmpty)
            _MessageState(
              icon: Icons.cloud_off_outlined,
              message: errorMessage!,
            )
          else if (products.isEmpty)
            const _MessageState(
              icon: Icons.inventory_2_outlined,
              message: 'មិនមានទំនិញលក់នៅថ្ងៃនេះទេ',
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowColor: WidgetStatePropertyAll(
                        colors.surfaceContainerHighest,
                      ),
                      headingTextStyle: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                      dataTextStyle: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(fontSize: 16),
                      headingRowHeight: 60,
                      dataRowMinHeight: 56,
                      dataRowMaxHeight: 64,
                      columnSpacing: 24,
                      horizontalMargin: 20,
                      columns: const [
                        DataColumn(label: Text('ល.រ')),
                        DataColumn(label: Text('ទំនិញ')),
                        DataColumn(label: Text('ឯកតា')),
                        DataColumn(label: Text('ចំនួន'), numeric: true),
                        DataColumn(label: Text('ថែម'), numeric: true),
                        DataColumn(label: Text('សល់មកវិញ'), numeric: true),
                        DataColumn(label: Text('បំបែក'), numeric: true),
                        DataColumn(label: Text('សរុបលក់'), numeric: true),
                        DataColumn(label: Text('ទឹកប្រាក់'), numeric: true),
                      ],
                      rows: [
                        for (var index = 0; index < products.length; index++)
                          _buildRow(index, products[index]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (errorMessage != null && products.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                errorMessage!,
                style: TextStyle(color: colors.error, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  DataRow _buildRow(int index, DailySaleProductSummary product) {
    final name = product.productName.isNotEmpty
        ? product.productName
        : product.productCode;
    return DataRow(
      key: ValueKey('daily-sale-product-${product.productCode}-$index'),
      cells: [
        DataCell(Text('${index + 1}')),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 180, maxWidth: 280),
            child: Text(name.isEmpty ? '-' : name),
          ),
        ),
        DataCell(Text(product.unit.isEmpty ? '-' : product.unit)),
        DataCell(Text(formatQuantity(product.quantity))),
        DataCell(Text(formatQuantity(product.freeQuantity))),
        DataCell(Text(formatQuantity(product.returnQuantity))),
        DataCell(Text(formatQuantity(product.splitQuantity))),
        DataCell(
          Text(
            formatQuantity(product.totalSaleQuantity),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        DataCell(
          Text(
            '${formatMoney(product.totalAmount)} រៀល',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.message});

  final IconData icon;
  final String message;

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
        ],
      ),
    ),
  );
}
