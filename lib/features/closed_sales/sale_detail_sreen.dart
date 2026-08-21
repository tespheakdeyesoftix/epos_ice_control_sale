import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../../app/app_setting_controller.dart';
import '../../app/app_theme.dart';
import '../../features/login/login_controller.dart';
import '../../features/sell/sale.dart';
import '../../features/sell/sell_controller.dart';
import '../../services/receipt_print_service.dart';
import '../../shared/note_dialog_widget.dart';
import '../../shared/receipts/receipt_template.dart';
import '../../shared/text_input_dialog_widget.dart';
import 'closed_sale.dart';
import 'closed_sale_controller.dart';
import 'sale_detail_controller.dart';
import 'widgets/sale_detail_dialogs.dart';
import 'widgets/customer_credit_warning_card.dart';
import 'widgets/sale_invoice_header_card.dart';
import 'widgets/sale_product_detail_card.dart';
import 'widgets/sale_summary_note_card.dart';
import 'widgets/sale_timeline_card.dart';
import 'widgets/split_bill_list_dialog_widget.dart';
import 'widgets/split_bill_parent_banner_widget.dart';

const double _saleDetailDialogBreakpoint = 900;

Future<void> showSaleDetail(BuildContext context, {required ClosedSale sale}) {
  final size = MediaQuery.sizeOf(context);
  final useFullScreen =
      size.width < _saleDetailDialogBreakpoint || size.height < 650;

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    useSafeArea: true,
    builder: (dialogContext) {
      final content = Navigator(
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => SaleDetailScreen(
            sale: sale,
            isDialogPresentation: true,
            onClose: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      );
      if (useFullScreen) {
        return Dialog.fullscreen(child: content);
      }
      return Dialog(
        insetPadding: const EdgeInsets.all(22),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: (size.width * .94).clamp(0.0, 1476.0),
          height: size.height * .94,
          child: content,
        ),
      );
    },
  );
}

class SaleDetailScreen extends StatefulWidget {
  const SaleDetailScreen({
    super.key,
    required this.sale,
    this.controller,
    this.isDialogPresentation = false,
    this.onClose,
  });

