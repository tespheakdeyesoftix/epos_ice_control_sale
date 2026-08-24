import 'package:flutter/material.dart';

import '../features/sell/widgets/pending_order_list_dialog_widget.dart';
import '../services/sale_service.dart';

Future<String?> showSelectClosedOrderDialog(
  BuildContext context, {
  required SaleService saleService,
  required String outlet,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => SelectClosedOrderDialogWidget(
      saleService: saleService,
      outlet: outlet,
      onEdit: (name) => Navigator.of(dialogContext).pop(name),
    ),
  );
}

class SelectClosedOrderDialogWidget extends StatelessWidget {
  const SelectClosedOrderDialogWidget({
    super.key,
    required this.saleService,
    required this.outlet,
    required this.onEdit,
  });

  final SaleService saleService;
  final String outlet;
  final ValueChanged<String> onEdit;

  @override
  Widget build(BuildContext context) {
    return PendingOrderListDialogWidget(
      saleService: saleService,
      outlet: outlet,
      saleStatus: 'Closed',
      status: 'Unpaid',
      onEdit: onEdit,
      editActionLabel: 'Edit Order',
      title: 'ជ្រើសរើសបុងដែលបានបិទ',
      emptyMessage: 'មិនមានបុងដែលបានបិទ និងមិនទាន់ទូទាត់ទេ។',
      titleIcon: Icons.receipt_long_rounded,
      keyPrefix: 'closed-order',
    );
  }
}
