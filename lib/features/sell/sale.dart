import 'sale_product.dart';

class Sale {
  const Sale({
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

String _dateOnly(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}
