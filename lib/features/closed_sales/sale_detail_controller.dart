import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/app_setting.dart';
import '../../app/app_setting_controller.dart';
import '../../features/login/login_controller.dart';
import '../../features/sell/sale.dart';
import '../../services/frappe_response_handler.dart';
import '../../services/receipt_print_service.dart';
import '../../services/sale_service.dart';
import '../../shared/receipts/receipt_a6_widget.dart';
import '../../shared/receipts/receipt_template.dart';
import '../../shared/receipts/receipt_template_renderer.dart';
import '../../utils/helpers.dart';
import 'closed_sale.dart';
import 'closed_sale_controller.dart';

/// Add developer-only tracked field names here to hide them from Activity.
/// Keep values lowercase; matching is case-insensitive.
const List<String> saleTimelineHiddenFields = <String>['product_qty'];

/// Add tracked monetary field names here so Activity displays their currency.
/// Keep values lowercase; matching is case-insensitive.
const List<String> saleTimelineCurrencyFields = <String>[
  'price',
  'product_price',
  'rate',
  'amount',
  'total_amount',
  'grand_total',
  'net_total',
  'paid_amount',
  'payment_amount',
  'total_payment',
  'balance',
  'outstanding_amount',
  'discount_amount',
  'write_off_amount',
  'total_write_off',
  'cost',
  'total_cost',
];

enum SaleTimelineKind { comment, change, created, modified }

class SaleTimelineEntry {
  const SaleTimelineEntry({
    this.name = '',
    this.owner = '',
    required this.kind,
    required this.author,
    required this.createdAt,
    required this.content,
    this.changes = const [],
  });

  final String name;
  final String owner;
  final SaleTimelineKind kind;
  final String author;
  final DateTime? createdAt;
  final String content;
  final List<String> changes;
}

class SaleDetailController extends GetxController {
  SaleDetailController({
    required this.summary,
    required this.saleService,
    this.closedSaleController,
    this.printService,
    this.appSettingController,
    this.loginController,
  });

  final ClosedSale summary;
  final SaleService? saleService;
  final ClosedSaleController? closedSaleController;
  final ReceiptPrintService? printService;
  final AppSettingController? appSettingController;
  final LoginController? loginController;

  final commentController = TextEditingController();
  final noteController = TextEditingController();
  final noteFocusNode = FocusNode();
  final sale = Rxn<Sale>();
  final rawDocument = <String, dynamic>{}.obs;
  final timeline = <SaleTimelineEntry>[].obs;
  final payments = <Map<String, dynamic>>[].obs;
  final printTemplates = <ReceiptTemplate>[ReceiptTemplate.standardA6].obs;
  final selectedPrintTemplate = ReceiptTemplate.standardA6.obs;
  final isLoading = false.obs;
  final isPosting = false.obs;
  final isPrinting = false.obs;
  final isSavingNote = false.obs;
  final isSavingReferenceNumber = false.obs;
  final editingCommentNames = <String>{}.obs;
  final errorMessage = RxnString();
  final noteSaveError = RxnString();
  bool _printTemplatesLoaded = false;
  String _lastSavedNote = '';

  Sale get displayedSale => sale.value ?? _summarySale;

  Sale get _summarySale => Sale(
    name: summary.name,
    postingDate: DateTime.tryParse(summary.postingDate),
    outlet: summary.outletUnit,
    customer: summary.customer,
    customerName: summary.customerName,
    customerPhoto: summary.customerPhoto,
    phoneNumber: summary.phoneNumber,
    driverName: summary.driverName,
    saleStatus: summary.saleStatus,
    totalPayment: summary.status.toLowerCase() == 'paid'
        ? summary.totalAmount
        : 0,
    totalSplitBill: summary.totalSplitBill,
    status: summary.status,
    saleProducts: const [],
  );

