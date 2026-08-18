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
      name: _text(json['name']),
      postingDate: _text(json['posting_date']),
      customer: _text(json['customer']),
      customerName: _text(json['customer_name']),
      phoneNumber: _text(json['phone_number']),
      canShowPrice: toDoubleValue(json['can_show_price']) == 1,
      driverName: _text(json['driver_name']),
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

String _text(dynamic value) => value == null ? '' : value.toString().trim();
