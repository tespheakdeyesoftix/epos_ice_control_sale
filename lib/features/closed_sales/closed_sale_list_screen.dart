import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/note_dialog_widget.dart';
import '../../shared/select_date_dialog_widget.dart';
import '../../utils/helpers.dart';
import '../login/login_controller.dart';
import '../pending_sales/widgets/pending_sale_view_dialog_widget.dart';
import 'closed_sale.dart';
import 'closed_sale_controller.dart';

class ClosedSaleListScreen extends GetView<ClosedSaleController> {
  const ClosedSaleListScreen({super.key});

  static const _desktopBreakpoint = 1040.0;
  static const _tableWidth = 1320.0;

  Future<void> _deleteSale(BuildContext context, ClosedSale sale) {
    if (!controller.checkDeleteBillPermission()) return Future.value();
    return showNoteDialog(
      context,
      promptTitle: 'មូលហេតុដែលលុបបុង ${sale.name}',
      presetKey: 'delete_bill_note',
      userKey: Get.find<LoginController>().localStorageUserKey,
      allowDeletingSavedNotes: true,
      onSubmit: (note) => controller.deleteSale(sale.name, note),
    );
  }

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
            ),
            _FilterBar(
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
            _ResultSummary(sales: controller.sales),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) =>
                    constraints.maxWidth >= _desktopBreakpoint
                    ? _desktopBody(context, colors, constraints)
                    : _compactBody(context, colors, constraints),
              ),
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
                const _TableHeader(),
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
        for (final group in controller.groupedSales.entries) ...[
          _DateGroupHeader(
            date: group.key,
            count: group.value.length,
            compact: compact,
          ),
          for (var index = 0; index < group.value.length; index++)
            compact
                ? _ClosedSaleCard(
                    sale: group.value[index],
                    onView: () => _viewSale(context, group.value[index]),
                    onEdit: () => controller.editOrder(group.value[index].name),
                    onDelete: () => _deleteSale(context, group.value[index]),
                    isDeleting: controller.deletingSaleNames.contains(
                      group.value[index].name,
                    ),
                  )
                : _ClosedSaleRow(
                    sale: group.value[index],
                    alternate: index.isOdd,
                    onView: () => _viewSale(context, group.value[index]),
                    onEdit: () => controller.editOrder(group.value[index].name),
                    onDelete: () => _deleteSale(context, group.value[index]),
                    isDeleting: controller.deletingSaleNames.contains(
                      group.value[index].name,
                    ),
                  ),
        ],
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
  });

  final int todayCount;
  final bool isLoading;
  final VoidCallback onRefresh;

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

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.searchController,
    required this.hasSearchText,
    required this.startDate,
    required this.endDate,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onStartDateTap,
    required this.onClearStartDate,
    required this.onEndDateTap,
    required this.onClearEndDate,
  });

  final TextEditingController searchController;
  final bool hasSearchText;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onStartDateTap;
  final VoidCallback onClearStartDate;
  final VoidCallback onEndDateTap;
  final VoidCallback onClearEndDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final search = SizedBox(
            height: 44,
            child: TextField(
              key: const ValueKey('closed-sale-search-input'),
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'ស្វែងរកលេខបុង ឬអតិថិជន',
                isDense: true,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: !hasSearchText
                    ? null
                    : IconButton(
                        key: const ValueKey('clear-closed-sale-search'),
                        tooltip: 'សម្អាតការស្វែងរក',
                        onPressed: onClearSearch,
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
              ),
            ),
          );
          final dates = Row(
            children: [
              Expanded(
                child: _DateFilter(
                  filterKey: const ValueKey('closed-sale-start-date-filter'),
                  clearKey: const ValueKey('clear-closed-sale-start-date'),
                  placeholder: 'ចាប់ពីថ្ងៃ',
                  date: startDate,
                  onTap: onStartDateTap,
                  onClear: onClearStartDate,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 7),
                child: Icon(Icons.arrow_forward_rounded, size: 18),
              ),
              Expanded(
                child: _DateFilter(
                  filterKey: const ValueKey('closed-sale-end-date-filter'),
                  clearKey: const ValueKey('clear-closed-sale-end-date'),
                  placeholder: 'ដល់ថ្ងៃ',
                  date: endDate,
                  onTap: onEndDateTap,
                  onClear: onClearEndDate,
                ),
              ),
            ],
          );
          if (compact) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [search, const SizedBox(height: 10), dates],
            );
          }
          return Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: 12),
              SizedBox(width: 390, child: dates),
            ],
          );
        },
      ),
    );
  }
}

class _DateFilter extends StatelessWidget {
  const _DateFilter({
    required this.filterKey,
    required this.clearKey,
    required this.placeholder,
    required this.date,
    required this.onTap,
    required this.onClear,
  });

