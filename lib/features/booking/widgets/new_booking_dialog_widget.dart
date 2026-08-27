import 'package:flutter/material.dart';

import '../../../services/doctype_data_source.dart';
import '../../../shared/select_data_dialog_widget.dart';
import '../../../utils/helpers.dart';
import '../../sell/product.dart';
import '../booking.dart';

Future<Map<String, dynamic>?> showNewBookingDialog(
  BuildContext context, {
  required DoctypeDataSource dataSource,
  Booking? booking,
  String customerName = '',
  String phoneNumber = '',
}) => showDialog<Map<String, dynamic>>(
  context: context,
  builder: (_) => NewBookingDialogWidget(
    dataSource: dataSource,
    booking: booking,
    customerName: booking?.customerName ?? customerName,
    phoneNumber: booking?.phoneNumber ?? phoneNumber,
  ),
);

class NewBookingDialogWidget extends StatefulWidget {
  const NewBookingDialogWidget({
    super.key,
    required this.dataSource,
    this.booking,
    this.customerName = '',
    this.phoneNumber = '',
  });

  final DoctypeDataSource dataSource;
  final Booking? booking;
  final String customerName;
  final String phoneNumber;

  @override
  State<NewBookingDialogWidget> createState() => _NewBookingDialogWidgetState();
}

