import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../shared/network_image.dart';
import '../../../utils/helpers.dart';
import '../sale_product.dart';

class OrderProductListWidget extends StatelessWidget {
  const OrderProductListWidget({
    super.key,
    required this.lines,
    required this.imageUriBuilder,
    required this.onRemove,
    required this.onEdit,
    required this.onDateTap,
    required this.onReferenceTap,
    required this.referenceNumber,
    required this.onNoteTap,
    required this.note,
    this.date,
  });

  final List<SaleProduct> lines;
  final Uri? Function(SaleProduct) imageUriBuilder;
  final ValueChanged<SaleProduct> onRemove;
  final ValueChanged<SaleProduct> onEdit;
  final VoidCallback onDateTap;
  final VoidCallback onReferenceTap;
  final String referenceNumber;
  final VoidCallback onNoteTap;
  final String note;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final orderDate = date ?? DateTime.now();
    final dateLabel =
        '${_twoDigits(orderDate.day)} / ${_twoDigits(orderDate.month)} / ${orderDate.year}';

    return Container(
      decoration: BoxDecoration(
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
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 13),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'មុខទំនិញបានជ្រើសរើស',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Material(
                  color: colors.inverseSurface,
                  borderRadius: BorderRadius.circular(10),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: const ValueKey('posting-date-button'),
                    onTap: onDateTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            color: colors.onInverseSurface,
                            size: 17,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            dateLabel,
                            style: TextStyle(
                              color: colors.onInverseSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: Material(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const ValueKey('reference-number-button'),
                onTap: onReferenceTap,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.outlineVariant),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tag_rounded, size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'លេខយោង:',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          referenceNumber.isEmpty
                              ? 'ចុចដើម្បីបញ្ចូល'
                              : referenceNumber,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: referenceNumber.isEmpty
                                ? colors.onSurfaceVariant
                                : colors.primary,
                            fontWeight: referenceNumber.isEmpty
                                ? FontWeight.w400
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.edit_outlined,
                        size: 17,
                        color: colors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          Expanded(
            child: lines.isEmpty
                ? const _EmptyOrderState()
                : ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: lines.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final line = lines[index];
                      return _OrderProductLine(
                        line: line,
                        imageUri: imageUriBuilder(line),
                        onRemove: () => onRemove(line),
                        onEdit: () => onEdit(line),
                      );
                    },
                  ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Material(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const ValueKey('sale-note-button'),
                onTap: onNoteTap,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 46),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.outlineVariant),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sticky_note_2_outlined,
                        size: 19,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'កំណត់ចំណាំ:',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          note.isEmpty ? 'ចុចដើម្បីបញ្ចូល' : note,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: note.isEmpty
                                ? colors.onSurfaceVariant
                                : colors.primary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.edit_outlined,
                        size: 17,
                        color: colors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderProductLine extends StatelessWidget {
  const _OrderProductLine({
    required this.line,
    required this.imageUri,
    required this.onRemove,
    required this.onEdit,
  });

  final SaleProduct line;
  final Uri? imageUri;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final productColor = colorFromHex(line.color, fallback: colors.primary);
    return Material(
      key: ValueKey('order-product-card-${line.productCode}'),
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 72,
              child: SizedBox(
                key: ValueKey('order-product-photo-area-${line.productCode}'),
                child: ColoredBox(
                  color: productColor.withValues(alpha: 0.16),
                  child: imageUri == null
                      ? _ProductPhotoFallback(color: productColor)
                      : AppNetworkImage(
                          key: ValueKey(
                            'order-product-photo-${line.productCode}',
                          ),
                          imageUrl: imageUri.toString(),
                          width: 72,
                          fit: BoxFit.cover,
                          memCacheWidth: 192,
                          memCacheHeight: 192,
                          maxWidthDiskCache: 256,
                          maxHeightDiskCache: 384,
                          placeholder: _ProductPhotoFallback(
                            color: productColor,
                          ),
                          errorWidget: _ProductPhotoFallback(
                            color: productColor,
                          ),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(85, 13, 13, 13),
              child: SizedBox(
                width: double.infinity,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 60),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 125),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.productName,
                              key: ValueKey(
                                'order-product-name-${line.productCode}',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${formatQuantity(line.totalSaleQuantity)} x ${formatMoney(line.price)} / ${line.unit}',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                            if (line.freeQuantity > 0)
                              _OrderProductDetail(
                                label: 'ថែម/Free:',
                                value: formatQuantity(line.freeQuantity),
                              ),
                            if (line.returnQuantity > 0)
                              _OrderProductDetail(
                                label: 'សល់មកវិញ:',
                                value: formatQuantity(line.returnQuantity),
                              ),
                            if (line.note.trim().isNotEmpty)
                              _OrderProductDetail(
                                label: 'កំណត់ចំណាំ:',
                                value: line.note.trim(),
                              ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Text(
                          '${formatMoney(line.totalAmount)} រៀល',
                          key: ValueKey(
                            'order-product-total-${line.productCode}',
                          ),
                          maxLines: 1,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: IconButton(
                            key: ValueKey(
                              'remove-order-product-${line.productCode}',
                            ),
                            tooltip: 'លុបទំនិញ',
                            padding: EdgeInsets.zero,
                            onPressed: onRemove,
                            icon: Icon(
                              Icons.close_rounded,
                              color: colors.error,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 6,
              top: 6,
              child: _SaleTransactionTypeChip(
                productCode: line.productCode,
                transactionType: line.saleTransactionType,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleTransactionTypeChip extends StatelessWidget {
  const _SaleTransactionTypeChip({
    required this.productCode,
    required this.transactionType,
  });

  final String productCode;
  final String transactionType;

  @override
  Widget build(BuildContext context) {
    final semanticColors = AppSemanticColors.of(context);
    final normalizedType = transactionType.trim().toLowerCase();
    final isBorrow = normalizedType == 'borrow';
    final isSale = normalizedType == 'sale' || normalizedType.isEmpty;
    final backgroundColor = isBorrow
        ? const Color(0xFFF79009)
        : isSale
        ? semanticColors.success
        : Theme.of(context).colorScheme.primary;
    final foregroundColor = isBorrow
        ? Colors.white
        : isSale
        ? semanticColors.onSuccess
        : Theme.of(context).colorScheme.onPrimary;
    final label = isBorrow
        ? 'ខ្ចី'
        : isSale
        ? 'លក់'
        : transactionType.trim();

    return Container(
      key: ValueKey('sale-transaction-type-$productCode'),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

class _ProductPhotoFallback extends StatelessWidget {
  const _ProductPhotoFallback({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.ac_unit_rounded, color: color, size: 21);
  }
}

class _OrderProductDetail extends StatelessWidget {
  const _OrderProductDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
      ),
    );
  }
}

class _EmptyOrderState extends StatelessWidget {
  const _EmptyOrderState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                color: colors.primary,
                size: 31,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'សូមជ្រើសរើសទំនិញដើម្បីចាប់ផ្ដើមការលក់',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
