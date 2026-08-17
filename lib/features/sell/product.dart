import '../../utils/helpers.dart';

class Product {
  const Product({
    required this.code,
    required this.name,
    required this.category,
    required this.unit,
    required this.price,
    required this.color,
    required this.photo,
    this.revenueGroup = '',
    this.multiplier = 1,
    this.allowSumQuantity = false,
    this.allowSplitBill = false,
    this.saleTransactionType = 'Sale',
    this.isInventoryProduct = false,
    this.cost = 0,
  });

  final String code;
  final String name;
  final String category;
  final String unit;
  final double price;
  final String color;
  final String photo;
  final String revenueGroup;
  final double multiplier;
  final bool allowSumQuantity;
  final bool allowSplitBill;
  final String saleTransactionType;
  final bool isInventoryProduct;
  final double cost;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      code: (json['product_code'] ?? json['name'] ?? '').toString(),
      name: (json['product_name'] ?? json['product_code'] ?? '').toString(),
      category: (json['product_category'] ?? '').toString(),
      unit: (json['unit'] ?? '').toString(),
      price: toDoubleValue(json['price']),
      color: (json['color'] ?? '#1677FF').toString(),
      photo: (json['photo'] ?? '').toString(),
      revenueGroup: (json['revenue_group'] ?? '').toString(),
      multiplier: toDoubleValue(json['multiplier'], fallback: 1),
      allowSumQuantity: toDoubleValue(json['allow_sum_qty']) == 1,
      allowSplitBill: toDoubleValue(json['allow_split_bill']) == 1,
      saleTransactionType: _saleTransactionType(json),
      isInventoryProduct: toDoubleValue(json['is_inventory_product']) == 1,
      cost: toDoubleValue(json['cost']),
    );
  }
}

String _saleTransactionType(Map<String, dynamic> json) {
  for (final value in [
    json['default_sale_type'],
    json['default_sale_transaction_type'],
  ]) {
    final type = value?.toString().trim() ?? '';
    if (type.isNotEmpty) return type;
  }
  return 'Sale';
}
