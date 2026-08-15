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
    this.paymentTypes = const [],
  });

  factory AppSetting.fromJson(Map<String, dynamic> json) {
    final paymentRows = json['payment_types'];
    return AppSetting(
      raw: Map.unmodifiable(json),
      businessNameEn: _text(json['business_name_en']),
      businessNameKh: _text(json['business_name_kh']),
      address: _text(json['address']),
      phoneNumber1: _text(json['phone_number_1']),
      photo: _text(json['photo']),
      propertyCode: _text(json['property_code']),
      outlet: _text(json['outlet']),
      defaultUnit: _text(json['default_unit']),
      defaultStockLocation: _text(json['default_stock_location']),
      defaultCurrency: _text(json['default_currency']),
      currencySymbol: _text(json['currency_symbol']),
      currencyFormat: _text(json['currency_format']),
      secondCurrency: _text(json['second_currency']),
      secondCurrencySymbol: _text(json['second_currency_symbol']),
      exchangeRate: toDoubleValue(json['exchange_rate'], fallback: 1),
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
  final List<Map<String, dynamic>> paymentTypes;
}

String _text(dynamic value) => value == null ? '' : value.toString().trim();
