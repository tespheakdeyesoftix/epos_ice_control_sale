import 'package:flutter/material.dart';

import '../../../utils/helpers.dart';
import '../../sell/product.dart';
import '../booking.dart';

class BookingToSaleProductSelection {
  const BookingToSaleProductSelection({
    required this.bookingProduct,
    required this.outletProduct,
  });

  final BookingProduct bookingProduct;
  final Product outletProduct;
}

Future<List<BookingToSaleProductSelection>?> showBookingToSaleProductDialog(
  BuildContext context, {
  required List<BookingProduct> bookingProducts,
  required List<Product> outletProducts,
  required String outletName,
}) => showDialog<List<BookingToSaleProductSelection>>(
  context: context,
  builder: (_) => BookingToSaleProductDialogWidget(
    bookingProducts: bookingProducts,
    outletProducts: outletProducts,
    outletName: outletName,
  ),
);

class BookingToSaleProductDialogWidget extends StatefulWidget {
  const BookingToSaleProductDialogWidget({
    super.key,
    required this.bookingProducts,
    required this.outletProducts,
    required this.outletName,
  });

  final List<BookingProduct> bookingProducts;
  final List<Product> outletProducts;
  final String outletName;

  @override
  State<BookingToSaleProductDialogWidget> createState() =>
      _BookingToSaleProductDialogWidgetState();
}

class _BookingToSaleProductDialogWidgetState
    extends State<BookingToSaleProductDialogWidget> {
  late final List<_SelectionRow> _rows = widget.bookingProducts
      .map(
        (bookingProduct) => _SelectionRow(
          bookingProduct: bookingProduct,
          outletProduct: _matchOutletProduct(
            bookingProduct,
            widget.outletProducts,
          ),
        ),
      )
      .toList(growable: false);

  List<BookingToSaleProductSelection> get _selected => _rows
      .where((row) => row.selected && row.outletProduct != null)
      .map(
        (row) => BookingToSaleProductSelection(
          bookingProduct: row.bookingProduct,
          outletProduct: row.outletProduct!,
        ),
      )
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      key: const ValueKey('booking-to-sale-product-dialog'),
      insetPadding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 12, 12),
              child: Row(
                children: [
                  Icon(Icons.point_of_sale_rounded, color: colors.primary),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'ជ្រើសរើសផលិតផលសម្រាប់ការលក់',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'បិទ',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'កន្លែងលក់បច្ចុប្បន្ន: ${widget.outletName}',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: _rows.isEmpty
                  ? const Center(child: Text('មិនមានផលិតផលក្នុងការកក់'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: _rows.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final row = _rows[index];
                        final available = row.outletProduct != null;
                        return Card(
                          key: ValueKey(
                            'booking-to-sale-product-${row.bookingProduct.productCode}',
                          ),
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          color: available
                              ? colors.surfaceContainerLow
                              : colors.surfaceContainerHighest.withValues(
                                  alpha: .55,
                                ),
                          child: CheckboxListTile(
                            key: ValueKey(
                              'booking-to-sale-checkbox-${row.bookingProduct.productCode}',
                            ),
                            value: row.selected,
                            onChanged: available
                                ? (value) => setState(
                                    () => row.selected = value ?? false,
                                  )
                                : null,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              _fallback(row.bookingProduct.productName),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${row.bookingProduct.productCode} • '
                                  '${formatQuantity(row.bookingProduct.quantity)} '
                                  '${row.bookingProduct.unit} • '
                                  '${formatMoney(row.bookingProduct.price)} រៀល',
                                ),
                                Text(
                                  available
                                      ? 'មាននៅកន្លែងលក់នេះ'
                                      : 'មិនមាននៅកន្លែងលក់នេះ',
                                  style: TextStyle(
                                    color: available
                                        ? colors.primary
                                        : colors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'បានជ្រើសរើស ${_selected.length} ផលិតផល',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('បោះបង់'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    key: const ValueKey('confirm-booking-to-sale-products'),
                    onPressed: _selected.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(_selected),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('បង្កើតការលក់'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionRow {
  _SelectionRow({required this.bookingProduct, required this.outletProduct})
    : selected = outletProduct != null;

  final BookingProduct bookingProduct;
  final Product? outletProduct;
  bool selected;
}

Product? _matchOutletProduct(
  BookingProduct bookingProduct,
  List<Product> outletProducts,
) {
  final bookingCode = bookingProduct.productCode.trim();
  final bookingUnit = bookingProduct.unit.trim();
  for (final product in outletProducts) {
    if (product.code.trim() != bookingCode) continue;
    if (bookingUnit.isEmpty || product.unit.trim() == bookingUnit) {
      return product;
    }
    for (final unit in product.productUnits) {
      if (unit.unit.trim() == bookingUnit) return product.forUnit(unit);
    }
  }
  return null;
}

String _fallback(String value) => value.trim().isEmpty ? '-' : value.trim();
