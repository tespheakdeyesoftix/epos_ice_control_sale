import 'dart:math' as math;

import 'product.dart';

class SaleProduct {
  const SaleProduct({
    required this.productCode,
    required this.productName,
    required this.productCategory,
    required this.unit,
    required this.price,
    this.outlet = '',
    this.photo = '',
    this.baseUnit = '',
    this.allowSplitBill = false,
    this.saleTransactionType = 'Sale',
    this.multiplier = 1,
    this.revenueGroup = '',
    this.allowSumQuantity = false,
    this.isInventoryProduct = false,
    this.quantity = 1,
    this.productPrice,
    this.freeQuantity = 0,
    this.returnQuantity = 0,
    this.splitQuantity = 0,
    this.cost = 0,
    this.stockLocation = '',
    this.allowFree = false,
    this.allowChangePrice = false,
    this.allowReturn = false,
    this.note = '',
    this.color = '#1677FF',
  });

  factory SaleProduct.fromProduct(
    Product product, {
    required String outlet,
    double quantity = 1,
  }) {
    return SaleProduct(
      productCode: product.code,
      productName: product.name,
      productCategory: product.category,
      unit: product.unit,
      baseUnit: product.unit,
      price: product.price,
      productPrice: product.price,
      outlet: outlet,
      photo: product.photo,
      allowSplitBill: product.allowSplitBill,
      saleTransactionType: product.saleTransactionType,
      multiplier: product.multiplier,
      revenueGroup: product.revenueGroup,
      allowSumQuantity: product.allowSumQuantity,
      isInventoryProduct: product.isInventoryProduct,
      quantity: quantity,
      cost: product.cost,
      color: product.color,
    );
  }

  final String productCode;
  final String productName;
  final String productCategory;
  final String outlet;
  final String photo;
  final String baseUnit;
  final bool allowSplitBill;
  final String saleTransactionType;
  final String unit;
  final double multiplier;
  final String revenueGroup;
  final bool allowSumQuantity;
  final bool isInventoryProduct;
  final double quantity;
  final double price;
  final double? productPrice;
  final double freeQuantity;
  final double returnQuantity;
  final double splitQuantity;
  final double cost;
  final String stockLocation;
  final bool allowFree;
  final bool allowChangePrice;
  final bool allowReturn;
  final String note;

  /// Local display color from Product; not part of the Sale Products doctype.
  final String color;

  double get totalSaleQuantity =>
      math.max(0, quantity - freeQuantity - returnQuantity - splitQuantity);
  double get subTotal => quantity * price;
  double get totalAmount => totalSaleQuantity * price;
  double get totalCost => totalSaleQuantity * cost;

  SaleProduct copyWith({
    double? quantity,
    double? freeQuantity,
    double? returnQuantity,
    double? splitQuantity,
    double? price,
    String? note,
  }) {
    return SaleProduct(
      productCode: productCode,
      productName: productName,
      productCategory: productCategory,
      outlet: outlet,
      photo: photo,
      baseUnit: baseUnit,
      allowSplitBill: allowSplitBill,
      saleTransactionType: saleTransactionType,
      unit: unit,
      multiplier: multiplier,
      revenueGroup: revenueGroup,
      allowSumQuantity: allowSumQuantity,
      isInventoryProduct: isInventoryProduct,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      productPrice: productPrice,
      freeQuantity: freeQuantity ?? this.freeQuantity,
      returnQuantity: returnQuantity ?? this.returnQuantity,
      splitQuantity: splitQuantity ?? this.splitQuantity,
      cost: cost,
      stockLocation: stockLocation,
      allowFree: allowFree,
      allowChangePrice: allowChangePrice,
      allowReturn: allowReturn,
      note: note ?? this.note,
      color: color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_code': productCode,
      'outlet': outlet,
      'product_name': productName,
      'photo': photo,
      'base_unit': baseUnit,
      'allow_split_bill': allowSplitBill ? 1 : 0,
      'sale_transaction_type': saleTransactionType,
      'unit': unit,
      'multiplier': multiplier,
      'product_category': productCategory,
      'revenue_group': revenueGroup,
      'allow_sum_qty': allowSumQuantity ? 1 : 0,
      'is_inventory_product': isInventoryProduct ? 1 : 0,
      'quantity': quantity,
      'price': price,
      'product_price': productPrice ?? price,
      'free_quantity': freeQuantity,
      'return_quantity': returnQuantity,
      'split_quantity': splitQuantity,
      'total_sale_quantity': totalSaleQuantity,
      'sub_total': subTotal,
      'total_amount': totalAmount,
      'cost': cost,
      'total_cost': totalCost,
      'stock_location': stockLocation,
      'allow_free': allowFree ? 1 : 0,
      'allow_change_price': allowChangePrice ? 1 : 0,
      'allow_return': allowReturn ? 1 : 0,
      'note': note,
    };
  }
}
