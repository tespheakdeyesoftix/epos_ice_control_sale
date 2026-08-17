import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../shared/input_number_dialog_widget.dart';
import '../../../utils/helpers.dart';
import '../sale_product.dart';

Future<SaleProduct?> showEditSaleOrderDialog(
  BuildContext context, {
  required SaleProduct saleProduct,
}) {
  return showDialog<SaleProduct>(
    context: context,
    builder: (_) => EditSaleOrderWidget(saleProduct: saleProduct),
  );
}

class EditSaleOrderWidget extends StatefulWidget {
  const EditSaleOrderWidget({super.key, required this.saleProduct});

  final SaleProduct saleProduct;

  @override
  State<EditSaleOrderWidget> createState() => _EditSaleOrderWidgetState();
}

class _EditSaleOrderWidgetState extends State<EditSaleOrderWidget> {
  late double _quantity;
  late double _price;
  late double _returnQuantity;
  late double _freeQuantity;
  late String _note;

  double get _allocatedQuantity =>
      _returnQuantity + _freeQuantity + widget.saleProduct.splitQuantity;

  bool get _hasValidQuantities => _allocatedQuantity <= _quantity + 0.000001;

  @override
  void initState() {
    super.initState();
    _quantity = widget.saleProduct.quantity;
    _price = widget.saleProduct.price;
    _returnQuantity = widget.saleProduct.returnQuantity;
    _freeQuantity = widget.saleProduct.freeQuantity;
    _note = widget.saleProduct.note;
  }

  Future<void> _editNumber({
    required double value,
    required bool allowZero,
    required ValueChanged<double> onChanged,
  }) async {
    final result = await showInputNumberDialog(
      context,
      initialValue: value,
      allowZero: allowZero,
    );
    if (result != null && mounted) setState(() => onChanged(result));
  }

  Future<void> _editNote() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _NoteDialog(initialValue: _note),
    );
    if (result != null && mounted) setState(() => _note = result);
  }

  void _save() {
    if (!_hasValidQuantities) return;
    Navigator.of(context).pop(
      widget.saleProduct.copyWith(
        quantity: _quantity,
        price: _price,
        returnQuantity: _returnQuantity,
        freeQuantity: _freeQuantity,
        note: _note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 60,
              padding: const EdgeInsets.only(left: 20),
              color: colors.inverseSurface,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'កែប្រែទំនិញលក់',
                      style: TextStyle(
                        color: colors.onInverseSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: IconButton(
                      key: const ValueKey('close-edit-sale-order'),
                      tooltip: 'បិទ',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: colors.onError,
                      style: IconButton.styleFrom(
                        backgroundColor: colors.error,
                        shape: const RoundedRectangleBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.saleProduct.productName,
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _TransactionStatusChip(
                          isBorrow: widget.saleProduct.isBorrow,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 2.7,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _EditOptionCard(
                          key: const ValueKey('edit-sale-quantity'),
                          icon: Icons.shopping_basket_outlined,
                          label: 'ចំនួន',
                          value: formatQuantity(_quantity),
                          onTap: () => _editNumber(
                            value: _quantity,
                            allowZero: false,
                            onChanged: (value) => _quantity = value,
                          ),
                        ),
                        _EditOptionCard(
                          key: const ValueKey('edit-sale-price'),
                          icon: Icons.payments_outlined,
                          label: 'តម្លៃ',
                          value: formatMoney(_price),
                          onTap: widget.saleProduct.isBorrow
                              ? null
                              : () => _editNumber(
                                  value: _price,
                                  allowZero: false,
                                  onChanged: (value) => _price = value,
                                ),
                        ),
                        _EditOptionCard(
                          key: const ValueKey('edit-sale-return-quantity'),
                          icon: Icons.assignment_return_outlined,
                          label: 'ចំនួនសល់មកវិញ',
                          value: formatQuantity(_returnQuantity),
                          onTap: () => _editNumber(
                            value: _returnQuantity,
                            allowZero: true,
                            onChanged: (value) => _returnQuantity = value,
                          ),
                        ),
                        _EditOptionCard(
                          key: const ValueKey('edit-sale-free-quantity'),
                          icon: Icons.card_giftcard_outlined,
                          label: 'ចំនួនថែម/Free',
                          value: formatQuantity(_freeQuantity),
                          onTap: () => _editNumber(
                            value: _freeQuantity,
                            allowZero: true,
                            onChanged: (value) => _freeQuantity = value,
                          ),
                        ),
                        _EditOptionCard(
                          key: const ValueKey('edit-sale-note'),
                          icon: Icons.notes_rounded,
                          label: 'កំណត់ចំណាំ',
                          value: _note.isEmpty ? 'មិនមាន' : _note,
                          onTap: _editNote,
                        ),
                      ],
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _hasValidQuantities
                          ? const SizedBox.shrink()
                          : Container(
                              key: const ValueKey(
                                'sale-quantity-validation-error',
                              ),
                              margin: const EdgeInsets.only(top: 14),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                color: colors.errorContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    color: colors.onErrorContainer,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'ចំនួនសល់មកវិញ + ចំនួនថែម/Free + ចំនួនបំបែក មិនអាចលើសចំនួនដើមបានទេ។',
                                      style: TextStyle(
                                        color: colors.onErrorContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('បោះបង់'),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            key: const ValueKey('save-sale-order-edit'),
                            onPressed: _hasValidQuantities ? _save : null,
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('រក្សាទុក'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('កំណត់ចំណាំ'),
      content: SizedBox(
        width: 430,
        child: TextField(
          key: const ValueKey('sale-product-note-input'),
          controller: _controller,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'បញ្ចូលកំណត់ចំណាំ'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('បោះបង់'),
        ),
        FilledButton(
          key: const ValueKey('accept-sale-product-note'),
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('យល់ព្រម'),
        ),
      ],
      backgroundColor: colors.surface,
    );
  }
}

class _EditOptionCard extends StatelessWidget {
  const _EditOptionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isEnabled = onTap != null;
    return Material(
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: isEnabled
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isEnabled
                    ? Icons.chevron_right_rounded
                    : Icons.lock_outline_rounded,
                color: isEnabled
                    ? colors.onSurfaceVariant
                    : colors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionStatusChip extends StatelessWidget {
  const _TransactionStatusChip({required this.isBorrow});

  final bool isBorrow;

  @override
  Widget build(BuildContext context) {
    final semanticColors = AppSemanticColors.of(context);
    final backgroundColor = isBorrow
        ? const Color(0xFFF79009)
        : semanticColors.success;
    final foregroundColor = isBorrow ? Colors.white : semanticColors.onSuccess;
    return Container(
      key: const ValueKey('edit-sale-transaction-status'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isBorrow ? 'ខ្ចី' : 'លក់',
        style: TextStyle(color: foregroundColor, fontWeight: FontWeight.w700),
      ),
    );
  }
}
