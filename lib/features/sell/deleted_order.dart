import '../../utils/helpers.dart';
import '../closed_sales/closed_sale.dart';

class DeletedOrder {
  const DeletedOrder({
    required this.sale,
    this.deletedDate,
    this.deleteNote = '',
    this.deletedBy = '',
  });

  factory DeletedOrder.fromJson(Map<String, dynamic> json) {
    return DeletedOrder(
      sale: ClosedSale.fromJson(json),
      deletedDate: DateTime.tryParse(textValue(json['deleted_date'])),
      deleteNote: textValue(json['deleted_note']),
      deletedBy: textValue(json['deleted_by'] ?? json['deleted_by']),
    );
  }

  final ClosedSale sale;
  final DateTime? deletedDate;
  final String deleteNote;
  final String deletedBy;
}
