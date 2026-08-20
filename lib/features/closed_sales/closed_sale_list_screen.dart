import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/app_theme.dart';
import '../../shared/network_image.dart';
import '../../shared/select_date_dialog_widget.dart';
import '../../utils/helpers.dart';
import '../pending_sales/widgets/pending_sale_view_dialog_widget.dart';
import 'closed_sale.dart';
import 'closed_sale_controller.dart';
import 'sale_detail_sreen.dart';
import 'widgets/pagger_card_widget.dart';
import 'widgets/quick_search_widget.dart';

enum _ClosedSaleContextAction { viewBillDetail }

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

  Future<void> _viewSale(BuildContext context, ClosedSale sale) {
    return showPendingSaleViewDialog(
      context,
      saleService: controller.sellController.saleService,
      name: sale.name,
    );
  }

  Future<void> _openSaleDetail(BuildContext context, ClosedSale sale) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => SaleDetailScreen(sale: sale)),
    );
  }

  Future<void> _showContextMenu(
    BuildContext context,
    ClosedSale sale,
    Offset globalPosition,
  ) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = overlay.globalToLocal(globalPosition);
    final action = await showMenu<_ClosedSaleContextAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      items: const [
        PopupMenuItem(
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
      ],
    );
    if (!context.mounted) return;
    if (action == _ClosedSaleContextAction.viewBillDetail) {
      await _openSaleDetail(context, sale);
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
        child: SingleChildScrollView(
          key: const ValueKey('closed-sale-horizontal-scroll'),
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: constraints.maxWidth - 40 < _tableWidth
                ? _tableWidth
                : constraints.maxWidth - 40,
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
    );
  }

  Widget _compactBody(
    BuildContext context,
    ColorScheme colors,
    BoxConstraints constraints,
  ) {
    return SingleChildScrollView(
      key: const ValueKey('closed-sale-horizontal-scroll'),
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        child: _listBody(context, colors, compact: true),
      ),
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

    return ListView(
      key: const ValueKey('closed-sale-list'),
      controller: controller.scrollController,
      padding: compact
          ? const EdgeInsets.fromLTRB(16, 0, 16, 20)
          : EdgeInsets.zero,
      children: [
        for (var index = 0; index < controller.sales.length; index++)
          compact
              ? _ClosedSaleCard(
                  sale: controller.sales[index],
                  imageBaseUri: controller.sellController.saleService.baseUri,
                  onContextMenu: (position) => _showContextMenu(
                    context,
                    controller.sales[index],
                    position,
                  ),
                  onOpenDetail: () =>
                      _openSaleDetail(context, controller.sales[index]),
                  onView: () => _viewSale(context, controller.sales[index]),
                )
              : _ClosedSaleRow(
                  sale: controller.sales[index],
                  imageBaseUri: controller.sellController.saleService.baseUri,
                  alternate: index.isOdd,
                  onContextMenu: (position) => _showContextMenu(
                    context,
                    controller.sales[index],
                    position,
                  ),
                  onOpenDetail: () =>
                      _openSaleDetail(context, controller.sales[index]),
                  onView: () => _viewSale(context, controller.sales[index]),
                ),
        if (controller.isLoading.value)
          const Padding(
            padding: EdgeInsets.all(18),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (controller.errorMessage.value != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextButton.icon(
              onPressed: controller.loadMore,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(controller.errorMessage.value!),
            ),
          ),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.todayCount,
    required this.isLoading,
    required this.onRefresh,
    required this.quickSearch,
  });

  final int todayCount;
  final bool isLoading;
  final VoidCallback onRefresh;
  final Widget quickSearch;

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
        _sortableHeader('លេខបុង', 16, ClosedSaleSortField.name),
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
        _sortableHeader('បង្កើតដោយ', 15, ClosedSaleSortField.owner),
        _sortableHeader('ពេលបង្កើត', 13, ClosedSaleSortField.creation),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'សកម្មភាព',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
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

class _ClosedSaleRow extends StatelessWidget {
  const _ClosedSaleRow({
    required this.sale,
    required this.imageBaseUri,
    required this.alternate,
    required this.onContextMenu,
    required this.onOpenDetail,
    required this.onView,
  });

  final ClosedSale sale;
  final Uri imageBaseUri;
  final bool alternate;
  final ValueChanged<Offset> onContextMenu;
  final VoidCallback onOpenDetail;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semanticColors = AppSemanticColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) => onContextMenu(details.globalPosition),
      child: Container(
        key: ValueKey('closed-sale-${sale.name}'),
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: sale.totalSplitBill > 0
              ? semanticColors.success.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.16
                      : 0.10,
                )
              : alternate
              ? colors.surfaceContainerLow
              : colors.surface,
          border: Border(bottom: BorderSide(color: colors.outlineVariant)),
        ),
        child: Row(
          children: [
            _DocumentLinkCell(sale: sale, onPressed: onOpenDetail),
            _DataCell(_formatDate(sale.postingDate), flex: 13),
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
            _DataCell(_fallback(sale.owner), flex: 15),
            _DataCell(
              formatTimeAgo(sale.creation),
              flex: 13,
              tooltip: formatExactDateTime(sale.creation),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _SaleActions(sale: sale, onView: onView),
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
    required this.onContextMenu,
    required this.onOpenDetail,
    required this.onView,
  });

  final ClosedSale sale;
  final Uri imageBaseUri;
  final ValueChanged<Offset> onContextMenu;
  final VoidCallback onOpenDetail;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) => onContextMenu(details.globalPosition),
      child: Card(
        key: ValueKey('closed-sale-${sale.name}'),
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
                _formatDate(sale.postingDate),
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
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            _fallback(sale.owner),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Text(
                          ' • ${formatTimeAgo(sale.creation)}',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 11,
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
          height: 38,
          child: OutlinedButton(
            key: ValueKey('view-closed-sale-${sale.name}'),
            onPressed: onView,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
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

class _DocumentLinkCell extends StatelessWidget {
  const _DocumentLinkCell({required this.sale, required this.onPressed});

  final ClosedSale sale;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: 16,
    child: Align(
      alignment: Alignment.centerLeft,
      child: _DocumentNumberButton(sale: sale, onPressed: onPressed),
    ),
  );
}

class _DocumentNumberButton extends StatelessWidget {
  const _DocumentNumberButton({required this.sale, required this.onPressed});

  final ClosedSale sale;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextButton(
      key: ValueKey('open-closed-sale-detail-${sale.name}'),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

class _DataCell extends StatelessWidget {
  const _DataCell(
    this.text, {
    required this.flex,
    this.align,
    this.emphasized = false,
    this.tooltip,
  });
  final String text;
  final int flex;
  final TextAlign? align;
  final bool emphasized;
  final String? tooltip;

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
    return Expanded(
      flex: flex,
      child: tooltip == null
          ? content
          : Tooltip(message: tooltip!, child: content),
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

String _formatDate(String value) {
  final parts = value.split('-');
  if (parts.length == 3) return '${parts[2]} / ${parts[1]} / ${parts[0]}';
  return value.isEmpty ? '-' : value;
}

String _customerLabel(ClosedSale sale) {
  if (sale.customer.isEmpty) return _fallback(sale.customerName);
  if (sale.customerName.isEmpty) return sale.customer;
  return '${sale.customer} - ${sale.customerName}';
}

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
