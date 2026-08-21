import 'package:flutter/material.dart';

import '../../closed_sales/closed_sale.dart';
import 'sale_search_result_card.dart';

class GlobalSearchResults extends StatelessWidget {
  const GlobalSearchResults({
    super.key,
    required this.results,
    required this.isLoading,
    required this.isShowingRecent,
    required this.onSelected,
    required this.onRetry,
    this.onEdit,
    this.editingSaleName,
    this.errorMessage,
  });

  final List<ClosedSale> results;
  final bool isLoading;
  final bool isShowingRecent;
  final String? errorMessage;
  final ValueChanged<ClosedSale> onSelected;
  final Future<void> Function(ClosedSale sale)? onEdit;
  final String? editingSaleName;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading && results.isEmpty) {
      return const Center(
        key: ValueKey('global-search-loading'),
        child: CircularProgressIndicator(),
      );
    }
    if (errorMessage != null && results.isEmpty) {
      return _MessageState(
        key: const ValueKey('global-search-error'),
        icon: Icons.cloud_off_outlined,
        message: errorMessage!,
        actionLabel: 'ព្យាយាមម្តងទៀត',
        onAction: onRetry,
      );
    }
    if (results.isEmpty) {
      return _MessageState(
        key: const ValueKey('global-search-empty'),
        icon: isShowingRecent
            ? Icons.receipt_long_outlined
            : Icons.search_off_rounded,
        message: isShowingRecent
            ? 'មិនមានវិក្កយបត្រលក់ដែលបានបិទទេ។'
            : 'រកមិនឃើញវិក្កយបត្រលក់ដែលត្រូវគ្នាទេ។',
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 2 : 1;
        return Stack(
          children: [
            SingleChildScrollView(
              key: const ValueKey('global-search-results'),
              padding: const EdgeInsets.only(bottom: 4),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final sale in results)
                    SizedBox(
                      width: columns == 1
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 12) / 2,
                      child: SaleSearchResultCard(
                        sale: sale,
                        onTap: () => onSelected(sale),
                        onEdit: onEdit == null ? null : () => onEdit!(sale),
                        isEditing: editingSaleName == sale.name,
                      ),
                    ),
                ],
              ),
            ),
            if (isLoading)
              const Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: LinearProgressIndicator(minHeight: 3),
              ),
            if (errorMessage != null)
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Material(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(errorMessage!)),
                        TextButton(
                          onPressed: onRetry,
                          child: const Text('ម្តងទៀត'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 44, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    ),
  );
}