  final Key filterKey;
  final Key clearKey;
  final String placeholder;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 44,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: filterKey,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(left: 11, right: 3),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: colors.primary,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    date == null ? placeholder : _displayDate(date!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: date == null
                          ? colors.onSurfaceVariant
                          : colors.onSurface,
                      fontSize: 12,
                      fontWeight: date == null
                          ? FontWeight.w400
                          : FontWeight.w700,
                    ),
                  ),
                ),
                if (date != null)
                  IconButton(
                    key: clearKey,
                    tooltip: 'លុបកាលបរិច្ឆេទ',
                    onPressed: onClear,
                    color: colors.error,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                    icon: const Icon(Icons.close_rounded, size: 16),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({required this.sales});

  final List<ClosedSale> sales;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final quantity = sales.fold<double>(
      0,
      (sum, sale) => sum + sale.totalSaleQuantity,
    );
    final amount = sales.fold<double>(0, (sum, sale) => sum + sale.totalAmount);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: [
          Text(
            'លទ្ធផល ${sales.length} បុង',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 14),
          _SummaryValue(
            icon: Icons.inventory_2_outlined,
            text: 'ចំនួន ${formatQuantity(quantity)}',
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _SummaryValue(
              icon: Icons.payments_outlined,
              text: 'សរុប ${formatMoney(amount)} រៀល',
            ),
          ),
          Text(
            'តាមទិន្នន័យដែលបានផ្ទុក',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ),
    ],
  );
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    color: Theme.of(context).colorScheme.surfaceContainer,
    child: const Row(
      children: [
        _HeaderCell('លេខបុង', flex: 16),
        _HeaderCell('អតិថិជន', flex: 24),
        _HeaderCell('អ្នកបើកបរ', flex: 16),
        _HeaderCell('ចំនួន', flex: 10, align: TextAlign.right),
        _HeaderCell('ទឹកប្រាក់សរុប', flex: 16, align: TextAlign.right),
        _HeaderCell('ស្ថានភាព', flex: 12, align: TextAlign.center),
        _HeaderCell('បង្កើតដោយ', flex: 15),
        _HeaderCell('ពេលបង្កើត', flex: 13),
        _HeaderCell('សកម្មភាព', flex: 26, align: TextAlign.center),
      ],
    ),
  );
}

class _ClosedSaleRow extends StatelessWidget {
  const _ClosedSaleRow({
    required this.sale,
    required this.alternate,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.isDeleting,
  });

  final ClosedSale sale;
  final bool alternate;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: ValueKey('closed-sale-${sale.name}'),
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: alternate ? colors.surfaceContainerLow : colors.surface,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          _DataCell(sale.name, flex: 16, emphasized: true),
          _DataCell(_customerLabel(sale), flex: 24),
          _DataCell(_fallback(sale.driverName), flex: 16),
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
          Expanded(
            flex: 12,
            child: Center(child: _StatusChip(status: sale.saleStatus)),
          ),
          _DataCell(_fallback(sale.owner), flex: 15),
          _DataCell(
            formatTimeAgo(sale.creation),
            flex: 13,
            tooltip: formatExactDateTime(sale.creation),
          ),
          Expanded(
            flex: 26,
            child: _SaleActions(
              sale: sale,
              onView: onView,
              onEdit: onEdit,
              onDelete: onDelete,
              isDeleting: isDeleting,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosedSaleCard extends StatelessWidget {
  const _ClosedSaleCard({
    required this.sale,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.isDeleting,
  });

  final ClosedSale sale;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
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
                  child: Text(
                    sale.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusChip(status: sale.saleStatus),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              _customerLabel(sale),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.onSurfaceVariant),
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
                _SaleActions(
                  sale: sale,
                  onView: onView,
                  onEdit: onEdit,
                  onDelete: onDelete,
                  isDeleting: isDeleting,
                ),
              ],
            ),
          ],
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
  const _SaleActions({
    required this.sale,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.isDeleting,
  });
  final ClosedSale sale;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 38,
          height: 34,
          child: OutlinedButton(
            key: ValueKey('view-closed-sale-${sale.name}'),
            onPressed: onView,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            child: const Icon(Icons.visibility_outlined, size: 19),
          ),
        ),
        IconButton(
          key: ValueKey('edit-closed-sale-${sale.name}'),
          tooltip: 'កែបុង',
          onPressed: onEdit,
          color: colors.primary,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.edit_outlined, size: 20),
        ),
        IconButton(
          key: ValueKey('delete-closed-sale-${sale.name}'),
          tooltip: 'លុប',
          onPressed: isDeleting ? null : onDelete,
          color: colors.error,
          visualDensity: VisualDensity.compact,
          icon: isDeleting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_outline_rounded, size: 20),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toLowerCase() == 'closed' ? 'បានបិទ' : _fallback(status),
        style: TextStyle(
          color: colors.onPrimaryContainer,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {required this.flex, this.align});
  final String text;
  final int flex;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Text(
      text,
      textAlign: align,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
    ),
  );
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
        fontSize: 12,
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

class _DateGroupHeader extends StatelessWidget {
  const _DateGroupHeader({
    required this.date,
    required this.count,
    required this.compact,
  });
  final String date;
  final int count;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: ValueKey('closed-sale-date-$date'),
      margin: compact ? const EdgeInsets.only(top: 4, bottom: 8) : null,
      padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 16, vertical: 9),
      color: compact ? Colors.transparent : colors.primaryContainer,
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined, size: 15, color: colors.primary),
          const SizedBox(width: 7),
          Text(
            _formatDate(date),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 7),
          Text(
            '$count បុង',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
          ),
        ],
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

String _displayDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$day / $month / ${date.year}';
}

String _fallback(String value) => value.trim().isEmpty ? '-' : value.trim();
