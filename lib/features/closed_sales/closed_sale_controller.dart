import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/frappe_response_handler.dart';
import '../navigation/app_destination.dart';
import '../navigation/app_shell_controller.dart';
import '../sell/sell_controller.dart';
import 'closed_sale.dart';

class ClosedSaleController extends GetxController {
  ClosedSaleController({
    required this.sellController,
    required this.appShellController,
  });

  final SellController sellController;
  final AppShellController appShellController;

  final scrollController = ScrollController();
  final searchController = TextEditingController();
  final searchText = ''.obs;
  final sales = <ClosedSale>[].obs;
  final startDate = Rxn<DateTime>();
  final endDate = Rxn<DateTime>();
  final isLoading = false.obs;
  final isLoadingTodayCount = false.obs;
  final todayClosedSaleCount = 0.obs;
  final deletingSaleNames = <String>{}.obs;
  final errorMessage = RxnString();

  Timer? _searchDebounce;
  Worker? _closedSaleWorker;
  bool _hasMore = true;

  Map<String, List<ClosedSale>> get groupedSales {
    final groups = <String, List<ClosedSale>>{};
    for (final sale in sales) {
      groups.putIfAbsent(sale.postingDate, () => []).add(sale);
    }
    return groups;
  }

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
    loadTodayClosedSaleCount();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    _closedSaleWorker?.dispose();
    searchController.dispose();
    scrollController.dispose();
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
    await loadMore();
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
      sellController.validateDeleteBillPermission(saleStatus: 'Closed');
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
