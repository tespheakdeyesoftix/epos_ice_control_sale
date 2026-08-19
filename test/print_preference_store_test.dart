import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/services/print_preference_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('stores print defaults per server station and outlet', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = PrintPreferenceStore(
      preferences: preferences,
      serverKey: 'https://example.test',
      stationName: 'Cashier 01',
    );

    await store.write(
      'Outlet A',
      const PrintPreference(
        printerUrl: 'printer://a6',
        printerName: 'A6 Printer',
        templateName: 'Outlet A6',
        copies: 3,
      ),
    );

    expect(store.read('Outlet A').printerName, 'A6 Printer');
    expect(store.read('Outlet A').templateName, 'Outlet A6');
    expect(store.read('Outlet A').copies, 3);
    expect(store.read('Outlet B').printerName, isEmpty);
    expect(store.read('Outlet B').copies, 1);
  });

  test('copy count is always constrained to one through three', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = PrintPreferenceStore(
      preferences: preferences,
      serverKey: 'server',
      stationName: 'station',
    );

    await store.write('outlet', const PrintPreference(copies: 99));

    expect(store.read('outlet').copies, 3);
  });
}