  final ClosedSale sale;
  final SaleDetailController? controller;
  final bool isDialogPresentation;
  final VoidCallback? onClose;

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  late final SaleDetailController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    controller = widget.controller ?? _createController();
    controller.load();
  }

  SaleDetailController _createController() {
    final sell = Get.isRegistered<SellController>()
        ? Get.find<SellController>()
        : null;
    return SaleDetailController(
      summary: widget.sale,
      saleService: sell?.saleService,
      closedSaleController: Get.isRegistered<ClosedSaleController>()
          ? Get.find<ClosedSaleController>()
          : null,
      printService: Get.isRegistered<ReceiptPrintService>()
          ? Get.find<ReceiptPrintService>()
          : null,
      appSettingController: Get.isRegistered<AppSettingController>()
          ? Get.find<AppSettingController>()
          : null,
      loginController: Get.isRegistered<LoginController>()
          ? Get.find<LoginController>()
          : null,
    );
  }

  @override
  void dispose() {
    if (_ownsController) controller.onClose();
    super.dispose();
  }

  Future<void> _editOrder() async {
    final opened = await controller.editOrder();
    if (opened && mounted) Navigator.of(context).pop();
  }

  Future<void> _deleteOrder() async {
    final closedSales = controller.closedSaleController;
    if (closedSales == null || !closedSales.checkDeleteBillPermission()) return;
    var deleted = false;
    await showNoteDialog(
      context,
      promptTitle: 'មូលហេតុដែលលុបបុង ${widget.sale.name}',
      presetKey: 'delete_bill_note',
      userKey: controller.loginController?.localStorageUserKey ?? 'anonymous',
      allowDeletingSavedNotes: true,
      onSubmit: (note) async {
        deleted = await controller.deleteOrder(note);
        return deleted;
      },
    );
    if (deleted && mounted) Navigator.of(context).pop();
  }

  Future<void> _editComment(SaleTimelineEntry entry) async {
    final value = await showEditSaleCommentDialog(
      context,
      initialComment: entry.content,
    );
    if (value == null || !mounted) return;
    await controller.updateComment(entry, value);
  }

  Future<void> _editReferenceNumber() async {
    final currentValue = controller.displayedSale.referenceNumber;
    final value = await showTextInputDialog(
      context,
      title: 'កែប្រែលេខយោង',
      initialValue: currentValue,
      labelText: 'លេខយោង',
      hintText: 'បញ្ចូលលេខយោង',
      icon: Icons.tag_rounded,
      maxLength: 140,
      inputKey: const ValueKey('sale-reference-number-input'),
      confirmButtonKey: const ValueKey('save-sale-reference-number'),
    );
    if (value == null || !mounted) return;
    await controller.updateReferenceNumber(value);
  }

  Future<void> _viewSplitBills() async {
    final service = controller.saleService;
    if (service == null) return;
    final selected = await showSplitBillListDialog(
      context,
      saleService: service,
      parentBillNumber: controller.displayedSale.name,
      canShowPrice: controller.displayedSale.canShowPrice,
      currencySymbol:
          controller.appSettingController?.current?.currencySymbol ?? '',
    );
    if (selected == null || !mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SaleDetailScreen(
          sale: selected,
          isDialogPresentation: widget.isDialogPresentation,
          onClose: widget.onClose,
        ),
      ),
    );
  }

  Future<void> _viewParentBill() async {
    final parentBillNumber = controller.displayedSale.parentBillNumber.trim();
    if (parentBillNumber.isEmpty) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SaleDetailScreen(
          sale: ClosedSale(name: parentBillNumber, postingDate: ''),
          isDialogPresentation: widget.isDialogPresentation,
          onClose: widget.onClose,
        ),
      ),
    );
  }

  Future<void> _closeDetail() async {
    controller.noteFocusNode.unfocus();
    await controller.saveNoteOnFocusLost();
    if (!mounted) return;
    final close = widget.onClose;
    if (close != null) {
      close();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showPrintPreview() async {
    await controller.loadPrintTemplates();
    if (!mounted) return;
    final zoomController = TransformationController();
    var zoom = 1.0;
    var selectedTemplate = controller.selectedPrintTemplate.value;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final windowSize = MediaQuery.sizeOf(dialogContext);
        var isPrinting = false;
        var isExporting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void updateZoom(double value) {
              zoom = value.clamp(.6, 2.4);
              zoomController.value = Matrix4.diagonal3Values(zoom, zoom, 1);
              setDialogState(() {});
            }

            return Dialog(
              insetPadding: const EdgeInsets.all(18),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: windowSize.width >= 960 ? 860 : windowSize.width * .92,
                height: windowSize.height * .90,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 8, 8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.preview_rounded),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'មើលមុនពេលបោះពុម្ព — ${widget.sale.name}',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              FilledButton.icon(
                                key: const ValueKey('preview-print-button'),
                                onPressed: isPrinting || isExporting
                                    ? null
                                    : () async {
                                        setDialogState(() => isPrinting = true);
                                        try {
                                          await Printing.layoutPdf(
                                            name: '${widget.sale.name}.pdf',
                                            format: selectedTemplate.pageFormat,
                                            dynamicLayout: false,
                                            onLayout: (_) =>
                                                controller.buildPrintPreview(
                                                  template: selectedTemplate,
                                                ),
                                          );
                                        } finally {
                                          if (dialogContext.mounted) {
                                            setDialogState(
                                              () => isPrinting = false,
                                            );
                                          }
                                        }
                                      },
                                icon: isPrinting
                                    ? const SizedBox.square(
                                        dimension: 17,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.print_outlined,
                                        size: 19,
                                      ),
                                label: const Text('បោះពុម្ព'),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                key: const ValueKey('preview-export-button'),
                                onPressed: isPrinting || isExporting
                                    ? null
                                    : () async {
                                        setDialogState(
                                          () => isExporting = true,
                                        );
                                        try {
                                          final bytes = await controller
                                              .buildPrintPreview(
                                                template: selectedTemplate,
                                              );
                                          await Printing.sharePdf(
                                            bytes: bytes,
                                            filename: '${widget.sale.name}.pdf',
                                          );
                                        } finally {
                                          if (dialogContext.mounted) {
                                            setDialogState(
                                              () => isExporting = false,
                                            );
                                          }
                                        }
                                      },
                                icon: isExporting
                                    ? const SizedBox.square(
                                        dimension: 17,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.ios_share_rounded,
                                        size: 19,
                                      ),
                                label: const Text('ចែករំលែក / នាំចេញ'),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'បិទ',
                                onPressed: isPrinting || isExporting
                                    ? null
                                    : () => Navigator.pop(dialogContext),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (controller.printTemplates.length > 1) ...[
                                const Icon(
                                  Icons.description_outlined,
                                  size: 19,
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 250,
                                  child:
                                      DropdownButtonFormField<ReceiptTemplate>(
                                        initialValue: selectedTemplate,
                                        isDense: true,
                                        decoration: const InputDecoration(
                                          labelText: 'គំរូបង្កាន់ដៃ',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                        ),
                                        items: [
                                          for (final template
                                              in controller.printTemplates)
                                            DropdownMenuItem(
                                              value: template,
                                              child: Text(
                                                template.templateName.isEmpty
                                                    ? template.name
                                                    : template.templateName,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                        ],
                                        onChanged: isPrinting || isExporting
                                            ? null
                                            : (template) {
                                                if (template == null) return;
                                                setDialogState(() {
                                                  selectedTemplate = template;
                                                  controller
                                                          .selectedPrintTemplate
                                                          .value =
                                                      template;
                                                });
                                              },
                                      ),
                                ),
                              ],
                              const Spacer(),
                              IconButton.outlined(
                                tooltip: 'បង្រួម',
                                onPressed: zoom <= .6
                                    ? null
                                    : () => updateZoom(zoom - .2),
                                icon: const Icon(Icons.zoom_out_rounded),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: SizedBox(
                                  width: 54,
                                  child: Text(
                                    '${(zoom * 100).round()}%',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton.outlined(
                                tooltip: 'ពង្រីក',
                                onPressed: zoom >= 2.4
                                    ? null
                                    : () => updateZoom(zoom + .2),
                                icon: const Icon(Icons.zoom_in_rounded),
                              ),
                              const SizedBox(width: 6),
                              TextButton(
                                onPressed: zoom == 1
                                    ? null
                                    : () => updateZoom(1),
                                child: const Text('កំណត់ឡើងវិញ'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: InteractiveViewer(
                        transformationController: zoomController,
                        minScale: .6,
                        maxScale: 2.4,
                        scaleEnabled: false,
                        onInteractionUpdate: (_) {
                          final nextZoom = zoomController.value
                              .getMaxScaleOnAxis();
                          if ((nextZoom - zoom).abs() >= .01) {
                            setDialogState(() => zoom = nextZoom);
                          }
                        },
                        child: PdfPreview(
                          key: ValueKey(selectedTemplate.name),
                          build: (_) => controller.buildPrintPreview(
                            template: selectedTemplate,
                          ),
                          initialPageFormat: selectedTemplate.pageFormat,
                          canChangeOrientation: false,
                          canChangePageFormat: false,
                          canDebug: false,
                          allowPrinting: false,
                          allowSharing: false,
                          useActions: false,
                          shouldRepaint: true,
                          pdfFileName: '${widget.sale.name}.pdf',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    zoomController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      key: const ValueKey('sale-detail-screen'),
      backgroundColor: colors.surfaceContainerLow,
      body: Column(
        children: [
          if (widget.isDialogPresentation)
            Obx(
              () => _SaleDetailDialogTitleBar(
                sale: controller.displayedSale,
                currencySymbol:
                    controller.appSettingController?.current?.currencySymbol ??
                    '',
                showBackButton: Navigator.of(context).canPop(),
                onBack: () => Navigator.of(context).pop(),
                onOpenParentBill:
                    controller.displayedSale.parentBillNumber.trim().isEmpty
                    ? null
                    : _viewParentBill,
                onRefresh: controller.isLoading.value ? null : controller.load,
                isRefreshing: controller.isLoading.value,
                onClose: _closeDetail,
              ),
            ),
          Expanded(
            child: SafeArea(
              top: !widget.isDialogPresentation,
              child: Obx(() {
                final sale = controller.displayedSale;
                final currencySymbol =
                    controller.appSettingController?.current?.currencySymbol ??
                    '';
                return Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: controller.load,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              18,
                              widget.isDialogPresentation ? 14 : 18,
                              18,
                              18,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 1440,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      SaleInvoiceHeaderCard(
                                        sale: sale,
                                        rawDocument: controller.rawDocument,
                                        imageBaseUri:
                                            controller.saleService?.baseUri,
                                        onBack: () =>
                                            Navigator.of(context).pop(),
                                        showBackButton:
                                            !widget.isDialogPresentation,
                                        onClose: null,
                                        onRefresh: controller.isLoading.value
                                            ? null
                                            : controller.load,
                                        onReprint: controller.isPrinting.value
                                            ? null
                                            : (copies) =>
                                                  controller.reprintReceipt(
                                                    copies: copies,
                                                  ),
                                        onEdit:
                                            controller.closedSaleController ==
                                                null
                                            ? null
                                            : _editOrder,
                                        onDelete:
                                            controller.closedSaleController ==
                                                null
                                            ? null
                                            : _deleteOrder,
                                        onPreview: _showPrintPreview,
                                        onPaymentHistory: () =>
                                            showPaymentHistoryDialog(
                                              context,
                                              payments: controller.payments,
                                              totalPayment: sale.totalPayment,
                                              canShowPrice: sale.canShowPrice,
                                              currencySymbol: currencySymbol,
                                            ),
                                        onViewSplitBills:
                                            sale.canSplitBill &&
                                                sale.totalSplitBill > 0
                                            ? _viewSplitBills
                                            : null,
                                        onEditReferenceNumber:
                                            controller
                                                .isSavingReferenceNumber
                                                .value
                                            ? null
                                            : _editReferenceNumber,
                                        onOpenParentBill:
                                            sale.parentBillNumber.trim().isEmpty
                                            ? null
                                            : _viewParentBill,
                                        isPrinting: controller.isPrinting.value,
                                        isRefreshing:
                                            controller.isLoading.value,
                                        currencySymbol: currencySymbol,
                                        showDocumentHeader:
                                            !widget.isDialogPresentation,
                                      ),
                                      if (controller.errorMessage.value !=
                                          null) ...[
                                        const SizedBox(height: 12),
                                        _LoadErrorBanner(
                                          message:
                                              controller.errorMessage.value!,
                                          onRetry: controller.load,
                                        ),
                                      ],
                                      const SizedBox(height: 14),
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final main = Column(
                                            children: [
                                              SaleProductDetailCard(
                                                products: sale.saleProducts,
                                                canShowPrice: sale.canShowPrice,
                                                currencySymbol: currencySymbol,
                                              ),
                                              const SizedBox(height: 14),
                                              SaleSummaryNoteCard(
                                                sale: sale,
                                                canShowPrice: sale.canShowPrice,
                                                currencySymbol: currencySymbol,
                                                noteController:
                                                    controller.noteController,
                                                noteFocusNode:
                                                    controller.noteFocusNode,
                                                isSavingNote: controller
                                                    .isSavingNote
                                                    .value,
                                                noteSaveError: controller
                                                    .noteSaveError
                                                    .value,
                                                onNoteFocusChanged: (hasFocus) {
                                                  if (!hasFocus) {
                                                    controller
                                                        .saveNoteOnFocusLost();
                                                  }
                                                },
                                              ),
                                            ],
                                          );
                                          final timeline = SaleTimelineCard(
                                            entries: controller.timeline,
                                            textController:
                                                controller.commentController,
                                            isPosting:
                                                controller.isPosting.value,
                                            onPost: controller.isPosting.value
                                                ? null
                                                : controller.postTimelineEntry,
                                            canEditComment:
                                                controller.canEditComment,
                                            editingCommentNames:
                                                controller.editingCommentNames,
                                            onEditComment: _editComment,
                                          );
                                          if (constraints.maxWidth < 1450) {
                                            return Column(
                                              children: [
                                                main,
                                                const SizedBox(height: 14),
                                                timeline,
                                              ],
                                            );
                                          }
                                          return Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(flex: 7, child: main),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                flex: 4,
                                                child: timeline,
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (controller.isLoading.value)
                      const Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: LinearProgressIndicator(minHeight: 3),
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleDetailDialogTitleBar extends StatelessWidget {
  const _SaleDetailDialogTitleBar({
    required this.sale,
    required this.currencySymbol,
    required this.showBackButton,
    required this.onBack,
    required this.onOpenParentBill,
    required this.onRefresh,
    required this.isRefreshing,
    required this.onClose,
  });

  final Sale sale;
  final String currencySymbol;
  final bool showBackButton;
  final VoidCallback onBack;
  final VoidCallback? onOpenParentBill;
  final VoidCallback? onRefresh;
  final bool isRefreshing;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('sale-detail-dialog-app-bar'),
      height: 58,
      color: colors.inverseSurface,
      child: Row(
        children: [
          if (showBackButton)
            SizedBox(
              width: 58,
              height: 58,
              child: IconButton(
                key: const ValueKey('sale-detail-dialog-back'),
                tooltip: 'ត្រឡប់ក្រោយ',
                onPressed: onBack,
                color: colors.onInverseSurface,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            )
          else ...[
            const SizedBox(width: 20),
            Icon(Icons.receipt_long_rounded, color: colors.onInverseSurface),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    'ព័ត៌មានលម្អិតវិក្កយបត្រ · ${sale.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onInverseSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (sale.parentBillNumber.trim().isNotEmpty &&
                    onOpenParentBill != null) ...[
                  const SizedBox(width: 9),
                  SplitBillParentBannerWidget(
                    parentBillNumber: sale.parentBillNumber,
                    onOpenParent: onOpenParentBill!,
                  ),
                ],
                if (sale.canSplitBill && sale.totalSplitBill > 0) ...[
                  const SizedBox(width: 9),
                  const _DialogMasterInvoicePill(),
                ],
              ],
            ),
          ),
          if (CustomerCreditWarningCard.shouldShow(sale)) ...[
            CustomerCreditWarningCard(
              sale: sale,
              currencySymbol: currencySymbol,
            ),
            const SizedBox(width: 8),
          ],
          _DialogStatusPill(
            label: sale.status.isEmpty ? sale.saleStatus : sale.status,
          ),
          const SizedBox(width: 8),
          IconButton(
            key: const ValueKey('refresh-sale-detail-dialog'),
            tooltip: 'ផ្ទុកឡើងវិញ',
            onPressed: isRefreshing ? null : onRefresh,
            color: colors.onInverseSurface,
            icon: Icon(
              isRefreshing
                  ? Icons.hourglass_top_rounded
                  : Icons.refresh_rounded,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 58,
            height: 58,
            child: IconButton(
              key: const ValueKey('close-sale-detail-dialog'),
              tooltip: 'បិទ',
              onPressed: onClose,
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
}

class _DialogStatusPill extends StatelessWidget {
  const _DialogStatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = switch (label.trim().toLowerCase()) {
      'paid' => const Color(0xFF4ADE80),
      'unpaid' => const Color(0xFFFCA5A5),
      'partially paid' => const Color(0xFFFBBF24),
      _ => colors.onInverseSurface,
    };
    final text = switch (label.trim().toLowerCase()) {
      'paid' => 'បានទូទាត់',
      'unpaid' => 'មិនទាន់ទូទាត់',
      'partially paid' => 'បានទូទាត់ខ្លះ',
      'closed' => 'បានបិទ',
      'draft' => 'ព្រាង',
      'deleted' => 'បានលុប',
      '' => 'បានបិទ',
      _ => label,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DialogMasterInvoicePill extends StatelessWidget {
  const _DialogMasterInvoicePill();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colors.tertiary.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.tertiary.withValues(alpha: .55)),
      ),
      child: Text(
        'វិក្កយបត្រមេ',
        style: TextStyle(
          color: colors.onInverseSurface,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LoadErrorBanner extends StatelessWidget {
  const _LoadErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, color: colors.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('ព្យាយាមម្តងទៀត')),
        ],
      ),
    );
  }
}

@Preview(name: 'Modern sale detail', size: Size(1280, 900))
Widget saleDetailScreenPreview() {
  const summary = ClosedSale(
    name: 'SO2026-0110',
    postingDate: '2026-08-20',
    customer: 'CUS-0001',
    customerName: 'Sample Customer',
    phoneNumber: '012 345 678',
    driverName: 'Sample Driver',
    totalAmount: 125000,
    saleStatus: 'Closed',
    status: 'Paid',
  );
  return MaterialApp(
    theme: AppTheme.light,
    home: SaleDetailScreen(
      sale: summary,
      controller: SaleDetailController(summary: summary, saleService: null),
    ),
  );
}
