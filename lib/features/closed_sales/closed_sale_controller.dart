import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/frappe_response_handler.dart';
import '../navigation/app_destination.dart';
import '../navigation/app_shell_controller.dart';
import '../sell/sell_controller.dart';
import 'closed_sale.dart';

enum ClosedSaleSortField {
  name('name'),
  postingDate('posting_date'),
  customerName('customer_name'),
  driverName('driver_name'),
  totalSplitBill('total_split_bill'),
  totalSaleQuantity('total_sale_quantity'),
  totalAmount('total_amount'),
  creation('creation');

  const ClosedSaleSortField(this.apiField);

  final String apiField;
}

class ClosedSaleController extends GetxController {
  ClosedSaleController({
    required this.sellController,
    required this.appShellController,
    SharedPreferences? preferences,
  }) : _preferences = preferences {
    final savedField = preferences?.getString(sortFieldPreferenceKey);
    final initialField = ClosedSaleSortField.values.firstWhere(
      (field) => field.apiField == savedField,
      orElse: () => ClosedSaleSortField.postingDate,
    );
    sortField = initialField.obs;
    sortAscending =
        (preferences?.getBool(sortAscendingPreferenceKey) ?? false).obs;
  }

  static const sortFieldPreferenceKey = 'closed_sales_sort_field';
  static const sortAscendingPreferenceKey = 'closed_sales_sort_ascending';

  final SellController sellController;
  final AppShellController appShellController;
  final SharedPreferences? _preferences;

  final scrollController = ScrollController();
  final horizontalScrollController = ScrollController();
  final searchController = TextEditingController();
  final searchText = ''.obs;
  final sales = <ClosedSale>[].obs;
  final startDate = Rxn<DateTime>();
  final endDate = Rxn<DateTime>();
  final customerFilter = ''.obs;
  final driverFilter = ''.obs;
  final statusFilter = ''.obs;
  final splitBillOnly = false.obs;
  final productCodeFilter = ''.obs;
  final productChildDoctype = 'Sale Product'.obs;
  final isLoading = false.obs;
  final isLoadingTodayCount = false.obs;
  final todayClosedSaleCount = 0.obs;
  final isLoadingTotalRecords = false.obs;
  final totalRecords = 0.obs;
  final deletingSaleNames = <String>{}.obs;
  final selectedSaleName = RxnString();
  final errorMessage = RxnString();
  late final Rx<ClosedSaleSortField> sortField;
  late final RxBool sortAscending;

  bool get hasAdvancedFilters =>
      customerFilter.value.isNotEmpty ||
      driverFilter.value.isNotEmpty ||
      statusFilter.value.isNotEmpty ||
      splitBillOnly.value ||
      productCodeFilter.value.isNotEmpty;

  Timer? _searchDebounce;
  Worker? _closedSaleWorker;
  bool _hasMore = true;
  int _totalCountRequestId = 0;

  DateTime get startDatePickerInitial =>
      startDate.value ?? endDate.value ?? DateTime.now();