class _NewBookingDialogWidgetState extends State<NewBookingDialogWidget> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _customerNameController;
  late final TextEditingController _phoneNumberController;
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  final _products = <_BookingProductDraft>[];
  DateTime? _deliveryDate;
  SelectDataValue? _bookingEvent;
  bool _showValidationErrors = false;
  bool _selectingProduct = false;

  @override
  void initState() {
    super.initState();
    _customerNameController = TextEditingController(text: widget.customerName);
    _phoneNumberController = TextEditingController(text: widget.phoneNumber);
    final booking = widget.booking;
    if (booking != null) {
      _addressController.text = booking.address;
      _noteController.text = booking.note;
      _deliveryDate = booking.deliveryDate;
      if (booking.bookingEvent.isNotEmpty) {
        _bookingEvent = SelectDataValue(
          name: booking.bookingEvent,
          title: booking.bookingEvent,
        );
      }
      _products.addAll(
        booking.products.map(_BookingProductDraft.fromBookingProduct),
      );
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDeliveryDate() async {
    final now = DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate: _deliveryDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 10, 12, 31),
    );
    if (value != null && mounted) setState(() => _deliveryDate = value);
  }

  Future<void> _selectBookingEvent() async {
    final value = await showSelectDataDialog(
      context,
      dataSource: widget.dataSource,
      doctype: 'Booking Event',
      label: 'ជ្រើសរើសកម្មវិធីកក់',
    );
    if (value != null && mounted) setState(() => _bookingEvent = value);
  }

  Future<void> _addProduct() async {
    setState(() => _selectingProduct = true);
    final product = await showBookingProductSelector(
      context,
      dataSource: widget.dataSource,
      excludedCodes: _products.map((row) => row.product.code).toSet(),
    );
    if (!mounted) return;
    setState(() {
      _selectingProduct = false;
      if (product != null) _products.add(_BookingProductDraft(product));
    });
  }

  void _submit() {
    setState(() => _showValidationErrors = true);
    if (!(_formKey.currentState?.validate() ?? false) ||
        _deliveryDate == null ||
        _bookingEvent == null ||
        _products.isEmpty) {
      return;
    }
    final now = DateTime.now();
    final postingDate = widget.booking?.postingDate ?? now;
    Navigator.of(context).pop(<String, dynamic>{
      'posting_date': _dateOnly(postingDate),
      'delivery_date': _dateOnly(_deliveryDate!),
      'booking_event': _bookingEvent!.name,
      'customer_name': _customerNameController.text.trim(),
      'phone_number': _phoneNumberController.text.trim(),
      'address': _addressController.text.trim(),
      'note': _noteController.text.trim(),
      'total_amount': _totalAmount,
      'booking_products': _products.map((row) => row.toJson()).toList(),
    });
  }

  double get _totalAmount => _products.fold(
    0,
    (total, product) => total + product.quantity * product.price,
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      key: const ValueKey('new-booking-dialog'),
      insetPadding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 820,
          maxHeight: MediaQuery.sizeOf(context).height * .92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 12, 14),
              child: Row(
                children: [
                  Icon(Icons.event_available_rounded, color: colors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.booking == null
                          ? 'បង្កើតការកក់ថ្មី'
                          : 'កែប្រែការកក់',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _showValidationErrors
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionTitle(
                        icon: Icons.person_outline_rounded,
                        title: 'ព័ត៌មានអតិថិជន',
                      ),
                      const SizedBox(height: 12),
                      _ResponsiveFields(
                        children: [
                          TextFormField(
                            key: const ValueKey('new-booking-customer-name'),
                            controller: _customerNameController,
                            autofocus: true,
                            maxLength: 140,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                            decoration: const InputDecoration(
                              labelText: 'ឈ្មោះអតិថិជន',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                          ),
                          TextFormField(
                            key: const ValueKey('new-booking-phone-number'),
                            controller: _phoneNumberController,
                            maxLength: 30,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                            validator: _requiredPhone,
                            decoration: const InputDecoration(
                              labelText: 'លេខទូរស័ព្ទ *',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const _SectionTitle(
                        icon: Icons.calendar_month_outlined,
                        title: 'ព័ត៌មានការកក់',
                      ),
                      const SizedBox(height: 12),
                      _ResponsiveFields(
                        children: [
                          _PickerField(
                            fieldKey: const ValueKey(
                              'new-booking-delivery-date',
                            ),
                            label: 'ថ្ងៃដឹកជញ្ជូន *',
                            value: _deliveryDate == null
                                ? ''
                                : formatDate(_deliveryDate),
                            icon: Icons.local_shipping_outlined,
                            onTap: _selectDeliveryDate,
                            errorText:
                                _showValidationErrors && _deliveryDate == null
                                ? 'សូមជ្រើសរើសថ្ងៃដឹកជញ្ជូន'
                                : null,
                          ),
                          _PickerField(
                            fieldKey: const ValueKey('new-booking-event'),
                            label: 'កម្មវិធីកក់ *',
                            value: _bookingEvent?.title ?? '',
                            icon: Icons.celebration_outlined,
                            onTap: _selectBookingEvent,
                            errorText:
                                _showValidationErrors && _bookingEvent == null
                                ? 'សូមជ្រើសរើសកម្មវិធីកក់'
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const ValueKey('new-booking-address'),
                        controller: _addressController,
                        minLines: 2,
                        maxLines: 3,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText: 'អាសយដ្ឋាន',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const ValueKey('new-booking-note'),
                        controller: _noteController,
                        minLines: 2,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText: 'កំណត់ចំណាំ',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Expanded(
                            child: _SectionTitle(
                              icon: Icons.inventory_2_outlined,
                              title: 'ផលិតផលកក់',
                            ),
                          ),
                          FilledButton.tonalIcon(
                            key: const ValueKey('add-booking-product'),
                            onPressed: _selectingProduct ? null : _addProduct,
                            icon: _selectingProduct
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.add_rounded),
                            label: const Text('បន្ថែមផលិតផល'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_products.isEmpty)
                        _EmptyProducts(
                          showError: _showValidationErrors,
                          onAdd: _addProduct,
                        )
                      else
                        ..._products.asMap().entries.map(
                          (entry) => _BookingProductRow(
                            draft: entry.value,
                            onChanged: () => setState(() {}),
                            onRemove: () =>
                                setState(() => _products.removeAt(entry.key)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'សរុប ${formatMoney(_totalAmount)} រៀល',
                      key: const ValueKey('new-booking-total'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('cancel-new-booking'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('បោះបង់'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    key: const ValueKey('submit-new-booking'),
                    onPressed: _submit,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(
                      widget.booking == null ? 'រក្សាទុក' : 'រក្សាការកែប្រែ',
                    ),
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

class _BookingProductDraft {
  _BookingProductDraft(this.product) : quantity = 1, price = product.price;

  _BookingProductDraft.fromBookingProduct(BookingProduct bookingProduct)
    : product = Product(
        code: bookingProduct.productCode,
        name: bookingProduct.productName,
        category: '',
        unit: bookingProduct.unit,
        price: bookingProduct.price,
        color: '#1677FF',
        photo: '',
        saleTransactionType: bookingProduct.transactionType.isEmpty
            ? 'Sale'
            : bookingProduct.transactionType,
      ),
      quantity = bookingProduct.quantity,
      price = bookingProduct.price;

  final Product product;
  double quantity;
  double price;

  Map<String, dynamic> toJson() => {
    'product_code': product.code,
    'product_name': product.name,
    'unit': product.unit,
    'quantity': quantity,
    'price': price,
    'total_amount': quantity * price,
    'transaction_type': product.saleTransactionType,
  };
}

class _BookingProductRow extends StatelessWidget {
  const _BookingProductRow({
    required this.draft,
    required this.onChanged,
    required this.onRemove,
  });

  final _BookingProductDraft draft;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      key: ValueKey('booking-product-${draft.product.code}'),
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        draft.product.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${draft.product.code} • ${draft.product.unit}',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: ValueKey('remove-booking-product-${draft.product.code}'),
                  tooltip: 'លុបផលិតផល',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey(
                      'booking-product-quantity-${draft.product.code}',
                    ),
                    initialValue: formatQuantity(draft.quantity),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'ចំនួន *',
                      suffixText: draft.product.unit,
                    ),
                    validator: _positiveNumber,
                    onChanged: (value) {
                      draft.quantity = _parseFormattedNumber(value) ?? 0;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: ValueKey(
                      'booking-product-price-${draft.product.code}',
                    ),
                    initialValue: formatQuantity(draft.price),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'តម្លៃ *',
                      suffixText: 'រៀល',
                    ),
                    validator: _nonNegativeNumber,
                    onChanged: (value) {
                      draft.price = _parseFormattedNumber(value) ?? -1;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'សរុប'),
                    child: Text(
                      formatMoney(draft.quantity * draft.price),
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<Product?> showBookingProductSelector(
  BuildContext context, {
  required DoctypeDataSource dataSource,
  Set<String> excludedCodes = const {},
}) => showDialog<Product>(
  context: context,
  builder: (_) => _BookingProductSelectorDialog(
    dataSource: dataSource,
    excludedCodes: excludedCodes,
  ),
);

class _BookingProductSelectorDialog extends StatefulWidget {
  const _BookingProductSelectorDialog({
    required this.dataSource,
    required this.excludedCodes,
  });

  final DoctypeDataSource dataSource;
  final Set<String> excludedCodes;

  @override
  State<_BookingProductSelectorDialog> createState() =>
      _BookingProductSelectorDialogState();
}

class _BookingProductSelectorDialogState
    extends State<_BookingProductSelectorDialog> {
  final _searchController = TextEditingController();
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Product>> _loadProducts() async {
    final rows = await widget.dataSource.getDoctypeRows(
      doctype: 'Product',
      fields: const [
        'name',
        'product_code',
        'product_name',
        'product_category',
        'unit',
        'price',
        'color',
        'photo',
        'default_sale_transaction_type',
      ],
      filters: const [
        ['enabled', '=', 1],
      ],
      orderBy: 'product_name asc',
      limit: 1000,
    );
    return rows
        .map(Product.fromJson)
        .where(
          (product) =>
              product.code.isNotEmpty &&
              !widget.excludedCodes.contains(product.code),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      key: const ValueKey('booking-product-selector'),
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 720),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 12, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'ជ្រើសរើសផលិតផលកក់',
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: TextField(
                key: const ValueKey('booking-product-search'),
                controller: _searchController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'ស្វែងរកផលិតផល...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<Product>>(
                future: _productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _ProductLoadError(
                      onRetry: () =>
                          setState(() => _productsFuture = _loadProducts()),
                    );
                  }
                  final query = _searchController.text.trim().toLowerCase();
                  final products = (snapshot.data ?? const <Product>[])
                      .where(
                        (product) =>
                            query.isEmpty ||
                            product.code.toLowerCase().contains(query) ||
                            product.name.toLowerCase().contains(query) ||
                            product.category.toLowerCase().contains(query),
                      )
                      .toList(growable: false);
                  if (products.isEmpty) {
                    return const Center(child: Text('រកមិនឃើញផលិតផល'));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: products.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          key: ValueKey(
                            'select-booking-product-${product.code}',
                          ),
                          leading: CircleAvatar(
                            backgroundColor: colors.primaryContainer,
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${product.code} • ${product.unit} • ${formatMoney(product.price)} រៀល',
                          ),
                          trailing: const Icon(Icons.add_circle_outline),
                          onTap: () => Navigator.of(context).pop(product),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductLoadError extends StatelessWidget {
  const _ProductLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('មិនអាចទាញយកផលិតផលបានទេ'),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('ព្យាយាមម្តងទៀត'),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    ],
  );
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 580) {
        return Column(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index < children.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            Expanded(child: children[index]),
            if (index < children.length - 1) const SizedBox(width: 14),
          ],
        ],
      );
    },
  );
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.errorText,
  });
  final Key fieldKey;
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) => InkWell(
    key: fieldKey,
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
        errorText: errorText,
      ),
      child: Text(
        value.isEmpty ? 'ជ្រើសរើស...' : value,
        style: TextStyle(
          color: value.isEmpty
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : null,
        ),
      ),
    ),
  );
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts({required this.showError, required this.onAdd});
  final bool showError;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      key: const ValueKey('new-booking-empty-products'),
      onTap: onAdd,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: showError ? colors.error : colors.outlineVariant,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.add_shopping_cart_rounded, color: colors.primary),
            const SizedBox(height: 8),
            Text(
              showError
                  ? 'សូមបន្ថែមផលិតផលយ៉ាងតិចមួយ'
                  : 'ចុចដើម្បីបន្ថែមផលិតផលកក់',
              style: TextStyle(color: showError ? colors.error : null),
            ),
          ],
        ),
      ),
    );
  }
}

String? _requiredPhone(String? value) =>
    value == null || value.trim().isEmpty ? 'សូមបញ្ចូលលេខទូរស័ព្ទ' : null;

String? _positiveNumber(String? value) {
  final number = _parseFormattedNumber(value);
  return number == null || number <= 0 ? 'ត្រូវតែធំជាង 0' : null;
}

String? _nonNegativeNumber(String? value) {
  final number = _parseFormattedNumber(value);
  return number == null || number < 0 ? 'ត្រូវតែ 0 ឬធំជាង' : null;
}

double? _parseFormattedNumber(String? value) => double.tryParse(
  (value ?? '').trim().replaceAll(',', '').replaceAll(' ', ''),
);

String _dateOnly(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
