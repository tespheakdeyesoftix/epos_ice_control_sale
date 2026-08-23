import '../../utils/helpers.dart';

class CustomerFreeProduct {
  const CustomerFreeProduct({
    required this.productCode,
    required this.productName,
    required this.unit,
    required this.quantity,
    this.multiplier = 1,
  });

  factory CustomerFreeProduct.fromJson(Map<String, dynamic> json) {
    return CustomerFreeProduct(
      productCode: textValue(json['product_code']).trim(),
      productName: textValue(json['product_name']).trim(),
      unit: textValue(json['unit']).trim(),
      quantity: toDoubleValue(json['quantity']),
      multiplier: toDoubleValue(json['multiplier'], fallback: 1),
    );
  }

  final String productCode;
  final String productName;
  final String unit;
  final double quantity;
  final double multiplier;

  bool matches({required String productCode, required String unit}) {
    return this.productCode == productCode.trim() && this.unit == unit.trim();
  }
}

enum FreeProductEvaluationStatus { applied, insufficientQuantity }

class FreeProductEvaluation {
  const FreeProductEvaluation({
    required this.productCode,
    required this.productName,
    required this.unit,
    required this.configuredFreeQuantity,
    required this.orderQuantity,
    required this.status,
  });

  final String productCode;
  final String productName;
  final String unit;
  final double configuredFreeQuantity;
  final double orderQuantity;
  final FreeProductEvaluationStatus status;

  bool get wasApplied => status == FreeProductEvaluationStatus.applied;
}

class AddProductResult {
  const AddProductResult({required this.added, this.freeProductEvaluation});

  final bool added;
  final FreeProductEvaluation? freeProductEvaluation;
}

class CustomerSelectionResult {
  const CustomerSelectionResult({this.freeProductEvaluations = const []});

  final List<FreeProductEvaluation> freeProductEvaluations;
}
