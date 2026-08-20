import 'package:get/get.dart';

import '../../app/session_outlet_controller.dart';
import '../../services/sale_service.dart';

class SaleSummaryController extends GetxController {
  SaleSummaryController({
    required this.saleService,
    required this.outletController,
  });

  final SaleService saleService;
  final SessionOutletController outletController;
  final summary = Rxn<DailySaleSummary>();
  final isLoading = false.obs;
  final errorMessage = RxnString();
  Worker? _outletWorker;

  @override
  void onInit() {
    super.onInit();
    _outletWorker = ever<String>(outletController.currentOutlet, (_) => load());
    load();
  }

  Future<void> load() async {
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

  @override
  void onClose() {
    _outletWorker?.dispose();
    super.onClose();
  }
}
