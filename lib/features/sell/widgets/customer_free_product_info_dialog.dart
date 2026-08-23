import 'package:flutter/material.dart';

import '../../../utils/helpers.dart';
import '../customer_free_product.dart';

Future<void> showCustomerFreeProductInfoDialog(
  BuildContext context, {
  required List<FreeProductEvaluation> evaluations,
}) {
  if (evaluations.isEmpty) return Future.value();
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const ValueKey('customer-free-product-info-dialog'),
      icon: const Icon(Icons.card_giftcard_rounded),
      title: const Text('ព័ត៌មានទំនិញថែម'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: ListBody(
            children: [
              for (var index = 0; index < evaluations.length; index++) ...[
                if (index > 0) const Divider(height: 24),
                Builder(
                  builder: (context) {
                    final evaluation = evaluations[index];
                    final freeQuantity = formatQuantity(
                      evaluation.configuredFreeQuantity,
                    );
                    final orderQuantity = formatQuantity(
                      evaluation.orderQuantity,
                    );
                    final message = evaluation.wasApplied
                        ? '«${evaluation.productName}» បានថែម $freeQuantity ${evaluation.unit}។'
                        : '«${evaluation.productName}» មានទំនិញថែម $freeQuantity ${evaluation.unit} '
                              'ប៉ុន្តែចំនួនទិញ $orderQuantity ${evaluation.unit} តិចជាងចំនួនថែម '
                              'ដូច្នេះមិនបានអនុវត្តទេ។';
                    return Row(
                      key: ValueKey(
                        'customer-free-product-${evaluation.productCode}-${evaluation.unit}',
                      ),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          evaluation.wasApplied
                              ? Icons.check_circle_outline_rounded
                              : Icons.info_outline_rounded,
                          color: evaluation.wasApplied
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.tertiary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(message)),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          key: const ValueKey('close-customer-free-product-info'),
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('យល់ព្រម'),
        ),
      ],
    ),
  );
}
