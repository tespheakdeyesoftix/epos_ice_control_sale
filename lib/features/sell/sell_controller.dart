import 'dart:convert';

import 'package:get/get.dart';

import '../../app/app_setting_controller.dart';
import '../../app/session_outlet_controller.dart';
import '../../services/customer_service.dart';
import '../../services/frappe_response_handler.dart';
import '../../services/product_service.dart';
import '../../services/sale_service.dart';
import 'customer.dart';
import 'customer_free_product.dart';
import 'customer_product_price.dart';
import 'payment_type.dart';
import 'product.dart';
import 'sale.dart';
import 'sale_product.dart';

part 'methods.dart';

class SellController extends GetxController {
  SellController({
    required this.productService,
    required this.customerService,
    required this.saleService,
    required this.outletName,
    required this.stationName,
    this.appSettingController,
    this.sessionOutletController,
    this.canChangeCustomerProvider,
    this.canChangeSaleDateProvider,
    this.canRemoveSaleProductProvider,
    this.canChangeProductPriceProvider,
    this.canUsePosPaymentProvider,
    this.canDeleteBillProvider,
  });

  final ProductService productService;
  final CustomerService customerService;
  final SaleService saleService;
  final String outletName;
  final String stationName;
  final AppSettingController? appSettingController;
  final SessionOutletController? sessionOutletController;
  final bool Function()? canChangeCustomerProvider;
  final bool Function()? canChangeSaleDateProvider;
  final bool Function()? canRemoveSaleProductProvider;
  final bool Function()? canChangeProductPriceProvider;
  final bool Function()? canUsePosPaymentProvider;
  final bool Function()? canDeleteBillProvider;
  final products = <Product>[].obs;
  final saleProducts = <SaleProduct>[].obs;
  final isLoading = false.obs;
  final isChangingOutlet = false.obs;
  final errorMessage = RxnString();
  final searchQuery = ''.obs;
  final selectedProductCategory = ''.obs;
  final selectedCustomer = Rxn<Customer>();
  final customerProductPrices = <CustomerProductPrice>[].obs;
  final customerFreeProducts = <CustomerFreeProduct>[].obs;
  final isLoadingCustomerProductPrices = false.obs;
  final selectedDriver = Rxn<Customer>();
  final openedSale = Rxn<Sale>();
  final plateNumber = ''.obs;
  final postingDate = _dateOnly(DateTime.now()).obs;
  final referenceNumber = ''.obs;
  final bookingNumber = ''.obs;
  final saleNote = ''.obs;
  final payments = <SalePayment>[].obs;
  final isSaving = false.obs;
  final isPrinting = false.obs;
  final isDeletingSale = false.obs;
  final isSearchingBill = false.obs;
  bool isBillSearchInputFocused = false;
  final pendingOrderCount = 0.obs;
  final closedSaleRevision = 0.obs;

  /// Changes after persisted Sale data makes cached summaries stale.
  final saleDataRevision = 0.obs;
  final isLoadingPendingOrders = false.obs;
  int _customerSelectionRequest = 0;
  int _pendingOrderCountRequest = 0;

  List<Product> get filteredProducts => _filteredProducts;
  List<String> get productCategories => _productCategories;
  int productCountForCategory(String category) =>
      _productCountForCategory(category);
  Sale get currentSale => _currentSale;
  double get totalQuantity => _totalQuantity;
  double get totalSaleQuantity => _totalSaleQuantity;
  double get grandTotal => _grandTotal;
  bool get hasSelectedCustomer => _hasSelectedCustomer;
  bool get isNewSale => _isNewSale;
  bool get canOpenPendingOrder => _canOpenPendingOrder;
  bool get isNewSaleDirty => _isNewSaleDirty;
  bool get isSaleDirty => _isSaleDirty;
  bool get isSaleEmpty => _isNewSale && !_isNewSaleDirty;
  bool get canSearchBillForEdit => _canSearchBillForEdit;
  bool get canChangeCustomer => _canChangeCustomer;
  bool get canChangeSaleDate => _canChangeSaleDate;
  bool canRemoveSaleProduct(SaleProduct item) => _canRemoveSaleProduct(item);
  bool get canChangeProductPrice => _canChangeProductPrice;
  bool get canUsePosPayment => _canUsePosPayment;
  bool get canDeleteBill => _canDeleteBill;
  String get activeOutletName =>
      sessionOutletController?.currentOutlet.value ?? outletName;
  List<String> get availableOutlets =>
      sessionOutletController?.availableOutlets.toList(growable: false) ??
      <String>[outletName];
  bool get canChangeOutlet => sessionOutletController?.canChangeOutlet ?? false;
  Uri? productImage(Product product) => _productImage(product);
  Uri? saleProductImage(SaleProduct product) => _saleProductImage(product);
  Uri? customerImage(Customer customer) => _customerImage(customer);

