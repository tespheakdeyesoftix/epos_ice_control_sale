import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/frappe_response_handler.dart';
import '../../shared/input_number_dialog_widget.dart';
import '../../shared/note_dialog_widget.dart';
import '../../shared/select_customer_dialog_widget.dart';
import '../../shared/select_closed_order_dialog_widget.dart';
import '../../shared/select_date_dialog_widget.dart';
import '../../shared/text_input_dialog_widget.dart';
import '../../utils/helpers.dart';
import '../login/login_controller.dart';
import 'customer.dart';
import 'sell_controller.dart';
import 'widgets/order_product_list_widget.dart';
import 'widgets/pending_order_badge_widget.dart';
import 'widgets/pending_order_list_dialog_widget.dart';
import 'widgets/edit_sale_order_widget.dart';
import 'widgets/product_card_widget.dart';
import 'widgets/select_customer_widget.dart';
import 'widgets/select_driver_widget.dart';
import 'widgets/save_order_success_widget.dart';

extension on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
}

void _showCustomerChangePermissionDenied() {
  const error = CustomerChangePermissionException();
  FrappeResponseHandler.show(
    FrappeServerMessage(message: error.message, indicator: 'orange'),
  );
}

void _showSaleDateChangePermissionDenied() {
  const error = SaleDateChangePermissionException();
  FrappeResponseHandler.show(
    FrappeServerMessage(message: error.message, indicator: 'orange'),
  );
}

double _checkoutColumnWidth(double availableWidth) {
  if (availableWidth <= 1100) return 250;
  return (availableWidth * 0.24).clamp(285.0, 350.0);
}

