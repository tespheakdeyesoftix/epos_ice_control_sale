import 'package:flutter/material.dart';

import '../../../services/sale_service.dart';
import '../../../shared/select_data_dialog_widget.dart';
import '../closed_sale_controller.dart';

class ClosedSaleAdvancedSearchResult {
  const ClosedSaleAdvancedSearchResult({
    required this.customer,
    required this.driver,
    required this.status,
    required this.splitBillOnly,
    required this.productCode,
    required this.productChildDoctype,
    required this.sortField,
    required this.sortAscending,
  });

  final String customer;
  final String driver;
  final String status;
  final bool splitBillOnly;
  final String productCode;
  final String productChildDoctype;
  final ClosedSaleSortField sortField;
  final bool sortAscending;

  bool get hasFilters =>
      customer.isNotEmpty ||
      driver.isNotEmpty ||
      status.isNotEmpty ||
      splitBillOnly ||
      productCode.isNotEmpty;
}

Future<ClosedSaleAdvancedSearchResult?> showClosedSaleAdvancedSearchDialog(
  BuildContext context, {
  required SaleService dataSource,
  required ClosedSaleAdvancedSearchResult initialValue,
}) {
  return showDialog<ClosedSaleAdvancedSearchResult>(
    context: context,
    builder: (_) => AdvanceSearchDialogWidget(
      dataSource: dataSource,
      initialValue: initialValue,
    ),
  );
}

class AdvanceSearchDialogWidget extends StatefulWidget {
  const AdvanceSearchDialogWidget({
    super.key,
    required this.dataSource,
    required this.initialValue,
  });

  final SaleService dataSource;
  final ClosedSaleAdvancedSearchResult initialValue;

  @override
  State<AdvanceSearchDialogWidget> createState() =>
      _AdvanceSearchDialogWidgetState();
}

class _AdvanceSearchDialogWidgetState extends State<AdvanceSearchDialogWidget> {
  late String _customer = widget.initialValue.customer;
  late String _customerTitle = widget.initialValue.customer;
  late String _driver = widget.initialValue.driver;
  late String _driverTitle = widget.initialValue.driver;
  late String _status = widget.initialValue.status;
  late bool _splitBillOnly = widget.initialValue.splitBillOnly;
  late String _productCode = widget.initialValue.productCode;
  late String _productTitle = widget.initialValue.productCode;
  late String _productChildDoctype = widget.initialValue.productChildDoctype;
  late ClosedSaleSortField _sortField = widget.initialValue.sortField;
  late bool _sortAscending = widget.initialValue.sortAscending;

