import 'package:get/get.dart';

import '../../app/session_outlet_controller.dart';
import '../../services/sale_service.dart';
import '../closed_sales/closed_sale.dart';
import '../navigation/app_destination.dart';
import '../navigation/app_shell_controller.dart';
import '../sell/sell_controller.dart';

class SaleSummaryController extends GetxController {
  SaleSummaryController({
    required this.saleService,
    required this.outletController,
    required this.sellController,
    required this.appShellController,
  });

  final SaleService saleService;
  final SessionOutletController outletController;
  final SellController sellController;
  final AppShellController appShellController;
  final summary = Rxn<DailySaleSummary>();
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final recentClosedSales = <ClosedSale>[].obs;
  final isLoadingRecentSales = false.obs;
  final recentSalesErrorMessage = RxnString();
  Worker? _outletWorker;
  Worker? _destinationWorker;
  bool _isLoadingAll = false;
  bool _reloadRequested = false;
  int _lastLoadedSaleDataRevision = -1;

  @override
  void onInit() {
    super.onInit();
    _outletWorker = ever<String>(outletController.currentOutlet, (_) => load());
    _destinationWorker = ever<AppDestination>(
      appShellController.selectedDestination,
      (destination) {
        if (destination == AppDestination.saleSummary) refreshIfStale();
      },
    );
    load();
  }

  Future<void> refreshIfStale() async {
    if (_lastLoadedSaleDataRevision == sellController.saleDataRevision.value) {
      return;
    }
    await load();
  }

  Future<void> load() async {
    if (_isLoadingAll) {
      _reloadRequested = true;
      return;
    }
    _isLoadingAll = true;
    try {
      do {
        _reloadRequested = false;
        final revisionAtStart = sellController.saleDataRevision.value;
        await Future.wait([loadSummary(), loadRecentClosedSales()]);
        if (errorMessage.value == null &&
            recentSalesErrorMessage.value == null) {
          _lastLoadedSaleDataRevision = revisionAtStart;
        }
      } while (_reloadRequested);
    } finally {
      _isLoadingAll = false;
    }
  }

  Future<void> loadSummary() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      summary.value = await saleService.getDailySaleSummary(
        outletController.currentOutlet.value,
      );
    } on Exception {
      errorMessage.value = 'មិនអាចទាញយកទិន្នន័យសង្ខេបការលក់បានទេ';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadRecentClosedSales() async {
    if (isLoadingRecentSales.value) return;
    isLoadingRecentSales.value = true;
    recentSalesErrorMessage.value = null;
    try {
      recentClosedSales.assignAll(
        await saleService.getRecentClosedSales(
          outlet: outletController.currentOutlet.value,
        ),
      );
    } on Exception {
      recentSalesErrorMessage.value = 'មិនអាចទាញយកការលក់ថ្មីៗដែលបានបិទបានទេ';
    } finally {
      isLoadingRecentSales.value = false;
    }
  }

  @override
  void onClose() {
    _outletWorker?.dispose();
    _destinationWorker?.dispose();
    super.onClose();
  }
}
