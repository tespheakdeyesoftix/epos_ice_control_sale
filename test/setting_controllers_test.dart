import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:ice_control_sale/app/app_setting.dart';
import 'package:ice_control_sale/app/app_setting_controller.dart';
import 'package:ice_control_sale/features/login/login_controller.dart';
import 'package:ice_control_sale/features/setting/receipt_template_controller.dart';
import 'package:ice_control_sale/features/setting/setting_controller.dart';
import 'package:ice_control_sale/services/print_preference_store.dart';
import 'package:ice_control_sale/services/receipt_print_service.dart';
import 'package:ice_control_sale/services/receipt_template_service.dart';
import 'package:ice_control_sale/shared/receipts/receipt_template.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'SettingController loads and saves workstation print defaults',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final store = PrintPreferenceStore(
        preferences: preferences,
        serverKey: 'server',
        stationName: 'Cashier 01',
      );
      final printService = ReceiptPrintService(
        gateway: _PrinterGateway(),
        preferenceStore: store,
      );
      final appSetting = AppSettingController(
        stationName: 'Cashier 01',
        initialSetting: const AppSetting(raw: {}, outlet: 'Main'),
      );
      final login = LoginController(
        authService: null,
        stationName: 'Cashier 01',
        outletName: 'Main',
      );
      final controller = SettingController(
        loginController: login,
        appSettingController: appSetting,
        printService: printService,
      );

      await controller.loadPrintSettings();
      controller.copies.value = 3;
      expect(await controller.savePrintSettings(), isTrue);

      expect(controller.selectedPrinter.value?.name, 'Default Printer');
      expect(store.read('Main').copies, 3);
    },
  );

  test(
    'ReceiptTemplateController previews locally and saves only on demand',
    () async {
      final service = _TemplateService();
      final controller = ReceiptTemplateController(
        service: service,
        appSettingController: AppSettingController(
          stationName: 'Cashier 01',
          initialSetting: const AppSetting(raw: {}),
        ),
      );

      await controller.loadTemplates();
      final originalCount = controller.selectedTemplate.value!.blocks.length;
      final layout = controller.selectedTemplate.value!.toLayoutJson();
      layout['blocks'] = [
        ...layout['blocks']! as List,
        {'id': 'divider', 'type': 'divider', 'position': 'flow'},
      ];
      controller.updateLayoutCode(jsonEncode(layout));
      expect(controller.applyLayoutCode(), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 800));

      expect(service.saveCalls, 0);

      await controller.saveNow();

      expect(
        controller.selectedTemplate.value!.blocks,
        hasLength(originalCount + 1),
      );
      expect(service.saveCalls, 1);
      controller.onClose();
    },
  );
}

class _PrinterGateway implements ReceiptPrinterGateway {
  @override
  Future<List<ReceiptPrinterInfo>> listPrinters() async => const [
    ReceiptPrinterInfo(
      url: 'printer://default',
      name: 'Default Printer',
      isDefault: true,
      isAvailable: true,
    ),
  ];

  @override
  Future<bool> printPdf({
    required ReceiptPrinterInfo printer,
    required Uint8List bytes,
    required String documentName,
    required PdfPageFormat format,
  }) async => true;
}

class _TemplateService extends ReceiptTemplateService {
  _TemplateService()
    : super(
        Uri.parse('https://example.test/'),
        client: MockClient((_) async => throw UnimplementedError()),
      );

  int saveCalls = 0;
  ReceiptTemplate template = ReceiptTemplate.standardA6.copyWith(
    name: 'Editable A6',
    templateName: 'Editable A6',
    isBuiltIn: false,
  );

  @override
  Future<List<ReceiptTemplate>> listTemplates() async => [template];

  @override
  Future<ReceiptTemplate> saveTemplate(ReceiptTemplate value) async {
    saveCalls++;
    template = value;
    return value;
  }

  @override
  Future<Uint8List?> loadLogo(String path) async => null;
}
