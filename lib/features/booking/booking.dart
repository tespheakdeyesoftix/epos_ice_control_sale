import '../../utils/helpers.dart';

class BookingProduct {
  const BookingProduct({
    required this.productCode,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.price,
    required this.totalAmount,
    required this.transactionType,
  });

  factory BookingProduct.fromJson(Map<String, dynamic> json) {
    return BookingProduct(
      productCode: textValue(json['product_code']),
      productName: textValue(json['product_name']),
      unit: textValue(json['unit']),
      quantity: toDoubleValue(json['quantity']),
      price: toDoubleValue(json['price']),
      totalAmount: toDoubleValue(json['total_amount']),
      transactionType: textValue(json['transaction_type']),
    );
  }

  final String productCode;
  final String productName;
  final String unit;
  final double quantity;
  final double price;
  final double totalAmount;
  final String transactionType;
}

class Booking {
  const Booking({
    required this.name,
    required this.postingDate,
    required this.deliveryDate,
    required this.bookingEvent,
    required this.customerName,
    required this.phoneNumber,
    required this.address,
    required this.note,
    required this.productsDescription,
    required this.totalAmount,
    required this.createdBy,
    required this.creation,
    required this.products,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final productRows = json['booking_products'];
    return Booking(
      name: textValue(json['name']),
      postingDate: DateTime.tryParse(textValue(json['posting_date'])),
      deliveryDate: DateTime.tryParse(textValue(json['delivery_date'])),
      bookingEvent: textValue(json['booking_event']),
      customerName: textValue(json['customer_name']),
      phoneNumber: textValue(json['phone_number']),
      address: textValue(json['address']),
      note: textValue(json['note']),
      productsDescription: textValue(json['booking_products_description']),
      totalAmount: toDoubleValue(json['total_amount']),
      createdBy: textValue(json['created_by']).isEmpty
          ? textValue(json['owner'])
          : textValue(json['created_by']),
      creation: DateTime.tryParse(textValue(json['creation'])),
      products: productRows is List
          ? productRows
                .whereType<Map>()
                .map(
                  (row) =>
                      BookingProduct.fromJson(Map<String, dynamic>.from(row)),
                )
                .toList(growable: false)
          : const [],
    );
  }

  final String name;
  final DateTime? postingDate;
  final DateTime? deliveryDate;
  final String bookingEvent;
  final String customerName;
  final String phoneNumber;
  final String address;
  final String note;
  final String productsDescription;
  final double totalAmount;
  final String createdBy;
  final DateTime? creation;
  final List<BookingProduct> products;

  double get totalQuantity =>
      products.fold(0, (total, product) => total + product.quantity);

  bool isDeliveredOn(DateTime date) {
    final delivery = deliveryDate;
    return delivery != null &&
        delivery.year == date.year &&
        delivery.month == date.month &&
        delivery.day == date.day;
  }
}
