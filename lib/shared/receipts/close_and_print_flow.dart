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
    final confirmed = await _confirmCloseAndPrint(context);
    if (!confirmed || !context.mounted) return false;

    final savedOrder = await sellController.saveOrder();
    savedSuccessfully = true;
    sellController.startNewSale();
    if (!context.mounted) return true;

    final printed = await _printWithRetry(
      context,
      printService: printService,
      savedOrder: savedOrder,
      business: business,
      sellerFallback: sellerFallback,
    );
    if (printed && context.mounted) {
      await showSaveOrderSuccessDialog(
        context,
        savedOrder: savedOrder,
        title: 'បានបិទការលក់ និងបោះពុម្ពវិក្កយបត្រដោយជោគជ័យ',
      );
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

Future<bool> _confirmCloseAndPrint(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const ValueKey('confirm-close-and-print-dialog'),
      icon: const Icon(Icons.print_outlined),
      title: const Text('បញ្ជាក់ការបិទ និងបោះពុម្ព'),
      content: const Text(
        'តើអ្នកប្រាកដថាចង់បិទការលក់ និងបោះពុម្ពវិក្កយបត្រនេះមែនទេ?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('បោះបង់'),
        ),
        FilledButton.icon(
          key: const ValueKey('confirm-close-and-print'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          icon: const Icon(Icons.print_rounded),
          label: const Text('បិទ និងបោះពុម្ព'),
        ),
      ],
    ),
  );
  return confirmed == true;
}

Future<bool> _printWithRetry(
  BuildContext context, {
  required ReceiptPrintService printService,
  required Map<String, dynamic> savedOrder,
  required AppSetting business,
  required String sellerFallback,
}) async {
  while (context.mounted) {
    try {
      await printService.printSavedOrder(
        savedOrder: savedOrder,
        business: business,
        sellerFallback: sellerFallback,
      );
      return true;
    } on Exception {
      if (!context.mounted) return false;
      final retry = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          key: const ValueKey('receipt-print-failed-dialog'),
          icon: const Icon(Icons.print_disabled_outlined),
          title: const Text('មិនអាចបោះពុម្ពបាន'),
          content: const Text(
            'បុងត្រូវបានរក្សាទុករួចហើយ ប៉ុន្តែមិនអាចបោះពុម្ពវិក្កយបត្របានទេ។ សូមពិនិត្យម៉ាស៊ីនបោះពុម្ពលំនាំដើម។',
          ),
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
