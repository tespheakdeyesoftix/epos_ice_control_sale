import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../utils/helpers.dart';
import '../product.dart';

Future<Product?> showSelectProductUnitDialog(
  BuildContext context, {
  required Product product,
  bool showPrices = true,
}) {
  return showDialog<Product>(
    context: context,
    builder: (_) =>
        SelectProductUnitDialogWidget(product: product, showPrices: showPrices),
  );
}

class SelectProductUnitDialogWidget extends StatelessWidget {
  const SelectProductUnitDialogWidget({
    super.key,
    required this.product,
    this.showPrices = true,
  });

  final Product product;
  final bool showPrices;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      key: const ValueKey('select-product-unit-dialog'),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 12, 10),
      contentPadding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
      title: Row(
        children: [
          Expanded(
            child: Text(
              'Select product unit',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            key: const ValueKey('close-product-unit-dialog'),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        height: math.min(product.productUnits.length * 92.0, 480),
        child: ListView.separated(
          itemCount: product.productUnits.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final productUnit = product.productUnits[index];
            return Material(
              color: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colors.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: ValueKey('select-product-unit-${productUnit.unit}'),
                onTap: () =>
                    Navigator.of(context).pop(product.forUnit(productUnit)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: colors.primaryContainer,
                        foregroundColor: colors.onPrimaryContainer,
                        child: const Icon(Icons.scale_outlined),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              productUnit.unit,
                              key: ValueKey(
                                'product-unit-name-${productUnit.unit}',
                              ),
                              style: TextStyle(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        showPrices
                            ? '${formatMoney(productUnit.price)} រៀល'
                            : '***',
                        key: ValueKey('product-unit-price-${productUnit.unit}'),
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
