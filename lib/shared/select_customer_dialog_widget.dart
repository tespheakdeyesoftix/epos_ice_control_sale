import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../features/sell/customer.dart';
import '../services/customer_service.dart';
import 'network_image.dart';

Future<Customer?> showSelectCustomerDialog(
  BuildContext context, {
  required CustomerService customerService,
  CustomerSelectionType selectionType = CustomerSelectionType.customer,
}) {
  return showDialog<Customer>(
    context: context,
    builder: (_) => SelectCustomerDialogWidget(
      customerService: customerService,
      selectionType: selectionType,
    ),
  );
}

class SelectCustomerDialogWidget extends StatefulWidget {
  const SelectCustomerDialogWidget({
    super.key,
    required this.customerService,
    this.selectionType = CustomerSelectionType.customer,
  });

  final CustomerService customerService;
  final CustomerSelectionType selectionType;

  @override
  State<SelectCustomerDialogWidget> createState() =>
      _SelectCustomerDialogWidgetState();
}

class _SelectCustomerDialogWidgetState
    extends State<SelectCustomerDialogWidget> {
  static const _khmerLetters = [
    'ក',
    'ខ',
    'គ',
    'ឃ',
    'ង',
    'ច',
    'ឆ',
    'ជ',
    'ឈ',
    'ញ',
    'ដ',
    'ឋ',
    'ឌ',
    'ឍ',
    'ណ',
    'ត',
    'ថ',
    'ទ',
    'ធ',
    'ន',
    'ប',
    'ផ',
    'ព',
    'ភ',
    'ម',
    'យ',
    'រ',
    'ល',
    'វ',
    'ស',
    'ហ',
    'ឡ',
    'អ',
  ];

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _customers = <Customer>[];
  Timer? _debounce;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_scheduleSearch);
    _scrollController.addListener(_handleScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController
      ..removeListener(_scheduleSearch)
      ..dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _load(reset: true),
    );
  }

  void _searchNow(String _) {
    _debounce?.cancel();
    _load(reset: true);
  }

  void _handleScroll() {
    if (_scrollController.position.extentAfter < 240) _load();
  }

  Future<void> _load({bool reset = false}) async {
    if (!reset && (_isLoading || !_hasMore)) return;
    final generation = reset ? ++_generation : _generation;
    final offset = reset ? 0 : _customers.length;
    if (reset) {
      setState(() {
        _customers.clear();
        _hasMore = true;
        _error = null;
        _isLoading = true;
      });
    } else {
      setState(() {
        _error = null;
        _isLoading = true;
      });
    }

    try {
      final page = await widget.customerService.getCustomers(
        search: _searchController.text,
        offset: offset,
        selectionType: widget.selectionType,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _customers.addAll(page.items);
        _hasMore = page.hasMore;
        _isLoading = false;
      });
    } on Exception {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = 'មិនអាចទាញយកបញ្ជីអតិថិជនបានទេ។';
        _isLoading = false;
      });
    }
  }

  void _appendLetter(String letter) {
    final selection = _searchController.selection;
    final text = _searchController.text;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    _searchController.value = TextEditingValue(
      text: text.replaceRange(start, end, letter),
      selection: TextSelection.collapsed(offset: start + letter.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final screen = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: math.min(1120, screen.width - 40),
        height: math.min(780, screen.height - 40),
        child: Column(
          children: [
            _buildTitleBar(colors),
            _buildKhmerKeyboard(colors),
            Divider(height: 1, color: colors.outlineVariant),
            _buildListHeader(colors),
            Expanded(child: _buildCustomerList(colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleBar(ColorScheme colors) {
    final isDriver = widget.selectionType == CustomerSelectionType.driver;
    return Container(
      height: 56,
      padding: const EdgeInsets.only(left: 18),
      color: colors.inverseSurface,
      child: Row(
        children: [
          SizedBox(
            width: 190,
            child: Text(
              isDriver ? 'ជ្រើសរើសអ្នកបើកបរ' : 'ជ្រើសរើសអតិថិជន',
              style: TextStyle(
                color: colors.onInverseSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    key: const ValueKey('customer-search-input'),
                    controller: _searchController,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _searchNow,
                    style: TextStyle(color: colors.onInverseSurface),
                    cursorColor: colors.onInverseSurface,
                    decoration: InputDecoration(
                      hintText: isDriver
                          ? 'ស្វែងរកអ្នកបើកបរ'
                          : 'ស្វែងរកអតិថិជន',
                      hintStyle: TextStyle(
                        color: colors.onInverseSurface.withValues(alpha: 0.68),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: colors.onInverseSurface.withValues(alpha: 0.8),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 42),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'សម្អាត',
                              onPressed: _searchController.clear,
                              icon: Icon(
                                Icons.close_rounded,
                                color: colors.onInverseSurface,
                                size: 18,
                              ),
                            ),
                      filled: true,
                      fillColor: colors.onInverseSurface.withValues(alpha: 0.1),
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: colors.onInverseSurface.withValues(
                            alpha: 0.16,
                          ),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: colors.onInverseSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 56,
            height: 56,
            child: IconButton(
              key: const ValueKey('close-customer-dialog'),
              tooltip: 'បិទ',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
              color: colors.onError,
              style: IconButton.styleFrom(
                backgroundColor: colors.error,
                shape: const RoundedRectangleBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKhmerKeyboard(ColorScheme colors) {
    return Container(
      color: colors.surfaceContainerLow,
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const columns = 11;
          final keyWidth = (constraints.maxWidth - (columns - 1) * 7) / columns;
          return Wrap(
            spacing: 7,
            runSpacing: 7,
            children: _khmerLetters
                .map(
                  (letter) => SizedBox(
                    width: keyWidth,
                    height: 40,
                    child: OutlinedButton(
                      key: ValueKey('customer-letter-$letter'),
                      onPressed: () => _appendLetter(letter),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: colors.surface,
                      ),
                      child: Text(letter, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildListHeader(ColorScheme colors) {
    final isDriver = widget.selectionType == CustomerSelectionType.driver;
    return Container(
      height: 43,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: colors.surfaceContainer,
      child: Row(
        children: [
          const SizedBox(width: 58),
          const SizedBox(width: 130, child: Text('លេខកូដ')),
          Expanded(
            flex: 3,
            child: Text(isDriver ? 'ឈ្មោះអ្នកបើកបរ' : 'ឈ្មោះអតិថិជន'),
          ),
          const Expanded(flex: 2, child: Text('លេខទូរស័ព្ទទី១')),
          const Expanded(flex: 2, child: Text('លេខទូរស័ព្ទទី២')),
          Expanded(
            flex: 2,
            child: Text(isDriver ? 'ស្លាកលេខ' : 'ក្រុមអតិថិជន'),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList(ColorScheme colors) {
    if (_customers.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_customers.isEmpty && _error != null) {
      return _CustomerMessage(
        icon: Icons.cloud_off_outlined,
        message: _error!,
        actionLabel: 'ព្យាយាមម្ដងទៀត',
        onAction: () => _load(reset: true),
      );
    }
    if (_customers.isEmpty) {
      return _CustomerMessage(
        icon: Icons.person_search_outlined,
        message: widget.selectionType == CustomerSelectionType.driver
            ? 'រកមិនឃើញអ្នកបើកបរទេ។'
            : 'រកមិនឃើញអតិថិជនទេ។',
      );
    }

    return ListView.builder(
      key: const ValueKey('customer-list'),
      controller: _scrollController,
      itemCount: _customers.length + (_isLoading || _error != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _customers.length) {
          return SizedBox(
            height: 56,
            child: Center(
              child: _error != null
                  ? TextButton(
                      onPressed: _load,
                      child: const Text('ព្យាយាមម្ដងទៀត'),
                    )
                  : const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
            ),
          );
        }
        final customer = _customers[index];
        return _CustomerRow(
          customer: customer,
          imageUri: widget.customerService.customerImage(customer),
          selectionType: widget.selectionType,
          isEven: index.isEven,
          onTap: () => Navigator.of(context).pop(customer),
        );
      },
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({
    required this.customer,
    required this.imageUri,
    required this.selectionType,
    required this.isEven,
    required this.onTap,
  });

  final Customer customer;
  final Uri? imageUri;
  final CustomerSelectionType selectionType;
  final bool isEven;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fallback = Icon(
      Icons.person_rounded,
      color: colors.primary,
      size: 22,
    );
    return Material(
      key: ValueKey('customer-row-${customer.name}'),
      color: isEven ? colors.surface : colors.surfaceContainerLowest,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 58,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ClipOval(
                    child: ColoredBox(
                      color: colors.surfaceContainer,
                      child: SizedBox(
                        width: 38,
                        height: 38,
                        child: imageUri == null
                            ? fallback
                            : AppNetworkImage(
                                imageUrl: imageUri.toString(),
                                width: 38,
                                height: 38,
                                memCacheWidth: 96,
                                memCacheHeight: 96,
                                errorWidget: fallback,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 130,
                child: Text(
                  customer.displayCode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(flex: 3, child: _CellText(customer.displayName)),
              Expanded(flex: 2, child: _CellText(customer.phoneNumber1)),
              Expanded(flex: 2, child: _CellText(customer.phoneNumber2)),
              Expanded(
                flex: 2,
                child: _CellText(
                  selectionType == CustomerSelectionType.driver
                      ? customer.plateNumber
                      : customer.customerGroup,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CellText extends StatelessWidget {
  const _CellText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}

class _CustomerMessage extends StatelessWidget {
  const _CustomerMessage({
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
          Text(message),
          if (actionLabel != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
