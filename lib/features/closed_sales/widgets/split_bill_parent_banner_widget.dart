import 'package:flutter/material.dart';

class SplitBillParentBannerWidget extends StatelessWidget {
  const SplitBillParentBannerWidget({
    super.key,
    required this.parentBillNumber,
    required this.onOpenParent,
  });

  final String parentBillNumber;
  final VoidCallback onOpenParent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'បុងនេះត្រូវបានបំបែកចេញពីបុងមេ $parentBillNumber',
      child: Material(
        color: colors.primaryContainer.withValues(alpha: .62),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: colors.primary.withValues(alpha: .28)),
        ),
        child: InkWell(
          key: const ValueKey('open-parent-split-bill'),
          borderRadius: BorderRadius.circular(10),
          onTap: onOpenParent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.call_split_rounded, size: 16, color: colors.primary),
                const SizedBox(width: 6),
                Text(
                  'បំបែកពី $parentBillNumber',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 14,
                  color: colors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
