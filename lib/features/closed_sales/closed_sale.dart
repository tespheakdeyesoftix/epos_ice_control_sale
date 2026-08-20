import '../../utils/helpers.dart';

class ClosedSale {
  const ClosedSale({
    required this.name,
    required this.postingDate,
    this.customer = '',
    this.customerName = '',
    this.phoneNumber = '',
    this.driverName = '',
    this.totalSaleQuantity = 0,
    this.totalAmount = 0,
    this.saleStatus = '',
    this.owner = '',
    this.creation,
  });

  factory ClosedSale.fromJson(Map<String, dynamic> json) {
    return ClosedSale(
      name: textValue(json['name']),
      postingDate: textValue(json['posting_date']),
      customer: textValue(json['customer']),
      customerName: textValue(json['customer_name']),
      phoneNumber: textValue(json['phone_number']),
      driverName: textValue(json['driver_name']),
      totalSaleQuantity: toDoubleValue(json['total_sale_quantity']),
      totalAmount: toDoubleValue(json['total_amount']),
      saleStatus: textValue(json['sale_status']),
      owner: textValue(json['owner']),
      creation: DateTime.tryParse(textValue(json['creation'])),
    );
  }

  final String name;
  final String postingDate;
  final String customer;
  final String customerName;
  final String phoneNumber;
  final String driverName;
  final double totalSaleQuantity;
  final double totalAmount;
  final String saleStatus;
  final String owner;
  final DateTime? creation;
}
