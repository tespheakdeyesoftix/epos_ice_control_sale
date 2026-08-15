import 'package:flutter/material.dart';

class PendingOrderBadgeWidget extends StatelessWidget {
  const PendingOrderBadgeWidget({
    super.key,
    required this.count,
    this.isLoading = false,
    this.onTap,
  });

  final int count;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final countLabel = count > 99 ? '99+' : count.toString();
    return Tooltip(
      message: 'ការលក់ដែលបានផ្អាក: $count',
      child: SizedBox(
        key: const ValueKey('pending-order-badge'),
        width: 50,
        height: 50,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: IconButton(
                key: const ValueKey('reload-pending-orders-button'),
                onPressed: isLoading ? null : onTap,
                style: IconButton.styleFrom(
                  backgroundColor: colors.surfaceContainerLow,
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.outlineVariant),
                ),
                icon: isLoading
                    ? SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.primary,
                        ),
                      )
                    : const Icon(Icons.pending_actions_rounded),
              ),
            ),
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                key: const ValueKey('pending-order-count'),
                constraints: const BoxConstraints(minWidth: 21, minHeight: 21),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.error,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.surface, width: 2),
                ),
                child: Text(
                  countLabel,
                  style: TextStyle(
                    color: colors.onError,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
