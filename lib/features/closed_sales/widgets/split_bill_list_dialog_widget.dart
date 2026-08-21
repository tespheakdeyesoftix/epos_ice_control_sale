import 'package:flutter/material.dart';

import '../../../services/frappe_response_handler.dart';
import '../../../services/sale_service.dart';
import '../../../utils/helpers.dart';
import '../closed_sale.dart';

Future<ClosedSale?> showSplitBillListDialog(
  BuildContext context, {
  required SaleService saleService,
  required String parentBillNumber,
  required bool canShowPrice,
  required String currencySymbol,
}) {
  return showDialog<ClosedSale>(
    context: context,
    builder: (_) => SplitBillListDialogWidget(
      saleService: saleService,
      parentBillNumber: parentBillNumber,
      canShowPrice: canShowPrice,
      currencySymbol: currencySymbol,
    ),
  );
}

class SplitBillListDialogWidget extends StatefulWidget {
  const SplitBillListDialogWidget({
    super.key,
    required this.saleService,
    required this.parentBillNumber,
    required this.canShowPrice,
    required this.currencySymbol,
  });

  final SaleService saleService;
  final String parentBillNumber;
  final bool canShowPrice;
  final String currencySymbol;

  @override
  State<SplitBillListDialogWidget> createState() =>
      _SplitBillListDialogWidgetState();
}

class _SplitBillListDialogWidgetState extends State<SplitBillListDialogWidget> {
  final _searchController = TextEditingController();
  List<ClosedSale> _bills = const [];
  bool _isLoading = true;
  String? _errorMessage;

  List<ClosedSale> get _filteredBills {
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isEmpty) return _bills;
    return _bills
        .where((bill) {
          return [
            bill.name,
            bill.customer,
            bill.customerName,
            bill.phoneNumber,
            bill.driverName,
            bill.status,
          ].any((value) => value.toLowerCase().contains(keyword));
        })
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() => setState(() {});

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final bills = await widget.saleService.getSplitBills(
        parentBillNumber: widget.parentBillNumber,
      );
      if (mounted) setState(() => _bills = bills);
    } on FrappeServerMessageException {
      // The shared API handler already displayed the server response.
    } on Exception {
      if (mounted) {
        setState(() => _errorMessage = 'មិនអាចទាញយកបុងបំបែកបានទេ។');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bills = _filteredBills;
    return AlertDialog(
      insetPadding: const EdgeInsets.all(24),
      titlePadding: const EdgeInsets.fromLTRB(22, 16, 12, 12),
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Icon(Icons.account_tree_outlined, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('បញ្ជីបុងបំបែក'),
                Text(
                  widget.parentBillNumber,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 310,
            height: 42,
            child: TextField(
              key: const ValueKey('split-bill-search-input'),
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ស្វែងរកបុងបំបែក...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'សម្អាត',
                        onPressed: _searchController.clear,
                        icon: const Icon(Icons.close_rounded),
                      ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'បិទ',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      content: SizedBox(
        width: 1080,
        height: 520,
        child: Column(
          children: [
            Divider(height: 1, color: colors.outlineVariant),
            _SplitBillTableHeader(currencySymbol: widget.currencySymbol),
            Divider(height: 1, color: colors.outlineVariant),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? _LoadError(message: _errorMessage!, onRetry: _load)
                  : bills.isEmpty
                  ? _EmptySplitBills(
                      hasSearch: _searchController.text.isNotEmpty,
                    )
                  : ListView.separated(
                      itemCount: bills.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: colors.outlineVariant),
                      itemBuilder: (context, index) => _SplitBillRow(
                        bill: bills[index],
                        canShowPrice: widget.canShowPrice,
                        currencySymbol: widget.currencySymbol,
                        onOpen: () => Navigator.pop(context, bills[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitBillTableHeader extends StatelessWidget {
  const _SplitBillTableHeader({required this.currencySymbol});

  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      color: colors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      child: Row(
        children: [
          const Expanded(flex: 3, child: Text('លេខបុង')),
          const Expanded(flex: 2, child: Text('កាលបរិច្ឆេទ')),
          const Expanded(flex: 4, child: Text('អតិថិជន')),
          const Expanded(
            flex: 2,
            child: Text('ចំនួន', textAlign: TextAlign.right),
          ),
          const Expanded(flex: 2, child: Text('ឯកតា')),
          Expanded(
            flex: 2,
            child: Text(
              currencySymbol.trim().isEmpty
                  ? 'សរុប'
                  : 'សរុប (${currencySymbol.trim()})',
              textAlign: TextAlign.right,
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text('ស្ថានភាព', textAlign: TextAlign.center),
          ),
          const Expanded(flex: 3, child: Text('អ្នកលក់ / ពេលបង្កើត')),
          const SizedBox(width: 38),
        ],
      ),
    );
  }
}

class _SplitBillRow extends StatelessWidget {
  const _SplitBillRow({
    required this.bill,
    required this.canShowPrice,
    required this.currencySymbol,
    required this.onOpen,
  });

  final ClosedSale bill;
  final bool canShowPrice;
  final String currencySymbol;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final customer = bill.customerName.isEmpty
        ? bill.customer
        : bill.customer.isEmpty
        ? bill.customerName
        : '${bill.customerName} (${bill.customer})';
    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                bill.name,
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(flex: 2, child: Text(formatDate(bill.postingDate))),
            Expanded(
              flex: 4,
              child: Text(
                customer.isEmpty ? '-' : customer,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                formatQuantity(bill.totalSaleQuantity),
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(bill.outletUnit.isEmpty ? '-' : bill.outletUnit),
            ),
            Expanded(
              flex: 2,
              child: Text(
                canShowPrice
                    ? formatCurrency(bill.totalAmount, currencySymbol)
                    : '••••',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(child: _PaymentStatusPill(status: bill.status)),
            ),
            Expanded(flex: 3, child: _SellerCreationCell(bill: bill)),
            SizedBox(
              width: 38,
              child: Icon(Icons.chevron_right_rounded, color: colors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SellerCreationCell extends StatelessWidget {
  const _SellerCreationCell({required this.bill});

  final ClosedSale bill;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final seller = bill.seller.trim().isEmpty ? bill.owner : bill.seller;
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            seller.trim().isEmpty ? '-' : seller,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Tooltip(
            message: formatExactDateTime(bill.creation),
            child: Text(
              formatTimeAgo(bill.creation),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentStatusPill extends StatelessWidget {
  const _PaymentStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final normalized = status.trim().toLowerCase();
    final color = switch (normalized) {
      'paid' => const Color(0xFF168A45),
      'unpaid' => colors.error,
      'partially paid' => const Color(0xFFD97706),
      _ => colors.primary,
    };
    final label = switch (normalized) {
      'paid' => 'បានទូទាត់',
      'unpaid' => 'មិនទាន់ទូទាត់',
      'partially paid' => 'បានទូទាត់ខ្លះ',
      _ => status,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('ព្យាយាមម្តងទៀត'),
        ),
      ],
    ),
  );
}

class _EmptySplitBills extends StatelessWidget {
  const _EmptySplitBills({required this.hasSearch});

  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_tree_outlined, size: 42, color: colors.outline),
          const SizedBox(height: 10),
          Text(
            hasSearch ? 'រកមិនឃើញបុងបំបែកដែលត្រូវគ្នាទេ' : 'មិនមានបុងបំបែកទេ',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
