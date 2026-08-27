import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/app_setting.dart';
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
    DateTime Function()? nowProvider,
  }) : _preferences = preferences,
       _nowProvider = nowProvider ?? DateTime.now {
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
  final DateTime Function() _nowProvider;

  final scrollController = ScrollController();
  final pinnedColumnScrollController = ScrollController();
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

  int get advancedFilterCount =>
      (customerFilter.value.isNotEmpty ? 1 : 0) +
      (driverFilter.value.isNotEmpty ? 1 : 0) +
      (statusFilter.value.isNotEmpty ? 1 : 0) +
      (splitBillOnly.value ? 1 : 0) +
      (productCodeFilter.value.isNotEmpty ? 1 : 0);

  Timer? _searchDebounce;
  Worker? _destinationWorker;
  Worker? _closedSaleBadgeWorker;
  bool _hasMore = true;
  bool _syncingVerticalScroll = false;
  int _totalCountRequestId = 0;
  int _lastLoadedClosedSaleRevision = -1;
  int _lastLoadedTodayCountRevision = -1;

  DateTime? get minimumPostingDate => minimumSaleListPostingDate(
    sellController
            .appSettingController
            ?.current
            ?.numberOfDaySellerCanViewSaleList ??
        0,
    today: _nowProvider(),
  );

  DateTime? get effectiveStartDate {
    final selectedDate = startDate.value;
    final minimumDate = minimumPostingDate;
    if (selectedDate == null) return minimumDate;
    if (minimumDate != null && selectedDate.isBefore(minimumDate)) {
      return minimumDate;
    }
    return DateUtils.dateOnly(selectedDate);
  }

  DateTime _clampToAllowedDate(DateTime value) {
    final selectedDate = DateUtils.dateOnly(value);
    final minimumDate = minimumPostingDate;
    if (minimumDate != null && selectedDate.isBefore(minimumDate)) {
      return minimumDate;
    }
    return selectedDate;
  }

  DateTime get startDatePickerInitial =>
      _clampToAllowedDate(startDate.value ?? endDate.value ?? _nowProvider());

  DateTime get endDatePickerInitial =>
      _clampToAllowedDate(endDate.value ?? startDate.value ?? _nowProvider());

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_handleScroll);
    pinnedColumnScrollController.addListener(_handlePinnedColumnScroll);
    _lastLoadedClosedSaleRevision = sellController.closedSaleRevision.value;
    _lastLoadedTodayCountRevision = sellController.closedSaleRevision.value;
    _destinationWorker = ever<AppDestination>(
      appShellController.selectedDestination,
      (destination) {
        if (destination == AppDestination.closedSales) refreshIfStale();
      },
    );
    _closedSaleBadgeWorker = ever<int>(
      sellController.closedSaleRevision,
      (_) => _refreshTodayCountIfStale(),
    );
    loadMore();
    loadTotalRecords();
    loadTodayClosedSaleCount();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    _destinationWorker?.dispose();
    _closedSaleBadgeWorker?.dispose();
    searchController.dispose();
    scrollController.dispose();
    pinnedColumnScrollController.dispose();
    horizontalScrollController.dispose();
    super.onClose();
  }

  void _handleScroll() {
    _syncVerticalScroll(scrollController, pinnedColumnScrollController);
    if (scrollController.position.extentAfter < 220) loadMore();
  }

  void _handlePinnedColumnScroll() {
    _syncVerticalScroll(pinnedColumnScrollController, scrollController);
    if (pinnedColumnScrollController.position.extentAfter < 220) loadMore();
  }

  void _syncVerticalScroll(ScrollController source, ScrollController target) {
    if (_syncingVerticalScroll || !source.hasClients || !target.hasClients) {
      return;
    }
    final offset = source.offset.clamp(0.0, target.position.maxScrollExtent);
    if ((target.offset - offset).abs() <= 0.5) return;
    _syncingVerticalScroll = true;
    try {
      target.jumpTo(offset);
    } finally {
      _syncingVerticalScroll = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value || !_hasMore) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final page = await sellController.saleService.getClosedSales(
        outlet: sellController.activeOutletName,
        search: searchController.text,
        startDate: effectiveStartDate == null
            ? ''
            : _apiDate(effectiveStartDate!),
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
    if (scrollController.hasClients) scrollController.jumpTo(0);
    if (pinnedColumnScrollController.hasClients) {
      pinnedColumnScrollController.jumpTo(0);
    }
    sales.clear();
    _hasMore = true;
    errorMessage.value = null;
    await Future.wait([loadMore(), loadTotalRecords()]);
  }

  Future<void> refreshIfStale() async {
    if (_lastLoadedClosedSaleRevision ==
        sellController.closedSaleRevision.value) {
      return;
    }
    final revisionAtStart = sellController.closedSaleRevision.value;
    await Future.wait([refreshList(), _refreshTodayCountIfStale()]);
    _lastLoadedClosedSaleRevision = revisionAtStart;
  }

  Future<void> refreshAll() async {
    final revisionAtStart = sellController.closedSaleRevision.value;
    await Future.wait([refreshList(), loadTodayClosedSaleCount()]);
    _lastLoadedClosedSaleRevision = revisionAtStart;
    _lastLoadedTodayCountRevision = revisionAtStart;
  }

  Future<void> _refreshTodayCountIfStale() async {
    if (_lastLoadedTodayCountRevision ==
        sellController.closedSaleRevision.value) {
      return;
    }
    final revisionAtStart = sellController.closedSaleRevision.value;
    final previousRevision = _lastLoadedTodayCountRevision;
    _lastLoadedTodayCountRevision = revisionAtStart;
    final loaded = await loadTodayClosedSaleCount();
    if (!loaded && _lastLoadedTodayCountRevision == revisionAtStart) {
      _lastLoadedTodayCountRevision = previousRevision;
    }
  }

  Future<bool> loadTodayClosedSaleCount() async {
    if (isLoadingTodayCount.value) return false;
    isLoadingTodayCount.value = true;
    try {
      todayClosedSaleCount.value = await sellController.saleService
          .getTodayClosedSaleCount(sellController.activeOutletName);
      return true;
    } on FrappeServerMessageException {
      // The shared API client already displayed the server message.
      return false;
    } on Exception {
      // Keep the last successful count when the badge refresh fails.
      return false;
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
        startDate: effectiveStartDate == null
            ? ''
            : _apiDate(effectiveStartDate!),
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
    final allowedDate = _clampToAllowedDate(value);
    startDate.value = allowedDate;
    if (endDate.value != null && endDate.value!.isBefore(allowedDate)) {
      endDate.value = allowedDate;
    }
    await refreshList();
  }

  Future<void> setEndDate(DateTime value) async {
    final allowedDate = _clampToAllowedDate(value);
    endDate.value = allowedDate;
    if (startDate.value != null && startDate.value!.isAfter(allowedDate)) {
      startDate.value = allowedDate;
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

  Future<void> clearCustomerFilter() async {
    customerFilter.value = '';
    await refreshList();
  }

  Future<void> clearDriverFilter() async {
    driverFilter.value = '';
    await refreshList();
  }

  Future<void> clearStatusFilter() async {
    statusFilter.value = '';
    await refreshList();
  }

  Future<void> clearSplitBillFilter() async {
    splitBillOnly.value = false;
    await refreshList();
  }

  Future<void> clearProductCodeFilter() async {
    productCodeFilter.value = '';
    await refreshList();
  }

  Future<void> clearAdvancedFilters() async {
    customerFilter.value = '';
    driverFilter.value = '';
    statusFilter.value = '';
    splitBillOnly.value = false;
    productCodeFilter.value = '';
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

  Future<bool> editOrder(String name) async {
    if (!sellController.canOpenPendingOrder) {
      _showMessage(
        'សូមរក្សាទុកការលក់បច្ចុប្បន្នជាមុនសិន មុននឹងកែបុងដែលបានបិទ។',
        indicator: 'orange',
      );
      return false;
    }
    try {
      await sellController.openClosedOrder(name);
      await appShellController.navigateTo(
        AppDestination.sale,
        resolveUnfinishedSale: () async => true,
      );
      return true;
    } on ClosedSaleOpenValidationException {
      _showMessage(
        'សូមរក្សាទុកការលក់បច្ចុប្បន្នជាមុនសិន មុននឹងកែបុងដែលបានបិទ។',
        indicator: 'orange',
      );
    } on FrappeServerMessageException {
      // The shared API client already displayed the server message.
    } on Exception {
      _showMessage('មិនអាចបើកបុងលក់នេះបានទេ។', indicator: 'red');
    }
    return false;
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
