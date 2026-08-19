import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_setting.dart';
import '../../features/sell/customer.dart';
import '../../features/sell/sell_controller.dart';
import '../../features/sell/widgets/save_order_success_widget.dart';
import '../../services/frappe_response_handler.dart';
import '../../services/receipt_print_service.dart';
import '../select_customer_dialog_widget.dart';

Future<bool> showCloseAndPrintFlow(
  BuildContext context, {
  required SellController sellController,
  required ReceiptPrintService printService,
  required AppSetting business,
  required String sellerFallback,
}) async {
  if (!printService.beginWorkflow()) return false;
  sellController.isPrinting.value = true;
  var savedSuccessfully = false;
  try {
    if (sellController.saleProducts.isEmpty) return false;
    if (!sellController.hasSelectedCustomer) {
      final selected = await _selectRequiredCustomer(context, sellController);
      if (selected == null || !context.mounted) return false;
      await sellController.selectCustomer(selected);
    }

    if (!context.mounted) return false;
    final defaultCopies =
        printService.preferenceStore
            ?.read(sellController.currentSale.outlet)
            .copies ??
        1;
    final copies = await _confirmCloseAndPrint(
      context,
      defaultCopies: defaultCopies,
    );
    if (copies == null || !context.mounted) return false;

    final savedOrder = await sellController.saveOrder();
    savedSuccessfully = true;
    sellController.startNewSale();
    if (!context.mounted) return true;

    var printPending = true;
    unawaited(
      showSaveOrderSuccessDialog(
        context,
        savedOrder: savedOrder,
        pauseCountdown: () => printPending,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    if (!context.mounted) return true;

    try {
      await _printWithRetry(
        context,
        printService: printService,
        savedOrder: savedOrder,
        business: business,
        sellerFallback: sellerFallback,
        copies: copies,
      );
    } finally {
      printPending = false;
    }
    return true;
  } on CustomerChangePermissionException catch (error) {
    FrappeResponseHandler.show(
      FrappeServerMessage(message: error.message, indicator: 'orange'),
    );
    return false;
  } on FrappeServerMessageException {
    return savedSuccessfully;
  } on Exception {
    if (!savedSuccessfully) {
      FrappeResponseHandler.show(
        const FrappeServerMessage(
          message: 'មិនអាចបិទការលក់បានទេ។ សូមព្យាយាមម្ដងទៀត។',
          indicator: 'red',
        ),
      );
      return false;
    }
    return true;
  } finally {
    sellController.isPrinting.value = false;
    printService.endWorkflow();
  }
}

Future<Customer?> _selectRequiredCustomer(
  BuildContext context,
  SellController controller,
) async {
  if (!controller.canChangeCustomer) {
    throw const CustomerChangePermissionException();
  }
  final selectNow = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const ValueKey('print-missing-customer-dialog'),
      icon: const Icon(Icons.person_search_outlined),
      title: const Text('មិនទាន់ជ្រើសរើសអតិថិជន'),
      content: const Text(
        'ការលក់នេះមិនទាន់មានអតិថិជនទេ។ តើអ្នកចង់ជ្រើសរើសអតិថិជនឥឡូវនេះទេ?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('បោះបង់'),
        ),
        FilledButton.icon(
          key: const ValueKey('print-select-customer-now'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('ជ្រើសរើសអតិថិជនឥឡូវនេះ'),
        ),
      ],
    ),
  );
  if (selectNow != true || !context.mounted) return null;
  return showSelectCustomerDialog(
    context,
    customerService: controller.customerService,
    selectionType: CustomerSelectionType.customer,
  );
}

Future<int?> _confirmCloseAndPrint(
  BuildContext context, {
  required int defaultCopies,
}) async {
  var selectedCopies = defaultCopies.clamp(1, 3);
  return showDialog<int>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        key: const ValueKey('confirm-close-and-print-dialog'),
        icon: const Icon(Icons.print_outlined),
        title: const Text('បញ្ជាក់ការបិទ និងបោះពុម្ព'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'តើអ្នកប្រាកដថាចង់បិទការលក់ និងបោះពុម្ពវិក្កយបត្រនេះមែនទេ?',
            ),
            const SizedBox(height: 18),
            const Text('ចំនួនច្បាប់ចម្លង'),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              key: const ValueKey('print-copy-selector'),
              segments: const [
                ButtonSegment(value: 1, label: Text('1')),
                ButtonSegment(value: 2, label: Text('2')),
                ButtonSegment(value: 3, label: Text('3')),
              ],
              selected: {selectedCopies},
              onSelectionChanged: (value) =>
                  setState(() => selectedCopies = value.first),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('បោះបង់'),
          ),
          FilledButton.icon(
            key: const ValueKey('confirm-close-and-print'),
            onPressed: () => Navigator.of(dialogContext).pop(selectedCopies),
            icon: const Icon(Icons.print_rounded),
            label: const Text('បិទ និងបោះពុម្ព'),
          ),
        ],
      ),
    ),
  );
}

