import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/app_setting.dart';
import '../../../app/app_setting_controller.dart';
import '../../../app/app_theme.dart';
import '../../../services/customer_service.dart';
import '../../../services/frappe_response_handler.dart';
import '../../../services/receipt_print_service.dart';
import '../../../services/sale_service.dart';
import '../../../shared/input_number_dialog_widget.dart';
import '../../../shared/select_customer_dialog_widget.dart';
import '../../../utils/helpers.dart';
import '../customer.dart';
import '../sale.dart';
import '../sale_product.dart';

Future<void> showNewSplitBillDialog(
  BuildContext context, {
  required SaleService saleService,
  required CustomerService customerService,
  required Sale parentSale,
  required String stationName,
  required Future<Sale?> Function() onSaved,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _NewSplitBillDialog(
      saleService: saleService,
      customerService: customerService,
      parentSale: parentSale,
      stationName: stationName,
      onSaved: onSaved,
    ),
  );
}

class _NewSplitBillDialog extends StatefulWidget {
  const _NewSplitBillDialog({
    required this.saleService,
    required this.customerService,
    required this.parentSale,
    required this.stationName,
    required this.onSaved,
  });

  final SaleService saleService;
  final CustomerService customerService;
  final Sale parentSale;
  final String stationName;
  final Future<Sale?> Function() onSaved;

  @override
  State<_NewSplitBillDialog> createState() => _NewSplitBillDialogState();
}

