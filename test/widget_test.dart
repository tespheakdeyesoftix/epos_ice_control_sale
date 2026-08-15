import 'package:flutter_test/flutter_test.dart';
import 'package:ice_control_sale/app/app_config.dart';
import 'package:ice_control_sale/app/app_setting.dart';
import 'package:ice_control_sale/app/app_setting_controller.dart';
import 'package:ice_control_sale/main.dart';

void main() {
  testWidgets('បង្ហាញទំព័រចូលប្រើប្រាស់', (tester) async {
    await tester.pumpWidget(
      IceSaleApp(
        config: AppConfig(
          Uri.parse('http://127.0.0.1:8888/'),
          stationName: 'Cashier 01',
          outletName: 'ទឹកកកដើម',
        ),
        appSettingController: AppSettingController(
          stationName: 'Cashier 01',
          initialSetting: const AppSetting(
            raw: {},
            businessNameEn: 'Heang Hok Kheang I',
            businessNameKh: 'រោងចក្រទឹកកក ហ៊ាងហុកឃាង',
            address: 'ខេត្តសៀមរាប',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('សូមស្វាគមន៍'), findsOneWidget);
    expect(find.text('រោងចក្រទឹកកក ហ៊ាងហុកឃាង'), findsOneWidget);
    expect(find.text('Heang Hok Kheang I'), findsOneWidget);
    expect(find.text('ខេត្តសៀមរាប'), findsOneWidget);
    expect(find.text('ចូលប្រើប្រាស់'), findsNWidgets(2));
    expect(find.text('ឈ្មោះអ្នកប្រើប្រាស់'), findsOneWidget);
    expect(find.text('ពាក្យសម្ងាត់'), findsOneWidget);
    expect(find.text('Cashier 01'), findsOneWidget);
    expect(find.text('ស្ថានីយ៖'), findsOneWidget);
    expect(find.text('សាខា៖'), findsOneWidget);
    expect(find.text('ទឹកកកដើម'), findsOneWidget);
  });
}
