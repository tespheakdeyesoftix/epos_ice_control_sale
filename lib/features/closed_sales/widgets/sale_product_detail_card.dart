import 'package:flutter/material.dart';

import '../../../features/sell/sale_product.dart';
import '../../../utils/helpers.dart';

class SaleProductDetailCard extends StatelessWidget {
  const SaleProductDetailCard({
    super.key,
    required this.products,
    required this.canShowPrice,
    required this.currencySymbol,
  });

  final List<SaleProduct> products;
  final bool canShowPrice;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'លម្អិតវិក្កយបត្រ',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${products.length} មុខ',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          if (products.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 36,
                    color: colors.outline,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'មិនមានផលិតផលក្នុងវិក្កយបត្រនេះទេ',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: constraints.maxWidth < 920
                      ? 920
                      : constraints.maxWidth,
                  child: Column(
                    children: [
                      const _ProductHeader(),
                      for (var index = 0; index < products.length; index++)
                        _ProductRow(
                          index: index,
                          product: products[index],
                          shaded: index.isOdd,
                          canShowPrice: canShowPrice,
                          currencySymbol: currencySymbol,
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      color: colors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: const Row(
        children: [
          SizedBox(width: 42, child: Text('#')),
          Expanded(flex: 4, child: Text('ផលិតផល')),
          Expanded(child: Text('ឯកតា')),
          Expanded(child: Text('ចំនួន', textAlign: TextAlign.right)),
          Expanded(child: Text('ថែម/Free', textAlign: TextAlign.right)),
          Expanded(child: Text('សល់មកវិញ', textAlign: TextAlign.right)),
          Expanded(child: Text('បំបែក', textAlign: TextAlign.right)),
          Expanded(child: Text('លក់សរុប', textAlign: TextAlign.right)),

          Expanded(flex: 2, child: Text('តម្លៃ', textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text('សរុប', textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.index,
    required this.product,
    required this.shaded,
    required this.canShowPrice,
    required this.currencySymbol,
  });

  final int index;
  final SaleProduct product;
  final bool shaded;
  final bool canShowPrice;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      color: shaded ? colors.surfaceContainerLow.withValues(alpha: .55) : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(
              '${index + 1}',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName.isEmpty
                      ? product.productCode
                      : product.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (product.note.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.notes_rounded,
                          size: 14,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product.note.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (product.productCode.isNotEmpty)
                  Text(
                    product.productCode,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: Text(product.unit)),
          Expanded(
            child: Text(
              formatQuantity(product.quantity),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              formatQuantity(product.freeQuantity),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              formatQuantity(product.returnQuantity),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              formatQuantity(product.splitQuantity),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              formatQuantity(product.totalSaleQuantity),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              canShowPrice
                  ? formatCurrency(product.price, currencySymbol)
                  : '••••',
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              canShowPrice
                  ? formatCurrency(product.totalAmount, currencySymbol)
                  : '••••',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
