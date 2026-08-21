import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/session_outlet_controller.dart';
import '../../app/app_setting_controller.dart';
import '../../shared/welcome_card_widget.dart';
import '../closed_sales/closed_sale_controller.dart';
import '../closed_sales/sale_detail_sreen.dart';
import '../login/login_controller.dart';
import '../navigation/app_destination.dart';
import '../navigation/app_shell_controller.dart';
import '../pending_sales/widgets/pending_sale_view_dialog_widget.dart';
import '../sell/widgets/pending_order_list_dialog_widget.dart';
import 'sale_summary_controller.dart';
import 'widgets/recent_order_widget.dart';
import 'widgets/sale_summary_kpi_widget.dart';
import 'widgets/sale_product_summary_widget.dart';

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
      floatingActionButton: Obx(() {
        final isRefreshing =
            settingController.isLoading.value ||
            summaryController.isLoading.value ||
            summaryController.isLoadingRecentSales.value;
        return FloatingActionButton(
          key: const ValueKey('refresh-sale-summary'),
          tooltip: 'ផ្ទុកឡើងវិញ',
          onPressed: isRefreshing
              ? null
              : () => Future.wait([
                  settingController.load(
                    outlet: outletSession.currentOutlet.value,
                  ),
                  summaryController.load(),
                ]),
          child: const Icon(Icons.refresh_rounded),
        );
      }),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
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
                      onRetry: summaryController.loadSummary,
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final productSummary = Obx(
                      () => SaleProductSummaryWidget(
                        products:
                            summaryController
                                .summary
                                .value
                                ?.saleProductSummary ??
                            const [],
                        isLoading: summaryController.isLoading.value,
                        errorMessage: summaryController.errorMessage.value,
                      ),
                    );
                    final recentOrders = Obx(
                      () => RecentOrderWidget(
                        orders: summaryController.recentClosedSales,
                        isLoading: summaryController.isLoadingRecentSales.value,
                        errorMessage:
                            summaryController.recentSalesErrorMessage.value,
                        imageBaseUri: summaryController.saleService.baseUri,
                        onRetry: summaryController.loadRecentClosedSales,
                        onViewAll: () {
                          shell.navigateTo(
                            AppDestination.closedSales,
                            resolveUnfinishedSale: () async => true,
                          );
                        },
                        onOrderTap: (sale) {
                          showSaleDetail(context, sale: sale);
                        },
                        onEdit: (sale) => Get.find<ClosedSaleController>()
                            .editOrder(sale.name),
                      ),
                    );
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: constraints.maxWidth >= 700
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 2, child: recentOrders),
                                const SizedBox(width: 16),
                                Expanded(flex: 3, child: productSummary),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                productSummary,
                                const SizedBox(height: 16),
                                recentOrders,
                              ],
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
          Obx(() {
            final isRefreshing =
                settingController.isLoading.value ||
                summaryController.isLoading.value ||
                summaryController.isLoadingRecentSales.value;
            if (!isRefreshing) return const SizedBox.shrink();
            return ColoredBox(
              key: const ValueKey('sale-summary-loading-overlay'),
              color: colors.surface.withValues(alpha: 0.68),
              child: const Center(child: CircularProgressIndicator()),
            );
          }),
        ],
      ),
    );
  }
}
