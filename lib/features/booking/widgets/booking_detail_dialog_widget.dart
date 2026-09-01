import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../features/closed_sales/closed_sale.dart';
import '../../../services/booking_service.dart';
import '../../../services/frappe_response_handler.dart';
import '../../../services/sale_service.dart';
import '../../../utils/helpers.dart';
import '../booking.dart';
import 'new_booking_dialog_widget.dart';

Future<void> showBookingDetailDialog(
  BuildContext context, {
  required Booking booking,
  required BookingService service,
  SaleService? saleService,
  String outlet = '',
  Future<void> Function()? onUpdated,
  Future<bool> Function(Booking booking)? onCreateSale,
  Future<void> Function(ClosedSale sale)? onOpenSale,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => BookingDetailDialogWidget(
      booking: booking,
      service: service,
      saleService: saleService,
      outlet: outlet,
      onUpdated: onUpdated,
      onCreateSale: onCreateSale,
      onOpenSale: onOpenSale,
    ),
  );
}

class BookingDetailDialogWidget extends StatefulWidget {
  const BookingDetailDialogWidget({
    super.key,
    required this.booking,
    required this.service,
    this.saleService,
    this.outlet = '',
    this.onUpdated,
    this.onCreateSale,
    this.onOpenSale,
  });

  final Booking booking;
  final BookingService service;
  final SaleService? saleService;
  final String outlet;
  final Future<void> Function()? onUpdated;
  final Future<bool> Function(Booking booking)? onCreateSale;
  final Future<void> Function(ClosedSale sale)? onOpenSale;

  @override
  State<BookingDetailDialogWidget> createState() =>
      _BookingDetailDialogWidgetState();
}

