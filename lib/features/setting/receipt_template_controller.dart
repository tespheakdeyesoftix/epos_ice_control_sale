import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';

import '../../app/app_setting.dart';
import '../../app/app_setting_controller.dart';
import '../../services/receipt_template_service.dart';
import '../../shared/receipts/receipt_a6_widget.dart';
import '../../shared/receipts/receipt_template.dart';
import '../../shared/receipts/receipt_template_renderer.dart';
import 'setting_controller.dart';

enum ReceiptTemplateEditorMode { preview, code, split }

class ReceiptTemplateController extends GetxController {
  ReceiptTemplateController({
    required this.service,
    required this.appSettingController,
  });

  final ReceiptTemplateService service;
  final AppSettingController appSettingController;

  final isLoading = false.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();
  final saveStatus = ''.obs;
  final templates = <ReceiptTemplate>[].obs;
  final selectedTemplate = Rxn<ReceiptTemplate>();
  final imageBytes = <String, Uint8List>{}.obs;
  final previewRevision = 0.obs;
  final editorMode = ReceiptTemplateEditorMode.split.obs;
  final layoutCode = ''.obs;
  final codeError = RxnString();
  final layoutWarnings = <String>[].obs;

  Timer? _codeTimer;
  ReceiptTemplate? _lastSavedTemplate;

  @override
  void onInit() {
    super.onInit();
    loadTemplates();
  }

  Future<void> loadTemplates() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final loaded = await service.listTemplates();
      templates.assignAll(loaded);
      await selectTemplate(loaded.firstOrNull);
    } on Exception {
      errorMessage.value = 'Unable to load receipt templates.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectTemplate(ReceiptTemplate? template) async {
    _codeTimer?.cancel();
    selectedTemplate.value = template;
    _lastSavedTemplate = template;
    layoutCode.value = template == null
        ? ''
        : const JsonEncoder.withIndent('  ').convert(template.toLayoutJson());
    codeError.value = null;
    layoutWarnings.assignAll(template?.layoutWarnings() ?? const <String>[]);
    saveStatus.value = '';
    imageBytes.clear();
    previewRevision.value++;
    if (template == null) return;
    await _loadTemplateImages(template);
  }

  Future<void> _loadTemplateImages(ReceiptTemplate template) async {
    try {
      final business =
          appSettingController.current ??
          const AppSetting(raw: <String, dynamic>{});
      final sources = ReceiptTemplateRenderer.resolveImageSources(
        sale: SettingController.previewSale,
        business: business,
        template: template,
        sellerFallback: 'Administrator',
      );
      final bytes = await service.loadImages(sources);
      if (selectedTemplate.value?.name == template.name) {
        imageBytes.assignAll(bytes);
        previewRevision.value++;
      }
    } on Exception {
      if (selectedTemplate.value?.name == template.name) {
        errorMessage.value = 'Unable to load the template logo.';
      }
    }
  }

  void changeTemplate(ReceiptTemplate value) {
    selectedTemplate.value = value;
    previewRevision.value++;
    saveStatus.value = 'Unsaved changes';
    if (!value.isBuiltIn) unawaited(_loadTemplateImages(value));
  }

  void updateLayoutCode(String value) {
    layoutCode.value = value;
    codeError.value = null;
    _codeTimer?.cancel();
    _codeTimer = Timer(const Duration(seconds: 3), applyLayoutCode);
  }

  bool applyLayoutCode() {
    _codeTimer?.cancel();
    final template = selectedTemplate.value;
    if (template == null || template.isBuiltIn) return false;
    try {
      final decoded = jsonDecode(layoutCode.value);
      if (decoded is! Map) {
        throw const FormatException('The layout root must be a JSON object.');
      }
      final updated = template.applyLayoutJson(
        Map<String, dynamic>.from(decoded),
      );
      codeError.value = null;
      layoutWarnings.assignAll(updated.layoutWarnings());
      changeTemplate(updated);
      return true;
    } on FormatException catch (error) {
      codeError.value = error.message;
      return false;
    } on TypeError {
      codeError.value = 'The layout contains a value with an invalid type.';
      return false;
    }
  }

  void formatLayoutCode() {
    final template = selectedTemplate.value;
    if (template == null || template.isBuiltIn || !applyLayoutCode()) return;
    layoutCode.value = const JsonEncoder.withIndent(
      '  ',
    ).convert(selectedTemplate.value!.toLayoutJson());
  }

  void resetLayoutCode() {
    final template = _lastSavedTemplate;
    if (template == null) return;
    _codeTimer?.cancel();
    selectedTemplate.value = template;
    layoutCode.value = const JsonEncoder.withIndent(
      '  ',
    ).convert(template.toLayoutJson());
    codeError.value = null;
    layoutWarnings.assignAll(template.layoutWarnings());
    saveStatus.value = '';
    previewRevision.value++;
  }

  Future<void> saveNow() async {
    if (!applyLayoutCode()) return;
    await saveTemplate();
  }

  Future<void> saveTemplate() async {
    final template = selectedTemplate.value;
    if (template == null || template.isBuiltIn || isSaving.value) return;
    isSaving.value = true;
    saveStatus.value = 'Saving...';
    try {
      final saved = await service.saveTemplate(template);
      final index = templates.indexWhere((item) => item.name == saved.name);
      if (index >= 0) templates[index] = saved;
      selectedTemplate.value = saved;
      _lastSavedTemplate = saved;
      layoutWarnings.assignAll(saved.layoutWarnings());
      saveStatus.value = 'Saved';
    } on Exception {
      saveStatus.value = 'Save failed';
    } finally {
      isSaving.value = false;
    }
  }

  Future<Uint8List> buildPreview() {
    final template = selectedTemplate.value ?? ReceiptTemplate.standardA6;
    final business =
        appSettingController.current ??
        const AppSetting(raw: <String, dynamic>{});
    if (template.isBuiltIn) {
      return ReceiptA6Widget.buildPdf(
        sale: SettingController.previewSale,
        business: business,
        sellerFallback: 'Administrator',
      );
    }
    return ReceiptTemplateRenderer.buildPdf(
      sale: SettingController.previewSale,
      business: business,
      sellerFallback: 'Administrator',
      template: template,
      imageBytes: Map<String, Uint8List>.from(imageBytes),
    );
  }

  @override
  void onClose() {
    _codeTimer?.cancel();
    super.onClose();
  }
}
