import '../utils/helpers.dart';

class AppSetting {
  const AppSetting({
    required this.raw,
    this.businessNameEn = '',
    this.businessNameKh = '',
    this.address = '',
    this.phoneNumber1 = '',
    this.photo = '',
    this.propertyCode = '',
    this.outlet = '',
    this.defaultUnit = '',
    this.defaultStockLocation = '',
    this.defaultCurrency = '',
    this.currencySymbol = '',
    this.currencyFormat = '',
    this.secondCurrency = '',
    this.secondCurrencySymbol = '',
    this.exchangeRate = 1,
    this.defaultPrintTemplate = '',
    this.paymentTypes = const [],
  });

  factory AppSetting.fromJson(Map<String, dynamic> json) {
    final paymentRows = json['payment_types'];
    return AppSetting(
      raw: Map.unmodifiable(json),
      businessNameEn: textValue(json['business_name_en']),
      businessNameKh: textValue(json['business_name_kh']),
      address: textValue(json['address']),
      phoneNumber1: textValue(json['phone_number_1']),
      photo: textValue(json['photo']),
      propertyCode: textValue(json['property_code']),
      outlet: textValue(json['outlet']),
      defaultUnit: textValue(json['default_unit']),
      defaultStockLocation: textValue(json['default_stock_location']),
      defaultCurrency: textValue(json['default_currency']),
      currencySymbol: textValue(json['currency_symbol']),
      currencyFormat: textValue(json['currency_format']),
      secondCurrency: textValue(json['second_currency']),
      secondCurrencySymbol: textValue(json['second_currency_symbol']),
      exchangeRate: toDoubleValue(json['exchange_rate'], fallback: 1),
      defaultPrintTemplate: textValue(json['default_print_template']),
      paymentTypes: paymentRows is List
          ? paymentRows
                .whereType<Map>()
                .map(
                  (row) => Map<String, dynamic>.unmodifiable(
                    Map<String, dynamic>.from(row),
                  ),
                )
                .toList(growable: false)
          : const [],
    );
  }

  final Map<String, dynamic> raw;
  final String businessNameEn;
  final String businessNameKh;
  final String address;
  final String phoneNumber1;
  final String photo;
  final String propertyCode;
  final String outlet;
  final String defaultUnit;
  final String defaultStockLocation;
  final String defaultCurrency;
  final String currencySymbol;
  final String currencyFormat;
  final String secondCurrency;
  final String secondCurrencySymbol;
  final double exchangeRate;
  final String defaultPrintTemplate;
  final List<Map<String, dynamic>> paymentTypes;
}
