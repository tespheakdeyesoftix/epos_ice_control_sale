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
    this.allowChangeSaleType = false,
    this.saleTransactionType = 'Sale',
    this.isInventoryProduct = false,
    this.cost = 0,
    this.productUnits = const [],
    this.baseUnit,
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
  final bool allowChangeSaleType;
  final String saleTransactionType;
  final bool isInventoryProduct;
  final double cost;
  final List<ProductUnit> productUnits;
  final String? baseUnit;

  Product forUnit(ProductUnit productUnit) {
    return Product(
      code: code,
      name: name,
      category: category,
      unit: productUnit.unit,
      price: productUnit.price,
      color: color,
      photo: productUnit.photo.trim().isEmpty ? photo : productUnit.photo,
      revenueGroup: revenueGroup,
      multiplier: productUnit.multiplier,
      allowSumQuantity: allowSumQuantity,
      allowSplitBill: allowSplitBill,
      allowChangeSaleType: allowChangeSaleType,
      saleTransactionType: saleTransactionType,
      isInventoryProduct: isInventoryProduct,
      cost: cost,
      productUnits: productUnits,
      baseUnit: resolvedBaseUnit,
    );
  }

  String get resolvedBaseUnit {
    final explicitBaseUnit = baseUnit?.trim() ?? '';
    if (explicitBaseUnit.isNotEmpty) return explicitBaseUnit;
    for (final productUnit in productUnits) {
      if (productUnit.isBaseUnit && productUnit.unit.trim().isNotEmpty) {
        return productUnit.unit;
      }
    }
    return unit;
  }

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
      allowChangeSaleType: toDoubleValue(json['allow_change_sale_type']) == 1,
      saleTransactionType: _saleTransactionType(json),
      isInventoryProduct: toDoubleValue(json['is_inventory_product']) == 1,
      cost: toDoubleValue(json['cost']),
      productUnits: _productUnits(json['product_units']),
    );
  }
}

class ProductUnit {
  const ProductUnit({
    required this.unit,
    required this.price,
    this.multiplier = 1,
    this.isBaseUnit = false,
    this.photo = '',
  });

  factory ProductUnit.fromJson(Map<String, dynamic> json) {
    return ProductUnit(
      unit: (json['unit'] ?? '').toString().trim(),
      price: toDoubleValue(json['price']),
      multiplier: toDoubleValue(json['multiplier'], fallback: 1),
      isBaseUnit: toDoubleValue(json['base_product_unit']) == 1,
      photo: (json['photo'] ?? '').toString().trim(),
    );
  }

  final String unit;
  final double price;
  final double multiplier;
  final bool isBaseUnit;
  final String photo;
}

List<ProductUnit> _productUnits(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((row) => ProductUnit.fromJson(Map<String, dynamic>.from(row)))
      .where((row) => row.unit.isNotEmpty)
      .toList(growable: false);
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
