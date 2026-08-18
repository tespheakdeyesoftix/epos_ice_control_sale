import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/frappe_response_handler.dart';
import '../navigation/app_destination.dart';
import '../navigation/app_shell_controller.dart';
import '../sell/sell_controller.dart';
import '../sell/widgets/pending_order_list_dialog_widget.dart';
import 'widgets/pending_sale_view_dialog_widget.dart';

class PendingSaleListScreen extends GetView<AppShellController> {
  const PendingSaleListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sell = controller.sellController;
    return PendingOrderListDialogWidget(
      saleService: sell.saleService,
      outlet: sell.outletName,
      embedded: true,
      onView: (name) => showPendingSaleViewDialog(
        context,
        saleService: sell.saleService,
        name: name,
      ),
      onEdit: (name) => _editOrder(context, name),
      onRefreshed: () => sell.loadPendingOrderCount(),
    );
  }

  Future<void> _editOrder(BuildContext context, String name) async {
    final sell = controller.sellController;
    if (!sell.canOpenPendingOrder) {
      _showMessage(
        'សូមរក្សាទុកការលក់បច្ចុប្បន្នជាមុនសិន មុននឹងកែបុងដែលបានផ្អាក។',
        indicator: 'orange',
      );
      return;
    }

    try {
      await sell.openPendingOrder(name);
      if (!context.mounted) return;
      await controller.navigateTo(
        AppDestination.sale,
        resolveUnfinishedSale: () async => true,
      );
    } on PendingOrderOpenValidationException {
      _showMessage(
        'សូមរក្សាទុកការលក់បច្ចុប្បន្នជាមុនសិន មុននឹងកែបុងដែលបានផ្អាក។',
        indicator: 'orange',
      );
    } on SaleEditBlockedException catch (error) {
      _showMessage(error.message, indicator: 'orange');
    } on PendingOrderNotDraftException {
      _showMessage('បុងនេះមិនមែនជាបុងដែលបានផ្អាកទៀតទេ។');
    } on FrappeServerMessageException {
      // The shared API client already displayed the server message.
    } on Exception {
      _showMessage('មិនអាចបើកបុងដែលបានផ្អាកនេះបានទេ។', indicator: 'red');
    }
  }

  void _showMessage(String message, {String indicator = ''}) {
    FrappeResponseHandler.show(
      FrappeServerMessage(message: message, indicator: indicator),
    );
  }
}