class _BookingDetailDialogWidgetState extends State<BookingDetailDialogWidget> {
  late Future<Booking> _bookingFuture;
  Future<List<ClosedSale>>? _relatedSalesFuture;
  bool _isCheckingRelatedSales = false;
  bool _hasIssuedSales = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bookingFuture = widget.service.getBooking(widget.booking.name);
    _loadRelatedSales();
  }

  void _loadRelatedSales() {
    final saleService = widget.saleService;
    final outlet = widget.outlet.trim();
    if (saleService == null || outlet.isEmpty) {
      _relatedSalesFuture = null;
      _isCheckingRelatedSales = false;
      _hasIssuedSales = false;
      return;
    }

    _isCheckingRelatedSales = true;
    final request = saleService.getSalesForBooking(
      outlet: outlet,
      bookingNumber: widget.booking.name,
    );
    _relatedSalesFuture = request;
    request.then(
      (sales) {
        if (!mounted || !identical(_relatedSalesFuture, request)) return;
        setState(() {
          _isCheckingRelatedSales = false;
          _hasIssuedSales = sales.isNotEmpty;
        });
      },
      onError: (_) {
        if (!mounted || !identical(_relatedSalesFuture, request)) return;
        setState(() {
          _isCheckingRelatedSales = false;
          _hasIssuedSales = false;
        });
      },
    );
  }

  void _retry() {
    setState(() {
      _bookingFuture = widget.service.getBooking(widget.booking.name);
      _loadRelatedSales();
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
      showSuccess('បានកែប្រែការកក់ដោយជោគជ័យ');
    } on Exception {
      if (mounted) {
        showError('មិនអាចកែប្រែការកក់បានទេ');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('delete-booking-confirmation'),
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(dialogContext).colorScheme.error,
        ),
        title: const Text('លុបការកក់?'),
        content: Text(
          'តើអ្នកពិតជាចង់លុបការកក់ ${booking.name} មែនទេ? សកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ។',
        ),
        actions: [
          TextButton(
            key: const ValueKey('cancel-delete-booking'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('បោះបង់'),
          ),
          FilledButton.icon(
            key: const ValueKey('confirm-delete-booking'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('លុប'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await widget.service.deleteBooking(booking.name);
      await widget.onUpdated?.call();
      if (!mounted) return;
      showSuccess('បានលុបការកក់ដោយជោគជ័យ');
      Navigator.of(context).pop();
    } on FrappeServerMessageException {
      if (mounted) setState(() => _isSaving = false);
    } on Exception {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showError('មិនអាចលុបការកក់បានទេ');
    }
  }

  Future<void> _createSale(Booking booking) async {
    final callback = widget.onCreateSale;
    if (callback == null ||
        _isSaving ||
        _isCheckingRelatedSales ||
        _hasIssuedSales ||
        !booking.isDeliveredOn(DateTime.now())) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final created = await callback(booking);
      if (created && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
              onDelete: () => _delete(snapshot.data!),
              onCreateSale: widget.onCreateSale == null
                  ? null
                  : () => _createSale(snapshot.data!),
              relatedSalesFuture: _relatedSalesFuture,
              isCheckingRelatedSales: _isCheckingRelatedSales,
              hasIssuedSales: _hasIssuedSales,
              onOpenSale: widget.onOpenSale,
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
    required this.onDelete,
    required this.isCheckingRelatedSales,
    required this.hasIssuedSales,
    this.relatedSalesFuture,
    this.onCreateSale,
    this.onOpenSale,
  });

  final Booking booking;
  final bool isSaving;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isCheckingRelatedSales;
  final bool hasIssuedSales;
  final Future<List<ClosedSale>>? relatedSalesFuture;
  final VoidCallback? onCreateSale;
  final Future<void> Function(ClosedSale sale)? onOpenSale;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final canCreateSaleToday = booking.isDeliveredOn(DateTime.now());
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
              _TouchCloseButton(
                key: const ValueKey('close-booking-detail'),
                onPressed: () => Navigator.of(context).pop(),
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
                if (relatedSalesFuture != null) ...[
                  _IssuedSalesCard(
                    salesFuture: relatedSalesFuture!,
                    onOpenSale: onOpenSale,
                  ),
                ],
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
                if (booking.note.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _NoteCard(note: booking.note),
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
        Divider(height: 1, color: colors.outlineVariant),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('delete-booking'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.error,
                  side: BorderSide(color: colors.error),
                ),
                onPressed: isSaving ? null : onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('លុប'),
              ),
              const SizedBox(width: 10),
              if (onCreateSale != null) ...[
                FilledButton.tonalIcon(
                  key: const ValueKey('create-sale-from-booking'),
                  onPressed:
                      isSaving ||
                          isCheckingRelatedSales ||
                          hasIssuedSales ||
                          !canCreateSaleToday
                      ? null
                      : onCreateSale,
                  icon: const Icon(Icons.point_of_sale_rounded),
                  label: const Text('បង្កើតការលក់'),
                ),
                const SizedBox(width: 10),
              ],
              FilledButton.icon(
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
            ],
          ),
        ),
      ],
    );
  }
}

class _TouchCloseButton extends StatelessWidget {
  const _TouchCloseButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Tooltip(
      message: 'បិទ',
      child: Semantics(
        button: true,
        label: 'បិទ',
        onTap: onPressed,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => onPressed(),
            child: SizedBox.square(
              dimension: 56,
              child: Center(child: Icon(Icons.close_rounded, color: color)),
            ),
          ),
        ),
      ),
    );
  }
}

class _IssuedSalesCard extends StatelessWidget {
  const _IssuedSalesCard({required this.salesFuture, this.onOpenSale});

  final Future<List<ClosedSale>> salesFuture;
  final Future<void> Function(ClosedSale sale)? onOpenSale;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ClosedSale>>(
      future: salesFuture,
      builder: (context, snapshot) {
        final sales = snapshot.data ?? const <ClosedSale>[];
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.hasError ||
            sales.isEmpty) {
          return const SizedBox.shrink();
        }

        final colors = Theme.of(context).colorScheme;
        return Container(
          key: const ValueKey('booking-issued-sales-card'),
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: .55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.primary.withValues(alpha: .35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.receipt_long_outlined, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ការកក់នេះបានចេញការលក់រួចហើយ។ លេខវិក្កយបត្រ៖',
                      style: TextStyle(
                        color: colors.onPrimaryContainer,
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final sale in sales)
                          OutlinedButton.icon(
                            key: ValueKey('open-booking-sale-${sale.name}'),
                            onPressed: onOpenSale == null
                                ? null
                                : () => onOpenSale!(sale),
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 16,
                            ),
                            label: Text(sale.name),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('booking-detail-note'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notes_rounded, color: colors.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'កំណត់ចំណាំ',
                  style: TextStyle(
                    color: colors.onTertiaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(note),
              ],
            ),
          ),
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
