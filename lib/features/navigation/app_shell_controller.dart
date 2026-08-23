import 'package:get/get.dart';

import '../global_search/global_search_controller.dart';
import '../sell/sell_controller.dart';
import 'app_destination.dart';

class AppShellController extends GetxController {
  AppShellController({required this.sellController});

  final SellController sellController;
  final selectedDestination = AppDestination.sale.obs;
  final visitedDestinations = <AppDestination>{AppDestination.sale}.obs;
  final isNavigating = false.obs;
  final isGlobalSearchOpen = false.obs;
  late final GlobalSearchController globalSearchController =
      GlobalSearchController(
        saleService: sellController.saleService,
        outletProvider: () => sellController.activeOutletName,
      );

  Future<bool> navigateTo(
    AppDestination destination, {
    required Future<bool> Function() resolveUnfinishedSale,
  }) async {
    if (destination == selectedDestination.value || isNavigating.value) {
      return false;
    }

    isNavigating.value = true;
    try {
      if (selectedDestination.value == AppDestination.sale &&
          sellController.isSaleDirty) {
        final canLeave = await resolveUnfinishedSale();
        if (!canLeave) return false;
      }
      visitedDestinations.add(destination);
      selectedDestination.value = destination;
      return true;
    } finally {
      isNavigating.value = false;
    }
  }

  @override
  void onClose() {
    globalSearchController.dispose();
    super.onClose();
  }
}
