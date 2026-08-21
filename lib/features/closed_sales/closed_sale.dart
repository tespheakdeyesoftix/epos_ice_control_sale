import '../../utils/helpers.dart';

class ClosedSale {
  const ClosedSale({
    required this.name,
    required this.postingDate,
    this.customer = '',
    this.customerName = '',
    this.customerPhoto = '',
    this.phoneNumber = '',
    this.driverName = '',
    this.totalSplitBill = 0,
    this.totalSaleQuantity = 0,
    this.outletUnit = '',
    this.totalAmount = 0,
    this.saleStatus = '',
    this.status = '',
    this.owner = '',
    this.seller = '',
    this.creation,
    this.modified,
  });

  factory ClosedSale.fromJson(Map<String, dynamic> json) {
    return ClosedSale(
      name: textValue(json['name']),
      postingDate: textValue(json['posting_date']),
      customer: textValue(json['customer']),
      customerName: textValue(json['customer_name']),
      customerPhoto: textValue(json['customer_photo']),
      phoneNumber: textValue(json['phone_number']),
      driverName: textValue(json['driver_name']),
      totalSplitBill: toDoubleValue(json['total_split_bill']).toInt(),
      totalSaleQuantity: toDoubleValue(json['total_sale_quantity']),
      outletUnit: textValue(json['outlet_unit']),
      totalAmount: toDoubleValue(json['total_amount']),
      saleStatus: textValue(json['sale_status']),
      status: textValue(json['status']),
      owner: textValue(json['owner']),
      seller: textValue(json['seller']),
      creation: DateTime.tryParse(textValue(json['creation'])),
      modified: DateTime.tryParse(textValue(json['modified'])),
    );
  }

  final String name;
  final String postingDate;
  final String customer;
  final String customerName;
  final String customerPhoto;
  final String phoneNumber;
  final String driverName;
  final int totalSplitBill;
  final double totalSaleQuantity;
  final String outletUnit;
  final double totalAmount;
  final String saleStatus;
  final String status;
  final String owner;
  final String seller;
  final DateTime? creation;
  final DateTime? modified;
}
