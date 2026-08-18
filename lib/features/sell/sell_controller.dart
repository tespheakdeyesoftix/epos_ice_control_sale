import 'package:get/get.dart';

import '../../app/app_setting_controller.dart';
import '../../app/session_outlet_controller.dart';
import '../../services/customer_service.dart';
import '../../services/frappe_response_handler.dart';
import '../../services/product_service.dart';
import '../../services/sale_service.dart';
import 'customer.dart';
import 'customer_product_price.dart';
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
    this.canEditBillProvider,
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
  final bool Function()? canEditBillProvider;
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
  final isLoadingCustomerProductPrices = false.obs;
  final selectedDriver = Rxn<Customer>();
  final openedSale = Rxn<Sale>();
  final plateNumber = ''.obs;
  final postingDate = _dateOnly(DateTime.now()).obs;
  final referenceNumber = ''.obs;
  final saleNote = ''.obs;
  final isSaving = false.obs;
  final isDeletingSale = false.obs;
  final isSearchingBill = false.obs;
  final pendingOrderCount = 0.obs;
  final closedSaleRevision = 0.obs;
  final isLoadingPendingOrders = false.obs;

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

  @override
  void onInit() {
    super.onInit();
    loadProducts();
    loadPendingOrderCount();
  }

  Future<void> loadPendingOrderCount() async {
    if (isLoadingPendingOrders.value) return;
    isLoadingPendingOrders.value = true;
    try {
      pendingOrderCount.value = await saleService.getTotalPendingOrder(
        activeOutletName,
      );
    } on Exception {
      // Keep the last known count when the server cannot be reached.
    } finally {
      isLoadingPendingOrders.value = false;
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
    if (isSaleDirty) throw const OutletChangeBlockedException();
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
      sessionOutletController?.commitOutlet(normalized);
      products.assignAll(outletProducts);
      if (!productCategories.contains(selectedProductCategory.value)) {
        selectedProductCategory.value = '';
      }
    } finally {
      isLoading.value = false;
      isChangingOutlet.value = false;
    }
  }

  Future<void> selectCustomer(Customer customer) async {
    if (!canChangeCustomer) {
      throw const CustomerChangePermissionException();
    }
    selectedCustomer.value = customer;
    customerProductPrices.clear();
    _applyCustomerPrices();
    isLoadingCustomerProductPrices.value = true;
    try {
      final prices = await customerService.getCustomerProductPrices(
        customer.name,
      );
      if (selectedCustomer.value?.name != customer.name) return;
      customerProductPrices.assignAll(prices);
      _applyCustomerPrices();
    } on Exception {
      // Keep original product prices when customer pricing is unavailable.
    } finally {
      if (selectedCustomer.value?.name == customer.name) {
        isLoadingCustomerProductPrices.value = false;
      }
    }
  }

  void clearCustomer() {
    if (!canChangeCustomer) {
      throw const CustomerChangePermissionException();
    }
    selectedCustomer.value = null;
    customerProductPrices.clear();
    isLoadingCustomerProductPrices.value = false;
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

  void updateSaleNote(String value) {
    saleNote.value = value.trim();
  }

  void requestPayment() {
    if (!canUsePosPayment) {
      throw const PosPaymentPermissionException();
    }
  }

  void validateDeleteBillPermission() {
    if (!canDeleteBill) {
      throw const DeleteBillPermissionException();
    }
  }

  bool hasProduct(Product product) =>
      saleProducts.any((item) => item.productCode == product.code);

  bool addProduct(Product product, {double quantity = 1}) {
    if (quantity <= 0 || hasProduct(product)) return false;
    final saleProduct = SaleProduct.fromProduct(
      product,
      outlet: activeOutletName,
      quantity: quantity,
    );
    final customerPrice = _customerPriceFor(
      productCode: saleProduct.productCode,
      unit: saleProduct.unit,
    );
    saleProducts.add(
      saleProduct.isBorrow || customerPrice == null
          ? saleProduct
          : saleProduct.copyWith(price: customerPrice.price),
    );
    return true;
  }

  void remove(SaleProduct item) {
    if (!canRemoveSaleProduct(item)) {
      throw const SaleProductRemovePermissionException();
    }
    saleProducts.removeWhere(
      (candidate) => candidate.productCode == item.productCode,
    );
  }

  void updateSaleProduct(SaleProduct updatedItem) {
    final index = saleProducts.indexWhere(
      (item) => item.productCode == updatedItem.productCode,
    );
    if (index < 0) return;
    final currentItem = saleProducts[index];
    final priceChanged =
        (currentItem.price - updatedItem.price).abs() > 0.000001;
    final saleTypeChanged =
        currentItem.saleTransactionType.trim().toLowerCase() !=
        updatedItem.saleTransactionType.trim().toLowerCase();
    if (priceChanged && !saleTypeChanged && !canChangeProductPrice) {
      throw const ProductPriceChangePermissionException();
    }
    saleProducts[index] = updatedItem;
  }

  void clearCart() => saleProducts.clear();

  Future<void> openPendingOrder(String name) async {
    if (!canOpenPendingOrder) {
      throw const PendingOrderOpenValidationException();
    }
    final sale = await saleService.getSale(name);
    if (!canOpenPendingOrder) {
      throw const PendingOrderOpenValidationException();
    }
    _validateSaleForEdit(sale);
    if (sale.saleStatus != 'Draft') {
      throw const PendingOrderNotDraftException();
    }

    _applyOpenedSale(sale);
  }

  Future<void> openClosedOrder(String name) async {
    if (!canSearchBillForEdit) {
      throw const ClosedSaleOpenValidationException();
    }
    final sale = await saleService.getSale(name);
    if (!canSearchBillForEdit) {
      throw const ClosedSaleOpenValidationException();
    }
    _validateSaleForEdit(sale);
    if (sale.saleStatus != 'Closed') {
      throw const SaleOrderNotClosedException();
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
      final sale = await saleService.searchBillForEdit(
        keyword: normalizedKeyword,
        outlet: activeOutletName,
      );
      if (!canSearchBillForEdit) {
        throw const BillSearchValidationException();
      }
      _validateSaleForEdit(sale);
      _applyOpenedSale(sale);
    } finally {
      isSearchingBill.value = false;
    }
  }

  Future<Map<String, dynamic>> saveOrder() async {
    if (saleProducts.isEmpty || !hasSelectedCustomer || isSaving.value) {
      throw const SaleValidationException();
    }
    isSaving.value = true;
    try {
      final savedOrder = await saleService.saveOrder(currentSale);
      await loadPendingOrderCount();
      closedSaleRevision.value++;
      return savedOrder;
    } finally {
      isSaving.value = false;
    }
  }

  Future<Map<String, dynamic>> pauseSale() async {
    if (saleProducts.isEmpty || isSaving.value) {
      throw const SaleValidationException();
    }
    isSaving.value = true;
    try {
      final savedOrder = await saleService.saveOrder(
        currentSale,
        saleStatus: 'Draft',
      );
      await loadPendingOrderCount();
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
    } finally {
      isDeletingSale.value = false;
    }
  }

  void startNewSale() {
    openedSale.value = null;
    saleProducts.clear();
    selectedCustomer.value = null;
    customerProductPrices.clear();
    isLoadingCustomerProductPrices.value = false;
    selectedDriver.value = null;
    plateNumber.value = '';
    postingDate.value = _dateOnly(DateTime.now());
    referenceNumber.value = '';
    saleNote.value = '';
  }
}
