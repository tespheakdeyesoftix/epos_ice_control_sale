import 'package:get/get.dart';

import '../sell/sell_controller.dart';
import 'app_destination.dart';

class AppShellController extends GetxController {
  AppShellController({required this.sellController});

  final SellController sellController;
  final selectedDestination = AppDestination.sale.obs;
  final visitedDestinations = <AppDestination>{AppDestination.sale}.obs;
  final isNavigating = false.obs;

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
          sellController.saleProducts.isNotEmpty) {
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
}
