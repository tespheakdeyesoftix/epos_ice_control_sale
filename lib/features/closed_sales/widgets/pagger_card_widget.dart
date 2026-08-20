import 'package:flutter/material.dart';

class ClosedSalePagerCardWidget extends StatelessWidget {
  const ClosedSalePagerCardWidget({
    super.key,
    required this.loadedCount,
    required this.totalCount,
    required this.isLoading,
  });

  final int loadedCount;
  final int totalCount;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final visibleLoaded = loadedCount > totalCount && !isLoading
        ? totalCount
        : loadedCount;
    final totalLabel = isLoading && totalCount == 0 ? '…' : '$totalCount';
    final progress = totalCount <= 0
        ? 0.0
        : (visibleLoaded / totalCount).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Card(
        key: const ValueKey('closed-sale-pager-card'),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.format_list_numbered_rounded,
                  size: 19,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$visibleLoaded of $totalLabel',
                key: const ValueKey('closed-sale-record-count'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'កំណត់ត្រា',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
              const Spacer(),
              SizedBox(
                width: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: isLoading && totalCount == 0 ? null : progress,
                    backgroundColor: colors.surfaceContainer,
                  ),
                ),
              ),
              if (isLoading) ...[
                const SizedBox(width: 10),
                const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
