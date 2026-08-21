import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/app_theme.dart';
import '../../shared/network_image.dart';
import '../../shared/select_date_dialog_widget.dart';
import '../../utils/helpers.dart';
import 'closed_sale.dart';
import 'closed_sale_controller.dart';
import 'sale_detail_sreen.dart';
import 'widgets/advance_search_dialog_widget.dart';
import 'widgets/pagger_card_widget.dart';
import 'widgets/quick_search_widget.dart';

enum _ClosedSaleContextAction {
  viewBillDetail,
  printPreview,
  paymentHistory,
  editBill,
  deleteBill,
}

const _actionColumnWidth = 245.0;
const _sellerCreationGap = 18.0;
const _sellerCreationFlex = 16;
const _documentColumnWidth = 190.0;
const _pinnedColumnWidth = _documentColumnWidth + 16;
const _tableRowHeight = 64.0;

class ClosedSaleListScreen extends GetView<ClosedSaleController> {
  const ClosedSaleListScreen({super.key});

  static const _desktopBreakpoint = 1040.0;
  static const _tableWidth = 1440.0;

  Future<void> _selectDate(BuildContext context, {required bool start}) async {
    final selected = await showSelectDateDialog(
      context,
      initialDate: start
          ? controller.startDatePickerInitial
          : controller.endDatePickerInitial,
    );
    if (selected == null || !context.mounted) return;
    if (start) {
      await controller.setStartDate(selected);
    } else {
      await controller.setEndDate(selected);
    }
  }

  Future<void> _openSaleDetail(BuildContext context, ClosedSale sale) {
    return showSaleDetail(context, sale: sale);
  }

  Future<void> _openSaleDetailAction(
    BuildContext context,
    ClosedSale sale,
    SaleDetailInitialAction action,
  ) {
    return showSaleDetail(context, sale: sale, initialAction: action);
  }

  Future<void> _openPrintPreview(BuildContext context, ClosedSale sale) {
    return showClosedSalePrintPreview(context, sale: sale);
  }

  Future<void> _showAdvancedSearch(BuildContext context) async {
    final result = await showClosedSaleAdvancedSearchDialog(
      context,
      dataSource: controller.sellController.saleService,
      initialValue: ClosedSaleAdvancedSearchResult(
        customer: controller.customerFilter.value,
        driver: controller.driverFilter.value,
        status: controller.statusFilter.value,
        splitBillOnly: controller.splitBillOnly.value,
        productCode: controller.productCodeFilter.value,
        productChildDoctype: controller.productChildDoctype.value,
        sortField: controller.sortField.value,
        sortAscending: controller.sortAscending.value,
      ),
    );
    if (result == null || !context.mounted) return;
    await controller.applyAdvancedSearch(
      customer: result.customer,
      driver: result.driver,
      status: result.status,
      onlySplitBills: result.splitBillOnly,
      productCode: result.productCode,
      childDoctype: result.productChildDoctype,
      selectedSortField: result.sortField,
      ascending: result.sortAscending,
    );
  }

