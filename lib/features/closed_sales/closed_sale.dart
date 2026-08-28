import '../../utils/helpers.dart';

class ClosedSale {
  const ClosedSale({
    required this.name,
    required this.postingDate,
    this.customer = '',
    this.customerName = '',
    this.customerPhoto = '',
    this.phoneNumber = '',
    this.referenceNumber = '',
    this.driver = '',
    this.driverName = '',
    this.plateNumber = '',
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
    this.deletedDate,
    this.deleteNote = '',
    this.deletedBy = '',
  });

  factory ClosedSale.fromJson(Map<String, dynamic> json) {
    return ClosedSale(
      name: textValue(json['name']),
      postingDate: textValue(json['posting_date']),
      customer: textValue(json['customer']),
      customerName: textValue(json['customer_name']),
      customerPhoto: textValue(json['customer_photo']),
      phoneNumber: textValue(json['phone_number']),
      referenceNumber: textValue(json['reference_number']),
      driver: textValue(json['driver']),
      driverName: textValue(json['driver_name']),
      plateNumber: textValue(json['plate_number']),
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
      deletedDate: DateTime.tryParse(textValue(json['deleted_date'])),
      deleteNote: textValue(json['delete_note']),
      deletedBy: textValue(json['deleted__by'] ?? json['deleted_by']),
    );
  }

  final String name;
  final String postingDate;
  final String customer;
  final String customerName;
  final String customerPhoto;
  final String phoneNumber;
  final String referenceNumber;
  final String driver;
  final String driverName;
  final String plateNumber;
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
  final DateTime? deletedDate;
  final String deleteNote;
  final String deletedBy;
}
