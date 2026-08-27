import '../../utils/helpers.dart';

class PaymentType {
  const PaymentType({
    required this.name,
    required this.currency,
    required this.exchangeRate,
  });

  factory PaymentType.fromJson(Map<String, dynamic> json) => PaymentType(
    name: textValue(json['name']),
    currency: textValue(json['currency']),
    exchangeRate: toDoubleValue(json['exchange_rate']),
  );

  final String name;
  final String currency;
  final double exchangeRate;

  bool get isValid =>
      name.isNotEmpty && currency.isNotEmpty && exchangeRate > 0;
}

class SalePayment {
  const SalePayment({
    required this.paymentType,
    required this.currency,
    required this.exchangeRate,
    required this.inputAmount,
  });

  factory SalePayment.fromJson(Map<String, dynamic> json) => SalePayment(
    paymentType: textValue(json['payment_type']),
    currency: textValue(json['currency']),
    exchangeRate: toDoubleValue(json['exchange_rate']),
    inputAmount: toDoubleValue(json['input_amount']),
  );

  factory SalePayment.fromPaymentType(
    PaymentType paymentType, {
    required double totalAmount,
  }) => SalePayment(
    paymentType: paymentType.name,
    currency: paymentType.currency,
    exchangeRate: paymentType.exchangeRate,
    inputAmount: totalAmount / paymentType.exchangeRate,
  );

  final String paymentType;
  final String currency;
  final double exchangeRate;
  final double inputAmount;

  Map<String, dynamic> toJson() => {
    'payment_type': paymentType,
    'currency': currency,
    'exchange_rate': exchangeRate,
    'input_amount': inputAmount,
  };
}