class SellScreen extends GetView<SellController> {
  const SellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final compactLayout = MediaQuery.sizeOf(context).width <= 1100;
    return Scaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(controller: controller),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  compactLayout ? 10 : 16,
                  compactLayout ? 10 : 14,
                  compactLayout ? 10 : 16,
                  compactLayout ? 10 : 12,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final rightWidth = _checkoutColumnWidth(
                      constraints.maxWidth,
                    );
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: KeyedSubtree(
                            key: const ValueKey('product-list-column'),
                            child: _ProductPanel(controller: controller),
                          ),
                        ),
                        SizedBox(width: compactLayout ? 8 : 12),
                        SizedBox(
                          key: const ValueKey('order-product-column'),
                          width: compactLayout ? 320 : 360,
                          child: Obx(
                            () => OrderProductListWidget(
                              lines: controller.saleProducts.toList(),
                              date: controller.postingDate.value,
                              referenceNumber: controller.referenceNumber.value,
                              note: controller.saleNote.value,
                              compact: compactLayout,
                              showPrices:
                                  controller
                                      .selectedCustomer
                                      .value
                                      ?.canShowPrice ??
                                  true,
                              onCancelNewOrder: controller.isNewSaleDirty
                                  ? controller.startNewSale
                                  : null,
                              showSaleNote: controller.isSaleDirty,
                              imageUriBuilder: controller.saleProductImage,
                              onRemove: controller.remove,
                              onEdit: (line) async {
                                final sale = controller.currentSale;
                                final canShowPrice =
                                    sale.customer.trim().isEmpty ||
                                    sale.canShowPrice;
                                final updated = await showEditSaleOrderDialog(
                                  context,
                                  saleProduct: line,
                                  canShowPrice: canShowPrice,
                                  customerName: sale.customerName,
                                );
                                if (updated != null) {
                                  controller.updateSaleProduct(updated);
                                }
                              },
                              onDateTap: () async {
                                if (!controller.canChangeSaleDate) {
                                  _showSaleDateChangePermissionDenied();
                                  return;
                                }
                                final selected = await showSelectDateDialog(
                                  context,
                                  initialDate: controller.postingDate.value,
                                );
                                if (selected != null) {
                                  try {
                                    controller.updatePostingDate(selected);
                                  } on SaleDateChangePermissionException {
                                    _showSaleDateChangePermissionDenied();
                                  }
                                }
                              },
                              onReferenceTap: () async {
                                final value = await showTextInputDialog(
                                  context,
                                  title: 'លេខយោង',
                                  labelText: 'លេខយោង',
                                  hintText: 'បញ្ចូលលេខយោង',
                                  initialValue:
                                      controller.referenceNumber.value,
                                  icon: Icons.tag_rounded,
                                  maxLength: 140,
                                  inputKey: const ValueKey(
                                    'reference-number-input',
                                  ),
                                  confirmButtonKey: const ValueKey(
                                    'confirm-reference-number',
                                  ),
                                );
                                if (value != null) {
                                  controller.updateReferenceNumber(value);
                                }
                              },
                              onNoteTap: () async {
                                final value = await showTextInputDialog(
                                  context,
                                  title: 'កំណត់ចំណាំ',
                                  labelText: 'កំណត់ចំណាំការលក់',
                                  hintText: 'បញ្ចូលកំណត់ចំណាំ',
                                  initialValue: controller.saleNote.value,
                                  icon: Icons.sticky_note_2_outlined,
                                  maxLength: 500,
                                  minLines: 4,
                                  maxLines: 7,
                                  inputKey: const ValueKey('sale-note-input'),
                                  confirmButtonKey: const ValueKey(
                                    'confirm-sale-note',
                                  ),
                                );
                                if (value != null) {
                                  controller.updateSaleNote(value);
                                }
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: compactLayout ? 8 : 12),
                        SizedBox(
                          width: rightWidth,
                          child: _CheckoutPanel(
                            controller: controller,
                            compact: compactLayout,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            _BottomBar(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatefulWidget {
  const _TopBar({required this.controller});

  final SellController controller;

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  SellController get controller => widget.controller;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _selectSearchKeyword() {
    if (!mounted || _searchController.text.isEmpty) return;
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _searchFocusNode.requestFocus();
      _searchController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _searchController.text.length,
      );
    });
  }

  void _focusSearchField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  Future<void> _searchBill(String value) async {
    final keyword = value.trim();
    if (keyword.isEmpty || controller.isSearchingBill.value) return;
    try {
      await controller.searchBillForEdit(keyword);
      _searchController.clear();
      _focusSearchField();
    } on BillSearchValidationException {
      _selectSearchKeyword();
      FrappeResponseHandler.show(
        const FrappeServerMessage(
          message:
              'អាចស្វែងរកបុងបានតែនៅពេលការលក់ថ្មីមិនទាន់មានទិន្នន័យប៉ុណ្ណោះ។',
          indicator: 'orange',
        ),
      );
    } on SaleEditBlockedException catch (error) {
      _selectSearchKeyword();
      FrappeResponseHandler.show(
        FrappeServerMessage(message: error.message, indicator: 'orange'),
      );
    } on FrappeServerMessageException {
      // The shared API client already displayed the server message.
      _selectSearchKeyword();
    } on Exception {
      _selectSearchKeyword();
      FrappeResponseHandler.show(
        const FrappeServerMessage(
          message: 'មិនអាចស្វែងរកបុងនេះបានទេ។',
          indicator: 'red',
        ),
      );
    }
  }

  Future<void> _selectClosedOrder() async {
    final name = await showSelectClosedOrderDialog(
      context,
      saleService: controller.saleService,
      outlet: controller.outletName,
    );
    if (name == null || !mounted) {
      _focusSearchField();
      return;
    }
    try {
      await controller.openClosedOrder(name);
      _searchController.clear();
      _focusSearchField();
    } on ClosedSaleOpenValidationException {
      FrappeResponseHandler.show(
        const FrappeServerMessage(
          message:
              'សូមរក្សាទុក ឬបោះបង់ការលក់បច្ចុប្បន្នជាមុនសិន មុននឹងជ្រើសរើសបុងដែលបានបិទ។',
          indicator: 'orange',
        ),
      );
      _focusSearchField();
    } on SaleEditBlockedException catch (error) {
      FrappeResponseHandler.show(
        FrappeServerMessage(message: error.message, indicator: 'orange'),
      );
      _focusSearchField();
    } on SaleOrderNotClosedException {
      FrappeResponseHandler.show(
        const FrappeServerMessage(
          message: 'បុងនេះមិនមែនជាបុងដែលបានបិទទៀតទេ។',
          indicator: 'orange',
        ),
      );
      _focusSearchField();
    } on FrappeServerMessageException {
      // The shared API client already displayed the server message.
      _focusSearchField();
    } on Exception {
      FrappeResponseHandler.show(
        const FrappeServerMessage(
          message: 'មិនអាចបើកបុងដែលបានបិទនេះបានទេ។',
          indicator: 'red',
        ),
      );
      _focusSearchField();
    }
  }

  @override
  Widget build(BuildContext context) {
    final login = Get.find<LoginController>();
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          bottom: BorderSide(color: context.colors.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 330,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        login.outletName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.colors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'ម៉ាស៊ីនលក់៖ ${login.stationName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Center(
              child: Obx(
                () => SizedBox(
                  width: 320,
                  height: 42,
                  child: TextField(
                    key: const ValueKey('sale-bill-search-input'),
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    autofocus: true,
                    enabled: !controller.isSearchingBill.value,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _searchBill,
                    decoration: InputDecoration(
                      hintText: 'ស្កេន ឬបញ្ចូលលេខបុង',
                      isDense: true,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      suffixIcon: controller.isSearchingBill.value
                          ? const Padding(
                              padding: EdgeInsets.all(11),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              key: const ValueKey('select-closed-order-button'),
                              tooltip: 'ជ្រើសរើសបុងដែលបានបិទ',
                              onPressed: _selectClosedOrder,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.receipt_long_outlined,
                                size: 19,
                              ),
                            ),
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      fillColor: context.colors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: context.colors.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Obx(
            () => PendingOrderBadgeWidget(
              count: controller.pendingOrderCount.value,
              isLoading: controller.isLoadingPendingOrders.value,
              onTap: () async {
                final name = await showPendingOrderListDialog(
                  context,
                  saleService: controller.saleService,
                  outlet: controller.outletName,
                );
                if (name != null && context.mounted) {
                  try {
                    await controller.openPendingOrder(name);
                  } on PendingOrderOpenValidationException {
                    if (!context.mounted) return;
                    Get.rawSnackbar(
                      messageText: Text(
                        'សូមរក្សាទុកការលក់បច្ចុប្បន្នជាមុនសិន មុននឹងបើកការលក់ដែលបានផ្អាក។',
                        style: TextStyle(
                          color: context.colors.onInverseSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: Icon(
                        Icons.info_outline_rounded,
                        color: context.colors.onInverseSurface,
                      ),
                      snackPosition: SnackPosition.TOP,
                      snackStyle: SnackStyle.FLOATING,
                      maxWidth: 620,
                      margin: const EdgeInsets.only(top: 18),
                      borderRadius: 12,
                      backgroundColor: context.colors.inverseSurface,
                      duration: const Duration(seconds: 4),
                    );
                  } on SaleEditBlockedException catch (error) {
                    FrappeResponseHandler.show(
                      FrappeServerMessage(
                        message: error.message,
                        indicator: 'orange',
                      ),
                    );
                  } on FrappeServerMessageException {
                    // The shared API client already displayed the server message.
                  } on Exception {
                    if (!context.mounted) return;
                    Get.rawSnackbar(
                      messageText: Text(
                        'មិនអាចបើកការលក់ដែលបានផ្អាកបានទេ។',
                        style: TextStyle(
                          color: context.colors.onError,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      snackPosition: SnackPosition.TOP,
                      snackStyle: SnackStyle.FLOATING,
                      maxWidth: 520,
                      margin: const EdgeInsets.only(top: 18),
                      borderRadius: 12,
                      backgroundColor: context.colors.error,
                      duration: const Duration(seconds: 4),
                    );
                  }
                }
                await controller.loadPendingOrderCount();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductPanel extends StatelessWidget {
  const _ProductPanel({required this.controller});

  final SellController controller;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 17, 18, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'បញ្ជីទំនិញ',
                    style: TextStyle(
                      color: context.colors.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Obx(
                  () => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CountBadge('${controller.filteredProducts.length} មុខ'),
                      const SizedBox(width: 7),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          key: const ValueKey('reload-products-button'),
                          tooltip: 'ផ្ទុកបញ្ជីទំនិញឡើងវិញ',
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.loadProducts,
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            backgroundColor: context.colors.surfaceContainer,
                            foregroundColor: context.colors.primary,
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 19),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.colors.outlineVariant),
          Obx(() {
            final categories = controller.productCategories;
            final selectedCategory = controller.selectedProductCategory.value;
            if (categories.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              height: 52,
              child: ListView.separated(
                key: const ValueKey('product-category-list'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = index == 0 ? '' : categories[index - 1];
                  final productCount = controller.productCountForCategory(
                    category,
                  );
                  final isSelected = selectedCategory == category;
                  return _ProductCategoryChip(
                    chipKey: ValueKey(
                      category.isEmpty
                          ? 'product-category-all'
                          : 'product-category-$category',
                    ),
                    label:
                        '${category.isEmpty ? 'ទាំងអស់' : category} ($productCount)',
                    selected: isSelected,
                    showAllIcon: category.isEmpty,
                    onTap: () => controller.selectProductCategory(category),
                  );
                },
              ),
            );
          }),
          Divider(height: 1, color: context.colors.outlineVariant),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final error = controller.errorMessage.value;
              if (error != null) {
                return _MessageState(
                  icon: Icons.cloud_off_outlined,
                  message: error,
                  actionLabel: 'ព្យាយាមម្តងទៀត',
                  onAction: controller.loadProducts,
                );
              }
              final products = controller.filteredProducts;
              if (products.isEmpty) {
                return const _MessageState(
                  icon: Icons.inventory_2_outlined,
                  message: 'មិនមានទំនិញទេ',
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(14),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 170,
                  mainAxisExtent: 190,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductCardWidget(
                    product: product,
                    imageUri: controller.productImage(product),
                    onTap: () async {
                      if (controller.hasProduct(product)) {
                        Get.rawSnackbar(
                          messageText: Text(
                            'ទំនិញ «${product.name}» ត្រូវបានជ្រើសរើសរួចហើយ។',
                            style: TextStyle(
                              color: context.colors.onInverseSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          icon: Icon(
                            Icons.info_outline_rounded,
                            color: context.colors.onInverseSurface,
                          ),
                          snackPosition: SnackPosition.TOP,
                          snackStyle: SnackStyle.FLOATING,
                          maxWidth: 520,
                          margin: const EdgeInsets.only(top: 18),
                          borderRadius: 12,
                          backgroundColor: context.colors.inverseSurface,
                          duration: const Duration(seconds: 3),
                        );
                        return;
                      }
                      final quantity = await showInputNumberDialog(context);
                      if (quantity != null) {
                        controller.addProduct(product, quantity: quantity);
                      }
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ProductCategoryChip extends StatelessWidget {
  const _ProductCategoryChip({
    required this.chipKey,
    required this.label,
    required this.selected,
    required this.showAllIcon,
    required this.onTap,
  });

  final Key chipKey;
  final String label;
  final bool selected;
  final bool showAllIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = selected ? colors.onPrimary : colors.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        key: chipKey,
        color: selected ? colors.primary : colors.surfaceContainerLow,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          focusColor: selected
              ? colors.onPrimary.withValues(alpha: 0.12)
              : colors.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showAllIcon) ...[
                  Icon(Icons.apps_rounded, size: 17, color: foreground),
                  const SizedBox(width: 7),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckoutPanel extends StatelessWidget {
  const _CheckoutPanel({required this.controller, required this.compact});

  final SellController controller;
  final bool compact;

  Future<void> _saveOrder(BuildContext context) async {
    if (!controller.hasSelectedCustomer) {
      final selectNow = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          key: const ValueKey('missing-customer-dialog'),
          icon: const Icon(Icons.person_search_outlined),
          title: const Text('មិនទាន់ជ្រើសរើសអតិថិជន'),
          content: const Text(
            'ការលក់នេះមិនទាន់មានអតិថិជនទេ។ តើអ្នកចង់ជ្រើសរើសអតិថិជនឥឡូវនេះទេ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('បោះបង់'),
            ),
            FilledButton.icon(
              key: const ValueKey('select-customer-now'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('ជ្រើសរើសអតិថិជនឥឡូវនេះ'),
            ),
          ],
        ),
      );
      if (selectNow != true || !context.mounted) return;

      if (!controller.canChangeCustomer) {
        _showCustomerChangePermissionDenied();
        return;
      }

      final selected = await showSelectCustomerDialog(
        context,
        customerService: controller.customerService,
        selectionType: CustomerSelectionType.customer,
      );
      if (selected != null) {
        try {
          await controller.selectCustomer(selected);
        } on CustomerChangePermissionException {
          _showCustomerChangePermissionDenied();
        }
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('បញ្ជាក់ការរក្សាទុក'),
        content: const Text('តើអ្នកប្រាកដថាចង់រក្សាទុកការលក់នេះមែនទេ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('បោះបង់'),
          ),
          FilledButton.icon(
            key: const ValueKey('confirm-save-order'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.save_outlined),
            label: const Text('រក្សាទុក'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final savedOrder = await controller.saveOrder();
      controller.startNewSale();
      if (!context.mounted) return;
      await showSaveOrderSuccessDialog(context, savedOrder: savedOrder);
    } on FrappeServerMessageException {
      // The shared API client already displayed the server message.
    } on Exception {
      if (!context.mounted) return;
      Get.rawSnackbar(
        messageText: Text(
          'មិនអាចរក្សាទុកការលក់បានទេ។ សូមព្យាយាមម្ដងទៀត។',
          style: TextStyle(
            color: context.colors.onError,
            fontWeight: FontWeight.w600,
          ),
        ),
        icon: Icon(Icons.error_outline_rounded, color: context.colors.onError),
        snackPosition: SnackPosition.TOP,
        snackStyle: SnackStyle.FLOATING,
        maxWidth: 520,
        margin: const EdgeInsets.only(top: 18),
        borderRadius: 12,
        backgroundColor: context.colors.error,
        duration: const Duration(seconds: 4),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(() {
          final saleDocumentName = controller.openedSale.value?.name ?? '';
          if (saleDocumentName.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OpenedSaleBanner(
              documentName: saleDocumentName,
              onCancelEdit:
                  controller.isSaving.value || controller.isDeletingSale.value
                  ? null
                  : controller.startNewSale,
            ),
          );
        }),
        Obx(() {
          final customer = controller.selectedCustomer.value;
          return SelectCustomerWidget(
            key: const ValueKey('customer-card'),
            customerCode: customer?.displayCode ?? '',
            customerName: customer?.displayName ?? 'អតិថិជនទូទៅ',
            phoneNumber: customer?.phoneNumber1 ?? '',
            photoUri: customer == null
                ? null
                : controller.customerImage(customer),
            compact: compact,
            onClear: customer == null
                ? null
                : () {
                    try {
                      controller.clearCustomer();
                    } on CustomerChangePermissionException {
                      _showCustomerChangePermissionDenied();
                    }
                  },
            onTap: () async {
              if (!controller.canChangeCustomer) {
                _showCustomerChangePermissionDenied();
                return;
              }
              final selected = await showSelectCustomerDialog(
                context,
                customerService: controller.customerService,
                selectionType: CustomerSelectionType.customer,
              );
              if (selected != null) {
                try {
                  await controller.selectCustomer(selected);
                } on CustomerChangePermissionException {
                  _showCustomerChangePermissionDenied();
                }
              }
            },
          );
        }),
        SizedBox(height: compact ? 8 : 12),
        Obx(() {
          final driver = controller.selectedDriver.value;
          return SelectDriverWidget(
            key: const ValueKey('driver-card'),
            driverCode: driver?.displayCode ?? '',
            driverName: driver?.displayName,
            phoneNumber: driver?.phoneNumber1 ?? '',
            plateNumber: controller.plateNumber.value,
            photoUri: driver == null ? null : controller.customerImage(driver),
            compact: compact,
            onClear: controller.clearDriver,
            onChangePlateNumber: driver == null
                ? null
                : () async {
                    final value = await showTextInputDialog(
                      context,
                      title: 'ប្តូរស្លាក់លេខឡាន',
                      labelText: 'ស្លាក់លេខឡាន',
                      hintText: 'បញ្ចូលស្លាក់លេខឡាន',
                      initialValue: controller.plateNumber.value,
                      icon: Icons.directions_car_outlined,
                      maxLength: 50,
                      inputKey: const ValueKey('plate-number-input'),
                      confirmButtonKey: const ValueKey('confirm-plate-number'),
                    );
                    if (value != null) controller.updatePlateNumber(value);
                  },
            onTap: () async {
              final selected = await showSelectCustomerDialog(
                context,
                customerService: controller.customerService,
                selectionType: CustomerSelectionType.driver,
              );
              if (selected != null) controller.selectDriver(selected);
            },
          );
        }),
        SizedBox(height: compact ? 8 : 12),
        Obx(
          () => Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  label: 'បិទការលក់',
                  icon: Icons.save_outlined,
                  backgroundColor: context.colors.error,
                  foregroundColor: context.colors.onError,
                  onPressed:
                      controller.saleProducts.isEmpty ||
                          controller.isSaving.value
                      ? null
                      : () => _saveOrder(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickActionButton(
                  label: 'បោះពុម្ព\nវិក្កយបត្រ',
                  icon: Icons.print_outlined,
                  backgroundColor: const Color(0xFFF79009),
                  foregroundColor: Colors.white,
                  onPressed: controller.saleProducts.isEmpty ? null : () {},
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _OpenedSaleBanner extends StatelessWidget {
  const _OpenedSaleBanner({
    required this.documentName,
    required this.onCancelEdit,
  });

  final String documentName;
  final VoidCallback? onCancelEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('opened-sale-document-banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_document,
                size: 20,
                color: context.colors.primary,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'កំពុងកែប្រែវិក្កយបត្រ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.colors.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      documentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton(
                        key: const ValueKey('cancel-sale-edit-button'),
                        onPressed: onCancelEdit,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.colors.error,
                          side: BorderSide(
                            color: context.colors.error.withValues(alpha: 0.55),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          minimumSize: const Size(0, 30),
                          visualDensity: VisualDensity.compact,
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('បោះបង់ការកែប្រែ'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.38),
          disabledForegroundColor: foregroundColor.withValues(alpha: 0.75),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.controller});

  final SellController controller;

  Future<void> _deleteSale(BuildContext context) async {
    final saleName = controller.currentSale.name;
    if (saleName.trim().isEmpty) return;
    await showNoteDialog(
      context,
      promptTitle: 'មូលហេតុដែលលុបបុង $saleName',
      onSubmit: (note) async {
        try {
          await controller.deleteOpenedSale(note);
          FrappeResponseHandler.show(
            FrappeServerMessage(
              message: 'បានលុបបុង $saleName ដោយជោគជ័យ។',
              indicator: 'green',
            ),
          );
          return true;
        } on FrappeServerMessageException {
          // The shared API client already displayed the server message.
          return false;
        } on Exception {
          FrappeResponseHandler.show(
            const FrappeServerMessage(
              message: 'មិនអាចលុបបុងនេះបានទេ។',
              indicator: 'red',
            ),
          );
          return false;
        }
      },
    );
  }

  Future<void> _pauseSale(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('បញ្ជាក់ការផ្អាកការលក់'),
        content: const Text('តើអ្នកប្រាកដថាចង់ផ្អាកការលក់នេះមែនទេ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('បោះបង់'),
          ),
          FilledButton.icon(
            key: const ValueKey('confirm-pause-sale'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.pause_circle_outline_rounded),
            label: const Text('ផ្អាកការលក់'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final savedOrder = await controller.pauseSale();
      controller.startNewSale();
      if (!context.mounted) return;
      await showSaveOrderSuccessDialog(
        context,
        savedOrder: savedOrder,
        title: 'ផ្អាកការលក់បានជោគជ័យ',
      );
    } on FrappeServerMessageException {
      // The shared API client already displayed the server message.
    } on Exception {
      if (!context.mounted) return;
      Get.rawSnackbar(
        messageText: Text(
          'មិនអាចផ្អាកការលក់បានទេ។ សូមព្យាយាមម្ដងទៀត។',
          style: TextStyle(
            color: context.colors.onError,
            fontWeight: FontWeight.w600,
          ),
        ),
        icon: Icon(Icons.error_outline_rounded, color: context.colors.onError),
        snackPosition: SnackPosition.TOP,
        snackStyle: SnackStyle.FLOATING,
        maxWidth: 520,
        margin: const EdgeInsets.only(top: 18),
        borderRadius: 12,
        backgroundColor: context.colors.error,
        duration: const Duration(seconds: 4),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentButtonWidth = _checkoutColumnWidth(
      MediaQuery.sizeOf(context).width - 32,
    );
    return Container(
      height: 94,
      padding: const EdgeInsets.fromLTRB(18, 13, 16, 13),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.outlineVariant)),
      ),
      child: Obx(
        () => Row(
          children: [
            _BottomAction(
              key: const ValueKey('delete-sale-button'),
              label: 'លុបការលក់',
              icon: Icons.delete_outline_rounded,
              color: context.colors.error,
              onPressed:
                  controller.isDeletingSale.value ||
                      controller.isSaving.value ||
                      controller.currentSale.name.trim().isEmpty
                  ? null
                  : () => _deleteSale(context),
            ),
            const SizedBox(width: 10),
            _BottomAction(
              key: const ValueKey('pause-sale-button'),
              label: 'ផ្អាកការលក់',
              icon: Icons.pause_circle_outline_rounded,
              color: context.colors.tertiary,
              onPressed:
                  controller.saleProducts.isEmpty || controller.isSaving.value
                  ? null
                  : () => _pauseSale(context),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Container(
                height: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Flexible(
                      flex: 2,
                      child: _SaleSummaryMetric(
                        label: 'ចំនួនសរុប',
                        value: formatQuantity(controller.totalSaleQuantity),
                        valueFontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    VerticalDivider(
                      width: 1,
                      indent: 12,
                      endIndent: 12,
                      color: context.colors.outlineVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: _SaleSummaryMetric(
                        label: 'ទឹកប្រាក់សរុប',
                        value:
                            (controller.selectedCustomer.value?.canShowPrice ??
                                true)
                            ? '${formatMoney(controller.grandTotal)} រៀល'
                            : '***',
                        valueFontSize: 28,
                        valueKey: const ValueKey('sale-summary-total-amount'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              key: const ValueKey('payment-button'),
              width: paymentButtonWidth,
              height: double.infinity,
              child: FilledButton.icon(
                onPressed: controller.saleProducts.isEmpty ? null : () {},
                icon: Icon(Icons.payments_outlined),
                label: const Text(
                  'ទូទាត់ប្រាក់',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: context.colors.shadow.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: context.colors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
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
                color: context.colors.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: context.colors.primary, size: 31),
            ),
            const SizedBox(height: 15),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 14),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SaleSummaryMetric extends StatelessWidget {
  const _SaleSummaryMetric({
    required this.label,
    required this.value,
    required this.valueFontSize,
    this.valueKey,
  });

  final String label;
  final String value;
  final double valueFontSize;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.colors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                key: valueKey,
                value,
                maxLines: 1,
                style: TextStyle(
                  color: context.colors.primary,
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      height: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.35)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }
}
