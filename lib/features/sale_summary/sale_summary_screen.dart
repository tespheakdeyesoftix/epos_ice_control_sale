import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/session_outlet_controller.dart';
import '../../app/app_setting_controller.dart';
import '../../shared/welcome_card_widget.dart';
import '../login/login_controller.dart';
import '../navigation/app_destination.dart';
import '../navigation/app_shell_controller.dart';
import '../pending_sales/widgets/pending_sale_view_dialog_widget.dart';
import '../sell/widgets/pending_order_list_dialog_widget.dart';
import 'sale_summary_controller.dart';
import 'widgets/sale_summary_kpi_widget.dart';

class SaleSummaryScreen extends StatelessWidget {
  const SaleSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final login = Get.find<LoginController>();
    final outletSession = Get.find<SessionOutletController>();
    final shell = Get.find<AppShellController>();
    final summaryController = Get.find<SaleSummaryController>();
    final settingController = Get.find<AppSettingController>();
    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(
              () => WelcomeCardWidget(
                businessNameKh:
                    settingController.current?.businessNameKh ?? '',
                businessNameEn:
                    settingController.current?.businessNameEn ?? '',
                businessAddress: settingController.current?.address ?? '',
                businessPhone:
                    settingController.current?.phoneNumber1 ?? '',
                businessLogoUrl:
                    settingController.logoUri?.toString() ?? '',
                userName: login.currentUsername.value,
                userImageUrl: login.currentUserImageUrl.value,
                outletName: outletSession.currentOutlet.value,
                stationName: login.stationName,
                onCreateOrder: () {
                  shell.sellController.startNewSale();
                  shell.navigateTo(
                    AppDestination.sale,
                    resolveUnfinishedSale: () async => true,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Obx(
                () => SaleSummaryKpiWidget(
                  summary: summaryController.summary.value,
                  isLoading: summaryController.isLoading.value,
                  errorMessage: summaryController.errorMessage.value,
                  onRetry: summaryController.load,
                  onSalesTap: () {
                    shell.navigateTo(
                      AppDestination.closedSales,
                      resolveUnfinishedSale: () async => true,
                    );
                  },
                  onPendingTap: () {
                    showPendingOrderListDialog(
                      context,
                      saleService: shell.sellController.saleService,
                      outlet: outletSession.currentOutlet.value,
                      onView: (name) => showPendingSaleViewDialog(
                        context,
                        saleService: shell.sellController.saleService,
                        name: name,
                      ),
                      onEdit: (name) async {
                        await shell.sellController.openPendingOrder(name);
                        if (!context.mounted) return;
                        await shell.navigateTo(
                          AppDestination.sale,
                          resolveUnfinishedSale: () async => true,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
