import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/sale_service.dart';
import '../closed_sales/closed_sale.dart';
import 'global_search_controller.dart';
import 'widgets/global_search_input.dart';
import 'widgets/global_search_results.dart';

Future<ClosedSale?> showGlobalSearchDialog(
  BuildContext context, {
  required SaleService saleService,
  required String Function() outletProvider,
  Future<bool> Function(ClosedSale sale)? onEdit,
  GlobalSearchController? controller,
}) {
  return showDialog<ClosedSale>(
    context: context,
    useSafeArea: true,
    builder: (_) => GlobalSearchDialog(
      saleService: saleService,
      outletProvider: outletProvider,
      onEdit: onEdit,
      controller: controller,
    ),
  );
}

class GlobalSearchDialog extends StatefulWidget {
  const GlobalSearchDialog({
    super.key,
    required this.saleService,
    required this.outletProvider,
    this.onEdit,
    this.controller,
  });

  final SaleService saleService;
  final String Function() outletProvider;
  final Future<bool> Function(ClosedSale sale)? onEdit;
  final GlobalSearchController? controller;

  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  late final GlobalSearchController controller;
  late final bool _ownsController;
  String? _editingSaleName;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    controller =
        widget.controller ??
        GlobalSearchController(
          saleService: widget.saleService,
          outletProvider: widget.outletProvider,
        );
    controller.addListener(_rebuild);
    unawaited(controller.ensureLoaded());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.searchFocusNode.requestFocus();
    });
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _editSale(ClosedSale sale) async {
    final onEdit = widget.onEdit;
    if (onEdit == null || _editingSaleName != null) return;
    setState(() => _editingSaleName = sale.name);
    try {
      final edited = await onEdit(sale);
      if (edited && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _editingSaleName = null);
    }
  }

  @override
  void dispose() {
    controller.removeListener(_rebuild);
    if (_ownsController) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final fullscreen = size.width < 640 || size.height < 600;
    final content = _SearchContent(
      controller: controller,
      onEdit: widget.onEdit == null ? null : _editSale,
      editingSaleName: _editingSaleName,
    );
    if (fullscreen) {
      return Dialog.fullscreen(
        key: const ValueKey('global-search-dialog'),
        child: content,
      );
    }
    return Dialog(
      key: const ValueKey('global-search-dialog'),
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 920,
        height: (size.height * .82).clamp(500.0, 760.0),
        child: content,
      ),
    );
  }
}

class _SearchContent extends StatelessWidget {
  const _SearchContent({
    required this.controller,
    required this.onEdit,
    required this.editingSaleName,
  });

  final GlobalSearchController controller;
  final Future<void> Function(ClosedSale sale)? onEdit;
  final String? editingSaleName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ស្វែងរកវិក្កយបត្រលក់'),
          leading: const Icon(Icons.manage_search_rounded),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              key: const ValueKey('close-global-search'),
              tooltip: 'បិទ',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlobalSearchInput(
                controller: controller.searchController,
                focusNode: controller.searchFocusNode,
                onChanged: controller.handleQueryChanged,
                onClear: controller.clearQuery,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.isShowingRecent
                          ? 'វិក្កយបត្រលក់ថ្មីៗ ១០ ចុងក្រោយ'
                          : 'លទ្ធផលស្វែងរក',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (!controller.isShowingRecent)
                    Text(
                      '${controller.results.length} លទ្ធផល',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: GlobalSearchResults(
                  results: controller.results,
                  isLoading: controller.isLoading,
                  isShowingRecent: controller.isShowingRecent,
                  errorMessage: controller.errorMessage,
                  onSelected: (sale) => Navigator.of(context).pop(sale),
                  onEdit: onEdit,
                  editingSaleName: editingSaleName,
                  onRetry: controller.retry,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
