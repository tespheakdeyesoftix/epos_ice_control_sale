import 'package:shared_preferences/shared_preferences.dart';

class PrintPreference {
  const PrintPreference({
    this.printerUrl = '',
    this.printerName = '',
    this.templateName = '',
    this.copies = 1,
  });

  final String printerUrl;
  final String printerName;
  final String templateName;
  final int copies;

  PrintPreference copyWith({
    String? printerUrl,
    String? printerName,
    String? templateName,
    int? copies,
  }) {
    return PrintPreference(
      printerUrl: printerUrl ?? this.printerUrl,
      printerName: printerName ?? this.printerName,
      templateName: templateName ?? this.templateName,
      copies: (copies ?? this.copies).clamp(1, 3),
    );
  }
}

class PrintPreferenceStore {
  PrintPreferenceStore({
    required SharedPreferences preferences,
    required this.serverKey,
    required this.stationName,
  }) : _preferences = preferences;

  final SharedPreferences _preferences;
  final String serverKey;
  final String stationName;

  String _prefix(String outlet) {
    final scope = [
      serverKey,
      stationName,
      outlet.trim(),
    ].map(Uri.encodeComponent).join('::');
    return 'print_preference::$scope';
  }

  PrintPreference read(String outlet) {
    final prefix = _prefix(outlet);
    return PrintPreference(
      printerUrl: _preferences.getString('$prefix::printer_url') ?? '',
      printerName: _preferences.getString('$prefix::printer_name') ?? '',
      templateName: _preferences.getString('$prefix::template_name') ?? '',
      copies: (_preferences.getInt('$prefix::copies') ?? 1).clamp(1, 3),
    );
  }

  Future<void> write(String outlet, PrintPreference value) async {
    final prefix = _prefix(outlet);
    await Future.wait([
      _preferences.setString('$prefix::printer_url', value.printerUrl),
      _preferences.setString('$prefix::printer_name', value.printerName),
      _preferences.setString('$prefix::template_name', value.templateName),
      _preferences.setInt('$prefix::copies', value.copies.clamp(1, 3)),
    ]);
  }
}
