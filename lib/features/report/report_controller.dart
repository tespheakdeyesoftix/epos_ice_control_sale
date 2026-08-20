import 'package:get/get.dart';

import '../../app/session_outlet_controller.dart';
import '../../services/report_file_service.dart';
import 'report_definition.dart';

class ReportController extends GetxController {
  ReportController({required this.outletController, required this.fileService});

  final SessionOutletController outletController;
  final ReportFileService fileService;

  final loadingReportKeys = <String>{}.obs;
  final errorMessage = RxnString();

  List<ReportDefinition> get reports => ReportRegistry.reports;

  bool isLoading(String reportKey) => loadingReportKeys.contains(reportKey);

  Future<ReportLaunchRequest?> createLaunchRequest(
    ReportDefinition definition,
  ) async {
    if (isLoading(definition.key)) return null;
    loadingReportKeys.add(definition.key);
    errorMessage.value = null;
    try {
      return await fileService.createLaunchRequest(
        reportPath: definition.reportPath,
        outlet: outletController.currentOutlet.value,
      );
    } on ReportFileException catch (error) {
      errorMessage.value = switch (error.error) {
        ReportFileError.missing =>
          'report_viewer.html was not found beside the application.',
        ReportFileError.unreadable => 'report_viewer.html cannot be read.',
        ReportFileError.invalidReportPath => 'The report path is invalid.',
      };
      return null;
    } on Exception {
      errorMessage.value = 'Unable to prepare the report viewer.';
      return null;
    } finally {
      loadingReportKeys.remove(definition.key);
    }
  }
}
