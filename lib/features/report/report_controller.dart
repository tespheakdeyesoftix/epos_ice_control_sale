import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/session_outlet_controller.dart';
import '../../services/frappe_response_handler.dart';
import '../../services/report_service.dart';
import 'report_definition.dart';

class ReportController extends GetxController {
  ReportController({
    required this.reportService,
    required this.outletController,
  });

  final ReportSessionProvider reportService;
  final SessionOutletController outletController;

  final selectedDate = DateUtils.dateOnly(DateTime.now()).obs;
  final loadingReportKeys = <String>{}.obs;
  final errorMessage = RxnString();

  List<ReportDefinition> get reports => ReportRegistry.reports;

  bool isLoading(String reportKey) => loadingReportKeys.contains(reportKey);

  void setSelectedDate(DateTime value) {
    selectedDate.value = DateUtils.dateOnly(value);
  }

  Future<ReportEmbedSession?> createSession(ReportDefinition definition) async {
    if (isLoading(definition.key)) return null;
    loadingReportKeys.add(definition.key);
    errorMessage.value = null;
    try {
      return await reportService.createEmbedSession(
        reportKey: definition.key,
        outlet: definition.includeOutlet
            ? outletController.currentOutlet.value
            : null,
        reportDate: definition.includeReportDate ? selectedDate.value : null,
      );
    } on FrappeServerMessageException {
      errorMessage.value = 'The report server rejected the request.';
      return null;
    } on ReportEmbedSessionExpiredException {
      errorMessage.value = 'The report link expired. Please try again.';
      return null;
    } on Exception {
      errorMessage.value =
          'Unable to open the report. Check the server connection and try again.';
      return null;
    } finally {
      loadingReportKeys.remove(definition.key);
    }
  }
}
