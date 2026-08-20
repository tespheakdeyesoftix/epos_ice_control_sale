import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/app_setting.dart';
import '../../app/app_setting_controller.dart';
import '../../app/theme_controller.dart';
import '../../services/frappe_response_handler.dart';
import '../../services/receipt_print_service.dart';
import '../../shared/network_image.dart';
import '../../shared/receipts/close_and_print_flow.dart';
import '../../shared/select_customer_dialog_widget.dart';
import '../../shared/user_profile_widget.dart';
import '../../shared/warning_pending_order_widget.dart';
import '../closed_sales/closed_sale_list_screen.dart';
import '../closed_sales/closed_sale_controller.dart';
import '../login/login_controller.dart';
import '../pending_sales/pending_sale_list_screen.dart';
import '../report/report_screen.dart';
import '../setting/setting_screen.dart';
import '../sale_summary/sale_summary_screen.dart';
import '../sell/customer.dart';
import '../sell/sell_controller.dart';
import '../sell/sell_screen.dart';
import '../sell/widgets/save_order_success_widget.dart';
import 'app_destination.dart';
import 'app_shell_controller.dart';

enum _SaleLeaveAction { close, closeAndPrint, hold, clear, continueSale }

class AppShellScreen extends GetView<AppShellController> {
  const AppShellScreen({super.key});

  Future<void> _navigate(
    BuildContext context,
    AppDestination destination,
  ) async {
    await controller.navigateTo(
      destination,
      resolveUnfinishedSale: () => _resolveUnfinishedSale(context),
    );
  }

  Future<void> _editPendingOrder(BuildContext context, String name) async {
    final sell = controller.sellController;
    try {
      await sell.openPendingOrder(name);
      if (!context.mounted) return;
      await controller.navigateTo(
        AppDestination.sale,
        resolveUnfinishedSale: () async => true,
      );
    } on PendingOrderOpenValidationException {
      FrappeResponseHandler.show(
        const FrappeServerMessage(
          message: 'សូមរក្សាទុកការលក់បច្ចុប្បន្នជាមុនសិន មុននឹងកែបុងរង់ចាំ។',
          indicator: 'orange',
        ),
      );
    } on SaleEditBlockedException catch (error) {
      FrappeResponseHandler.show(
        FrappeServerMessage(message: error.message, indicator: 'orange'),
      );
    } on PendingOrderNotDraftException {
      FrappeResponseHandler.show(
        const FrappeServerMessage(
          message: 'បុងនេះមិនមែនជាបុងរង់ចាំទៀតទេ។',
          indicator: 'orange',
        ),
      );
    } on FrappeServerMessageException {
      // The shared API client already displayed the server message.
    } on Exception {
      FrappeResponseHandler.show(
        const FrappeServerMessage(
          message: 'មិនអាចបើកបុងរង់ចាំនេះបានទេ។',
          indicator: 'red',
        ),
      );
    }
  }