  Product? productByCode(String productCode) {
    for (final product in products) {
      if (product.code == productCode) return product;
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    loadProducts();
    loadPendingOrderCount();
  }

  Future<void> loadPendingOrderCount() async {
    final request = ++_pendingOrderCountRequest;
    final outlet = activeOutletName;
    isLoadingPendingOrders.value = true;
    try {
      final count = await saleService.getTotalPendingOrder(outlet);
      if (request == _pendingOrderCountRequest && outlet == activeOutletName) {
        pendingOrderCount.value = count;
      }
    } on Exception {
      // Keep the last known count when the server cannot be reached.
    } finally {
      if (request == _pendingOrderCountRequest) {
        isLoadingPendingOrders.value = false;
      }
    }
  }

  Future<void> loadProducts() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      products.assignAll(await productService.getProducts(activeOutletName));
      if (!productCategories.contains(selectedProductCategory.value)) {
        selectedProductCategory.value = '';
      }
    } on FrappeServerMessageException {
      // The shared API client already displayed the server message.
    } on Exception {
      errorMessage.value = 'មិនអាចទាញយកបញ្ជីទំនិញបានទេ។';
    } finally {
      isLoading.value = false;
    }
  }

  void updateSearch(String value) => searchQuery.value = value;

  void selectProductCategory(String category) {
    selectedProductCategory.value = category.trim();
  }

  Future<void> changeOutlet(String outlet) async {
    final normalized = outlet.trim();
    if (normalized.isEmpty || normalized == activeOutletName) return;
    if (!isSaleEmpty) throw const OutletChangeBlockedException();
    if (!availableOutlets.contains(normalized)) {
      throw const OutletChangeValidationException();
    }
    if (isChangingOutlet.value || isLoading.value) {
      throw const OutletChangeInProgressException();
    }

    isChangingOutlet.value = true;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final outletProducts = await productService.getProducts(normalized);
      await appSettingController?.load(outlet: normalized);
      products.assignAll(outletProducts);
      if (!productCategories.contains(selectedProductCategory.value)) {
        selectedProductCategory.value = '';
      }
      saleDataRevision.value++;
      sessionOutletController?.commitOutlet(normalized);
      closedSaleRevision.value++;
      await loadPendingOrderCount();
    } finally {
      isLoading.value = false;
      isChangingOutlet.value = false;
    }
  }

  Future<CustomerSelectionResult> selectCustomer(Customer customer) async {
    if (!canChangeCustomer) {
      throw const CustomerChangePermissionException();
    }
    final request = ++_customerSelectionRequest;
    selectedCustomer.value = customer;
    customerProductPrices.clear();
    customerFreeProducts.clear();
    _clearSaleProductFreeQuantities();
    _applyCustomerPrices();
    isLoadingCustomerProductPrices.value = true;

    final pricesRequest = customerService
        .getCustomerProductPrices(customer.name)
        .then<List<CustomerProductPrice>>(
          (items) => items,
          onError: (_) => const <CustomerProductPrice>[],
        );
    final freeProductsRequest = customerService
        .getCustomerFreeProducts(customer.name)
        .then<List<CustomerFreeProduct>>(
          (items) => items,
          onError: (_) => const <CustomerFreeProduct>[],
        );

    try {
      final prices = await pricesRequest;
      final freeProducts = await freeProductsRequest;

      if (request != _customerSelectionRequest ||
          selectedCustomer.value?.name != customer.name) {
        return const CustomerSelectionResult();
      }
      customerProductPrices.assignAll(prices);
      customerFreeProducts.assignAll(freeProducts);
      _applyCustomerPrices();
      return CustomerSelectionResult(
        freeProductEvaluations: _applyCustomerFreeProducts(),
      );
    } on Exception {
      return const CustomerSelectionResult();
    } finally {
      if (request == _customerSelectionRequest &&
          selectedCustomer.value?.name == customer.name) {
        isLoadingCustomerProductPrices.value = false;
      }
    }
  }

  void clearCustomer() {
    if (!canChangeCustomer) {
      throw const CustomerChangePermissionException();
    }
    _customerSelectionRequest++;
    selectedCustomer.value = null;
    customerProductPrices.clear();
    customerFreeProducts.clear();
    isLoadingCustomerProductPrices.value = false;
    _clearSaleProductFreeQuantities();
    _applyCustomerPrices();
  }

  void selectDriver(Customer driver) {
    selectedDriver.value = driver;
    plateNumber.value = driver.plateNumber.trim();
  }

  void clearDriver() {
    selectedDriver.value = null;
    plateNumber.value = '';
  }

  void updatePlateNumber(String value) {
    plateNumber.value = value.trim();
  }

  void updatePostingDate(DateTime date) {
    if (!canChangeSaleDate) {
      throw const SaleDateChangePermissionException();
    }
    final selectedDate = _dateOnly(date);
    final maximumDate = _dateOnly(DateTime.now()).add(const Duration(days: 1));
    if (!selectedDate.isAfter(maximumDate)) postingDate.value = selectedDate;
  }

  void updateReferenceNumber(String value) {
    referenceNumber.value = value.trim();
  }

  void updateBookingNumber(String value) {
    bookingNumber.value = value.trim();
  }

  void updateSaleNote(String value) {
    saleNote.value = value.trim();
  }

  void requestPayment() {
    if (!canUsePosPayment) {
      throw const PosPaymentPermissionException();
    }
  }

  void selectPaymentType(PaymentType paymentType) {
    if (!paymentType.isValid) throw const PaymentTypeValidationException();
    recalculateSummary();
    payments.assign(
      SalePayment.fromPaymentType(paymentType, totalAmount: grandTotal),
    );
  }

  /// Refreshes checkout totals using the latest product summary metadata.
  ///
  /// Older draft rows can omit `allow_sum_qty`, which makes their line amount
  /// visible while excluding it from the Sale-level quantity and amount.
  void recalculateSummary() {
    final recalculatedProducts = saleProducts
        .map((line) {
          final product = productByCode(line.productCode);
          if (product == null ||
              product.allowSumQuantity == line.allowSumQuantity) {
            return line;
          }
          return line.copyWith(allowSumQuantity: product.allowSumQuantity);
        })
        .toList(growable: false);
    saleProducts.assignAll(recalculatedProducts);
  }

  void validateDeleteBillPermission() {
    if (!canDeleteBill) {
      throw const DeleteBillPermissionException();
    }
  }

  bool hasProduct(Product product) => saleProducts.any(
    (item) =>
        item.productCode == product.code &&
        item.unit.trim() == product.unit.trim(),
  );

  AddProductResult addProduct(
    Product product, {
    double quantity = 1,
    double? price,
  }) {
    if (quantity <= 0 || hasProduct(product)) {
      return const AddProductResult(added: false);
    }
    final saleProduct = SaleProduct.fromProduct(
      product,
      outlet: activeOutletName,
      quantity: quantity,
    );
    final customerPrice = _customerPriceFor(
      productCode: saleProduct.productCode,
      unit: saleProduct.unit,
    );
    var nextProduct = saleProduct.isBorrow || customerPrice == null
        ? saleProduct
        : saleProduct.copyWith(price: customerPrice.price);
    if (price != null && !nextProduct.isBorrow) {
      nextProduct = nextProduct.copyWith(price: price, productPrice: price);
    }
    final evaluation = _evaluateCustomerFreeProduct(nextProduct);
    if (evaluation?.wasApplied ?? false) {
      nextProduct = nextProduct.copyWith(
        freeQuantity: evaluation!.configuredFreeQuantity,
      );
    }
    saleProducts.add(nextProduct);
    return AddProductResult(added: true, freeProductEvaluation: evaluation);
  }

  CustomerFreeProduct? _customerFreeProductFor({
    required String productCode,
    required String unit,
  }) {
    for (final item in customerFreeProducts) {
      if (item.matches(productCode: productCode, unit: unit)) return item;
    }
    return null;
  }

  FreeProductEvaluation? _evaluateCustomerFreeProduct(SaleProduct product) {
    final rule = _customerFreeProductFor(
      productCode: product.productCode,
      unit: product.unit,
    );
    if (rule == null) return null;
    return FreeProductEvaluation(
      productCode: product.productCode,
      productName: product.productName.trim().isEmpty
          ? rule.productName
          : product.productName,
      unit: product.unit.trim(),
      configuredFreeQuantity: rule.quantity,
      orderQuantity: product.quantity,
      status: product.quantity >= rule.quantity
          ? FreeProductEvaluationStatus.applied
          : FreeProductEvaluationStatus.insufficientQuantity,
    );
  }

  List<FreeProductEvaluation> _applyCustomerFreeProducts() {
    final evaluations = <FreeProductEvaluation>[];
    final updatedProducts = saleProducts
        .map((product) {
          final evaluation = _evaluateCustomerFreeProduct(product);
          if (evaluation == null) return product.copyWith(freeQuantity: 0);
          evaluations.add(evaluation);
          return product.copyWith(
            freeQuantity: evaluation.wasApplied
                ? evaluation.configuredFreeQuantity
                : 0,
          );
        })
        .toList(growable: false);
    saleProducts.assignAll(updatedProducts);
    return List.unmodifiable(evaluations);
  }

  void _clearSaleProductFreeQuantities() {
    saleProducts.assignAll(
      saleProducts
          .map((product) => product.copyWith(freeQuantity: 0))
          .toList(growable: false),
    );
  }

  void remove(SaleProduct item) {
    if (!canRemoveSaleProduct(item)) {
      throw const SaleProductRemovePermissionException();
    }
    saleProducts.removeWhere(
      (candidate) =>
          candidate.productCode == item.productCode &&
          candidate.unit.trim() == item.unit.trim(),
    );
  }

  void updateSaleProduct(SaleProduct updatedItem, {SaleProduct? originalItem}) {
    final original = originalItem ?? updatedItem;
    final index = saleProducts.indexWhere(
      (item) =>
          item.productCode == original.productCode &&
          item.unit.trim() == original.unit.trim(),
    );
    if (index < 0) return;
    final duplicateIndex = saleProducts.indexWhere(
      (item) =>
          item.productCode == updatedItem.productCode &&
          item.unit.trim() == updatedItem.unit.trim(),
    );
    if (duplicateIndex >= 0 && duplicateIndex != index) {
      throw const SaleProductUnitAlreadySelectedException();
    }
    final currentItem = saleProducts[index];
    final unitChanged = currentItem.unit.trim() != updatedItem.unit.trim();
    var nextItem = updatedItem;
    if (unitChanged) {
      final customerPrice = _customerPriceFor(
        productCode: updatedItem.productCode,
        unit: updatedItem.unit,
      );
      nextItem = updatedItem.copyWith(
        price: updatedItem.isBorrow
            ? 0
            : customerPrice?.price ??
                  updatedItem.productPrice ??
                  updatedItem.price,
      );
    }
    final priceChanged = (currentItem.price - nextItem.price).abs() > 0.000001;
    final saleTypeChanged =
        currentItem.saleTransactionType.trim().toLowerCase() !=
        nextItem.saleTransactionType.trim().toLowerCase();
    if (priceChanged &&
        !unitChanged &&
        !saleTypeChanged &&
        !canChangeProductPrice) {
      throw const ProductPriceChangePermissionException();
    }
    saleProducts[index] = nextItem;
  }

  void clearCart() => saleProducts.clear();

  Future<void> openPendingOrder(String name) async {
    if (!canOpenPendingOrder) {
      throw const PendingOrderOpenValidationException();
    }
    final sale = await saleService.getSaleForEdit(
      name: name,
      stationName: stationName,
    );
    if (!canOpenPendingOrder) {
      throw const PendingOrderOpenValidationException();
    }
    _applyOpenedSale(sale);
  }

  Future<void> openClosedOrder(String name) async {
    if (!canSearchBillForEdit) {
      throw const ClosedSaleOpenValidationException();
    }
    final sale = await saleService.getSaleForEdit(
      name: name,
      stationName: stationName,
    );
    if (!canSearchBillForEdit) {
      throw const ClosedSaleOpenValidationException();
    }
    _applyOpenedSale(sale);
  }

  Future<void> searchBillForEdit(String keyword) async {
    final normalizedKeyword = keyword.trim();
    if (normalizedKeyword.isEmpty) {
      throw const BillSearchKeywordException();
    }
    if (!canSearchBillForEdit || isSearchingBill.value) {
      throw const BillSearchValidationException();
    }
    isSearchingBill.value = true;
    try {
      final sale = await saleService.getSaleForEdit(
        name: normalizedKeyword,
        stationName: stationName,
      );
      if (!canSearchBillForEdit) {
        throw const BillSearchValidationException();
      }
      _applyOpenedSale(sale);
    } finally {
      isSearchingBill.value = false;
    }
  }

  Future<Map<String, dynamic>> saveOrder() async {
    recalculateSummary();
    if (saleProducts.isEmpty || !hasSelectedCustomer || isSaving.value) {
      throw const SaleValidationException();
    }
    final hadDirtyChanges = isSaleDirty;
    isSaving.value = true;
    try {
      final savedOrder = await saleService.saveOrder(currentSale);
      await loadPendingOrderCount();
      closedSaleRevision.value++;
      if (hadDirtyChanges) saleDataRevision.value++;
      return savedOrder;
    } finally {
      isSaving.value = false;
    }
  }

  Future<Map<String, dynamic>> pauseSale() async {
    if (saleProducts.isEmpty || isSaving.value) {
      throw const SaleValidationException();
    }
    final hadDirtyChanges = isSaleDirty;
    isSaving.value = true;
    try {
      final savedOrder = await saleService.saveOrder(
        currentSale,
        saleStatus: 'Draft',
      );
      await loadPendingOrderCount();
      if (hadDirtyChanges) saleDataRevision.value++;
      return savedOrder;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteOpenedSale(String deletedNote) async {
    validateDeleteBillPermission();
    final sale = openedSale.value;
    if (sale == null ||
        sale.name.trim().isEmpty ||
        isDeletingSale.value ||
        isSaving.value) {
      throw const SaleDeleteValidationException();
    }
    isDeletingSale.value = true;
    try {
      await saleService.deleteSale(
        docName: sale.name,
        deletedNote: deletedNote,
        stationName: stationName,
      );
      final wasDraft = sale.saleStatus == 'Draft';
      startNewSale();
      if (wasDraft) {
        await loadPendingOrderCount();
      } else {
        closedSaleRevision.value++;
      }
      saleDataRevision.value++;
    } finally {
      isDeletingSale.value = false;
    }
  }

  void startNewSale() {
    _customerSelectionRequest++;
    openedSale.value = null;
    saleProducts.clear();
    selectedCustomer.value = null;
    customerProductPrices.clear();
    customerFreeProducts.clear();
    isLoadingCustomerProductPrices.value = false;
    selectedDriver.value = null;
    plateNumber.value = '';
    postingDate.value = _dateOnly(DateTime.now());
    referenceNumber.value = '';
    bookingNumber.value = '';
    saleNote.value = '';
    payments.clear();
  }
}
