import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/select_date_dialog_widget.dart';
import '../../shared/note_dialog_widget.dart';
import '../../utils/helpers.dart';
import '../login/login_controller.dart';
import 'closed_sale.dart';
import 'closed_sale_controller.dart';

class ClosedSaleListScreen extends GetView<ClosedSaleController> {
  const ClosedSaleListScreen({super.key});

  static const _tableWidth = 1480.0;

  Future<void> _deleteSale(BuildContext context, ClosedSale sale) {
    if (!controller.checkDeleteBillPermission()) {
      return Future<void>.value();
    }
    return showNoteDialog(
      context,
      promptTitle: 'មូលហេតុដែលលុបបុង ${sale.name}',
      presetKey: 'delete_bill_note',
      userKey: Get.find<LoginController>().localStorageUserKey,
      allowDeletingSavedNotes: true,
      onSubmit: (note) => controller.deleteSale(sale.name, note),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final selected = await showSelectDateDialog(
      context,
      initialDate: controller.startDatePickerInitial,
    );
    if (selected == null || !context.mounted) return;
    await controller.setStartDate(selected);
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final selected = await showSelectDateDialog(
      context,
      initialDate: controller.endDatePickerInitial,
    );
    if (selected == null || !context.mounted) return;
    await controller.setEndDate(selected);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Obx(
      () => ColoredBox(
        key: const ValueKey('closed-sale-list-screen'),
        color: colors.surfaceContainerLowest,
        child: Column(
          children: [
            _AppBar(
              searchController: controller.searchController,
              hasSearchText: controller.searchText.value.isNotEmpty,
              startDate: controller.startDate.value,
              endDate: controller.endDate.value,
              isLoading: controller.isLoading.value,
              onSearchChanged: controller.handleSearchChanged,
              onClearSearch: controller.clearSearch,
              onStartDateTap: () => _selectStartDate(context),
              onClearStartDate: controller.clearStartDate,
              onEndDateTap: () => _selectEndDate(context),
              onClearEndDate: controller.clearEndDate,
              onRefresh: controller.refreshAll,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  key: const ValueKey('closed-sale-horizontal-scroll'),
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: _tableWidth,
                    height: constraints.maxHeight,
                    child: Column(
                      children: [
                        const _TableHeader(),
                        Expanded(child: _buildBody(context, colors)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ColorScheme colors) {
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

    final groupedSales = controller.groupedSales;
    return ListView(
      key: const ValueKey('closed-sale-list'),
      controller: controller.scrollController,
      children: [
        for (final group in groupedSales.entries) ...[
          _DateGroupHeader(date: group.key, count: group.value.length),
          for (var index = 0; index < group.value.length; index++)
            _ClosedSaleRow(
              sale: group.value[index],
              alternate: index.isOdd,
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

class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.searchController,
    required this.hasSearchText,
    required this.startDate,
    required this.endDate,
    required this.isLoading,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onStartDateTap,
    required this.onClearStartDate,
    required this.onEndDateTap,
    required this.onClearEndDate,
    required this.onRefresh,
  });

  final TextEditingController searchController;
  final bool hasSearchText;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isLoading;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onStartDateTap;
  final VoidCallback onClearStartDate;
  final VoidCallback onEndDateTap;
  final VoidCallback onClearEndDate;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('closed-sale-app-bar'),
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'បញ្ជីការលក់ដែលបានបិទ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 220,
            height: 42,
            child: TextField(
              key: const ValueKey('closed-sale-search-input'),
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search',
                isDense: true,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                suffixIcon: !hasSearchText
                    ? null
                    : IconButton(
                        key: const ValueKey('clear-closed-sale-search'),
                        onPressed: onClearSearch,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _DateFilter(
            filterKey: const ValueKey('closed-sale-start-date-filter'),
            clearKey: const ValueKey('clear-closed-sale-start-date'),
            placeholder: 'Start Date',
            date: startDate,
            onTap: onStartDateTap,
            onClear: onClearStartDate,
          ),
          const SizedBox(width: 8),
          _DateFilter(
            filterKey: const ValueKey('closed-sale-end-date-filter'),
            clearKey: const ValueKey('clear-closed-sale-end-date'),
            placeholder: 'End Date',
            date: endDate,
            onTap: onEndDateTap,
            onClear: onClearEndDate,
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
      width: 160,
      height: 42,
      child: Material(
        color: colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: filterKey,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 2),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: colors.primary,
                ),
                const SizedBox(width: 6),
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
                          : FontWeight.w600,
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

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: const Row(
        children: [
          _HeaderCell('លេខឯកសារ', flex: 17),
          _HeaderCell('កាលបរិច្ឆេទ', flex: 13),
          _HeaderCell('អតិថិជន', flex: 22),
          _HeaderCell('អ្នកបើកបរ', flex: 18),
          _HeaderCell('ចំនួន', flex: 10, align: TextAlign.right),
          _HeaderCell('ទឹកប្រាក់សរុប', flex: 16, align: TextAlign.right),
          _HeaderCell('ស្ថានភាព', flex: 12, align: TextAlign.center),
          _HeaderCell('បង្កើតដោយ', flex: 16),
          _HeaderCell('ពេលបង្កើត', flex: 14),
          _HeaderCell('សកម្មភាព', flex: 30, align: TextAlign.center),
        ],
      ),
    );
  }
}

class _ClosedSaleRow extends StatelessWidget {
  const _ClosedSaleRow({
    required this.sale,
    required this.alternate,
    required this.onEdit,
    required this.onDelete,
    required this.isDeleting,
  });

  final ClosedSale sale;
  final bool alternate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: ValueKey('closed-sale-${sale.name}'),
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: alternate ? colors.surfaceContainerLow : colors.surface,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          _DataCell(sale.name, flex: 17, emphasized: true),
          _DataCell(_formatDate(sale.postingDate), flex: 13),
          _DataCell(_customerLabel(sale), flex: 22),
          _DataCell(_fallback(sale.driverName), flex: 18),
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
          _DataCell(_fallback(sale.owner), flex: 16),
          _DataCell(
            formatTimeAgo(sale.creation),
            flex: 14,
            tooltip: formatExactDateTime(sale.creation),
          ),
          Expanded(
            flex: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  key: ValueKey('view-closed-sale-${sale.name}'),
                  onPressed: null,
                  icon: const Icon(Icons.visibility_outlined, size: 17),
                  label: const Text('មើល'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 7),
                FilledButton.tonalIcon(
                  key: ValueKey('edit-closed-sale-${sale.name}'),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('កែបុង'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 7),
                OutlinedButton.icon(
                  key: ValueKey('delete-closed-sale-${sale.name}'),
                  onPressed: isDeleting ? null : onDelete,
                  icon: isDeleting
                      ? const SizedBox.square(
                          dimension: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline_rounded, size: 17),
                  label: const Text('លុប'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.error,
                    side: BorderSide(color: colors.error),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    visualDensity: VisualDensity.compact,
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toLowerCase() == 'closed' ? 'បានបិទ' : _fallback(status),
        style: TextStyle(
          color: colors.onPrimaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w700,
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
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
        fontSize: 13,
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
  const _DateGroupHeader({required this.date, required this.count});

  final String date;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: ValueKey('closed-sale-date-$date'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      color: colors.primaryContainer.withValues(alpha: 0.55),
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined, size: 16, color: colors.primary),
          const SizedBox(width: 8),
          Text(
            _formatDate(date),
            style: TextStyle(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($count)',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
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
          Icon(icon, size: 44, color: colors.onSurfaceVariant),
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
