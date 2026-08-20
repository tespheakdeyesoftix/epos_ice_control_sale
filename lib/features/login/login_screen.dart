import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/app_setting.dart';
import '../../app/app_setting_controller.dart';
import '../../shared/network_image.dart';
import 'login_controller.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingController = AppSettingController.to;
    return Obx(
      () => Scaffold(
        body: Row(
          children: [
            Expanded(
              flex: 65,
              child: _WelcomePanel(
                setting: settingController.current,
                logoUri: settingController.logoUri,
              ),
            ),
            Expanded(
              flex: 35,
              child: _LoginPanel(
                controller: controller,
                setting: settingController.current,
                logoUri: settingController.logoUri,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({required this.setting, required this.logoUri});

  final AppSetting? setting;
  final Uri? logoUri;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/login_hero.png', fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xC8194777), Color(0x33194777), Color(0xAA052B55)],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(64, 60, 64, 64),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _CompanyLogo(
                imageUri: logoUri,
                size: 66,
                borderRadius: 17,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                fallbackColor: Colors.white,
              ),
              const SizedBox(height: 24),
              const Text(
                'សូមស្វាគមន៍',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                setting?.businessNameKh.isNotEmpty == true
                    ? setting!.businessNameKh
                    : 'ប្រព័ន្ធគ្រប់គ្រងការលក់ទឹកកក',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  height: 1.6,
                ),
              ),
              if (setting?.businessNameEn.isNotEmpty == true) ...[
                const SizedBox(height: 2),
                Text(
                  setting!.businessNameEn,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 16,
                  ),
                ),
              ],
              if (setting?.address.isNotEmpty == true) ...[
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 19,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        setting!.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LoginPanel extends StatefulWidget {
  const _LoginPanel({
    required this.controller,
    required this.setting,
    required this.logoUri,
  });

  final LoginController controller;
  final AppSetting? setting;
  final Uri? logoUri;

  @override
  State<_LoginPanel> createState() => _LoginPanelState();
}

class _LoginPanelState extends State<_LoginPanel> {
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      if (widget.controller.usernameController.text.isEmpty) {
        widget.controller.usernameController.text = 'Administrator';
      }
      if (widget.controller.passwordController.text.isEmpty) {
        widget.controller.passwordController.text = '123456';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // _BusinessHeader(
                  //   businessNameKh: setting?.businessNameKh ?? '',
                  //   businessNameEn: setting?.businessNameEn ?? '',
                  //   logoUri: logoUri,
                  // ),
                  // const SizedBox(height: 34),
                  Text(
                    'ចូលប្រើប្រាស់',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'សូមបញ្ចូលព័ត៌មានរបស់អ្នកដើម្បីបន្ត',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 36),
                  const _FieldLabel('ឈ្មោះអ្នកប្រើប្រាស់'),
                  const SizedBox(height: 9),
                  TextField(
                    key: const ValueKey('login-username-input'),
                    controller: controller.usernameController,
                    autofocus: true,
                    autofillHints: const [AutofillHints.username],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'បញ្ចូលឈ្មោះអ្នកប្រើប្រាស់',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const _FieldLabel('ពាក្យសម្ងាត់'),
                  const SizedBox(height: 9),
                  Obx(
                    () => TextField(
                      controller: controller.passwordController,
                      obscureText: controller.obscurePassword.value,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => controller.login(),
                      decoration: InputDecoration(
                        hintText: 'បញ្ចូលពាក្យសម្ងាត់',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: controller.obscurePassword.value
                              ? 'បង្ហាញពាក្យសម្ងាត់'
                              : 'លាក់ពាក្យសម្ងាត់',
                          onPressed: controller.togglePasswordVisibility,
                          icon: Icon(
                            controller.obscurePassword.value
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Obx(() {
                    final message = controller.errorMessage.value;
                    if (message == null) return const SizedBox(height: 28);
                    return Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: colors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              message,
                              style: TextStyle(
                                color: colors.error,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(
                    height: 54,
                    child: Obx(
                      () => FilledButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.login,
                        child: controller.isLoading.value
                            ? SizedBox(
                                width: 23,
                                height: 23,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: colors.onPrimary,
                                ),
                              )
                            : const Text(
                                'ចូលប្រើប្រាស់',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Divider(color: colors.outlineVariant),
                  const SizedBox(height: 14),
                  _StationOutletFooter(
                    stationName: controller.stationName,
                    outletName: controller.outletName,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Kept for the optional company header currently disabled in [_LoginPanel].
// ignore: unused_element
class _BusinessHeader extends StatelessWidget {
  const _BusinessHeader({
    required this.businessNameKh,
    required this.businessNameEn,
    required this.logoUri,
  });

  final String businessNameKh;
  final String businessNameEn;
  final Uri? logoUri;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CompanyLogo(
          imageUri: logoUri,
          size: 62,
          borderRadius: 16,
          backgroundColor: colors.surfaceContainer,
          fallbackColor: colors.primary,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                businessNameKh.isEmpty
                    ? 'ប្រព័ន្ធគ្រប់គ្រងការលក់ទឹកកក'
                    : businessNameKh,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
              if (businessNameEn.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  businessNameEn,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StationOutletFooter extends StatelessWidget {
  const _StationOutletFooter({
    required this.stationName,
    required this.outletName,
  });

  final String stationName;
  final String outletName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          _LocationInfoRow(
            icon: Icons.point_of_sale_outlined,
            label: 'ទីតាំងលក់',
            value: outletName,
          ),
          const SizedBox(height: 9),
          _LocationInfoRow(
            icon: Icons.storefront_outlined,
            label: 'ម៉ាស៊ីនលក់',
            value: stationName,
          ),
        ],
      ),
    );
  }
}

class _LocationInfoRow extends StatelessWidget {
  const _LocationInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: colors.primary, size: 19),
        const SizedBox(width: 9),
        Text(
          '$label៖',
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompanyLogo extends StatelessWidget {
  const _CompanyLogo({
    required this.imageUri,
    required this.size,
    required this.borderRadius,
    required this.backgroundColor,
    required this.fallbackColor,
  });

  final Uri? imageUri;
  final double size;
  final double borderRadius;
  final Color backgroundColor;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      Icons.ac_unit_rounded,
      color: fallbackColor,
      size: size * 0.5,
    );
    return Container(
      key: const ValueKey('login-company-logo'),
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: imageUri == null
          ? fallback
          : AppNetworkImage(
              imageUrl: imageUri.toString(),
              width: size,
              height: size,
              fit: BoxFit.cover,
              memCacheWidth: 192,
              memCacheHeight: 192,
              errorWidget: fallback,
            ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Text(
      label,
      style: TextStyle(
        color: colors.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
