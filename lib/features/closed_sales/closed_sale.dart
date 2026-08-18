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
      name: _text(json['name']),
      postingDate: _text(json['posting_date']),
      customer: _text(json['customer']),
      customerName: _text(json['customer_name']),
      phoneNumber: _text(json['phone_number']),
      driverName: _text(json['driver_name']),
      totalSaleQuantity: toDoubleValue(json['total_sale_quantity']),
      totalAmount: toDoubleValue(json['total_amount']),
      saleStatus: _text(json['sale_status']),
      owner: _text(json['owner']),
      creation: DateTime.tryParse(_text(json['creation'])),
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

String _text(dynamic value) => value == null ? '' : value.toString().trim();
