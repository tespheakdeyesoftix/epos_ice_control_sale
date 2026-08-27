import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../services/booking_service.dart';
import '../../../utils/helpers.dart';
import '../booking.dart';
import 'new_booking_dialog_widget.dart';

Future<void> showBookingDetailDialog(
  BuildContext context, {
  required Booking booking,
  required BookingService service,
  Future<void> Function()? onUpdated,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => BookingDetailDialogWidget(
      booking: booking,
      service: service,
      onUpdated: onUpdated,
    ),
  );
}

class BookingDetailDialogWidget extends StatefulWidget {
  const BookingDetailDialogWidget({
    super.key,
    required this.booking,
    required this.service,
    this.onUpdated,
  });

  final Booking booking;
  final BookingService service;
  final Future<void> Function()? onUpdated;

  @override
  State<BookingDetailDialogWidget> createState() =>
      _BookingDetailDialogWidgetState();
}

class _BookingDetailDialogWidgetState extends State<BookingDetailDialogWidget> {
  late Future<Booking> _bookingFuture;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bookingFuture = widget.service.getBooking(widget.booking.name);
  }

  void _retry() {
    setState(() {
      _bookingFuture = widget.service.getBooking(widget.booking.name);
    });
  }

  Future<void> _edit(Booking booking) async {
    final data = await showNewBookingDialog(
      context,
      dataSource: widget.service,
      booking: booking,
    );
    if (data == null || !mounted) return;
    setState(() => _isSaving = true);
    try {
      await widget.service.updateBooking(booking.name, data);
      final refreshed = await widget.service.getBooking(booking.name);
      await widget.onUpdated?.call();
      if (!mounted) return;
      setState(() => _bookingFuture = Future.value(refreshed));
      _showToast(success: true);
    } on Exception {
      if (mounted) _showToast(success: false);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showToast({required bool success}) {
    final colors = Theme.of(context).colorScheme;
    Get.rawSnackbar(
      messageText: Text(
        success ? 'បានកែប្រែការកក់ដោយជោគជ័យ' : 'មិនអាចកែប្រែការកក់បានទេ',
        style: TextStyle(
          color: success ? colors.onPrimary : colors.onError,
          fontWeight: FontWeight.w600,
        ),
      ),
      icon: Icon(
        success
            ? Icons.check_circle_outline_rounded
            : Icons.error_outline_rounded,
        color: success ? colors.onPrimary : colors.onError,
      ),
      snackPosition: SnackPosition.TOP,
      snackStyle: SnackStyle.FLOATING,
      maxWidth: 540,
      margin: const EdgeInsets.only(top: 18),
      borderRadius: 12,
      backgroundColor: success ? colors.primary : colors.error,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    return Dialog(
      key: ValueKey('booking-detail-dialog-${widget.booking.name}'),
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 900,
          maxHeight: screenSize.height * .88,
        ),
        child: FutureBuilder<Booking>(
          future: _bookingFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 320,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return SizedBox(
                height: 320,
                child: _ErrorContent(onRetry: _retry),
              );
            }
            return _BookingDetailContent(
              booking: snapshot.data!,
              isSaving: _isSaving,
              onEdit: () => _edit(snapshot.data!),
            );
          },
        ),
      ),
    );
  }
}

class _BookingDetailContent extends StatelessWidget {
  const _BookingDetailContent({
    required this.booking,
    required this.isSaving,
    required this.onEdit,
  });

  final Booking booking;
  final bool isSaving;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.event_note_rounded,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ព័ត៌មានលម្អិតការកក់',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      booking.name,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                key: const ValueKey('edit-booking'),
                onPressed: isSaving ? null : onEdit,
                icon: isSaving
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.edit_outlined),
                label: const Text('កែប្រែ'),
              ),
              const SizedBox(width: 6),
              IconButton(
                key: const ValueKey('close-booking-detail'),
                tooltip: 'បិទ',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: colors.outlineVariant),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _InfoTile(
                      icon: Icons.person_outline_rounded,
                      label: 'អតិថិជន',
                      value: _fallback(booking.customerName),
                    ),
                    _InfoTile(
                      icon: Icons.phone_outlined,
                      label: 'លេខទូរស័ព្ទ',
                      value: _fallback(booking.phoneNumber),
                    ),
                    _InfoTile(
                      icon: Icons.celebration_outlined,
                      label: 'កម្មវិធី',
                      value: _fallback(booking.bookingEvent),
                    ),
                    _InfoTile(
                      icon: Icons.local_shipping_outlined,
                      label: 'ថ្ងៃដឹកជញ្ជូន',
                      value: formatDate(booking.deliveryDate),
                    ),
                    _InfoTile(
                      icon: Icons.calendar_today_outlined,
                      label: 'ថ្ងៃកក់',
                      value: formatDate(booking.postingDate),
                    ),
                    _InfoTile(
                      icon: Icons.payments_outlined,
                      label: 'ទឹកប្រាក់សរុប',
                      value: '${formatMoney(booking.totalAmount)} រៀល',
                      emphasized: true,
                    ),
                  ],
                ),
                if (booking.address.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _AddressCard(address: booking.address),
                ],
                const SizedBox(height: 24),
                Text(
                  'ផលិតផល (${booking.products.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                if (booking.products.isEmpty)
                  const _EmptyProducts()
                else
                  ...booking.products.map(
                    (product) => _ProductCard(product: product),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 21, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: emphasized ? colors.primary : colors.onSurface,
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

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on_outlined, color: colors.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(child: Text(address)),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final BookingProduct product;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fallback(product.productName),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (product.productCode.isNotEmpty)
                    Text(
                      product.productCode,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _ProductMetric(
                label: 'ចំនួន',
                value: '${formatQuantity(product.quantity)} ${product.unit}',
              ),
            ),
            Expanded(
              child: _ProductMetric(
                label: 'តម្លៃ',
                value: formatMoney(product.price),
              ),
            ),
            Expanded(
              child: _ProductMetric(
                label: 'សរុប',
                value: formatMoney(product.totalAmount),
                emphasized: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductMetric extends StatelessWidget {
  const _ProductMetric({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: emphasized ? colors.primary : colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Center(
      child: Text(
        'មិនមានផលិតផល',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ),
  );
}

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline_rounded, size: 42),
        const SizedBox(height: 10),
        const Text('មិនអាចទាញយកព័ត៌មានការកក់បានទេ។'),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('ព្យាយាមម្តងទៀត'),
        ),
      ],
    ),
  );
}

String _fallback(String value) => value.trim().isEmpty ? '-' : value.trim();