  String _customerDoctype = 'Customer';
  String _driverDoctype = 'Customer';
  String _productDoctype = 'Product';
  List<String> _statusOptions = const ['Paid', 'Unpaid', 'Partially Paid'];
  bool _loadingMeta = true;
  String? _metaWarning;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    try {
      final saleMeta = _normalizeMeta(
        await widget.dataSource.getDoctypeMeta('Sale'),
      );
      final fields = _metaFields(saleMeta);
      _customerDoctype = _fieldOptions(fields, 'customer', _customerDoctype);
      _driverDoctype = _fieldOptions(fields, 'driver', _driverDoctype);

      final statusField = _findField(fields, 'status');
      final statusOptions = _text(statusField?['options'])
          .split('\n')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
      if (statusOptions.isNotEmpty) _statusOptions = statusOptions;

      final tableField = fields.cast<Map<String, dynamic>?>().firstWhere(
        (field) =>
            _text(field?['fieldtype']).startsWith('Table') &&
            (_text(field?['fieldname']) == 'sale_products' ||
                _text(
                  field?['options'],
                ).toLowerCase().contains('sale product')),
        orElse: () => null,
      );
      final childDoctype = _text(tableField?['options']);
      if (childDoctype.isNotEmpty) _productChildDoctype = childDoctype;
      final childMeta = _normalizeMeta(
        await widget.dataSource.getDoctypeMeta(_productChildDoctype),
      );
      _productDoctype = _fieldOptions(
        _metaFields(childMeta),
        'product_code',
        _productDoctype,
      );
    } on Exception {
      _metaWarning = 'មិនអាចអាន Meta បានទេ។ កំពុងប្រើការកំណត់លំនាំដើម។';
    } finally {
      if (mounted) setState(() => _loadingMeta = false);
    }
  }

  Future<void> _selectCustomer() async {
    final value = await showSelectDataDialog(
      context,
      dataSource: widget.dataSource,
      doctype: _customerDoctype,
      label: 'ជ្រើសរើសអតិថិជន',
      filters: const [
        ['enabled', '=', 1],
        ['is_customer', '=', 1],
      ],
    );
    if (value != null && mounted) {
      setState(() {
        _customer = value.name;
        _customerTitle = value.title;
      });
    }
  }

  Future<void> _selectDriver() async {
    final value = await showSelectDataDialog(
      context,
      dataSource: widget.dataSource,
      doctype: _driverDoctype,
      label: 'ជ្រើសរើសអ្នកបើកបរ',
      filters: const [
        ['enabled', '=', 1],
        ['is_driver', '=', 1],
      ],
    );
    if (value != null && mounted) {
      setState(() {
        _driver = value.name;
        _driverTitle = value.title;
      });
    }
  }

  Future<void> _selectProduct() async {
    final value = await showSelectDataDialog(
      context,
      dataSource: widget.dataSource,
      doctype: _productDoctype,
      label: 'ជ្រើសរើសផលិតផល',
    );
    if (value != null && mounted) {
      setState(() {
        _productCode = value.name;
        _productTitle = value.title;
      });
    }
  }

  void _clear() {
    setState(() {
      _customer = '';
      _customerTitle = '';
      _driver = '';
      _driverTitle = '';
      _status = '';
      _splitBillOnly = false;
      _productCode = '';
      _productTitle = '';
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      ClosedSaleAdvancedSearchResult(
        customer: _customer,
        driver: _driver,
        status: _status,
        splitBillOnly: _splitBillOnly,
        productCode: _productCode,
        productChildDoctype: _productChildDoctype,
        sortField: _sortField,
        sortAscending: _sortAscending,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final visibleStatusOptions = <String>{
      ..._statusOptions,
      if (_status.isNotEmpty) _status,
    }.toList(growable: false);
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 12, 12),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, color: colors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ស្វែងរកកម្រិតខ្ពស់',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'បិទ',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_loadingMeta) const LinearProgressIndicator(),
                    if (_metaWarning != null) ...[
                      Text(
                        _metaWarning!,
                        style: TextStyle(color: colors.error, fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                    ],
                    _LinkField(
                      label: 'អតិថិជន',
                      value: _customerTitle,
                      enabled: !_loadingMeta,
                      onTap: _selectCustomer,
                      onClear: _customer.isEmpty
                          ? null
                          : () => setState(() {
                              _customer = '';
                              _customerTitle = '';
                            }),
                    ),
                    const SizedBox(height: 14),
                    _LinkField(
                      label: 'អ្នកបើកបរ',
                      value: _driverTitle,
                      enabled: !_loadingMeta,
                      onTap: _selectDriver,
                      onClear: _driver.isEmpty
                          ? null
                          : () => setState(() {
                              _driver = '';
                              _driverTitle = '';
                            }),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      key: ValueKey('closed-sale-status-$_status'),
                      initialValue: _status.isEmpty ? null : _status,
                      decoration: const InputDecoration(
                        labelText: 'ស្ថានភាពការទូទាត់',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      items: visibleStatusOptions
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(_statusLabel(status)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) =>
                          setState(() => _status = value ?? ''),
                    ),
                    const SizedBox(height: 14),
                    _LinkField(
                      label: 'កូដផលិតផល',
                      value: _productTitle,
                      enabled: !_loadingMeta,
                      icon: Icons.inventory_2_outlined,
                      onTap: _selectProduct,
                      onClear: _productCode.isEmpty
                          ? null
                          : () => setState(() {
                              _productCode = '';
                              _productTitle = '';
                            }),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      key: const ValueKey('closed-sale-split-bill-filter'),
                      value: _splitBillOnly,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('បង្ហាញតែបុងដែលបានបំបែក'),
                      subtitle: const Text('ចំនួនបំបែកបុងធំជាង 1'),
                      onChanged: (value) =>
                          setState(() => _splitBillOnly = value ?? false),
                    ),
                    const Divider(height: 28),
                    Text(
                      'តម្រៀបតាម',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<ClosedSaleSortField>(
                            initialValue: _sortField,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.sort_rounded),
                            ),
                            items: ClosedSaleSortField.values
                                .map(
                                  (field) => DropdownMenuItem(
                                    value: field,
                                    child: Text(_sortLabel(field)),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) => setState(
                              () => _sortField = value ?? _sortField,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<bool>(
                            initialValue: _sortAscending,
                            decoration: const InputDecoration(),
                            items: const [
                              DropdownMenuItem(value: true, child: Text('ឡើង')),
                              DropdownMenuItem(
                                value: false,
                                child: Text('ចុះ'),
                              ),
                            ],
                            onChanged: (value) => setState(
                              () => _sortAscending = value ?? _sortAscending,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.clear_all_rounded),
                    label: const Text('សម្អាត'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    key: const ValueKey('apply-closed-sale-advanced-search'),
                    onPressed: _loadingMeta ? null : _apply,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('ស្វែងរក'),
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

class _LinkField extends StatelessWidget {
  const _LinkField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
    this.onClear,
    this.icon = Icons.link_rounded,
  });

  final String label;
  final String value;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final IconData icon;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: enabled ? onTap : null,
    borderRadius: BorderRadius.circular(12),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: onClear == null
            ? const Icon(Icons.arrow_drop_down_rounded)
            : IconButton(
                tooltip: 'សម្អាត',
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              ),
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

Map<String, dynamic> _normalizeMeta(Map<String, dynamic> value) {
  dynamic meta = value;
  if (meta is Map && meta['meta'] is Map) meta = meta['meta'];
  if (meta is Map &&
      meta['docs'] is List &&
      (meta['docs'] as List).isNotEmpty) {
    meta = (meta['docs'] as List).first;
  }
  return meta is Map ? Map<String, dynamic>.from(meta) : <String, dynamic>{};
}

List<Map<String, dynamic>> _metaFields(Map<String, dynamic> meta) {
  final fields = meta['fields'];
  if (fields is! List) return const [];
  return fields
      .whereType<Map>()
      .map((field) => Map<String, dynamic>.from(field))
      .toList(growable: false);
}

Map<String, dynamic>? _findField(
  List<Map<String, dynamic>> fields,
  String fieldname,
) {
  for (final field in fields) {
    if (_text(field['fieldname']) == fieldname) return field;
  }
  return null;
}

String _fieldOptions(
  List<Map<String, dynamic>> fields,
  String fieldname,
  String fallback,
) {
  final options = _text(_findField(fields, fieldname)?['options']);
  return options.isEmpty ? fallback : options;
}

String _statusLabel(String status) => switch (status.toLowerCase()) {
  'paid' => 'បានទូទាត់',
  'unpaid' => 'មិនទាន់ទូទាត់',
  'partially paid' => 'បានទូទាត់ខ្លះ',
  _ => status,
};

String _sortLabel(ClosedSaleSortField field) => switch (field) {
  ClosedSaleSortField.name => 'លេខបុង',
  ClosedSaleSortField.postingDate => 'ថ្ងៃចុះបញ្ជី',
  ClosedSaleSortField.customerName => 'អតិថិជន',
  ClosedSaleSortField.driverName => 'អ្នកបើកបរ',
  ClosedSaleSortField.totalSplitBill => 'ចំនួនបំបែកបុង',
  ClosedSaleSortField.totalSaleQuantity => 'ចំនួនលក់សរុប',
  ClosedSaleSortField.totalAmount => 'ទឹកប្រាក់សរុប',
  ClosedSaleSortField.creation => 'ថ្ងៃបង្កើត',
};

String _text(Object? value) => value?.toString().trim() ?? '';
