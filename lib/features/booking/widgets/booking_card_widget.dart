import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../utils/helpers.dart';
import '../booking.dart';

class BookingCardWidget extends StatelessWidget {
  const BookingCardWidget({
    super.key,
    required this.booking,
    required this.isToday,
    required this.onTap,
  });

  final Booking booking;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      key: ValueKey('booking-card-${booking.name}'),
      margin: EdgeInsets.zero,
      elevation: 0,
      color: isToday
          ? colors.primaryContainer.withValues(alpha: .35)
          : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isToday
              ? colors.primary.withValues(alpha: .45)
              : colors.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.primary,
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'ថ្ងៃនេះ',
                        style: TextStyle(
                          color: colors.onPrimary,
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 7),
              _CardLine(
                icon: Icons.person_outline_rounded,
                text: _fallback(booking.customerName),
              ),
              const SizedBox(height: 5),
              _CardLine(
                icon: Icons.celebration_outlined,
                text: _fallback(booking.bookingEvent),
              ),
              const SizedBox(height: 5),
              _CardLine(
                icon: Icons.local_shipping_outlined,
                text: formatDate(booking.deliveryDate),
              ),
              if (booking.productsDescription.isNotEmpty) ...[
                const SizedBox(height: 5),
                _CardLine(
                  icon: Icons.inventory_2_outlined,
                  text: booking.productsDescription,
                ),
              ],
              const Spacer(),
              Divider(height: 1, color: colors.outlineVariant),
              const SizedBox(height: 7),
              Row(
                children: [
                  if (booking.phoneNumber.isNotEmpty) ...[
                    Icon(
                      Icons.phone_outlined,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        booking.phoneNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  Text(
                    '${formatMoney(booking.totalAmount)} រៀល',
                    style: TextStyle(
                      color: colors.primary,
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardLine extends StatelessWidget {
  const _CardLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

String _fallback(String value) => value.trim().isEmpty ? '-' : value.trim();
