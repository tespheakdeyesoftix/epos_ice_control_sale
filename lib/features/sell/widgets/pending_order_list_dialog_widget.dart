import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/frappe_response_handler.dart';
import '../../../services/sale_service.dart';
import '../../../shared/select_date_dialog_widget.dart';
import '../../../utils/helpers.dart';
import '../pending_order.dart';

Future<String?> showPendingOrderListDialog(
  BuildContext context, {
  required SaleService saleService,
  required String outlet,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) =>
        PendingOrderListDialogWidget(saleService: saleService, outlet: outlet),
  );
}

class PendingOrderListDialogWidget extends StatefulWidget {
  const PendingOrderListDialogWidget({
    super.key,
    required this.saleService,
    required this.outlet,
    this.embedded = false,
    this.onView,
    this.onEdit,
    this.onRefreshed,
  });

  final SaleService saleService;
  final String outlet;
  final bool embedded;
  final ValueChanged<String>? onView;
  final ValueChanged<String>? onEdit;
  final VoidCallback? onRefreshed;

  @override
  State<PendingOrderListDialogWidget> createState() =>
      _PendingOrderListDialogWidgetState();
}

class _PendingOrderListDialogWidgetState
    extends State<PendingOrderListDialogWidget> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _orders = <PendingOrder>[];
  Timer? _searchDebounce;
  DateTime? _postingDate;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.position.extentAfter < 220) _loadMore();
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final page = await widget.saleService.getPendingOrders(
        outlet: widget.outlet,
        search: _searchController.text,
        postingDate: _postingDate == null ? '' : _apiDate(_postingDate!),
        offset: _orders.length,
      );
      if (!mounted) return;
      setState(() {
        _orders.addAll(page.items);
        _hasMore = page.hasMore;
      });
    } on FrappeServerMessageException {
      // The shared API client already displayed the server message.
    } on Exception {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'មិនអាចទាញយកការលក់ដែលបានផ្អាកបានទេ។';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _orders.clear();
      _hasMore = true;
      _errorMessage = null;
    });
    await _loadMore();
    widget.onRefreshed?.call();
  }

  void _handleSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _refresh);
  }

  Future<void> _selectPostingDate() async {
    final selected = await showSelectDateDialog(
      context,
      initialDate: _postingDate ?? DateTime.now(),
    );
    if (selected == null || !mounted) return;
    setState(() => _postingDate = selected);
    await _refresh();
  }

  Future<void> _clearPostingDate() async {
    setState(() => _postingDate = null);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final content = Column(
      children: [
        Container(
          key: widget.embedded
              ? const ValueKey('pending-screen-app-bar')
              : null,
          height: widget.embedded ? 82 : 58,
          padding: EdgeInsets.only(
            left: widget.embedded ? 24 : 20,
            right: widget.embedded ? 20 : 0,
          ),
          decoration: BoxDecoration(
            color: widget.embedded ? colors.surface : colors.inverseSurface,
            border: widget.embedded
                ? Border(bottom: BorderSide(color: colors.outlineVariant))
                : null,
          ),
          child: Row(
            children: [
              if (!widget.embedded) ...[
                Icon(
                  Icons.pending_actions_rounded,
                  color: colors.onInverseSurface,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  'បញ្ជីការលក់ដែលបានផ្អាក',
                  style: TextStyle(
                    color: widget.embedded
                        ? colors.onSurface
                        : colors.onInverseSurface,
                    fontSize: widget.embedded ? 22 : 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _FilterBar(
                searchController: _searchController,
                postingDate: _postingDate,
                onSearchChanged: _handleSearchChanged,
                onClearSearch: () {
                  _searchController.clear();
                  _handleSearchChanged('');
                },
                onDateTap: _selectPostingDate,
                onClearDate: _clearPostingDate,
              ),
              const SizedBox(width: 10),
              IconButton(
                key: const ValueKey('refresh-pending-order-list'),
                tooltip: 'ផ្ទុកឡើងវិញ',
                onPressed: _isLoading ? null : _refresh,
                color: widget.embedded
                    ? colors.primary
                    : colors.onInverseSurface,
                style: widget.embedded
                    ? IconButton.styleFrom(
                        backgroundColor: colors.surfaceContainerLow,
                        side: BorderSide(color: colors.outlineVariant),
                      )
                    : null,
                icon: const Icon(Icons.refresh_rounded),
              ),
              if (!widget.embedded)
                SizedBox(
                  width: 58,
                  height: 58,
                  child: IconButton(
                    key: const ValueKey('close-pending-order-list'),
                    tooltip: 'បិទ',
                    onPressed: () => Navigator.of(context).pop(),
                    color: colors.onError,
                    style: IconButton.styleFrom(
                      backgroundColor: colors.error,
                      shape: const RoundedRectangleBorder(),
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
            ],
          ),
        ),
        _TableHeader(colors: colors, showActions: widget.embedded),
        Expanded(child: _buildBody(colors)),
      ],
    );
    if (widget.embedded) {
      return ColoredBox(
        key: const ValueKey('pending-order-list-screen'),
        color: colors.surfaceContainerLowest,
        child: content,
      );
    }
    return Dialog(
      key: const ValueKey('pending-order-list-dialog'),
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(width: 1050, height: 680, child: content),
    );
  }

  Widget _buildBody(ColorScheme colors) {
    if (_orders.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_orders.isEmpty && _errorMessage != null) {
      return _MessageState(
        icon: Icons.cloud_off_outlined,
        message: _errorMessage!,
        actionLabel: 'ព្យាយាមម្ដងទៀត',
        onAction: _loadMore,
      );
    }
    if (_orders.isEmpty) {
      return const _MessageState(
        icon: Icons.inventory_2_outlined,
        message: 'មិនមានការលក់ដែលបានផ្អាកទេ។',
      );
    }

    final groupedOrders = <String, List<PendingOrder>>{};
    for (final order in _orders) {
      groupedOrders.putIfAbsent(order.postingDate, () => []).add(order);
    }
    return ListView(
      key: const ValueKey('pending-order-list'),
      controller: _scrollController,
      children: [
        for (final group in groupedOrders.entries) ...[
          _DateGroupHeader(date: group.key, count: group.value.length),
          for (var index = 0; index < group.value.length; index++)
            _PendingOrderRow(
              order: group.value[index],
              alternate: index.isOdd,
              onTap: widget.embedded
                  ? null
                  : () => Navigator.of(context).pop(group.value[index].name),
              onView: widget.embedded ? widget.onView : null,
              onEdit: widget.embedded ? widget.onEdit : null,
            ),
        ],
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(18),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextButton.icon(
              onPressed: _loadMore,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_errorMessage!),
            ),
          ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.searchController,
    required this.postingDate,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onDateTap,
    required this.onClearDate,
  });

  final TextEditingController searchController;
  final DateTime? postingDate;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onDateTap;
  final VoidCallback onClearDate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 220,
          height: 42,
          child: TextField(
            key: const ValueKey('pending-order-search-input'),
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search',
              isDense: true,
              fillColor: colors.surfaceContainerLow,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      key: const ValueKey('clear-pending-order-search'),
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
        const SizedBox(width: 8),
        SizedBox(
          width: 180,
          height: 42,
          child: Material(
            color: colors.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colors.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const ValueKey('pending-order-date-filter'),
              onTap: onDateTap,
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
                        postingDate == null
                            ? 'កាលបរិច្ឆេទ'
                            : _displayDate(postingDate!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: postingDate == null
                              ? colors.onSurfaceVariant
                              : colors.onSurface,
                          fontSize: 12,
                          fontWeight: postingDate == null
                              ? FontWeight.w400
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (postingDate != null)
                      IconButton(
                        key: const ValueKey('clear-pending-order-date'),
                        tooltip: 'លុបកាលបរិច្ឆេទ',
                        onPressed: onClearDate,
                        color: colors.error,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        icon: const Icon(Icons.close_rounded, size: 17),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.colors, required this.showActions});

  final ColorScheme colors;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          _HeaderCell('លេខឯកសារ', flex: 18),
          _HeaderCell('កាលបរិច្ឆេទ', flex: 15),
          _HeaderCell('អតិថិជន', flex: 22),
          _HeaderCell('អ្នកបើកបរ', flex: 22),
          _HeaderCell('ចំនួនសរុប', flex: 12, textAlign: TextAlign.right),
          _HeaderCell('ទឹកប្រាក់សរុប', flex: 17, textAlign: TextAlign.right),
          if (showActions)
            _HeaderCell('សកម្មភាព', flex: 24, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {required this.flex, this.textAlign});

  final String label;
  final int flex;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: textAlign,
        style: TextStyle(
          color: colors.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
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
      key: ValueKey('pending-order-date-$date'),
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

class _PendingOrderRow extends StatelessWidget {
  const _PendingOrderRow({
    required this.order,
    required this.alternate,
    required this.onTap,
    required this.onView,
    required this.onEdit,
  });

  final PendingOrder order;
  final bool alternate;
  final VoidCallback? onTap;
  final ValueChanged<String>? onView;
  final ValueChanged<String>? onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      key: ValueKey('pending-order-${order.name}'),
      color: alternate ? colors.surfaceContainerLow : colors.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            children: [
              _DataCell(order.name, flex: 18, emphasized: true),
              _DataCell(_formatDate(order.postingDate), flex: 15),
              _DataCell(_customerLabel(order), flex: 22),
              _DataCell(_fallback(order.driverName), flex: 22),
              _DataCell(
                formatQuantity(order.totalSaleQuantity),
                flex: 12,
                textAlign: TextAlign.right,
              ),
              _DataCell(
                '${formatMoney(order.totalAmount)} រៀល',
                flex: 17,
                textAlign: TextAlign.right,
                emphasized: true,
              ),
              if (onView != null || onEdit != null)
                Expanded(
                  flex: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        key: ValueKey('view-pending-order-${order.name}'),
                        onPressed: onView == null
                            ? null
                            : () => onView!(order.name),
                        icon: const Icon(Icons.visibility_outlined, size: 17),
                        label: const Text('មើល'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: 7),
                      FilledButton.tonalIcon(
                        key: ValueKey('edit-pending-order-${order.name}'),
                        onPressed: onEdit == null
                            ? null
                            : () => onEdit!(order.name),
                        icon: const Icon(Icons.edit_outlined, size: 17),
                        label: const Text('កែបុង'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  const _DataCell(
    this.value, {
    required this.flex,
    this.textAlign,
    this.emphasized = false,
  });

  final String value;
  final int flex;
  final TextAlign? textAlign;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
        style: TextStyle(
          color: emphasized ? colors.onSurface : colors.onSurfaceVariant,
          fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
          fontSize: 13,
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

String _customerLabel(PendingOrder order) {
  final customer = order.customer.trim();
  final customerName = order.customerName.trim();
  if (customer.isEmpty) return _fallback(customerName);
  if (customerName.isEmpty) return customer;
  return '$customer - $customerName';
}

String _apiDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _displayDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$day / $month / ${date.year}';
}

String _fallback(String value) => value.trim().isEmpty ? '-' : value.trim();