  Future<void> _showContextMenu(
    BuildContext context,
    ClosedSale sale,
    Offset globalPosition,
  ) async {
    final colors = Theme.of(context).colorScheme;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = overlay.globalToLocal(globalPosition);
    final action = await showMenu<_ClosedSaleContextAction>(
      context: context,
      color: colors.surfaceContainerHighest,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shadowColor: colors.shadow.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant),
      ),
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      items: [
        const PopupMenuItem(
          key: ValueKey('closed-sale-context-view-detail'),
          value: _ClosedSaleContextAction.viewBillDetail,
          child: Row(
            children: [
              Icon(Icons.receipt_long_outlined, size: 19),
              SizedBox(width: 10),
              Text('មើលលម្អិតបុង'),
            ],
          ),
        ),
        const PopupMenuItem(
          key: ValueKey('closed-sale-context-print-preview'),
          value: _ClosedSaleContextAction.printPreview,
          child: Row(
            children: [
              Icon(Icons.preview_outlined, size: 19),
              SizedBox(width: 10),
              Text('Print Preview Invoice'),
            ],
          ),
        ),
        const PopupMenuItem(
          key: ValueKey('closed-sale-context-payment-history'),
          value: _ClosedSaleContextAction.paymentHistory,
          child: Row(
            children: [
              Icon(Icons.payments_outlined, size: 19),
              SizedBox(width: 10),
              Text('View Payment History'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          key: ValueKey('closed-sale-context-edit-bill'),
          value: _ClosedSaleContextAction.editBill,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 19),
              SizedBox(width: 10),
              Text('Edit Bill'),
            ],
          ),
        ),
        PopupMenuItem(
          key: const ValueKey('closed-sale-context-delete-bill'),
          value: _ClosedSaleContextAction.deleteBill,
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 19, color: colors.error),
              const SizedBox(width: 10),
              Text('Delete Bill', style: TextStyle(color: colors.error)),
            ],
          ),
        ),
      ],
    );
    if (!context.mounted) return;
    switch (action) {
      case _ClosedSaleContextAction.viewBillDetail:
        await _openSaleDetail(context, sale);
      case _ClosedSaleContextAction.printPreview:
        await _openPrintPreview(context, sale);
      case _ClosedSaleContextAction.paymentHistory:
        await _openSaleDetailAction(
          context,
          sale,
          SaleDetailInitialAction.paymentHistory,
        );
      case _ClosedSaleContextAction.editBill:
        await _openSaleDetailAction(
          context,
          sale,
          SaleDetailInitialAction.edit,
        );
      case _ClosedSaleContextAction.deleteBill:
        await _openSaleDetailAction(
          context,
          sale,
          SaleDetailInitialAction.delete,
        );
      case null:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Obx(
      () => ColoredBox(
        key: const ValueKey('closed-sale-list-screen'),
        color: colors.surfaceContainerLow,
        child: Column(
          children: [
            _PageHeader(
              todayCount: controller.todayClosedSaleCount.value,
              isLoading: controller.isLoading.value,
              onRefresh: controller.refreshAll,
              advancedSearch: _AdvancedSearchButton(
                filterCount: controller.advancedFilterCount,
                onPressed: () => _showAdvancedSearch(context),
              ),
              quickSearch: ClosedSaleQuickSearchWidget(
                searchController: controller.searchController,
                hasSearchText: controller.searchText.value.isNotEmpty,
                startDate: controller.startDate.value,
                endDate: controller.endDate.value,
                onSearchChanged: controller.handleSearchChanged,
                onClearSearch: controller.clearSearch,
                onStartDateTap: () => _selectDate(context, start: true),
                onClearStartDate: controller.clearStartDate,
                onEndDateTap: () => _selectDate(context, start: false),
                onClearEndDate: controller.clearEndDate,
              ),
            ),
            if (controller.hasAdvancedFilters)
              _ActiveFiltersBar(
                customer: controller.customerFilter.value,
                driver: controller.driverFilter.value,
                status: controller.statusFilter.value,
                splitBillOnly: controller.splitBillOnly.value,
                productCode: controller.productCodeFilter.value,
                onClearCustomer: controller.clearCustomerFilter,
                onClearDriver: controller.clearDriverFilter,
                onClearStatus: controller.clearStatusFilter,
                onClearSplitBill: controller.clearSplitBillFilter,
                onClearProduct: controller.clearProductCodeFilter,
                onClearAll: controller.clearAdvancedFilters,
              ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) =>
                    constraints.maxWidth >= _desktopBreakpoint
                    ? _desktopBody(context, colors, constraints)
                    : _compactBody(context, colors, constraints),
              ),
            ),
            ClosedSalePagerCardWidget(
              loadedCount: controller.sales.length,
              totalCount: controller.totalRecords.value,
              isLoading: controller.isLoadingTotalRecords.value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _desktopBody(
    BuildContext context,
    ColorScheme colors,
    BoxConstraints constraints,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: _tableViewport(
          context,
          colors,
          constraints,
          width: constraints.maxWidth - 40 < _tableWidth
              ? _tableWidth
              : constraints.maxWidth - 40,
        ),
      ),
    );
  }

  Widget _compactBody(
    BuildContext context,
    ColorScheme colors,
    BoxConstraints constraints,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: _tableViewport(context, colors, constraints, width: _tableWidth),
      ),
    );
  }

  Widget _tableViewport(
    BuildContext context,
    ColorScheme colors,
    BoxConstraints constraints, {
    required double width,
  }) {
    return Stack(
      children: [
        Scrollbar(
          controller: controller.horizontalScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          interactive: true,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
            key: const ValueKey('closed-sale-horizontal-scroll'),
            controller: controller.horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              height: constraints.maxHeight,
              child: Column(
                children: [
                  _TableHeader(
                    sortField: controller.sortField.value,
                    sortAscending: controller.sortAscending.value,
                    onSort: controller.sortBy,
                  ),
                  Expanded(child: _listBody(context, colors)),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 14,
          width: _pinnedColumnWidth,
          child: _PinnedDocumentColumn(
            sales: controller.sales,
            selectedSaleName: controller.selectedSaleName.value,
            scrollController: controller.pinnedColumnScrollController,
            sortField: controller.sortField.value,
            sortAscending: controller.sortAscending.value,
            onSort: () => controller.sortBy(ClosedSaleSortField.name),
            onSelect: controller.selectSale,
            onOpenDetail: (sale) => _openSaleDetail(context, sale),
            onContextMenu: (sale, position) =>
                _showContextMenu(context, sale, position),
          ),
        ),
      ],
    );
  }

  Widget _listBody(
    BuildContext context,
    ColorScheme colors, {
    bool compact = false,
  }) {
    if (controller.sales.isEmpty && controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.sales.isEmpty && controller.errorMessage.value != null) {
      return _MessageState(
        icon: Icons.cloud_off_outlined,
        message: controller.errorMessage.value!,
        actionLabel: 'ព្យាយាមម្ដងទៀត',
        onAction: controller.loadMore,
      );
    }
    if (controller.sales.isEmpty) {
      return const _MessageState(
        icon: Icons.receipt_long_outlined,
        message: 'មិនមានការលក់ដែលបានបិទទេ។',
      );
    }

    final loadingItemCount = controller.isLoading.value ? 1 : 0;
    final errorItemCount = controller.errorMessage.value == null ? 0 : 1;
    return ListView.builder(
      key: const ValueKey('closed-sale-list'),
      controller: controller.scrollController,
      padding: compact
          ? const EdgeInsets.fromLTRB(16, 0, 16, 20)
          : const EdgeInsets.only(bottom: 18),
      itemCount: controller.sales.length + loadingItemCount + errorItemCount,
      itemBuilder: (context, index) {
        if (index < controller.sales.length) {
          final sale = controller.sales[index];
          return compact
              ? _ClosedSaleCard(
                  sale: sale,
                  imageBaseUri: controller.sellController.saleService.baseUri,
                  isSelected: controller.selectedSaleName.value == sale.name,
                  onSelect: () => controller.selectSale(sale.name),
                  onContextMenu: (position) =>
                      _showContextMenu(context, sale, position),
                  onOpenDetail: () => _openSaleDetail(context, sale),
                  onView: () => _openSaleDetail(context, sale),
                )
              : _ClosedSaleRow(
                  sale: sale,
                  imageBaseUri: controller.sellController.saleService.baseUri,
                  alternate: index.isOdd,
                  isSelected: controller.selectedSaleName.value == sale.name,
                  onSelect: () => controller.selectSale(sale.name),
                  onContextMenu: (position) =>
                      _showContextMenu(context, sale, position),
                  onOpenDetail: () => _openSaleDetail(context, sale),
                  onView: () => _openSaleDetail(context, sale),
                );
        }
        final extraIndex = index - controller.sales.length;
        if (controller.isLoading.value && extraIndex == 0) {
          return const Padding(
            padding: EdgeInsets.all(18),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(12),
          child: TextButton.icon(
            onPressed: controller.loadMore,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(controller.errorMessage.value!),
          ),
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.todayCount,
    required this.isLoading,
    required this.onRefresh,
    required this.quickSearch,
    required this.advancedSearch,
  });

  final int todayCount;
  final bool isLoading;
  final VoidCallback onRefresh;
  final Widget quickSearch;
  final Widget advancedSearch;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('closed-sale-app-bar'),
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.receipt_long_outlined, color: colors.primary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'បញ្ជីការលក់បានបិទ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  'ពិនិត្យ កែប្រែ និងគ្រប់គ្រងបុងលក់ដែលបានបិទ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (MediaQuery.sizeOf(context).width >= 1000) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'ថ្ងៃនេះ  $todayCount',
                style: TextStyle(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          quickSearch,
          const SizedBox(width: 10),
          advancedSearch,
          const SizedBox(width: 8),
          IconButton(
            key: const ValueKey('refresh-closed-sale-list'),
            tooltip: 'ផ្ទុកឡើងវិញ',
            onPressed: isLoading ? null : onRefresh,
            color: colors.primary,
            style: IconButton.styleFrom(
              backgroundColor: colors.surfaceContainerLow,
              side: BorderSide(color: colors.outlineVariant),
            ),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _AdvancedSearchButton extends StatelessWidget {
  const _AdvancedSearchButton({
    required this.filterCount,
    required this.onPressed,
  });

  final int filterCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasFilters = filterCount > 0;
    return Badge(
      isLabelVisible: hasFilters,
      label: Text('$filterCount'),
      backgroundColor: colors.tertiary,
      child: IconButton(
        key: const ValueKey('closed-sale-advanced-search'),
        tooltip: 'ស្វែងរកកម្រិតខ្ពស់',
        onPressed: onPressed,
        color: hasFilters ? colors.onPrimary : colors.primary,
        style: IconButton.styleFrom(
          backgroundColor: hasFilters
              ? colors.primary
              : colors.surfaceContainerLow,
          side: BorderSide(color: colors.outlineVariant),
        ),
        icon: const Icon(Icons.tune_rounded),
      ),
    );
  }
}

class _ActiveFiltersBar extends StatelessWidget {
  const _ActiveFiltersBar({
    required this.customer,
    required this.driver,
    required this.status,
    required this.splitBillOnly,
    required this.productCode,
    required this.onClearCustomer,
    required this.onClearDriver,
    required this.onClearStatus,
    required this.onClearSplitBill,
    required this.onClearProduct,
    required this.onClearAll,
  });

  final String customer;
  final String driver;
  final String status;
  final bool splitBillOnly;
  final String productCode;
  final VoidCallback onClearCustomer;
  final VoidCallback onClearDriver;
  final VoidCallback onClearStatus;
  final VoidCallback onClearSplitBill;
  final VoidCallback onClearProduct;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      color: colors.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              'កំពុងច្រោះ៖',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            if (customer.isNotEmpty)
              _FilterChip(
                label: 'អតិថិជន: $customer',
                onDeleted: onClearCustomer,
              ),
            if (driver.isNotEmpty)
              _FilterChip(
                label: 'អ្នកបើកបរ: $driver',
                onDeleted: onClearDriver,
              ),
            if (status.isNotEmpty)
              _FilterChip(
                label: 'ស្ថានភាព: ${_paymentStatusLabel(status)}',
                onDeleted: onClearStatus,
              ),
            if (splitBillOnly)
              _FilterChip(label: 'បុងបានបំបែក', onDeleted: onClearSplitBill),
            if (productCode.isNotEmpty)
              _FilterChip(
                label: 'ផលិតផល: $productCode',
                onDeleted: onClearProduct,
              ),
            TextButton.icon(
              onPressed: onClearAll,
              icon: const Icon(Icons.clear_all_rounded, size: 18),
              label: const Text('សម្អាតទាំងអស់'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onDeleted});

  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: InputChip(
      label: Text(label),
      onDeleted: onDeleted,
      deleteIcon: const Icon(Icons.close_rounded, size: 17),
      visualDensity: VisualDensity.compact,
    ),
  );
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
  });

  final ClosedSaleSortField sortField;
  final bool sortAscending;
  final ValueChanged<ClosedSaleSortField> onSort;

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    color: Theme.of(context).colorScheme.surfaceContainer,
    child: Row(
      children: [
        _DocumentHeaderCell(
          sortKey: const ValueKey('closed-sale-sort-name-underlay'),
          isSorted: sortField == ClosedSaleSortField.name,
          sortAscending: sortAscending,
          onTap: () => onSort(ClosedSaleSortField.name),
        ),
        _sortableHeader('កាលបរិច្ឆេទ', 13, ClosedSaleSortField.postingDate),
        _sortableHeader('អតិថិជន', 24, ClosedSaleSortField.customerName),
        _sortableHeader('អ្នកបើកបរ', 16, ClosedSaleSortField.driverName),
        _sortableHeader(
          'បុងបំបែក',
          11,
          ClosedSaleSortField.totalSplitBill,
          align: TextAlign.right,
        ),
        _sortableHeader(
          'ចំនួន',
          10,
          ClosedSaleSortField.totalSaleQuantity,
          align: TextAlign.right,
        ),
        _sortableHeader(
          'ទឹកប្រាក់សរុប',
          16,
          ClosedSaleSortField.totalAmount,
          align: TextAlign.right,
        ),
        const SizedBox(width: _sellerCreationGap),
        _sortableHeader(
          'អ្នកលក់ / ពេលបង្កើត',
          _sellerCreationFlex,
          ClosedSaleSortField.creation,
        ),
        const SizedBox(
          key: ValueKey('closed-sale-action-header'),
          width: _actionColumnWidth,
        ),
      ],
    ),
  );

  _HeaderCell _sortableHeader(
    String label,
    int flex,
    ClosedSaleSortField field, {
    TextAlign? align,
  }) {
    return _HeaderCell(
      label,
      flex: flex,
      align: align,
      sortKey: ValueKey('closed-sale-sort-${field.apiField}'),
      isSorted: sortField == field,
      sortAscending: sortAscending,
      onTap: () => onSort(field),
    );
  }
}

class _PinnedDocumentColumn extends StatelessWidget {
  const _PinnedDocumentColumn({
    required this.sales,
    required this.selectedSaleName,
    required this.scrollController,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    required this.onSelect,
    required this.onOpenDetail,
    required this.onContextMenu,
  });

  final List<ClosedSale> sales;
  final String? selectedSaleName;
  final ScrollController scrollController;
  final ClosedSaleSortField sortField;
  final bool sortAscending;
  final VoidCallback onSort;
  final ValueChanged<String> onSelect;
  final ValueChanged<ClosedSale> onOpenDetail;
  final void Function(ClosedSale sale, Offset position) onContextMenu;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(right: BorderSide(color: colors.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 5,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.only(left: 16),
            color: colors.surfaceContainer,
            alignment: Alignment.centerLeft,
            child: _DocumentHeaderCell(
              isSorted: sortField == ClosedSaleSortField.name,
              sortAscending: sortAscending,
              onTap: onSort,
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemExtent: _tableRowHeight,
              itemCount: sales.length,
              itemBuilder: (context, index) {
                final sale = sales[index];
                final selected = selectedSaleName == sale.name;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(sale.name),
                  onDoubleTap: () => onOpenDetail(sale),
                  onSecondaryTapDown: (details) =>
                      onContextMenu(sale, details.globalPosition),
                  child: Container(
                    padding: const EdgeInsets.only(left: 16, top: 9, bottom: 9),
                    decoration: BoxDecoration(
                      color: _rowBackground(
                        context,
                        sale,
                        index.isOdd,
                        selected,
                      ),
                      border: Border(
                        left: selected
                            ? BorderSide(color: colors.primary, width: 4)
                            : BorderSide.none,
                        bottom: BorderSide(color: colors.outlineVariant),
                      ),
                    ),
                    child: _DocumentLinkCell(
                      sale: sale,
                      onPressed: () => onOpenDetail(sale),
                      buttonKey: ValueKey(
                        'open-pinned-closed-sale-detail-${sale.name}',
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosedSaleRow extends StatelessWidget {
  const _ClosedSaleRow({
    required this.sale,
    required this.imageBaseUri,
    required this.alternate,
    required this.isSelected,
    required this.onSelect,
    required this.onContextMenu,
    required this.onOpenDetail,
    required this.onView,
  });

  final ClosedSale sale;
  final Uri imageBaseUri;
  final bool alternate;
  final bool isSelected;
  final VoidCallback onSelect;
  final ValueChanged<Offset> onContextMenu;
  final VoidCallback onOpenDetail;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSelect,
      onDoubleTap: onOpenDetail,
      onSecondaryTapDown: (details) => onContextMenu(details.globalPosition),
      child: Container(
        key: ValueKey('closed-sale-${sale.name}'),
        height: _tableRowHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: _rowBackground(context, sale, alternate, isSelected),
          border: Border(
            left: isSelected
                ? BorderSide(color: colors.primary, width: 4)
                : BorderSide.none,
            bottom: BorderSide(color: colors.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            _DocumentLinkCell(sale: sale, onPressed: onOpenDetail),
            _DataCell(formatDate(sale.postingDate), flex: 13),
            _CustomerCell(sale: sale, imageBaseUri: imageBaseUri),
            _DataCell(_fallback(sale.driverName), flex: 16),
            _DataCell(
              sale.totalSplitBill.toString(),
              flex: 11,
              align: TextAlign.right,
            ),
            _DataCell(
              formatQuantity(sale.totalSaleQuantity),
              flex: 10,
              align: TextAlign.right,
            ),
            _DataCell(
              '${formatMoney(sale.totalAmount)} រៀល',
              flex: 16,
              align: TextAlign.right,
              emphasized: true,
            ),
            const SizedBox(width: _sellerCreationGap),
            _SellerCreationCell(sale: sale),
            SizedBox(
              key: ValueKey('closed-sale-action-${sale.name}'),
              width: _actionColumnWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _SaleActions(sale: sale, onView: onView),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClosedSaleCard extends StatelessWidget {
  const _ClosedSaleCard({
    required this.sale,
    required this.imageBaseUri,
    required this.isSelected,
    required this.onSelect,
    required this.onContextMenu,
    required this.onOpenDetail,
    required this.onView,
  });

  final ClosedSale sale;
  final Uri imageBaseUri;
  final bool isSelected;
  final VoidCallback onSelect;
  final ValueChanged<Offset> onContextMenu;
  final VoidCallback onOpenDetail;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSelect,
      onDoubleTap: onOpenDetail,
      onSecondaryTapDown: (details) => onContextMenu(details.globalPosition),
      child: Card(
        key: ValueKey('closed-sale-${sale.name}'),
        color: isSelected
            ? colors.primaryContainer.withValues(alpha: 0.78)
            : null,
        shape: isSelected
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colors.primary, width: 2),
              )
            : null,
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _DocumentNumberButton(
                        sale: sale,
                        onPressed: onOpenDetail,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                formatDate(sale.postingDate),
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  _CustomerAvatar(sale: sale, imageBaseUri: imageBaseUri),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _customerLabel(sale),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: _CardMetric(
                      label: 'ចំនួន',
                      value: formatQuantity(sale.totalSaleQuantity),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _CardMetric(
                      label: 'ទឹកប្រាក់សរុប',
                      value: '${formatMoney(sale.totalAmount)} រៀល',
                      emphasized: true,
                    ),
                  ),
                  Expanded(
                    child: _CardMetric(
                      label: 'អ្នកបើកបរ',
                      value: _fallback(sale.driverName),
                    ),
                  ),
                  Expanded(
                    child: _CardMetric(
                      label: 'បុងបំបែក',
                      value: sale.totalSplitBill.toString(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: colors.outlineVariant),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fallback(sale.owner),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Tooltip(
                          message: formatExactDateTime(sale.creation),
                          child: Text(
                            formatTimeAgo(sale.creation),
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SaleActions(sale: sale, onView: onView),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardMetric extends StatelessWidget {
  const _CardMetric({
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
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
          ),
          const SizedBox(height: 2),
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
      ),
    );
  }
}

class _SaleActions extends StatelessWidget {
  const _SaleActions({required this.sale, required this.onView});
  final ClosedSale sale;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _StatusChip(status: sale.status),
        const SizedBox(width: 8),
        SizedBox(
          height: 34,
          child: OutlinedButton(
            key: ValueKey('view-closed-sale-${sale.name}'),
            onPressed: onView,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text(
              'មើលលម្អិត',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semanticColors = AppSemanticColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (label, backgroundColor, foregroundColor) = switch (status
        .trim()
        .toLowerCase()) {
      'paid' => (
        'បានបង់ប្រាក់',
        semanticColors.success,
        semanticColors.onSuccess,
      ),
      'unpaid' => ('មិនទាន់បង់ប្រាក់', colors.error, colors.onError),
      'partially paid' => (
        'បានបង់ប្រាក់មួយផ្នែក',
        isDark ? const Color(0xFFFFB74D) : const Color(0xFFF79009),
        isDark ? const Color(0xFF3D2400) : Colors.white,
      ),
      _ => (
        _fallback(status),
        colors.surfaceContainer,
        colors.onSurfaceVariant,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(
    this.text, {
    required this.flex,
    this.align,
    this.sortKey,
    this.isSorted = false,
    this.sortAscending = true,
    this.onTap,
  });
  final String text;
  final int flex;
  final TextAlign? align;
  final Key? sortKey;
  final bool isSorted;
  final bool sortAscending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: InkWell(
      key: sortKey,
      onTap: onTap,
      child: SizedBox.expand(
        child: Row(
          mainAxisAlignment: switch (align) {
            TextAlign.right => MainAxisAlignment.end,
            TextAlign.center => MainAxisAlignment.center,
            _ => MainAxisAlignment.start,
          },
          children: [
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: align,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            if (isSorted) ...[
              const SizedBox(width: 3),
              Icon(
                sortAscending
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 15,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _DocumentHeaderCell extends StatelessWidget {
  const _DocumentHeaderCell({
    this.sortKey = const ValueKey('closed-sale-sort-name'),
    required this.isSorted,
    required this.sortAscending,
    required this.onTap,
  });

  final Key? sortKey;
  final bool isSorted;
  final bool sortAscending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: _documentColumnWidth,
    child: InkWell(
      key: sortKey,
      onTap: onTap,
      child: Row(
        children: [
          const Flexible(
            child: Text(
              'លេខបុង',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          if (isSorted) ...[
            const SizedBox(width: 3),
            Icon(
              sortAscending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 15,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ],
      ),
    ),
  );
}

class _DocumentLinkCell extends StatelessWidget {
  const _DocumentLinkCell({
    required this.sale,
    required this.onPressed,
    this.buttonKey,
  });

  final ClosedSale sale;
  final VoidCallback onPressed;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: _documentColumnWidth,
    child: Align(
      alignment: Alignment.centerLeft,
      child: _DocumentNumberButton(
        sale: sale,
        onPressed: onPressed,
        actionKey: buttonKey,
      ),
    ),
  );
}

class _DocumentNumberButton extends StatelessWidget {
  const _DocumentNumberButton({
    required this.sale,
    required this.onPressed,
    this.actionKey,
  });

  final ClosedSale sale;
  final VoidCallback onPressed;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextButton(
      key: actionKey ?? ValueKey('open-closed-sale-detail-${sale.name}'),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: colors.primary,
        backgroundColor: colors.primaryContainer.withValues(alpha: 0.65),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 16),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              sale.name,
              softWrap: true,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
          if (sale.totalSplitBill > 0) ...[
            const SizedBox(width: 6),
            Tooltip(
              message: 'បុងបំបែក',
              child: Icon(
                Icons.call_split_rounded,
                key: ValueKey('closed-sale-split-icon-${sale.name}'),
                size: 17,
                color: AppSemanticColors.of(context).success,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CustomerCell extends StatelessWidget {
  const _CustomerCell({required this.sale, required this.imageBaseUri});

  final ClosedSale sale;
  final Uri imageBaseUri;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: 24,
    child: Row(
      children: [
        _CustomerAvatar(sale: sale, imageBaseUri: imageBaseUri),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            _customerLabel(sale),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CustomerAvatar extends StatelessWidget {
  const _CustomerAvatar({required this.sale, required this.imageBaseUri});

  final ClosedSale sale;
  final Uri imageBaseUri;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final imageUrl = _resolveImageUrl(sale.customerPhoto, imageBaseUri);
    final fallback = ColoredBox(
      color: colors.primaryContainer,
      child: Icon(
        Icons.person_rounded,
        size: 20,
        color: colors.onPrimaryContainer,
      ),
    );
    return ClipOval(
      key: ValueKey('closed-sale-customer-avatar-${sale.name}'),
      child: SizedBox.square(
        dimension: 38,
        child: imageUrl == null
            ? fallback
            : AppNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: 76,
                memCacheHeight: 76,
                placeholder: ColoredBox(color: colors.surfaceContainerHighest),
                errorWidget: fallback,
              ),
      ),
    );
  }
}

class _SellerCreationCell extends StatelessWidget {
  const _SellerCreationCell({required this.sale});

  final ClosedSale sale;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      flex: _sellerCreationFlex,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _fallback(sale.owner),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Tooltip(
            message: formatExactDateTime(sale.creation),
            child: Text(
              formatTimeAgo(sale.creation),
              textAlign: TextAlign.left,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  const _DataCell(
    this.text, {
    required this.flex,
    this.align,
    this.emphasized = false,
  });
  final String text;
  final int flex;
  final TextAlign? align;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final content = Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: align,
      style: TextStyle(
        color: emphasized ? colors.onSurface : colors.onSurfaceVariant,
        fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
        fontSize: 16,
      ),
    );
    return Expanded(flex: flex, child: content);
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
    final colors = Theme.of(context).colorScheme;
    return Center(
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
            child: Icon(icon, size: 34, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: colors.onSurfaceVariant)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

String _customerLabel(ClosedSale sale) {
  if (sale.customer.isEmpty) return _fallback(sale.customerName);
  if (sale.customerName.isEmpty) return sale.customer;
  return '${sale.customer} - ${sale.customerName}';
}

Color _rowBackground(
  BuildContext context,
  ClosedSale sale,
  bool alternate,
  bool isSelected,
) {
  final colors = Theme.of(context).colorScheme;
  if (isSelected) {
    return colors.primaryContainer.withValues(alpha: 0.78);
  }
  if (sale.totalSplitBill > 0) {
    return AppSemanticColors.of(context).success.withValues(
      alpha: Theme.of(context).brightness == Brightness.dark ? 0.16 : 0.10,
    );
  }
  return alternate ? colors.surfaceContainerLow : colors.surface;
}

String _paymentStatusLabel(String status) => switch (status.toLowerCase()) {
  'paid' => 'បានទូទាត់',
  'unpaid' => 'មិនទាន់ទូទាត់',
  'partially paid' => 'បានទូទាត់ខ្លះ',
  _ => status,
};

String? _resolveImageUrl(String value, Uri baseUri) {
  final photo = value.trim();
  if (photo.isEmpty) return null;
  final uri = Uri.tryParse(photo);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    return uri.toString();
  }
  return baseUri.resolve(photo).toString();
}

String _fallback(String value) => value.trim().isEmpty ? '-' : value.trim();
