import '../../utils/helpers.dart';

enum CustomerSelectionType { customer, driver }

class Customer {
  const Customer({
    required this.name,
    required this.customerName,
    this.customerCode = '',
    this.phoneNumber1 = '',
    this.phoneNumber2 = '',
    this.customerGroup = '',
    this.keyword = '',
    this.plateNumber = '',
    this.photo = '',
    this.canEditBill = false,
    this.canShowPrice = false,
    this.canSplitBill = false,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      name: _text(json['name']),
      customerCode: _text(json['customer_code']),
      customerName: _text(json['customer_name']),
      phoneNumber1: _text(json['phone_number_1']),
      phoneNumber2: _text(json['phone_number_2']),
      customerGroup: _text(json['customer_group']),
      keyword: _text(json['keyword']),
      plateNumber: _text(json['plate_number']),
      photo: _text(json['photo']),
      canEditBill: toDoubleValue(json['can_edit_bill']) == 1,
      canShowPrice: toDoubleValue(json['can_show_price']) == 1,
      canSplitBill: toDoubleValue(json['can_split_bill']) == 1,
    );
  }

  final String name;
  final String customerCode;
  final String customerName;
  final String phoneNumber1;
  final String phoneNumber2;
  final String customerGroup;
  final String keyword;
  final String plateNumber;
  final String photo;
  final bool canEditBill;
  final bool canShowPrice;
  final bool canSplitBill;

  String get displayCode => customerCode.isEmpty ? name : customerCode;
  String get displayName => customerName.isEmpty ? name : customerName;
}

String _text(dynamic value) => value == null ? '' : value.toString().trim();
