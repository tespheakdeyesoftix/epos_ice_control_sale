import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import 'network_image.dart';

class WelcomeCardWidget extends StatelessWidget {
  const WelcomeCardWidget({
    super.key,
    required this.userName,
    required this.outletName,
    required this.stationName,
    this.userImageUrl = '',
    this.now,
    this.onCreateOrder,
    this.businessNameKh = '',
    this.businessNameEn = '',
    this.businessAddress = '',
    this.businessPhone = '',
    this.businessLogoUrl = '',
  });

  final String userName;
  final String userImageUrl;
  final String outletName;
  final String stationName;
  final DateTime? now;
  final VoidCallback? onCreateOrder;
  final String businessNameKh;
  final String businessNameEn;
  final String businessAddress;
  final String businessPhone;
  final String businessLogoUrl;

  String get greeting {
    final hour = (now ?? DateTime.now()).hour;
    if (hour < 12) return 'អរុណសួស្តី';
    if (hour < 18) return 'ទិវាសួស្តី';
    return 'សាយណ្ហសួស្តី';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = userName.trim().isEmpty ? 'អ្នកប្រើប្រាស់' : userName.trim();
    return SizedBox(
      key: const ValueKey('welcome-card'),
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.primary, colors.primary.withValues(alpha: 0.78)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.18),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: Stack(
            children: [
              const Positioned(
                right: -42,
                top: -58,
                child: _DecorationCircle(size: 180),
              ),
              const Positioned(
                right: 115,
                bottom: -72,
                child: _DecorationCircle(size: 130),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 760;
                  final greetingBlock = _UserGreeting(
                    name: name,
                    imageUrl: userImageUrl,
                    businessLogoUrl: businessLogoUrl,
                    greeting: greeting,
                    businessNameKh: businessNameKh,
                    businessNameEn: businessNameEn,
                    businessAddress: businessAddress,
                    businessPhone: businessPhone,
                  );
                  final workplace = _WorkplaceDetails(
                    outletName: outletName,
                    stationName: stationName,
                    onCreateOrder: onCreateOrder,
                  );
                  return Padding(
                    padding: EdgeInsets.all(compact ? 24 : 36),
                    child: compact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              greetingBlock,
                              const SizedBox(height: 18),
                              workplace,
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: greetingBlock),
                              const SizedBox(width: 24),
                              workplace,
                            ],
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserGreeting extends StatelessWidget {
  const _UserGreeting({
    required this.name,
    required this.imageUrl,
    required this.businessLogoUrl,
    required this.greeting,
    required this.businessNameKh,
    required this.businessNameEn,
    required this.businessAddress,
    required this.businessPhone,
  });
  final String name;
  final String imageUrl;
  final String businessLogoUrl;
  final String greeting;
  final String businessNameKh;
  final String businessNameEn;
  final String businessAddress;
  final String businessPhone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fallback = ColoredBox(
      color: colors.onPrimary.withValues(alpha: 0.18),
      child: Center(
        child: Text(
          name.characters.first.toUpperCase(),
          style: TextStyle(
            color: colors.onPrimary,
            fontSize: 31,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
    final logoFallback = businessLogoUrl.trim().isEmpty
        ? fallback
        : AppNetworkImage(
            key: const ValueKey('welcome-business-logo'),
            imageUrl: businessLogoUrl,
            fit: BoxFit.cover,
            memCacheWidth: 160,
            memCacheHeight: 160,
            maxWidthDiskCache: 320,
            maxHeightDiskCache: 320,
            placeholder: fallback,
            errorWidget: fallback,
          );
    return Row(
      children: [
        Container(
          width: 88,
          height: 88,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: colors.onPrimary.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: colors.onPrimary.withValues(alpha: 0.6)),
          ),
          child: ClipOval(
            child: imageUrl.trim().isEmpty
                ? logoFallback
                : AppNetworkImage(
                    key: const ValueKey('welcome-user-avatar'),
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 160,
                    memCacheHeight: 160,
                    maxWidthDiskCache: 320,
                    maxHeightDiskCache: 320,
                    placeholder: logoFallback,
                    errorWidget: logoFallback,
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting 👋',
                style: TextStyle(
                  color: colors.onPrimary.withValues(alpha: 0.84),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              if (businessNameKh.trim().isNotEmpty ||
                  businessNameEn.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  businessNameKh.trim().isNotEmpty
                      ? businessNameKh.trim()
                      : businessNameEn.trim(),
                  key: const ValueKey('welcome-business-name'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onPrimary.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (businessNameKh.trim().isNotEmpty &&
                    businessNameEn.trim().isNotEmpty)
                  Text(
                    businessNameEn.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onPrimary.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
              ],
              if (businessAddress.trim().isNotEmpty ||
                  businessPhone.trim().isNotEmpty) ...[
                const SizedBox(height: 7),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    if (businessAddress.trim().isNotEmpty)
                      _BusinessDetail(
                        icon: Icons.location_on_outlined,
                        value: businessAddress.trim(),
                      ),
                    if (businessPhone.trim().isNotEmpty)
                      _BusinessDetail(
                        icon: Icons.phone_outlined,
                        value: businessPhone.trim(),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BusinessDetail extends StatelessWidget {
  const _BusinessDetail({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: foreground.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground.withValues(alpha: 0.72),
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkplaceDetails extends StatelessWidget {
  const _WorkplaceDetails({
    required this.outletName,
    required this.stationName,
    required this.onCreateOrder,
  });
  final String outletName;
  final String stationName;
  final VoidCallback? onCreateOrder;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _InfoPill(
            icon: Icons.storefront_outlined,
            label: 'កន្លែងលក់',
            value: outletName.trim().isEmpty
                ? 'មិនបានកំណត់'
                : outletName.trim(),
          ),
          _InfoPill(
            icon: Icons.point_of_sale_outlined,
            label: 'ម៉ាស៊ីនលក់',
            value: stationName.trim().isEmpty
                ? 'មិនបានកំណត់'
                : stationName.trim(),
            width: 190,
            height: 62,
          ),
        ],
      ),
      if (onCreateOrder != null) ...[
        const SizedBox(height: 18),
        FilledButton.icon(
          key: const ValueKey('create-new-order-button'),
          onPressed: onCreateOrder,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.onPrimary,
            foregroundColor: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            textStyle: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          icon: const Icon(Icons.add_shopping_cart_rounded),
          label: const Text('បញ្ជេញបុងថ្មី'),
        ),
      ],
    ],
  );
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
    this.width,
    this.height,
  });
  final IconData icon;
  final String label;
  final String value;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onPrimary;
    return Container(
      width: width,
      height: height,
      constraints: const BoxConstraints(maxWidth: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: foreground.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 21),
          const SizedBox(width: 9),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: foreground.withValues(alpha: 0.72),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorationCircle extends StatelessWidget {
  const _DecorationCircle({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.1),
        width: 24,
      ),
    ),
  );
}
