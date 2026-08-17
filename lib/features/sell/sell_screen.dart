import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/frappe_response_handler.dart';
import '../../shared/input_number_dialog_widget.dart';
import '../../shared/select_customer_dialog_widget.dart';
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

double _checkoutColumnWidth(double availableWidth) {
  return (availableWidth * 0.24).clamp(285.0, 350.0);
}

class SellScreen extends GetView<SellController> {
  const SellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(controller: controller),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final rightWidth = _checkoutColumnWidth(
                      constraints.maxWidth,
                    );
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _ProductPanel(controller: controller)),
                        const SizedBox(width: 12),
                        SizedBox(
                          key: const ValueKey('order-product-column'),
                          width: 360,
                          child: Obx(
                            () => OrderProductListWidget(
                              lines: controller.saleProducts.toList(),
                              date: controller.postingDate.value,
                              referenceNumber: controller.referenceNumber.value,
                              note: controller.saleNote.value,
                              imageUriBuilder: controller.saleProductImage,
                              onRemove: controller.remove,
                              onEdit: (line) async {
                                final updated = await showEditSaleOrderDialog(
                                  context,
                                  saleProduct: line,
                                );
                                if (updated != null) {
                                  controller.updateSaleProduct(updated);
                                }
                              },
                              onDateTap: () async {
                                final selected = await showSelectDateDialog(
                                  context,
                                  initialDate: controller.postingDate.value,
                                );
                                if (selected != null) {
                                  controller.updatePostingDate(selected);
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
                        const SizedBox(width: 12),
                        SizedBox(
                          width: rightWidth,
                          child: _CheckoutPanel(controller: controller),
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller});

  final SellController controller;

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
                        login.stationName,
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
                        'ទីតាំងលក់៖ ${login.outletName}',
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
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: TextField(
                  onChanged: controller.updateSearch,
                  decoration: InputDecoration(
                    hintText: 'ស្វែងរកទំនិញតាមឈ្មោះ ឬលេខកូដ',
                    prefixIcon: Icon(Icons.search_rounded),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    fillColor: context.colors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: context.colors.outlineVariant,
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
                  final isSelected =
                      controller.selectedProductCategory.value == category;
                  return FilterChip(
                    key: ValueKey(
                      category.isEmpty
                          ? 'product-category-all'
                          : 'product-category-$category',
                    ),
                    label: Text(
                      '${category.isEmpty ? 'ទាំងអស់' : category} ($productCount)',
                    ),
                    selected: isSelected,
                    showCheckmark: false,
                    avatar: category.isEmpty
                        ? const Icon(Icons.apps_rounded, size: 17)
                        : null,
                    onSelected: (_) =>
                        controller.selectProductCategory(category),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(
                      color: isSelected
                          ? context.colors.primary
                          : context.colors.outlineVariant,
                    ),
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

class _CheckoutPanel extends StatelessWidget {
  const _CheckoutPanel({required this.controller});

  final SellController controller;

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

      final selected = await showSelectCustomerDialog(
        context,
        customerService: controller.customerService,
        selectionType: CustomerSelectionType.customer,
      );
      if (selected != null) await controller.selectCustomer(selected);
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
            child: _OpenedSaleBanner(documentName: saleDocumentName),
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
            onTap: () async {
              final selected = await showSelectCustomerDialog(
                context,
                customerService: controller.customerService,
                selectionType: CustomerSelectionType.customer,
              );
              if (selected != null) await controller.selectCustomer(selected);
            },
          );
        }),
        const SizedBox(height: 12),
        Obx(() {
          final driver = controller.selectedDriver.value;
          return SelectDriverWidget(
            key: const ValueKey('driver-card'),
            driverCode: driver?.displayCode ?? '',
            driverName: driver?.displayName,
            phoneNumber: driver?.phoneNumber1 ?? '',
            plateNumber: controller.plateNumber.value,
            photoUri: driver == null ? null : controller.customerImage(driver),
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
        const SizedBox(height: 12),
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
  const _OpenedSaleBanner({required this.documentName});

  final String documentName;

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
      child: Row(
        children: [
          Icon(Icons.edit_document, size: 20, color: context.colors.primary),
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
                Text(
                  documentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w800,
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
              label: 'លុបការលក់',
              icon: Icons.delete_outline_rounded,
              color: context.colors.error,
              onPressed: controller.saleProducts.isEmpty
                  ? null
                  : controller.clearCart,
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
                        value: '${formatMoney(controller.grandTotal)} រៀល',
                        valueFontSize: 28,
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
  });

  final String label;
  final String value;
  final double valueFontSize;

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
