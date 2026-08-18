import 'package:get/get.dart';

import '../../app/app_setting_controller.dart';
import '../../services/customer_service.dart';
import '../../services/frappe_response_handler.dart';
import '../../services/product_service.dart';
import '../../services/sale_service.dart';
import 'customer.dart';
import 'customer_product_price.dart';
import 'product.dart';
import 'sale.dart';
import 'sale_product.dart';

class SellController extends GetxController {
  SellController({
    required this.productService,
    required this.customerService,
    required this.saleService,
    required this.outletName,
    required this.stationName,
    this.appSettingController,
  });

  final ProductService productService;
  final CustomerService customerService;
  final SaleService saleService;
  final String outletName;
  final String stationName;
  final AppSettingController? appSettingController;
  final products = <Product>[].obs;
  final saleProducts = <SaleProduct>[].obs;
  final isLoading = false.obs;
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
  final pendingOrderCount = 0.obs;
  final closedSaleRevision = 0.obs;
  final isLoadingPendingOrders = false.obs;

  List<Product> get filteredProducts {
    final query = searchQuery.value.trim().toLowerCase();
    final category = selectedProductCategory.value;
    return products.where((product) {
      final matchesCategory =
          category.isEmpty || product.category.trim() == category;
      final matchesSearch =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.code.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<String> get productCategories {
    final categories = <String>{};
    for (final product in products) {
      final category = product.category.trim();
      if (category.isNotEmpty) categories.add(category);
    }
    return categories.toList(growable: false);
  }

  int productCountForCategory(String category) {
    final normalizedCategory = category.trim();
    if (normalizedCategory.isEmpty) return products.length;
    return products
        .where((product) => product.category.trim() == normalizedCategory)
        .length;
  }

  Sale get currentSale {
    final customer = selectedCustomer.value;
    final driver = selectedDriver.value;
    final savedSale = openedSale.value;
    return Sale(
      name: savedSale?.name ?? '',
      namingSeries: savedSale?.namingSeries ?? 'SO.YYYY.-.####',
      outlet: outletName,
      stockLocation: savedSale?.stockLocation.isNotEmpty == true
          ? savedSale!.stockLocation
          : appSettingController?.current?.defaultStockLocation ?? '',
      seller: savedSale?.seller ?? '',
      postingDate: postingDate.value,
      referenceNumber: referenceNumber.value,
      note: saleNote.value,
      saleProducts: List.unmodifiable(saleProducts),
      customer: customer?.name ?? '',
      customerName: customer?.displayName ?? '',
      phoneNumber: customer?.phoneNumber1 ?? '',
      customerGroup: customer?.customerGroup ?? '',
      customerPhoto: customer?.photo ?? '',
      canEditBill: customer?.canEditBill ?? false,
      canShowPrice: customer?.canShowPrice ?? false,
      canSplitBill: customer?.canSplitBill ?? false,
      driver: driver?.displayCode ?? '',
      driverName: driver?.displayName ?? '',
      driverPhoneNumber: driver?.phoneNumber1 ?? '',
      plateNumber: plateNumber.value,
      driverPhoto: driver?.photo ?? '',
      saleStatus: savedSale?.saleStatus ?? 'Draft',
      parentBillNumber: savedSale?.parentBillNumber ?? '',
      totalPayment: savedSale?.totalPayment ?? 0,
      totalWriteOff: savedSale?.totalWriteOff ?? 0,
      status: savedSale?.status ?? 'Unpaid',
      id: savedSale?.id ?? '',
      enableEditMode: savedSale?.enableEditMode ?? true,
      station: stationName,
      lastUpdateStation: stationName,
    );
  }

  double get totalQuantity => currentSale.totalQuantity;
  double get totalSaleQuantity => currentSale.totalSaleQuantity;
  double get grandTotal => currentSale.totalAmount;
  bool get hasSelectedCustomer => selectedCustomer.value != null;
  bool get isNewSale => openedSale.value == null;
  bool get canOpenPendingOrder => saleProducts.isEmpty && isNewSale;

  Uri? productImage(Product product) => _resolveImage(product.photo);

  Uri? saleProductImage(SaleProduct product) => _resolveImage(product.photo);

  Uri? customerImage(Customer customer) =>
      customerService.customerImage(customer);

  Uri? _resolveImage(String photo) {
    if (photo.trim().isEmpty) return null;
    return productService.baseUri.resolve(photo.trim());
  }

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
        outletName,
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
      products.assignAll(await productService.getProducts(outletName));
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

  Future<void> selectCustomer(Customer customer) async {
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

  bool hasProduct(Product product) =>
      saleProducts.any((item) => item.productCode == product.code);

  bool addProduct(Product product, {double quantity = 1}) {
    if (quantity <= 0 || hasProduct(product)) return false;
    final saleProduct = SaleProduct.fromProduct(
      product,
      outlet: outletName,
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

  CustomerProductPrice? _customerPriceFor({
    required String productCode,
    required String unit,
  }) {
    for (final price in customerProductPrices) {
      if (price.matches(productCode: productCode, unit: unit)) return price;
    }
    return null;
  }

  void _applyCustomerPrices() {
    final repricedProducts = saleProducts
        .map((item) {
          final customerPrice = _customerPriceFor(
            productCode: item.productCode,
            unit: item.unit,
          );
          return item.copyWith(
            price: item.isBorrow
                ? 0
                : customerPrice?.price ?? item.productPrice ?? item.price,
          );
        })
        .toList(growable: false);
    saleProducts.assignAll(repricedProducts);
  }

  void remove(SaleProduct item) => saleProducts.removeWhere(
    (candidate) => candidate.productCode == item.productCode,
  );

  void updateSaleProduct(SaleProduct updatedItem) {
    final index = saleProducts.indexWhere(
      (item) => item.productCode == updatedItem.productCode,
    );
    if (index >= 0) saleProducts[index] = updatedItem;
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
    if (sale.saleStatus != 'Draft') {
      throw const PendingOrderNotDraftException();
    }

    _applyOpenedSale(sale);
  }

  Future<void> openClosedOrder(String name) async {
    if (!canOpenPendingOrder) {
      throw const ClosedSaleOpenValidationException();
    }
    final sale = await saleService.getSale(name);
    if (!canOpenPendingOrder) {
      throw const ClosedSaleOpenValidationException();
    }
    if (sale.saleStatus != 'Closed') {
      throw const SaleOrderNotClosedException();
    }

    _applyOpenedSale(sale);
  }

  void _applyOpenedSale(Sale sale) {
    openedSale.value = sale;
    postingDate.value = sale.postingDate ?? _dateOnly(DateTime.now());
    referenceNumber.value = sale.referenceNumber;
    saleNote.value = sale.note;
    saleProducts.assignAll(sale.saleProducts);
    selectedCustomer.value = sale.customer.isEmpty
        ? null
        : Customer(
            name: sale.customer,
            customerName: sale.customerName,
            phoneNumber1: sale.phoneNumber,
            customerGroup: sale.customerGroup,
            photo: sale.customerPhoto,
            canEditBill: sale.canEditBill,
            canShowPrice: sale.canShowPrice,
            canSplitBill: sale.canSplitBill,
          );
    selectedDriver.value = sale.driver.isEmpty
        ? null
        : Customer(
            name: sale.driver,
            customerName: sale.driverName,
            phoneNumber1: sale.driverPhoneNumber,
            plateNumber: sale.plateNumber,
            photo: sale.driverPhoto,
          );
    plateNumber.value = sale.plateNumber;
    customerProductPrices.clear();
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

class SaleValidationException implements Exception {
  const SaleValidationException();
}

class PendingOrderOpenValidationException implements Exception {
  const PendingOrderOpenValidationException();
}

class PendingOrderNotDraftException implements Exception {
  const PendingOrderNotDraftException();
}

class ClosedSaleOpenValidationException implements Exception {
  const ClosedSaleOpenValidationException();
}

class SaleOrderNotClosedException implements Exception {
  const SaleOrderNotClosedException();
}

class SaleDeleteValidationException implements Exception {
  const SaleDeleteValidationException();
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
