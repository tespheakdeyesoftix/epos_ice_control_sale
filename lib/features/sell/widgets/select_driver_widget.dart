import 'package:flutter/material.dart';

import '../../../shared/network_image.dart';

class SelectDriverWidget extends StatelessWidget {
  const SelectDriverWidget({
    super.key,
    this.driverCode = '',
    this.driverName,
    this.phoneNumber = '',
    this.plateNumber = '',
    this.photoUri,
    this.onTap,
    this.onClear,
    this.onChangePlateNumber,
  });

  final String driverCode;
  final String? driverName;
  final String phoneNumber;
  final String plateNumber;
  final Uri? photoUri;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final VoidCallback? onChangePlateNumber;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selectedName = driverName?.trim() ?? '';
    final hasDriver = selectedName.isNotEmpty;
    final displayName = !hasDriver
        ? 'ជ្រើសរើសអ្នកបើកបរ'
        : driverCode.isEmpty
        ? selectedName
        : '$driverCode - $selectedName';
    final details = [
      if (phoneNumber.trim().isNotEmpty) phoneNumber.trim(),
      if (plateNumber.trim().isNotEmpty) plateNumber.trim(),
    ].join(' • ');

    return Container(
      decoration: _decoration(colors),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('driver-card-hit-area'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.badge_outlined, color: colors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'អ្នកបើកបរ',
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
                          if (details.isNotEmpty)
                            Text(
                              details,
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
                    if (hasDriver)
                      IconButton(
                        key: const ValueKey('clear-selected-driver'),
                        tooltip: 'លុបអ្នកបើកបរ',
                        onPressed: onClear,
                        style: IconButton.styleFrom(
                          backgroundColor: colors.error.withValues(alpha: 0.1),
                        ),
                        icon: Icon(
                          Icons.close_rounded,
                          color: colors.error,
                          size: 20,
                        ),
                      )
                    else
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colors.onSurfaceVariant,
                      ),
                  ],
                ),
                if (hasDriver && onChangePlateNumber != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 42,
                    child: OutlinedButton.icon(
                      key: const ValueKey('change-plate-number-button'),
                      onPressed: onChangePlateNumber,
                      icon: const Icon(Icons.directions_car_outlined, size: 18),
                      label: const Text('ប្តូរស្លាក់លេខឡាន'),
                    ),
                  ),
                ],
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
