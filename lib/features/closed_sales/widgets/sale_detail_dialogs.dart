import 'package:flutter/material.dart';

import '../../../utils/helpers.dart';

Future<String?> showEditSaleCommentDialog(
  BuildContext context, {
  required String initialComment,
}) {
  final textController = TextEditingController(text: initialComment);
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.mode_comment_outlined),
      title: const Text('កែប្រែមតិយោបល់'),
      content: SizedBox(
        width: 500,
        child: TextField(
          key: const ValueKey('edit-sale-comment-input'),
          controller: textController,
          autofocus: true,
          minLines: 3,
          maxLines: 7,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'មតិយោបល់',
            hintText: 'សរសេរមតិយោបល់...',
            alignLabelWithHint: true,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('បោះបង់'),
        ),
        FilledButton.icon(
          onPressed: () {
            final value = textController.text.trim();
            if (value.isNotEmpty) Navigator.pop(dialogContext, value);
          },
          icon: const Icon(Icons.save_outlined),
          label: const Text('រក្សាទុក'),
        ),
      ],
    ),
  ).whenComplete(textController.dispose);
}

Future<void> showPaymentHistoryDialog(
  BuildContext context, {
  required List<Map<String, dynamic>> payments,
  required double totalPayment,
  required bool canShowPrice,
  required String currencySymbol,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final colors = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        icon: const Icon(Icons.payments_outlined),
        title: const Text('ប្រវត្តិការទូទាត់'),
        content: SizedBox(
          width: 560,
          child: payments.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 34),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 34,
                        color: colors.outline,
                      ),
                      const SizedBox(height: 10),
                      const Text('មិនមានប្រវត្តិការទូទាត់លម្អិតទេ'),
                      const SizedBox(height: 4),
                      Text(
                        'បានទូទាត់សរុប: ${canShowPrice ? formatCurrency(totalPayment, currencySymbol) : '••••'}',
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: payments.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    final method = _firstText(payment, const [
                      'payment_type',
                      'mode_of_payment',
                      'payment_method',
                      'type',
                    ]);
                    final amount = _firstNumber(payment, const [
                      'amount',
                      'paid_amount',
                      'payment_amount',
                    ]);
                    final date = _firstText(payment, const [
                      'posting_date',
                      'payment_date',
                      'creation',
                    ]);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: CircleAvatar(
                        backgroundColor: colors.primary.withValues(alpha: .1),
                        child: Icon(
                          Icons.payments_outlined,
                          color: colors.primary,
                        ),
                      ),
                      title: Text(
                        method.isEmpty ? 'ការទូទាត់ទី ${index + 1}' : method,
                      ),
                      subtitle: Text(formatDate(date)),
                      trailing: Text(
                        canShowPrice
                            ? formatCurrency(amount, currencySymbol)
                            : '••••',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('បិទ'),
          ),
        ],
      );
    },
  );
}

String _firstText(Map<String, dynamic> row, List<String> keys) {
  for (final key in keys) {
    final value = textValue(row[key]);
    if (value.isNotEmpty) return value;
  }
  return '';
}

double _firstNumber(Map<String, dynamic> row, List<String> keys) {
  for (final key in keys) {
    if (row[key] != null) return toDoubleValue(row[key]);
  }
  return 0;
}
