import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../services/sale_service.dart';
import '../../../utils/helpers.dart';
import '../payment_type.dart';

enum PaymentDialogAction { payment, paymentAndPrint }

class PaymentDialogResult {
  const PaymentDialogResult({required this.paymentType, required this.action});

  final PaymentType paymentType;
  final PaymentDialogAction action;
}

Future<PaymentDialogResult?> showPaymentDialog(
  BuildContext context, {
  required SaleService service,
  required double totalAmount,
}) => showDialog<PaymentDialogResult>(
  context: context,
  builder: (_) =>
      PaymentDialogWidget(service: service, totalAmount: totalAmount),
);

class PaymentDialogWidget extends StatefulWidget {
  const PaymentDialogWidget({
    super.key,
    required this.service,
    required this.totalAmount,
  });

  final SaleService service;
  final double totalAmount;

  @override
  State<PaymentDialogWidget> createState() => _PaymentDialogWidgetState();
}

class _PaymentDialogWidgetState extends State<PaymentDialogWidget> {
  late Future<List<PaymentType>> _paymentTypesFuture;
  PaymentType? _selected;

  @override
  void initState() {
    super.initState();
    _paymentTypesFuture = widget.service.getPaymentTypes();
  }

  void _retry() {
    setState(() {
      _selected = null;
      _paymentTypesFuture = widget.service.getPaymentTypes();
    });
  }

  void _submit(PaymentDialogAction action) {
    final paymentType = _selected;
    if (paymentType == null || !paymentType.isValid) return;
    Navigator.of(
      context,
    ).pop(PaymentDialogResult(paymentType: paymentType, action: action));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      key: const ValueKey('payment-dialog'),
      insetPadding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 12, 12),
              child: Row(
                children: [
                  Icon(Icons.payments_outlined, color: colors.primary),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'ជ្រើសរើសប្រភេទការទូទាត់',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'បិទ',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'ទឹកប្រាក់ត្រូវទូទាត់',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: colors.onPrimaryContainer,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${formatMoney(widget.totalAmount)} រៀល',
                    key: const ValueKey('payment-total-amount'),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: colors.onPrimaryContainer,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: FutureBuilder<List<PaymentType>>(
                future: _paymentTypesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _PaymentLoadError(onRetry: _retry);
                  }
                  final paymentTypes = snapshot.data ?? const <PaymentType>[];
                  if (paymentTypes.isEmpty) {
                    return const Center(child: Text('មិនមានប្រភេទការទូទាត់'));
                  }
                  return RadioGroup<PaymentType>(
                    groupValue: _selected,
                    onChanged: (value) => setState(() => _selected = value),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: paymentTypes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final paymentType = paymentTypes[index];
                        final inputAmount = paymentType.isValid
                            ? widget.totalAmount / paymentType.exchangeRate
                            : 0;
                        return Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          color: colors.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: colors.outlineVariant),
                          ),
                          child: RadioListTile<PaymentType>(
                            key: ValueKey('payment-type-${paymentType.name}'),
                            value: paymentType,
                            enabled: paymentType.isValid,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 16,
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _fallback(paymentType.name),
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (paymentType.isValid) ...[
                                  const SizedBox(width: 16),
                                  Text(
                                    '${formatQuantity(inputAmount)} ${paymentType.currency}',
                                    key: ValueKey(
                                      'payment-type-amount-${paymentType.name}',
                                    ),
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      color: colors.primary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: paymentType.isValid
                                ? Text(
                                    '${paymentType.currency} • '
                                    '1 ${paymentType.currency} = '
                                    '${formatQuantity(paymentType.exchangeRate)} រៀល',
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 15,
                                      height: 1.5,
                                    ),
                                  )
                                : const Text('ទិន្នន័យការទូទាត់មិនត្រឹមត្រូវ'),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(120, 58),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      textStyle: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('បោះបង់'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    key: const ValueKey('confirm-payment'),
                    onPressed: _selected == null
                        ? null
                        : () => _submit(PaymentDialogAction.payment),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(150, 58),
                      padding: const EdgeInsets.symmetric(horizontal: 26),
                      textStyle: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('ទូទាត់'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    key: const ValueKey('confirm-payment-and-print'),
                    onPressed: _selected == null
                        ? null
                        : () => _submit(PaymentDialogAction.paymentAndPrint),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(260, 58),
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      textStyle: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('ទូទាត់ និងបោះពុម្ពវិក្កយបត្រ'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentLoadError extends StatelessWidget {
  const _PaymentLoadError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('មិនអាចទាញយកប្រភេទការទូទាត់បានទេ'),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('ព្យាយាមម្តងទៀត'),
        ),
      ],
    ),
  );
}

String _fallback(String value) => value.trim().isEmpty ? '-' : value.trim();