  Future<bool> _resolveUnfinishedSale(BuildContext context) async {
    final action = await showDialog<_SaleLeaveAction>(
      context: context,
      builder: (dialogContext) => Dialog(
        key: const ValueKey('unfinished-sale-navigation-dialog'),
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'មានការលក់មិនទាន់បានរក្សាទុក',
                  style: Theme.of(
                    dialogContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'សូមជ្រើសរើសរបៀបដោះស្រាយការលក់បច្ចុប្បន្ន មុនពេលចាកចេញពីផ្ទាំងលក់។',
                  style: TextStyle(
                    color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                _LeaveActionTile(
                  key: const ValueKey('leave-sale-close'),
                  icon: Icons.save_outlined,
                  title: 'បិទការលក់',
                  subtitle: 'រក្សាទុកការលក់ជាស្ថានភាពបានបិទ',
                  onTap: () =>
                      Navigator.of(dialogContext).pop(_SaleLeaveAction.close),
                ),
                const SizedBox(height: 8),
                _LeaveActionTile(
                  key: const ValueKey('leave-sale-close-and-print'),
                  icon: Icons.print_outlined,
                  title: 'បិទការលក់ និងបោះពុម្ភវិកយបត្រ',
                  subtitle: 'រក្សាទុកការលក់ ហើយបោះពុម្ពវិក្កយបត្រ',
                  onTap: () => Navigator.of(
                    dialogContext,
                  ).pop(_SaleLeaveAction.closeAndPrint),
                ),
                const SizedBox(height: 8),
                _LeaveActionTile(
                  key: const ValueKey('leave-sale-hold'),
                  icon: Icons.pause_circle_outline_rounded,
                  title: 'ដាក់ក្នុងរង់ចាំ',
                  subtitle: 'រក្សាទុកការលក់ជាព្រាងសម្រាប់បន្តពេលក្រោយ',
                  onTap: () =>
                      Navigator.of(dialogContext).pop(_SaleLeaveAction.hold),
                ),
                const SizedBox(height: 8),
                _LeaveActionTile(
                  key: const ValueKey('leave-sale-clear'),
                  icon: Icons.delete_outline_rounded,
                  title: 'សម្អាត ហើយបន្ត',
                  subtitle: 'លុបការលក់បច្ចុប្បន្ន ហើយបន្តទៅផ្ទាំងថ្មី',
                  isDestructive: true,
                  onTap: () =>
                      Navigator.of(dialogContext).pop(_SaleLeaveAction.clear),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  key: const ValueKey('leave-sale-continue'),
                  onPressed: () => Navigator.of(
                    dialogContext,
                  ).pop(_SaleLeaveAction.continueSale),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('បន្តការលក់'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (action == null || action == _SaleLeaveAction.continueSale) return false;
    if (!context.mounted) return false;

    final sell = controller.sellController;
    if (action == _SaleLeaveAction.clear) {
      sell.startNewSale();
      return true;
    }

    if (action == _SaleLeaveAction.closeAndPrint) {
      final login = Get.find<LoginController>();
      final session = login.currentSession.value;
      final sellerFallback = session?.fullName.trim().isNotEmpty == true
          ? session!.fullName.trim()
          : (session?.user.trim().isNotEmpty == true
                ? session!.user.trim()
                : login.currentUsername.value.trim());
      final printService = Get.isRegistered<ReceiptPrintService>()
          ? Get.find<ReceiptPrintService>()
          : Get.put(ReceiptPrintService());
      return showCloseAndPrintFlow(
        context,
        sellController: sell,
        printService: printService,
        business:
            Get.find<AppSettingController>().current ??
            const AppSetting(raw: <String, dynamic>{}),
        sellerFallback: sellerFallback,
      );
    }

    try {
      if (action == _SaleLeaveAction.close && !sell.hasSelectedCustomer) {
        if (!context.mounted) return false;
        if (!sell.canChangeCustomer) {
          const error = CustomerChangePermissionException();
          FrappeResponseHandler.show(
            FrappeServerMessage(message: error.message, indicator: 'orange'),
          );
          return false;
        }
        final customer = await showSelectCustomerDialog(
          context,
          customerService: sell.customerService,
          selectionType: CustomerSelectionType.customer,
        );
        if (customer == null) return false;
        await sell.selectCustomer(customer);
      }
      if (!context.mounted) return false;

      final savedOrder = action == _SaleLeaveAction.close
          ? await sell.saveOrder()
          : await sell.pauseSale();
      sell.startNewSale();
      if (!context.mounted) return false;
      await showSaveOrderSuccessDialog(
        context,
        savedOrder: savedOrder,
        title: action == _SaleLeaveAction.close
            ? 'រក្សាទុកការលក់បានជោគជ័យ'
            : 'ដាក់ការលក់ក្នុងរង់ចាំបានជោគជ័យ',
      );
      return context.mounted;
    } on CustomerChangePermissionException catch (error) {
      FrappeResponseHandler.show(
        FrappeServerMessage(message: error.message, indicator: 'orange'),
      );
      return false;
    } on FrappeServerMessageException {
      return false;
    } on Exception {
      if (context.mounted) _showNavigationError(context);
      return false;
    }
  }

  void _showNavigationError(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Get.rawSnackbar(
      messageText: Text(
        'មិនអាចរក្សាទុកការលក់បានទេ។ សូមព្យាយាមម្តងទៀត។',
        style: TextStyle(color: colors.onError, fontWeight: FontWeight.w600),
      ),
      icon: Icon(Icons.error_outline_rounded, color: colors.onError),
      snackPosition: SnackPosition.TOP,
      snackStyle: SnackStyle.FLOATING,
      maxWidth: 540,
      margin: const EdgeInsets.only(top: 18),
      borderRadius: 12,
      backgroundColor: colors.error,
      duration: const Duration(seconds: 4),
    );
  }

  Widget _screenFor(AppDestination destination) {
    return switch (destination) {
      AppDestination.sale => const SellScreen(),
      AppDestination.saleSummary => const SaleSummaryScreen(),
      AppDestination.closedSales => const ClosedSaleListScreen(),
      AppDestination.pendingSales => const PendingSaleListScreen(),
      AppDestination.report => const ReportScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final settingController = Get.isRegistered<AppSettingController>()
        ? Get.find<AppSettingController>()
        : null;
    final loginController = Get.find<LoginController>();
    final themeController = Get.find<ThemeController>();
    final closedSaleController = Get.find<ClosedSaleController>();
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Obx(() {
              final selected = controller.selectedDestination.value;
              final visited = controller.visitedDestinations.toSet();
              return Row(
                children: [
                  Container(
                    key: const ValueKey('app-navigation-rail'),
                    width: 64,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border(
                        right: BorderSide(color: colors.outlineVariant),
                      ),
                    ),
                    child: NavigationRail(
                      minWidth: 64,
                      selectedIndex: selected.index,
                      labelType: NavigationRailLabelType.none,
                      groupAlignment: -0.8,
                      backgroundColor: colors.surface,
                      indicatorColor: colors.primaryContainer,
                      useIndicator: true,
                      leading: Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 18),
                        child: _RailCompanyAvatar(
                          settingController: settingController,
                        ),
                      ),
                      trailingAtBottom: true,
                      trailing: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              key: const ValueKey('rail-settings-button'),
                              tooltip: 'ការកំណត់',
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SettingScreen(),
                                ),
                              ),
                              icon: const Icon(Icons.settings_outlined),
                            ),
                            SizedBox(
                              width: 32,
                              child: Divider(
                                key: const ValueKey('rail-profile-separator'),
                                height: 17,
                                color: colors.outlineVariant,
                              ),
                            ),
                            Obx(
                              () => UserProfileWidget(
                                username: loginController.currentUsername.value,
                                userImageUrl:
                                    loginController.currentUserImageUrl.value,
                                isDark: themeController.isDark.value,
                                onThemeToggle: themeController.toggleTheme,
                                onLogout: loginController.logout,
                                compact: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      onDestinationSelected: controller.isNavigating.value
                          ? null
                          : (index) => _navigate(
                              context,
                              AppDestination.values[index],
                            ),
                      destinations: AppDestination.values
                          .map(
                            (destination) => NavigationRailDestination(
                              icon: Tooltip(
                                key: ValueKey(
                                  'nav-destination-${destination.name}',
                                ),
                                message: destination.label,
                                child: _RailDestinationIcon(
                                  destination: destination,
                                  pendingCount: controller
                                      .sellController
                                      .pendingOrderCount
                                      .value,
                                  closedCount: closedSaleController
                                      .todayClosedSaleCount
                                      .value,
                                ),
                              ),
                              label: Text(destination.label),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: selected.index,
                      children: AppDestination.values
                          .map(
                            (destination) => visited.contains(destination)
                                ? KeyedSubtree(
                                    key: ValueKey(
                                      'destination-screen-${destination.name}',
                                    ),
                                    child: _screenFor(destination),
                                  )
                                : const SizedBox.shrink(),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ],
              );
            }),
          ),
          if (loginController.currentSession.value != null)
            PendingOrderWarningLauncher(
              saleService: controller.sellController.saleService,
              outlet: controller.sellController.activeOutletName,
              onEdit: (name) => _editPendingOrder(context, name),
            ),
        ],
      ),
    );
  }
}

class _RailDestinationIcon extends StatelessWidget {
  const _RailDestinationIcon({
    required this.destination,
    required this.pendingCount,
    required this.closedCount,
  });

  final AppDestination destination;
  final int pendingCount;
  final int closedCount;

  @override
  Widget build(BuildContext context) {
    final badgeCount = switch (destination) {
      AppDestination.pendingSales => pendingCount,
      AppDestination.closedSales => closedCount,
      _ => null,
    };
    if (badgeCount == null) {
      return Icon(destination.icon);
    }
    final colors = Theme.of(context).colorScheme;
    final countLabel = badgeCount > 99 ? '99+' : badgeCount.toString();
    final keyPrefix = destination == AppDestination.pendingSales
        ? 'pending'
        : 'closed-sale';
    return SizedBox(
      width: 34,
      height: 32,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: Icon(destination.icon)),
          Positioned(
            key: ValueKey('$keyPrefix-rail-badge'),
            top: -5,
            right: -5,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.error,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.surface, width: 1.5),
              ),
              child: Text(
                countLabel,
                key: ValueKey('$keyPrefix-rail-count'),
                style: TextStyle(
                  color: colors.onError,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailCompanyAvatar extends StatelessWidget {
  const _RailCompanyAvatar({required this.settingController});

  final AppSettingController? settingController;

  @override
  Widget build(BuildContext context) {
    final controller = settingController;
    if (controller == null) return const _RailLogoAvatar(imageUri: null);
    return Obx(() => _RailLogoAvatar(imageUri: controller.logoUri));
  }
}

class _RailLogoAvatar extends StatelessWidget {
  const _RailLogoAvatar({required this.imageUri});

  final Uri? imageUri;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const fallback = _RailLogoFallback();
    return Tooltip(
      message: 'ស្លាកសញ្ញាក្រុមហ៊ុន',
      child: Container(
        key: const ValueKey('rail-company-logo'),
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: colors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: colors.outlineVariant),
        ),
        child: ClipOval(
          child: imageUri == null
              ? fallback
              : AppNetworkImage(
                  key: const ValueKey('rail-company-logo-image'),
                  imageUrl: imageUri.toString(),
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  memCacheWidth: 96,
                  memCacheHeight: 96,
                  maxWidthDiskCache: 192,
                  maxHeightDiskCache: 192,
                  placeholder: fallback,
                  errorWidget: fallback,
                ),
        ),
      ),
    );
  }
}

class _RailLogoFallback extends StatelessWidget {
  const _RailLogoFallback();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surfaceContainer,
      child: Icon(Icons.ac_unit_rounded, color: colors.primary, size: 22),
    );
  }
}

class _LeaveActionTile extends StatelessWidget {
  const _LeaveActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isEnabled = onTap != null;
    final foreground = !isEnabled
        ? colors.onSurfaceVariant.withValues(alpha: 0.55)
        : isDestructive
        ? colors.error
        : colors.onSurface;
    return Material(
      color: !isEnabled
          ? colors.surfaceContainerLow.withValues(alpha: 0.55)
          : isDestructive
          ? colors.errorContainer.withValues(alpha: 0.45)
          : colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(icon, color: foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isEnabled
                    ? Icons.chevron_right_rounded
                    : Icons.schedule_rounded,
                color: foreground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