Future<bool> _printWithRetry(
  BuildContext context, {
  required ReceiptPrintService printService,
  required Map<String, dynamic> savedOrder,
  required AppSetting business,
  required String sellerFallback,
  required int copies,
}) async {
  while (context.mounted) {
    try {
      await printService.printSavedOrder(
        savedOrder: savedOrder,
        business: business,
        sellerFallback: sellerFallback,
        copies: copies,
      );
      return true;
    } on Exception catch (error) {
      if (!context.mounted) return false;
      final details = _describePrintFailure(error);
      final retry = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          key: const ValueKey('receipt-print-failed-dialog'),
          icon: const Icon(Icons.print_disabled_outlined),
          title: const Text('មិនអាចបោះពុម្ពបាន'),
          content: _PrintFailureContent(details: details),
          actions: [
            TextButton(
              key: const ValueKey('close-print-failure'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('បិទ'),
            ),
            FilledButton.icon(
              key: const ValueKey('retry-receipt-print'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('បោះពុម្ពម្ដងទៀត'),
            ),
          ],
        ),
      );
      if (retry != true) return false;
    }
  }
  return false;
}

_PrintFailureDetails _describePrintFailure(Exception error) {
  if (error is! ReceiptPrintException) {
    return _PrintFailureDetails(
      reason: 'The receipt could not be prepared or sent to the printer.',
      action:
          'Check the receipt template and printer connection, then try again.',
      technicalMessage: error.toString(),
    );
  }
  final (reason, action) = switch (error.failure) {
    ReceiptPrintFailure.invalidSale => (
      'The saved sale has no invoice number.',
      'Refresh the sale or contact your administrator before retrying.',
    ),
    ReceiptPrintFailure.noPrintersFound => (
      'Windows did not report any installed printers.',
      'Connect the printer and install its Windows driver.',
    ),
    ReceiptPrintFailure.noDefaultPrinter => (
      'No available default printer is configured.',
      'Select a printer in Print Settings or set a Windows default printer.',
    ),
    ReceiptPrintFailure.configuredPrinterNotFound => (
      'The selected printer name or driver no longer exists.',
      'Check the printer name and driver, then select it again in Print Settings.',
    ),
    ReceiptPrintFailure.printerOffline => (
      'The selected printer is offline or turned off.',
      'Turn it on, reconnect its cable or network, and wait until Windows shows it online.',
    ),
    ReceiptPrintFailure.invalidPrinterPort => (
      'The configured printer port is missing or incorrect.',
      'Check the USB/network port in Windows Printer Properties and select the printer again.',
    ),
    ReceiptPrintFailure.printerDriverNotFound => (
      'The printer driver is missing or cannot be loaded.',
      'Install or repair the correct Windows printer driver.',
    ),
    ReceiptPrintFailure.printerServiceUnavailable => (
      'The Windows Print Spooler service is unavailable.',
      'Start or restart the Print Spooler service, then retry.',
    ),
    ReceiptPrintFailure.printerDiscoveryFailed => (
      'The app could not read the Windows printer list.',
      'Check Windows printing services and app permission, then retry.',
    ),
    ReceiptPrintFailure.printRejected => (
      'Windows or the printer rejected the print job.',
      'Check the print queue, paper, connection, driver, and printer status.',
    ),
  };
  return _PrintFailureDetails(
    reason: reason,
    action: action,
    printerName: error.printerName,
    technicalMessage: error.technicalMessage,
  );
}

class _PrintFailureDetails {
  const _PrintFailureDetails({
    required this.reason,
    required this.action,
    this.printerName = '',
    this.technicalMessage = '',
  });

  final String reason;
  final String action;
  final String printerName;
  final String technicalMessage;
}

class _PrintFailureContent extends StatelessWidget {
  const _PrintFailureContent({required this.details});

  final _PrintFailureDetails details;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The sale was saved successfully, but the receipt was not printed.',
            ),
            const SizedBox(height: 16),
            Text(
              'Reason',
              style: TextStyle(
                color: colors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(details.reason),
            if (details.printerName.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Printer: ${details.printerName.trim()}'),
            ],
            const SizedBox(height: 14),
            const Text(
              'What to do',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(details.action),
            if (details.technicalMessage.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: const Text('Technical details'),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SelectableText(
                      details.technicalMessage.trim(),
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
