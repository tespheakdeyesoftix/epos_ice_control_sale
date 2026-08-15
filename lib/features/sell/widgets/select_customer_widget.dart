import 'package:flutter/material.dart';

import '../../../shared/network_image.dart';

class SelectCustomerWidget extends StatelessWidget {
  const SelectCustomerWidget({
    super.key,
    this.customerCode = '',
    this.customerName = 'អតិថិជនទូទៅ',
    this.phoneNumber = '',
    this.photoUri,
    this.onTap,
  });

  final String customerCode;
  final String customerName;
  final String phoneNumber;
  final Uri? photoUri;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final displayName = customerCode.isEmpty
        ? customerName
        : '$customerCode - $customerName';
    return Container(
      decoration: _decoration(colors),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      color: colors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'អតិថិជន',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    ClipOval(
                      child: ColoredBox(
                        color: colors.surfaceContainer,
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: photoUri == null
                              ? Icon(
                                  Icons.person_rounded,
                                  color: colors.primary,
                                )
                              : AppNetworkImage(
                                  imageUrl: photoUri.toString(),
                                  width: 40,
                                  height: 40,
                                  memCacheWidth: 96,
                                  memCacheHeight: 96,
                                  errorWidget: Icon(
                                    Icons.person_rounded,
                                    color: colors.primary,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (phoneNumber.isNotEmpty)
                            Text(
                              phoneNumber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _decoration(ColorScheme colors) {
  return BoxDecoration(
    color: colors.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: colors.outlineVariant),
    boxShadow: [
      BoxShadow(
        color: colors.shadow.withValues(alpha: 0.05),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
