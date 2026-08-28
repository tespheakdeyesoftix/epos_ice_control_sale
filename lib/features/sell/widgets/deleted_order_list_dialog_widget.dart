import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../services/frappe_response_handler.dart';
import '../../../services/sale_service.dart';
import '../../../shared/select_date_dialog_widget.dart';
import '../../../utils/helpers.dart';
import '../../closed_sales/closed_sale.dart';
import '../deleted_order.dart';

Future<void> showDeletedOrderListDialog(
  BuildContext context, {
  required SaleService saleService,
  required String outlet,
  required ValueChanged<ClosedSale> onView,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => DeletedOrderListDialogWidget(
      saleService: saleService,
      outlet: outlet,
      onView: onView,
    ),
  );
}

class DeletedOrderListDialogWidget extends StatefulWidget {
  const DeletedOrderListDialogWidget({
    super.key,
    required this.saleService,
    required this.outlet,
    required this.onView,
  });

  final SaleService saleService;
  final String outlet;
  final ValueChanged<ClosedSale> onView;

  @override
  State<DeletedOrderListDialogWidget> createState() =>
      _DeletedOrderListDialogWidgetState();
}

class _DeletedOrderListDialogWidgetState
    extends State<DeletedOrderListDialogWidget> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _orders = <DeletedOrder>[];
  Timer? _searchDebounce;
  DateTime? _postingDate = DateTime.now();
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
      final page = await widget.saleService.getDeletedOrders(
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
        _errorMessage = 'មិនអាចទាញយកបញ្ជីការលក់ដែលបានលុបបានទេ។';
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
    return Dialog(
      key: const ValueKey('deleted-order-list-dialog'),
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: 1380,
        height: 700,
        child: Column(
          children: [
            _DialogHeader(
              searchController: _searchController,
              postingDate: _postingDate,
              isLoading: _isLoading,
              onSearchChanged: _handleSearchChanged,
              onClearSearch: () {
                _searchController.clear();
                _handleSearchChanged('');
              },
              onDateTap: _selectPostingDate,
              onClearDate: _clearPostingDate,
              onRefresh: _refresh,
            ),
            _TableHeader(colors: colors),
            Expanded(child: _buildBody(colors)),
          ],
        ),
      ),
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
        icon: Icons.delete_sweep_outlined,
        message: 'មិនមានការលក់ដែលបានលុបទេ។',
      );
    }

    return ListView.builder(
      key: const ValueKey('deleted-order-list'),
      controller: _scrollController,
      itemCount: _orders.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _orders.length) {
          return const Padding(
            padding: EdgeInsets.all(18),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _DeletedOrderRow(
          order: _orders[index],
          alternate: index.isOdd,
          onView: () => widget.onView(_orders[index].sale),
        );
      },
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.searchController,
    required this.postingDate,
    required this.isLoading,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onDateTap,
    required this.onClearDate,
    required this.onRefresh,
  });

  final TextEditingController searchController;
  final DateTime? postingDate;
  final bool isLoading;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onDateTap;
  final VoidCallback onClearDate;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = colors.onInverseSurface;
    final muted = foreground.withValues(alpha: 0.68);
    final border = foreground.withValues(alpha: 0.24);
    return Container(
      height: 64,
      padding: const EdgeInsets.only(left: 20),
      color: colors.inverseSurface,
      child: Row(
        children: [
          Icon(Icons.delete_sweep_outlined, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'បញ្ជីការលក់ដែលបានលុប',
              style: TextStyle(
                color: foreground,
                fontFamily: AppTheme.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 230,
            height: 42,
            child: TextField(
              key: const ValueKey('deleted-order-search-input'),
              controller: searchController,
              onChanged: onSearchChanged,
              cursorColor: foreground,
              style: TextStyle(
                color: foreground,
                fontFamily: AppTheme.fontFamily,
              ),
              decoration: InputDecoration(
                hintText: 'ស្វែងរក',
                hintStyle: TextStyle(color: muted),
                filled: true,
                fillColor: colors.inverseSurface,
                prefixIcon: Icon(Icons.search_rounded, color: muted, size: 20),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        key: const ValueKey('clear-deleted-order-search'),
                        onPressed: onClearSearch,
                        icon: Icon(Icons.close_rounded, color: muted, size: 18),
                      ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: _inputBorder(border),
                enabledBorder: _inputBorder(border),
                focusedBorder: _inputBorder(foreground),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 180,
            height: 42,
            child: Material(
              color: colors.inverseSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: border),
              ),
              child: InkWell(
                key: const ValueKey('deleted-order-date-filter'),
                onTap: onDateTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.only(left: 11, right: 3),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_outlined, color: foreground),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          postingDate == null
                              ? 'កាលបរិច្ឆេទ'
                              : _displayDate(postingDate!),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: postingDate == null ? muted : foreground,
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12,
                            fontWeight: postingDate == null
                                ? FontWeight.w400
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (postingDate != null)
                        IconButton(
                          key: const ValueKey('clear-deleted-order-date'),
                          onPressed: onClearDate,
                          color: colors.error,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close_rounded, size: 17),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('refresh-deleted-order-list'),
            tooltip: 'ផ្ទុកឡើងវិញ',
            onPressed: isLoading ? null : onRefresh,
            color: foreground,
            icon: const Icon(Icons.refresh_rounded),
          ),
          SizedBox(
            width: 64,
            height: 64,
            child: IconButton(
              key: const ValueKey('close-deleted-order-list'),
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
    );
  }

  OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    padding: const EdgeInsets.symmetric(horizontal: 18),
    decoration: BoxDecoration(
      color: colors.surfaceContainer,
      border: Border(bottom: BorderSide(color: colors.outlineVariant)),
    ),
    child: const Row(
      children: [
        _HeaderCell('លេខឯកសារ', flex: 15),
        _HeaderCell('កាលបរិច្ឆេទ', flex: 12),
        _HeaderCell('អតិថិជន', flex: 18),
        _HeaderCell('ចំនួនសរុប', flex: 10, align: TextAlign.right),
        _HeaderCell('ទឹកប្រាក់សរុប', flex: 14, align: TextAlign.right),
        _HeaderCell('ចំណាំការលុប', flex: 22),
        _HeaderCell('លុបដោយ', flex: 20),
        _HeaderCell('សកម្មភាព', flex: 14, align: TextAlign.center),
      ],
    ),
  );
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
      style: const TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    ),
  );
}

class _DeletedOrderRow extends StatelessWidget {
  const _DeletedOrderRow({
    required this.order,
    required this.alternate,
    required this.onView,
  });

  final DeletedOrder order;
  final bool alternate;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final sale = order.sale;
    return Container(
      key: ValueKey('deleted-order-${sale.name}'),
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: alternate ? colors.surfaceContainerLow : colors.surface,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          _DataCell(sale.name, flex: 15, emphasized: true),
          _DataCell(_formatDate(sale.postingDate), flex: 12),
          _DataCell(_customerLabel(sale), flex: 18),
          _DataCell(
            formatQuantity(sale.totalSaleQuantity),
            flex: 10,
            align: TextAlign.right,
          ),
          _DataCell(
            '${formatMoney(sale.totalAmount)} រៀល',
            flex: 14,
            align: TextAlign.right,
            emphasized: true,
          ),
          _DataCell(_fallback(order.deleteNote), flex: 22),
          _DeletedByCell(order: order, flex: 20),
          Expanded(
            flex: 14,
            child: Center(
              child: OutlinedButton.icon(
                key: ValueKey('view-deleted-order-${sale.name}'),
                onPressed: onView,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.visibility_outlined, size: 17),
                label: const Text('មើលលម្អិត'),
              ),
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
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: align,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontFamily: AppTheme.fontFamily,
        fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
        fontSize: 12,
      ),
    ),
  );
}

class _DeletedByCell extends StatelessWidget {
  const _DeletedByCell({required this.order, required this.flex});

  final DeletedOrder order;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: Tooltip(
        message: formatExactDateTime(order.deletedDate),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _fallback(order.deletedBy),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.onSurface,
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formatTimeAgo(order.deletedDate),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w400,
                fontSize: 11,
              ),
            ),
          ],
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
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 44,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 12),
        Text(message, style: const TextStyle(fontFamily: AppTheme.fontFamily)),
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

String _customerLabel(ClosedSale sale) {
  final customer = sale.customer.trim();
  final customerName = sale.customerName.trim();
  if (customer.isEmpty) return _fallback(customerName);
  if (customerName.isEmpty) return customer;
  return '$customer - $customerName';
}

String _formatDate(String value) {
  final parts = value.split('-');
  if (parts.length == 3) return '${parts[2]} / ${parts[1]} / ${parts[0]}';
  return _fallback(value);
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
