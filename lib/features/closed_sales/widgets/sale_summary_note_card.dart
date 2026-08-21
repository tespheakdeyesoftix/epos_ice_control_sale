import 'package:flutter/material.dart';

import '../../../features/sell/sale.dart';
import '../../../utils/helpers.dart';

class SaleSummaryNoteCard extends StatelessWidget {
  const SaleSummaryNoteCard({
    super.key,
    required this.sale,
    required this.canShowPrice,
    required this.currencySymbol,
    required this.noteController,
    required this.noteFocusNode,
    required this.isSavingNote,
    required this.noteSaveError,
    required this.onViewPaymentHistory,
    required this.onNoteFocusChanged,
  });

  final Sale sale;
  final bool canShowPrice;
  final String currencySymbol;
  final TextEditingController noteController;
  final FocusNode noteFocusNode;
  final bool isSavingNote;
  final String? noteSaveError;
  final VoidCallback? onViewPaymentHistory;
  final ValueChanged<bool> onNoteFocusChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final note = _NoteCard(
          controller: noteController,
          focusNode: noteFocusNode,
          isSaving: isSavingNote,
          errorMessage: noteSaveError,
          onFocusChanged: onNoteFocusChanged,
        );
        final summary = _SummaryCard(
          sale: sale,
          canShowPrice: canShowPrice,
          currencySymbol: currencySymbol,
          onViewPaymentHistory: onViewPaymentHistory,
        );
        if (constraints.maxWidth < 720) {
          return Column(children: [note, const SizedBox(height: 12), summary]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: note),
            const SizedBox(width: 12),
            SizedBox(width: 360, child: summary),
          ],
        );
      },
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.controller,
    required this.focusNode,
    required this.isSaving,
    required this.errorMessage,
    required this.onFocusChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSaving;
  final String? errorMessage;
  final ValueChanged<bool> onFocusChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sticky_note_2_outlined, color: colors.primary),
                const SizedBox(width: 10),
                Text(
                  'កំណត់ចំណាំ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                if (isSaving) ...[
                  const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'កំពុងរក្សាទុក...',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ] else
                  Icon(Icons.edit_outlined, color: colors.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 14),
            Focus(
              onFocusChange: onFocusChanged,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 4,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                onTapOutside: (_) => focusNode.unfocus(),
                decoration: InputDecoration(
                  hintText: 'បញ្ចូលកំណត់ចំណាំវិក្កយបត្រ',
                  filled: true,
                  fillColor: colors.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: colors.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: colors.error, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.sale,
    required this.canShowPrice,
    required this.currencySymbol,
    required this.onViewPaymentHistory,
  });

  final Sale sale;
  final bool canShowPrice;
  final String currencySymbol;
  final VoidCallback? onViewPaymentHistory;

  String money(double value) =>
      canShowPrice ? formatCurrency(value, currencySymbol) : '••••';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'សង្ខេបវិក្កយបត្រ',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            _SummaryLine(
              label: 'ចំនួនសរុប',
              value: formatQuantity(sale.totalSaleQuantity),
            ),
            _SummaryLine(
              label: 'ទឹកប្រាក់សរុប',
              value: money(sale.totalAmount),
            ),
            _SummaryLine(
              label: 'បានទូទាត់',
              value: money(sale.totalPayment),
              onTap: sale.totalPayment > 0 ? onViewPaymentHistory : null,
              tooltip: 'មើលប្រវត្តិការទូទាត់',
            ),
            if (sale.totalWriteOff != 0)
              _SummaryLine(label: 'កាត់ចោល', value: money(sale.totalWriteOff)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: colors.outlineVariant),
            ),
            _SummaryLine(
              label: 'នៅសល់',
              value: money(sale.balance),
              emphasized: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.onTap,
    this.tooltip,
  });

  final String label;
  final String value;
  final bool emphasized;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: emphasized ? colors.onSurface : colors.onSurfaceVariant,
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          _buildValue(colors),
        ],
      ),
    );
  }

  Widget _buildValue(ColorScheme colors) {
    final valueWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: onTap != null || emphasized
                ? colors.primary
                : colors.onSurface,
            fontSize: emphasized ? 18 : null,
            fontWeight: FontWeight.w800,
            decoration: onTap == null ? null : TextDecoration.underline,
            decorationColor: colors.primary,
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 5),
          Icon(Icons.open_in_new_rounded, size: 14, color: colors.primary),
        ],
      ],
    );
    if (onTap == null) return valueWidget;
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: valueWidget,
        ),
      ),
    );
  }
}
