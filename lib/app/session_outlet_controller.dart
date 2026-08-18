import 'package:get/get.dart';

import '../services/frappe_auth_service.dart';

class SessionOutletController extends GetxController {
  SessionOutletController({required String configuredOutlet})
    : configuredOutlet = configuredOutlet.trim(),
      currentOutlet = configuredOutlet.trim().obs;

  final String configuredOutlet;
  final RxString currentOutlet;
  final availableOutlets = <String>[].obs;

  bool get canChangeOutlet => availableOutlets.length > 1;

  void startSession(AuthSession session) {
    currentOutlet.value = configuredOutlet;
    availableOutlets.assignAll(session.outlets);
  }

  void commitOutlet(String outlet) {
    final normalized = outlet.trim();
    if (normalized.isEmpty) return;
    currentOutlet.value = normalized;
  }

  void reset() {
    currentOutlet.value = configuredOutlet;
    availableOutlets.clear();
  }
}
