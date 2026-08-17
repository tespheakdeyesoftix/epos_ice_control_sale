import '../../utils/helpers.dart';

class CustomerProductPrice {
  const CustomerProductPrice({
    required this.productCode,
    required this.unit,
    required this.price,
  });

  factory CustomerProductPrice.fromJson(Map<String, dynamic> json) {
    return CustomerProductPrice(
      productCode: (json['product_code'] ?? '').toString().trim(),
      unit: (json['unit'] ?? '').toString().trim(),
      price: toDoubleValue(json['price']),
    );
  }

  final String productCode;
  final String unit;
  final double price;

  bool matches({required String productCode, required String unit}) {
    return this.productCode == productCode.trim() && this.unit == unit.trim();
  }
}
