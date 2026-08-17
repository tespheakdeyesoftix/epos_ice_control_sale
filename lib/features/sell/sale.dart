import '../../utils/helpers.dart';
import 'sale_product.dart';

class Sale {
  const Sale({
    this.name = '',
    required this.outlet,
    required this.saleProducts,
    this.doctype = 'Sale',
    this.namingSeries = 'SO.YYYY.-.####',
    this.postingDate,
    this.referenceNumber = '',
    this.stockLocation = '',
    this.seller = '',
    this.customer = '',
    this.customerName = '',
    this.phoneNumber = '',
    this.customerGroup = '',
    this.customerPhoto = '',
    this.canShowPrice = false,
    this.canSplitBill = false,
    this.canEditBill = false,
    this.driver = '',
    this.driverName = '',
    this.driverPhoneNumber = '',
    this.plateNumber = '',
    this.driverPhoto = '',
    this.saleStatus = 'Draft',
    this.parentBillNumber = '',
    this.note = '',
    this.totalPayment = 0,
    this.totalWriteOff = 0,
    this.status = 'Unpaid',
    this.id = '',
    this.enableEditMode = true,
    this.station = '',
    this.lastUpdateStation = '',
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    final productRows = json['sale_products'];
    return Sale(
      name: _text(json['name']),
      doctype: _text(json['doctype']).isEmpty ? 'Sale' : _text(json['doctype']),
      namingSeries: _text(json['naming_series']).isEmpty
          ? 'SO.YYYY.-.####'
          : _text(json['naming_series']),
      postingDate: DateTime.tryParse(_text(json['posting_date'])),
      referenceNumber: _text(json['reference_number']),
      outlet: _text(json['outlet']),
      stockLocation: _text(json['stock_location']),
      seller: _text(json['seller']),
      customer: _text(json['customer']),
      customerName: _text(json['customer_name']),
      phoneNumber: _text(json['phone_number']),
      customerGroup: _text(json['customer_group']),
      customerPhoto: _text(json['customer_photo']),
      canShowPrice: _flag(json['can_show_price']),
      canSplitBill: _flag(json['can_split_bill']),
      canEditBill: _flag(json['can_edit_bill']),
      driver: _text(json['driver']),
      driverName: _text(json['driver_name']),
      driverPhoneNumber: _text(json['driver_phone_number']),
      plateNumber: _text(json['plate_number']),
      driverPhoto: _text(json['driver_photo']),
      saleStatus: _text(json['sale_status']).isEmpty
          ? 'Draft'
          : _text(json['sale_status']),
      parentBillNumber: _text(json['parent_bill_number']),
      saleProducts: productRows is List
          ? productRows
                .whereType<Map>()
                .map(
                  (row) => SaleProduct.fromJson(Map<String, dynamic>.from(row)),
                )
                .toList(growable: false)
          : const [],
      note: _text(json['note']),
      totalPayment: toDoubleValue(json['total_payment']),
      totalWriteOff: toDoubleValue(json['total_write_off']),
      status: _text(json['status']).isEmpty ? 'Unpaid' : _text(json['status']),
      id: _text(json['id']),
      enableEditMode: json['enable_edit_mode'] == null
          ? true
          : _flag(json['enable_edit_mode']),
      station: _text(json['station']),
      lastUpdateStation: _text(json['last_update_station']),
    );
  }

  final String name;
  final String doctype;
  final String namingSeries;
  final DateTime? postingDate;
  final String referenceNumber;
  final String outlet;
  final String stockLocation;
  final String seller;
  final String customer;
  final String customerName;
  final String phoneNumber;
  final String customerGroup;
  final String customerPhoto;
  final bool canShowPrice;
  final bool canSplitBill;
  final bool canEditBill;
  final String driver;
  final String driverName;
  final String driverPhoneNumber;
  final String plateNumber;
  final String driverPhoto;
  final String saleStatus;
  final String parentBillNumber;
  final List<SaleProduct> saleProducts;
  final String note;
  final double totalPayment;
  final double totalWriteOff;
  final String status;
  final String id;
  final bool enableEditMode;
  final String station;
  final String lastUpdateStation;

  double get totalQuantity => _sum((item) => item.quantity);
  double get totalFree => _sum((item) => item.freeQuantity);
  double get totalQuantityReturn => _sum((item) => item.returnQuantity);
  double get totalSplitQuantity => _sum((item) => item.splitQuantity);
  double get totalSaleQuantity => _sum((item) => item.totalSaleQuantity);
  double get totalAmount => _sum((item) => item.totalAmount);
  double get balance => totalAmount - totalPayment - totalWriteOff;

  double _sum(double Function(SaleProduct) selector) {
    return saleProducts.fold(0, (sum, item) => sum + selector(item));
  }

  Map<String, dynamic> toJson() {
    final date = postingDate ?? DateTime.now();
    return {
      if (name.isNotEmpty) 'name': name,
      'doctype': doctype,
      'naming_series': namingSeries,
      'posting_date': _dateOnly(date),
      'reference_number': referenceNumber,
      'outlet': outlet,
      'stock_location': stockLocation,
      'seller': seller,
      'customer': customer,
      'customer_name': customerName,
      'phone_number': phoneNumber,
      'customer_group': customerGroup,
      'customer_photo': customerPhoto,
      'can_show_price': canShowPrice ? 1 : 0,
      'can_split_bill': canSplitBill ? 1 : 0,
      'can_edit_bill': canEditBill ? 1 : 0,
      'driver': driver,
      'driver_name': driverName,
      'driver_phone_number': driverPhoneNumber,
      'plate_number': plateNumber,
      'driver_photo': driverPhoto,
      'sale_status': saleStatus,
      'parent_bill_number': parentBillNumber,
      'sale_products': saleProducts.map((item) => item.toJson()).toList(),
      'note': note,
      'total_quantity': totalQuantity,
      'total_free': totalFree,
      'total_quantity_return': totalQuantityReturn,
      'total_split_quantity': totalSplitQuantity,
      'total_sale_quantity': totalSaleQuantity,
      'total_payment': totalPayment,
      'total_amount': totalAmount,
      'total_write_off': totalWriteOff,
      'balance': balance,
      'status': status,
      'id': id,
      'enable_edit_mode': enableEditMode ? 1 : 0,
      'station': station,
      'last_update_station': lastUpdateStation,
    };
  }
}

String _text(dynamic value) => value == null ? '' : value.toString().trim();

bool _flag(dynamic value) => toDoubleValue(value) == 1;

String _dateOnly(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}