class _NewSplitBillDialogState extends State<_NewSplitBillDialog> {
  final _referenceController = TextEditingController();
  final _noteController = TextEditingController();
  late Sale _parentSale;
  late List<SaleProduct> _products;
  late List<double> _quantities;
  Customer? _customer;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _parentSale = widget.parentSale;
    _setProducts(_parentSale);
  }

  void _setProducts(Sale parentSale) {
    _products = parentSale.saleProducts
        .where(
          (product) => product.allowSplitBill && product.totalSaleQuantity > 0,
        )
        .toList(growable: false);
    _quantities = List<double>.filled(_products.length, 0);
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectCustomer() async {
    final selected = await showSelectCustomerDialog(
      context,
      customerService: widget.customerService,
      selectionType: CustomerSelectionType.customer,
    );
    if (selected != null && mounted) setState(() => _customer = selected);
  }

  Future<void> _editQuantity(int index) async {
    final product = _products[index];
    final quantity = await showInputNumberDialog(
      context,
      initialValue: _quantities[index],
      allowZero: true,
    );
    if (quantity == null || !mounted) return;
    if (quantity > product.totalSaleQuantity + 0.000001) {
      showWarning(
        'ចំនួន ${product.productName} មិនអាចលើស ${formatQuantity(product.totalSaleQuantity)} ${product.unit} បានទេ។',
      );
      return;
    }
    setState(() => _quantities[index] = quantity);
  }

  Future<void> _save({bool printAfterSave = false}) async {
    final customer = _customer;
    if (customer == null) {
      showWarning('សូមជ្រើសរើសអតិថិជន។');
      return;
    }

    final selectedProducts = <SaleProduct>[];
    for (var index = 0; index < _products.length; index++) {
      final source = _products[index];
      final quantity = _quantities[index];
      if (quantity > source.totalSaleQuantity + 0.000001) {
        showWarning(
          'ចំនួន ${source.productName} មិនអាចលើស ${formatQuantity(source.totalSaleQuantity)} ${source.unit} បានទេ។',
        );
        return;
      }
      if (quantity > 0) {
        selectedProducts.add(_splitProduct(source, quantity));
      }
    }
    if (selectedProducts.isEmpty) {
      showWarning('សូមបញ្ចូលចំនួនផលិតផលយ៉ាងតិចមួយ។');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final parent = _parentSale;
      final splitSale = Sale(
        outlet: parent.outlet,
        stockLocation: parent.stockLocation,
        seller: parent.seller,
        postingDate: DateTime.now(),
        referenceNumber: _referenceController.text.trim(),
        customer: customer.name,
        customerName: customer.displayName,
        phoneNumber: customer.phoneNumber1,
        customerGroup: customer.customerGroup,
        customerPhoto: customer.photo,
        canShowPrice: customer.canShowPrice,
        canSplitBill: customer.canSplitBill,
        canEditBill: customer.canEditBill,
        driver: parent.customer,
        driverName: parent.customerName,
        driverPhoneNumber: parent.phoneNumber,
        driverPhoto: parent.customerPhoto,
        parentBillNumber: parent.name,
        saleProducts: selectedProducts,
        note: _noteController.text.trim(),
        station: widget.stationName,
        lastUpdateStation: widget.stationName,
      );
      final savedOrder = await widget.saleService.saveOrder(splitSale);
      if (!mounted) return;
      if (printAfterSave) {
        final printed = await _print(savedOrder);
        if (!mounted) return;
        if (printed) {
          showSuccess('បានបង្កើត និងបោះពុម្ពបុងបំបែកដោយជោគជ័យ។');
        } else {
          showWarning(
            'បានរក្សាទុកបុងបំបែក ប៉ុន្តែមិនអាចបោះពុម្ពវិក្កយបត្របានទេ។',
          );
        }
      } else {
        showSuccess('បានបង្កើតបុងបំបែកដោយជោគជ័យ។');
      }
      final refreshedParent = await widget.onSaved();
      if (!mounted) return;
      setState(() {
        if (refreshedParent != null) {
          _parentSale = refreshedParent;
        }
        _setProducts(_parentSale);
        _customer = null;
        _referenceController.clear();
        _noteController.clear();
      });
    } on FrappeServerMessageException {
      // The shared API handler already displayed the server response.
    } on Exception {
      showError('មិនអាចបង្កើតបុងបំបែកបានទេ។ សូមព្យាយាមម្ដងទៀត។');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _print(Map<String, dynamic> savedOrder) async {
    if (!Get.isRegistered<ReceiptPrintService>()) return false;
    final printService = Get.find<ReceiptPrintService>();
    if (!printService.beginWorkflow()) return false;
    try {
      final business = Get.isRegistered<AppSettingController>()
          ? Get.find<AppSettingController>().current
          : null;
      await printService.printSavedOrder(
        savedOrder: savedOrder,
        business: business ?? const AppSetting(raw: <String, dynamic>{}),
        sellerFallback: _parentSale.seller,
      );
      return true;
    } on Exception {
      return false;
    } finally {
      printService.endWorkflow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: (size.width - 48).clamp(0, 920),
        height: (size.height - 48).clamp(0, 800),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 10, 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'បង្កើតបុងបំបែកថ្មី',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'បិទ',
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.outlineVariant),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ParentBillSummary(sale: _parentSale),
                    const SizedBox(height: 20),
                    const Text(
                      'ព័ត៌មានបុងបំបែកថ្មី',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final fields = [
                          _CustomerField(
                            customer: _customer,
                            onTap: _selectCustomer,
                          ),
                          TextField(
                            key: const ValueKey('split-bill-reference-input'),
                            controller: _referenceController,
                            decoration: const InputDecoration(
                              labelText: 'លេខយោង',
                            ),
                          ),
                        ];
                        if (constraints.maxWidth < 620) {
                          return Column(
                            children: [
                              fields[0],
                              const SizedBox(height: 12),
                              fields[1],
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: fields[0]),
                            const SizedBox(width: 16),
                            Expanded(child: fields[1]),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'ផលិតផល',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_products.isEmpty)
                      _NoSplitProducts(colors: colors)
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 680 ? 2 : 1;
                          const spacing = 12.0;
                          final cardWidth =
                              (constraints.maxWidth - spacing * (columns - 1)) /
                              columns;
                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: List.generate(
                              _products.length,
                              (index) => SizedBox(
                                width: cardWidth,
                                child: _SplitProductCard(
                                  product: _products[index],
                                  splitQuantity: _quantities[index],
                                  onTap: () => _editQuantity(index),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const ValueKey('split-bill-note-input'),
                      controller: _noteController,
                      minLines: 4,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'កំណត់ចំណាំ',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: colors.outlineVariant),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('save-split-bill-button'),
                    onPressed: _isSaving || _products.isEmpty
                        ? null
                        : () => _save(),
                    icon: _isSaving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('រក្សាទុក'),
                  ),
                  FilledButton.icon(
                    key: const ValueKey('save-print-split-bill-button'),
                    onPressed: _isSaving || _products.isEmpty
                        ? null
                        : () => _save(printAfterSave: true),
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('រក្សាទុក និងបោះពុម្ព'),
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

SaleProduct _splitProduct(SaleProduct source, double quantity) {
  final json = source.toJson()
    ..remove('name')
    ..['quantity'] = quantity
    ..['free_quantity'] = 0
    ..['return_quantity'] = 0
    ..['split_quantity'] = 0;
  return SaleProduct.fromJson(json);
}

class _ParentBillSummary extends StatelessWidget {
  const _ParentBillSummary({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final customer = sale.customerName.trim().isEmpty
        ? sale.customer
        : sale.customerName;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ព័ត៌មានបុងមេ',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 28,
            runSpacing: 8,
            children: [
              _SummaryValue(label: 'លេខបុង', value: sale.name),
              _SummaryValue(
                label: 'កាលបរិច្ឆេទ',
                value: formatDate(sale.postingDate?.toIso8601String() ?? ''),
              ),
              _SummaryValue(
                label: 'អតិថិជន',
                value: customer.trim().isEmpty ? '-' : customer,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 230,
    child: Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(fontFamily: AppTheme.fontFamily),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CustomerField extends StatelessWidget {
  const _CustomerField({required this.customer, required this.onTap});

  final Customer? customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    key: const ValueKey('split-bill-customer-field'),
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: InputDecorator(
      decoration: const InputDecoration(
        labelText: 'អតិថិជន *',
        suffixIcon: Icon(Icons.person_search_outlined),
      ),
      child: Text(
        customer?.displayName ?? 'ជ្រើសរើសអតិថិជន',
        style: const TextStyle(fontFamily: AppTheme.fontFamily),
      ),
    ),
  );
}

class _SplitProductCard extends StatelessWidget {
  const _SplitProductCard({
    required this.product,
    required this.splitQuantity,
    required this.onTap,
  });

  final SaleProduct product;
  final double splitQuantity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasQuantity = splitQuantity > 0;
    return Card(
      key: ValueKey('split-bill-quantity-${product.productCode}'),
      margin: EdgeInsets.zero,
      color: hasQuantity
          ? colors.primaryContainer.withValues(alpha: .35)
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.touch_app_outlined, color: colors.primary),
                ],
              ),
              const SizedBox(height: 14),
              _ProductQuantityValue(
                label: 'ចំនួនអាចបំបែកបាន',
                value:
                    '${formatQuantity(product.totalSaleQuantity)} ${product.unit}',
              ),
              const SizedBox(height: 8),
              _ProductQuantityValue(
                label: 'ចំនួនបំបែក',
                value: '${formatQuantity(splitQuantity)} ${product.unit}',
                emphasized: true,
              ),
              const SizedBox(height: 12),
              Text(
                'ចុចដើម្បីបញ្ចូលចំនួន',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.primary,
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductQuantityValue extends StatelessWidget {
  const _ProductQuantityValue({
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
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: emphasized ? colors.primary : colors.onSurface,
            fontFamily: AppTheme.fontFamily,
            fontSize: emphasized ? 18 : 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _NoSplitProducts extends StatelessWidget {
  const _NoSplitProducts({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Text(
      'មិនមានផលិតផលដែលអនុញ្ញាតឱ្យបំបែកបុងទេ។',
      textAlign: TextAlign.center,
      style: TextStyle(fontFamily: AppTheme.fontFamily),
    ),
  );
}
