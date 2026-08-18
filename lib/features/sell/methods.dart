part of 'sell_controller.dart';

/// Derived state and internal business helpers for [SellController].
///
/// User-triggered event methods remain in `sell_controller.dart`; this
/// extension keeps calculations and document mapping out of the controller.
extension SellControllerMethods on SellController {
  List<Product> get _filteredProducts {
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

  List<String> get _productCategories {
    final categories = <String>{};
    for (final product in products) {
      final category = product.category.trim();
      if (category.isNotEmpty) categories.add(category);
    }
    return categories.toList(growable: false);
  }

  int _productCountForCategory(String category) {
    final normalizedCategory = category.trim();
    if (normalizedCategory.isEmpty) return products.length;
    return products
        .where((product) => product.category.trim() == normalizedCategory)
        .length;
  }

  Sale get _currentSale {
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
      totalSplitBill: savedSale?.totalSplitBill ?? 0,
      status: savedSale?.status ?? 'Unpaid',
      id: savedSale?.id ?? '',
      enableEditMode: savedSale?.enableEditMode ?? true,
      station: stationName,
      lastUpdateStation: stationName,
    );
  }

  double get _totalQuantity => _currentSale.totalQuantity;
  double get _totalSaleQuantity => _currentSale.totalSaleQuantity;
  double get _grandTotal => _currentSale.totalAmount;
  bool get _hasSelectedCustomer => selectedCustomer.value != null;
  bool get _isNewSale => openedSale.value == null;
  bool get _canOpenPendingOrder => saleProducts.isEmpty && _isNewSale;
  bool get _isNewSaleDirty =>
      _isNewSale &&
      (saleProducts.isNotEmpty ||
          selectedCustomer.value != null ||
          selectedDriver.value != null ||
          plateNumber.value.trim().isNotEmpty ||
          referenceNumber.value.trim().isNotEmpty ||
          saleNote.value.trim().isNotEmpty ||
          postingDate.value != _dateOnly(DateTime.now()));
  bool get _isSaleDirty => !_isNewSale || _isNewSaleDirty;
  bool get _canSearchBillForEdit => _isNewSale && !_isNewSaleDirty;
  bool get _canChangeCustomer =>
      _isNewSale || (canChangeCustomerProvider?.call() ?? true);

  Uri? _productImage(Product product) => _resolveImage(product.photo);

  Uri? _saleProductImage(SaleProduct product) => _resolveImage(product.photo);

  Uri? _customerImage(Customer customer) =>
      customerService.customerImage(customer);

  Uri? _resolveImage(String photo) {
    if (photo.trim().isEmpty) return null;
    return productService.baseUri.resolve(photo.trim());
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

  void _validateSaleForEdit(Sale sale) {
    if (sale.saleStatus.trim().toLowerCase() == 'deleted') {
      throw const SaleEditBlockedException(SaleEditBlockedReason.deleted);
    }
    if (sale.status.trim().toLowerCase() != 'unpaid') {
      throw const SaleEditBlockedException(SaleEditBlockedReason.notUnpaid);
    }
    if (sale.totalSplitBill > 0) {
      throw const SaleEditBlockedException(SaleEditBlockedReason.splitBill);
    }
    if (!sale.canEditBill) {
      throw const SaleEditBlockedException(SaleEditBlockedReason.notAllowed);
    }
  }
}

enum SaleEditBlockedReason { notUnpaid, splitBill, notAllowed, deleted }

class SaleEditBlockedException implements Exception {
  const SaleEditBlockedException(this.reason);

  final SaleEditBlockedReason reason;

  String get message => switch (reason) {
    SaleEditBlockedReason.notUnpaid =>
      'មិនអាចកែប្រែបុងនេះបានទេ ព្រោះបុងបានទូទាត់រួចហើយ។',
    SaleEditBlockedReason.splitBill =>
      'មិនអាចកែប្រែបុងនេះបានទេ ព្រោះបុងនេះបានបំបែករួចហើយ។',
    SaleEditBlockedReason.notAllowed => 'អតិថិជននេះមិនអនុញ្ញាតឱ្យកែប្រែបុងទេ។',
    SaleEditBlockedReason.deleted => 'មិនអាចកែប្រែបុងដែលបានលុបបានទេ។',
  };
}

class SaleValidationException implements Exception {
  const SaleValidationException();
}

class CustomerChangePermissionException implements Exception {
  const CustomerChangePermissionException();

  String get message => 'អ្នកមិនមានសិទ្ធិកែប្រែអតិថិជនទេ។';
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

class BillSearchValidationException implements Exception {
  const BillSearchValidationException();
}

class BillSearchKeywordException implements Exception {
  const BillSearchKeywordException();
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