  DateTime get endDatePickerInitial =>
      endDate.value ?? startDate.value ?? DateTime.now();

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_handleScroll);
    _closedSaleWorker = ever<int>(
      sellController.closedSaleRevision,
      (_) => refreshAll(),
    );
    loadMore();
    loadTotalRecords();
    loadTodayClosedSaleCount();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    _closedSaleWorker?.dispose();
    searchController.dispose();
    scrollController.dispose();
    horizontalScrollController.dispose();
    super.onClose();
  }

  void _handleScroll() {
    if (scrollController.position.extentAfter < 220) loadMore();
  }

  Future<void> loadMore() async {
    if (isLoading.value || !_hasMore) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final page = await sellController.saleService.getClosedSales(
        outlet: sellController.activeOutletName,
        search: searchController.text,
        startDate: startDate.value == null ? '' : _apiDate(startDate.value!),
        endDate: endDate.value == null ? '' : _apiDate(endDate.value!),
        sortField: sortField.value.apiField,
        sortAscending: sortAscending.value,
        customer: customerFilter.value,
        driver: driverFilter.value,
        status: statusFilter.value,
        splitBillOnly: splitBillOnly.value,
        productCode: productCodeFilter.value,
        productChildDoctype: productChildDoctype.value,
        offset: sales.length,
      );
      sales.addAll(page.items);
      _hasMore = page.hasMore;
    } on FrappeServerMessageException {
      // The shared API client already displayed the server message.
    } on Exception {
      errorMessage.value = 'មិនអាចទាញយកបញ្ជីការលក់ដែលបានបិទបានទេ។';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshList() async {
    sales.clear();
    _hasMore = true;
    errorMessage.value = null;
    await Future.wait([loadMore(), loadTotalRecords()]);
  }

  Future<void> refreshAll() async {
    await Future.wait([refreshList(), loadTodayClosedSaleCount()]);
  }

  Future<void> loadTodayClosedSaleCount() async {
    if (isLoadingTodayCount.value) return;
    isLoadingTodayCount.value = true;
    try {
      todayClosedSaleCount.value = await sellController.saleService
          .getTodayClosedSaleCount(sellController.activeOutletName);
    } on FrappeServerMessageException {
      // The shared API client already displayed the server message.
    } on Exception {
      // Keep the last successful count when the badge refresh fails.
    } finally {
      isLoadingTodayCount.value = false;
    }
  }

  Future<void> loadTotalRecords() async {
    final requestId = ++_totalCountRequestId;
    isLoadingTotalRecords.value = true;
    try {
      final count = await sellController.saleService.getClosedSaleCount(
        outlet: sellController.activeOutletName,
        search: searchController.text,
        startDate: startDate.value == null ? '' : _apiDate(startDate.value!),
        endDate: endDate.value == null ? '' : _apiDate(endDate.value!),
        customer: customerFilter.value,
        driver: driverFilter.value,
        status: statusFilter.value,
        splitBillOnly: splitBillOnly.value,
        productCode: productCodeFilter.value,
        productChildDoctype: productChildDoctype.value,
      );
      if (requestId == _totalCountRequestId) totalRecords.value = count;
    } on FrappeServerMessageException {
      // The shared API client already displayed the server message.
    } on Exception {
      // Keep the last successful total when the count request fails.
    } finally {
      if (requestId == _totalCountRequestId) {
        isLoadingTotalRecords.value = false;
      }
    }
  }

  void handleSearchChanged(String value) {
    searchText.value = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), refreshList);
  }

  void clearSearch() {
    searchController.clear();
    searchText.value = '';
    handleSearchChanged('');
  }

  Future<void> setStartDate(DateTime value) async {
    startDate.value = value;
    if (endDate.value != null && endDate.value!.isBefore(value)) {
      endDate.value = value;
    }
    await refreshList();
  }

  Future<void> setEndDate(DateTime value) async {
    endDate.value = value;
    if (startDate.value != null && startDate.value!.isAfter(value)) {
      startDate.value = value;
    }
    await refreshList();
  }

  Future<void> clearStartDate() async {
    startDate.value = null;
    await refreshList();
  }

  Future<void> clearEndDate() async {
    endDate.value = null;
    await refreshList();
  }

  Future<void> sortBy(ClosedSaleSortField field) async {
    if (sortField.value == field) {
      sortAscending.toggle();
    } else {
      sortField.value = field;
      sortAscending.value = true;
    }
    await _saveSorting();
    await refreshList();
  }

  Future<void> applyAdvancedSearch({
    required String customer,
    required String driver,
    required String status,
    required bool onlySplitBills,
    required String productCode,
    required String childDoctype,
    required ClosedSaleSortField selectedSortField,
    required bool ascending,
  }) async {
    customerFilter.value = customer.trim();
    driverFilter.value = driver.trim();
    statusFilter.value = status.trim();
    splitBillOnly.value = onlySplitBills;
    productCodeFilter.value = productCode.trim();
    productChildDoctype.value = childDoctype.trim().isEmpty
        ? 'Sale Product'
        : childDoctype.trim();
    sortField.value = selectedSortField;
    sortAscending.value = ascending;
    await _saveSorting();
    await refreshList();
  }

  Future<void> _saveSorting() => Future.wait([
    _preferences?.setString(sortFieldPreferenceKey, sortField.value.apiField) ??
        Future<void>.value(),
    _preferences?.setBool(sortAscendingPreferenceKey, sortAscending.value) ??
        Future<void>.value(),
  ]);

  void selectSale(String name) {
    selectedSaleName.value = name;
  }

  Future<void> editOrder(String name) async {
    if (!sellController.canOpenPendingOrder) {
      _showMessage(
        'សូមរក្សាទុកការលក់បច្ចុប្បន្នជាមុនសិន មុននឹងកែបុងដែលបានបិទ។',
        indicator: 'orange',
      );
      return;
    }
    try {
      await sellController.openClosedOrder(name);
      await appShellController.navigateTo(
        AppDestination.sale,
        resolveUnfinishedSale: () async => true,
      );
    } on ClosedSaleOpenValidationException {
      _showMessage(
        'សូមរក្សាទុកការលក់បច្ចុប្បន្នជាមុនសិន មុននឹងកែបុងដែលបានបិទ។',
        indicator: 'orange',
      );
    } on SaleEditBlockedException catch (error) {
      _showMessage(error.message, indicator: 'orange');
    } on SaleOrderNotClosedException {
      _showMessage('បុងនេះមិនមែនជាបុងដែលបានបិទទៀតទេ។');
    } on FrappeServerMessageException {
      // The shared API client already displayed the server message.
    } on Exception {
      _showMessage('មិនអាចបើកបុងលក់នេះបានទេ។', indicator: 'red');
    }
  }

  Future<bool> deleteSale(String name, String deletedNote) async {
    if (!checkDeleteBillPermission()) return false;
    if (deletingSaleNames.contains(name)) return false;
    deletingSaleNames.add(name);
    try {
      await sellController.saleService.deleteSale(
        docName: name,
        deletedNote: deletedNote,
        stationName: sellController.stationName,
      );
      sales.removeWhere((sale) => sale.name == name);
      if (totalRecords.value > 0) totalRecords.value--;
      await loadTodayClosedSaleCount();
      _showMessage('បានលុបបុង $name ដោយជោគជ័យ។', indicator: 'green');
      return true;
    } on FrappeServerMessageException {
      // The shared API client already displayed the server message.
      return false;
    } on Exception {
      _showMessage('មិនអាចលុបបុងនេះបានទេ។', indicator: 'red');
      return false;
    } finally {
      deletingSaleNames.remove(name);
    }
  }

  bool checkDeleteBillPermission() {
    try {
      sellController.validateDeleteBillPermission();
      return true;
    } on DeleteBillPermissionException catch (error) {
      _showMessage(error.message, indicator: 'orange');
      return false;
    }
  }

  void _showMessage(String message, {String indicator = ''}) {
    FrappeResponseHandler.show(
      FrappeServerMessage(message: message, indicator: indicator),
    );
  }
}

String _apiDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