  Future<void> load() async {
    final service = saleService;
    if (service == null || isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final payload = await service.loadSaleDocument(summary.name);
      final docs = payload['docs'];
      Map<String, dynamic>? document;
      if (docs is List) {
        for (final row in docs.whereType<Map>()) {
          if (textValue(row['doctype']) == 'Sale' ||
              textValue(row['name']) == summary.name) {
            document = Map<String, dynamic>.from(row);
            break;
          }
        }
        if (document == null && docs.whereType<Map>().isNotEmpty) {
          document = Map<String, dynamic>.from(docs.whereType<Map>().first);
        }
      }
      if (document == null) throw const SaleServiceException(200);
      rawDocument.assignAll(document);
      sale.value = Sale.fromJson(document);
      if (!noteFocusNode.hasFocus && !isSavingNote.value) {
        _lastSavedNote = sale.value?.note ?? '';
        noteController.text = _lastSavedNote;
      }
      payments.assignAll(_parsePayments(document));
      timeline.assignAll(
        _parseTimeline(
          payload['docinfo'],
          document,
          currencySymbol: appSettingController?.current?.currencySymbol ?? '',
        ),
      );
    } on FrappeServerMessageException {
      // The shared response handler already displayed the server message.
    } on Exception {
      errorMessage.value = 'មិនអាចទាញយកព័ត៌មានវិក្កយបត្របានទេ។';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> postTimelineEntry() async {
    final service = saleService;
    final content = commentController.text.trim();
    if (service == null || content.isEmpty || isPosting.value) return false;
    isPosting.value = true;
    try {
      final session = loginController?.currentSession.value;
      await service.addSaleComment(
        saleName: summary.name,
        content: content,
        email: session?.email ?? session?.user ?? '',
        author: _currentAuthor,
      );
      commentController.clear();
      await load();
      _showMessage('បានបង្ហោះដោយជោគជ័យ។', indicator: 'green');
      return true;
    } on FrappeServerMessageException {
      return false;
    } on Exception {
      _showMessage('មិនអាចបង្ហោះបានទេ។ សូមព្យាយាមម្តងទៀត។', indicator: 'red');
      return false;
    } finally {
      isPosting.value = false;
    }
  }

  bool canEditComment(SaleTimelineEntry entry) {
    if (entry.kind != SaleTimelineKind.comment || entry.name.isEmpty) {
      return false;
    }
    final owner = entry.owner.trim().toLowerCase();
    final session = loginController?.currentSession.value;
    if (session?.user.trim().toLowerCase() == 'administrator') return true;
    return owner.isNotEmpty &&
        [
          session?.user,
          session?.email,
          session?.username,
        ].any((value) => value?.trim().toLowerCase() == owner);
  }

  Future<bool> updateComment(SaleTimelineEntry entry, String content) async {
    final service = saleService;
    final value = content.trim();
    if (service == null ||
        value.isEmpty ||
        !canEditComment(entry) ||
        editingCommentNames.contains(entry.name)) {
      return false;
    }
    editingCommentNames.add(entry.name);
    try {
      await service.updateSaleComment(commentName: entry.name, content: value);
      await load();
      _showMessage('បានកែប្រែមតិយោបល់ដោយជោគជ័យ។', indicator: 'green');
      return true;
    } on FrappeServerMessageException {
      return false;
    } on Exception {
      _showMessage('មិនអាចកែប្រែមតិយោបល់បានទេ។', indicator: 'red');
      return false;
    } finally {
      editingCommentNames.remove(entry.name);
    }
  }

  Future<void> saveNoteOnFocusLost() async {
    final service = saleService;
    final value = noteController.text;
    if (isSavingNote.value) {
      while (isSavingNote.value) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
      return;
    }
    if (service == null || value == _lastSavedNote) {
      return;
    }
    isSavingNote.value = true;
    noteSaveError.value = null;
    try {
      await service.updateSaleNote(saleName: summary.name, note: value);
      _lastSavedNote = value;
      rawDocument['note'] = value;
      sale.value = Sale.fromJson(Map<String, dynamic>.from(rawDocument));
      await load();
      _showMessage('បានរក្សាទុកកំណត់ចំណាំ។', indicator: 'green');
    } on FrappeServerMessageException {
      noteSaveError.value = 'មិនអាចរក្សាទុកកំណត់ចំណាំបានទេ។';
    } on Exception {
      noteSaveError.value = 'មិនអាចរក្សាទុកកំណត់ចំណាំបានទេ។';
      _showMessage(noteSaveError.value!, indicator: 'red');
    } finally {
      isSavingNote.value = false;
    }
  }

  Future<bool> updateReferenceNumber(String referenceNumber) async {
    final service = saleService;
    final value = referenceNumber.trim();
    if (service == null || isSavingReferenceNumber.value) return false;
    if (value == displayedSale.referenceNumber.trim()) return true;
    isSavingReferenceNumber.value = true;
    try {
      await service.updateSaleReferenceNumber(
        saleName: summary.name,
        referenceNumber: value,
      );
      rawDocument['reference_number'] = value;
      sale.value = Sale.fromJson(Map<String, dynamic>.from(rawDocument));
      await load();
      _showMessage('បានរក្សាទុកលេខយោង។', indicator: 'green');
      return true;
    } on FrappeServerMessageException {
      return false;
    } on Exception {
      _showMessage('មិនអាចរក្សាទុកលេខយោងបានទេ។', indicator: 'red');
      return false;
    } finally {
      isSavingReferenceNumber.value = false;
    }
  }

  Future<bool> editOrder() async {
    return await closedSaleController?.editOrder(summary.name) ?? false;
  }

  Future<bool> deleteOrder(String reason) async {
    return closedSaleController?.deleteSale(summary.name, reason) ?? false;
  }

  Future<void> reprintReceipt({int copies = 1}) async {
    final printer = printService;
    if (printer == null || isPrinting.value || !printer.beginWorkflow()) return;
    isPrinting.value = true;
    try {
      await printer.printSavedOrder(
        savedOrder: displayedSale.toJson(),
        business: _business,
        sellerFallback: _currentAuthor,
        copies: copies.clamp(1, 3),
      );
      _showMessage('បានបោះពុម្ពវិក្កយបត្រឡើងវិញ។', indicator: 'green');
    } on ReceiptPrintException {
      _showMessage(
        'មិនអាចបោះពុម្ពវិក្កយបត្របានទេ។ សូមពិនិត្យម៉ាស៊ីនបោះពុម្ព។',
        indicator: 'red',
      );
    } on Exception {
      _showMessage('មិនអាចបោះពុម្ពវិក្កយបត្របានទេ។', indicator: 'red');
    } finally {
      isPrinting.value = false;
      printer.endWorkflow();
    }
  }

  Future<void> loadPrintTemplates() async {
    if (_printTemplatesLoaded) return;
    _printTemplatesLoaded = true;
    final service = printService?.templateService;
    if (service == null) return;
    try {
      final templates = await service.listTemplates();
      final customTemplates = templates
          .where((template) => !template.isBuiltIn)
          .toList(growable: false);
      if (customTemplates.isEmpty) return;
      printTemplates.assignAll(customTemplates);
      final preference = printService?.preferenceStore?.read(
        displayedSale.outlet,
      );
      final preferredNames = <String>[
        preference?.templateName ?? '',
        _business.defaultPrintTemplate,
      ];
      for (final preferredName in preferredNames) {
        final normalized = preferredName.trim();
        if (normalized.isEmpty) continue;
        for (final template in customTemplates) {
          if (template.name == normalized ||
              template.templateName == normalized) {
            selectedPrintTemplate.value = template;
            return;
          }
        }
      }
      selectedPrintTemplate.value = customTemplates.first;
    } on Exception {
      // The built-in receipt remains available when remote templates fail.
    }
  }

  Future<Uint8List> buildPrintPreview({ReceiptTemplate? template}) async {
    final resolvedTemplate = template ?? selectedPrintTemplate.value;
    if (resolvedTemplate.isBuiltIn) {
      return ReceiptA6Widget.buildPdf(
        sale: displayedSale,
        business: _business,
        sellerFallback: _currentAuthor,
        copies: 1,
      );
    }
    final sources = ReceiptTemplateRenderer.resolveImageSources(
      sale: displayedSale,
      business: _business,
      template: resolvedTemplate,
      sellerFallback: _currentAuthor,
    );
    final images =
        await printService?.templateService?.loadImages(sources) ??
        const <String, Uint8List>{};
    return ReceiptTemplateRenderer.buildPdf(
      sale: displayedSale,
      business: _business,
      sellerFallback: _currentAuthor,
      template: resolvedTemplate,
      copies: 1,
      imageBytes: images,
    );
  }

  AppSetting get _business =>
      appSettingController?.current ??
      const AppSetting(raw: <String, dynamic>{});

  String get _currentAuthor {
    final session = loginController?.currentSession.value;
    for (final value in [
      session?.fullName,
      session?.user,
      loginController?.currentUsername.value,
      summary.owner,
    ]) {
      final text = value?.trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return 'អ្នកប្រើប្រាស់';
  }

  void _showMessage(String message, {String indicator = ''}) {
    FrappeResponseHandler.show(
      FrappeServerMessage(message: message, indicator: indicator),
    );
  }

  @override
  void onClose() {
    commentController.dispose();
    noteController.dispose();
    noteFocusNode.dispose();
    super.onClose();
  }
}

List<Map<String, dynamic>> _parsePayments(Map<String, dynamic> document) {
  for (final key in const [
    'sale_payments',
    'payments',
    'payment_history',
    'payment_details',
  ]) {
    final rows = document[key];
    if (rows is List) {
      return rows
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);
    }
  }
  return const [];
}

List<SaleTimelineEntry> _parseTimeline(
  Object? value,
  Map<String, dynamic> document, {
  required String currencySymbol,
}) {
  if (value is! Map) return const [];
  final info = Map<String, dynamic>.from(value);
  final userInfo = info['user_info'] is Map
      ? Map<String, dynamic>.from(info['user_info'] as Map)
      : const <String, dynamic>{};
  String author(Object? owner) {
    final key = textValue(owner);
    final user = userInfo[key];
    if (user is Map) {
      for (final candidate in [
        user['fullname'],
        user['full_name'],
        user['name'],
      ]) {
        final label = textValue(candidate);
        if (label.isNotEmpty) return label;
      }
    }
    return key.isEmpty ? 'ប្រព័ន្ធ' : key;
  }

  final entries = <SaleTimelineEntry>[];
  void addSimple(Object? rows, SaleTimelineKind kind) {
    if (rows is! List) return;
    for (final item in rows.whereType<Map>()) {
      entries.add(
        SaleTimelineEntry(
          name: textValue(item['name']),
          owner: textValue(item['owner']),
          kind: kind,
          author: author(item['owner']),
          createdAt: DateTime.tryParse(textValue(item['creation'])),
          content: _plainText(textValue(item['content'])),
        ),
      );
    }
  }

  addSimple(info['comments'], SaleTimelineKind.comment);

  final versions = info['versions'];
  if (versions is List) {
    for (final item in versions.whereType<Map>()) {
      final changes = _versionChanges(
        item['data'],
        currencySymbol: currencySymbol,
      );
      if (changes.isEmpty) continue;
      entries.add(
        SaleTimelineEntry(
          kind: SaleTimelineKind.change,
          author: author(item['owner']),
          createdAt: DateTime.tryParse(textValue(item['creation'])),
          content: 'បានកែប្រែ ${changes.length} ចំណុច',
          changes: changes,
        ),
      );
    }
  }
  final creation = DateTime.tryParse(textValue(document['creation']));
  if (creation != null) {
    entries.add(
      SaleTimelineEntry(
        kind: SaleTimelineKind.created,
        author: author(document['owner']),
        createdAt: creation,
        content: 'បានបង្កើតវិក្កយបត្រនេះ',
      ),
    );
  }
  final modified = DateTime.tryParse(textValue(document['modified']));
  if (modified != null) {
    entries.add(
      SaleTimelineEntry(
        kind: SaleTimelineKind.modified,
        author: author(document['modified_by']),
        createdAt: modified,
        content: 'បានកែប្រែវិក្កយបត្រនេះចុងក្រោយ',
      ),
    );
  }
  entries.sort((a, b) {
    final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return right.compareTo(left);
  });
  return entries;
}

List<String> _versionChanges(Object? value, {required String currencySymbol}) {
  dynamic data = value;
  if (data is String) {
    try {
      data = jsonDecode(data);
    } on FormatException {
      return const [];
    }
  }
  if (data is! Map) return const [];
  final result = <String>[];
  final changed = data['changed'];
  if (changed is List) {
    for (final row in changed.whereType<List>()) {
      if (row.length < 3) continue;
      final fieldName = textValue(row[0]);
      if (saleTimelineHiddenFields.contains(fieldName.toLowerCase())) continue;
      result.add(
        '$fieldName: ${_trackedValue(fieldName, row[1], currencySymbol)} → ${_trackedValue(fieldName, row[2], currencySymbol)}',
      );
    }
  }
  for (final key in const ['added', 'removed', 'row_changed']) {
    final rows = data[key];
    if (rows is List && rows.isNotEmpty) {
      final label = switch (key) {
        'added' => 'បានបន្ថែម',
        'removed' => 'បានលុបចេញ',
        _ => 'បានកែប្រែជួរទិន្នន័យ',
      };
      result.add('$label: ${rows.length}');
    }
  }
  return result;
}

String _trackedValue(String fieldName, Object? value, String currencySymbol) {
  final raw = textValue(value);
  if (raw.isEmpty) return '—';
  if (!saleTimelineCurrencyFields.contains(fieldName.toLowerCase())) return raw;
  final number = double.tryParse(raw.replaceAll(',', ''));
  return number == null ? raw : formatCurrency(number, currencySymbol);
}

String _plainText(String value) {
  return value
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .trim();
}
