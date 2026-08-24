import 'package:get/get.dart';

import '../../app/session_outlet_controller.dart';
import '../../services/report_file_service.dart';
import '../../services/report_config_service.dart';
import '../../services/report_list_service.dart';
import 'report_definition.dart';

class ReportController extends GetxController {
  ReportController({
    required this.outletController,
    required this.fileService,
    required this.configService,
    required this.listService,
  });

  final SessionOutletController outletController;
  final ReportFileService fileService;
  final ReportConfigService configService;
  final ReportListService listService;

  final reports = <ReportDefinition>[].obs;
  final loadingReportKeys = <String>{}.obs;
  final errorMessage = RxnString();
  final isLoadingScreen = false.obs;
  BoldReportConfig? _config;

  Future<void> loadScreen() async {
    if (isLoadingScreen.value) return;
    isLoadingScreen.value = true;
    errorMessage.value = null;
    _config = null;
    try {
      final results = await Future.wait<dynamic>([
        listService.getSellerReports(),
        configService.getConfig(),
      ]);
      reports.assignAll(results[0] as List<ReportDefinition>);
      _config = results[1] as BoldReportConfig;
    } on ReportListServiceException catch (error) {
      reports.clear();
      errorMessage.value = 'Unable to load reports (HTTP ${error.statusCode}).';
    } on ReportConfigServiceException catch (error) {
      reports.clear();
      errorMessage.value = error.error == ReportConfigError.http
          ? 'Unable to load report configuration (HTTP ${error.statusCode}).'
          : 'The report configuration returned by the server is invalid.';
    } on Exception {
      reports.clear();
      errorMessage.value = 'Unable to load reports.';
    } finally {
      isLoadingScreen.value = false;
    }
  }

  bool isLoading(String reportKey) => loadingReportKeys.contains(reportKey);

  Future<ReportLaunchRequest?> createLaunchRequest(
    ReportDefinition definition,
  ) async {
    if (isLoading(definition.key)) return null;
    loadingReportKeys.add(definition.key);
    errorMessage.value = null;
    try {
      final config = _config;
      if (config == null) {
        errorMessage.value = 'Report configuration has not been loaded.';
        return null;
      }
      return await fileService.createLaunchRequest(
        reportPath: definition.reportPath,
        outlet: outletController.currentOutlet.value,
        config: config,
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
