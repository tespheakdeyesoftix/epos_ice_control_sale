import '../../utils/helpers.dart';

class PendingOrder {
  const PendingOrder({
    required this.name,
    required this.postingDate,
    this.customer = '',
    this.customerName = '',
    this.phoneNumber = '',
    this.canShowPrice = false,
    this.driverName = '',
    this.totalSaleQuantity = 0,
    this.totalAmount = 0,
  });

  factory PendingOrder.fromJson(Map<String, dynamic> json) {
    return PendingOrder(
      name: textValue(json['name']),
      postingDate: textValue(json['posting_date']),
      customer: textValue(json['customer']),
      customerName: textValue(json['customer_name']),
      phoneNumber: textValue(json['phone_number']),
      canShowPrice: toDoubleValue(json['can_show_price']) == 1,
      driverName: textValue(json['driver_name']),
      totalSaleQuantity: toDoubleValue(json['total_sale_quantity']),
      totalAmount: toDoubleValue(json['total_amount']),
    );
  }

  final String name;
  final String postingDate;
  final String customer;
  final String customerName;
  final String phoneNumber;
  final bool canShowPrice;
  final String driverName;
  final double totalSaleQuantity;
  final double totalAmount;
}
