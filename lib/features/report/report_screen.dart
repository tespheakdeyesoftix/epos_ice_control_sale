import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/report_browser_service.dart';
import '../../services/report_file_service.dart';
import 'report_controller.dart';
import 'report_definition.dart';

typedef ReportExternalLauncher =
    Future<void> Function(ReportLaunchRequest request);

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, this.externalLauncher});

  final ReportExternalLauncher? externalLauncher;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportController get controller => Get.find<ReportController>();

  @override
  void initState() {
    super.initState();
    unawaited(controller.loadScreen());
  }

  Future<void> _openReport(ReportDefinition definition) async {
    final request = await controller.createLaunchRequest(definition);
    if (request == null) return;

    try {
      final launcher = widget.externalLauncher ?? EdgeReportLauncher().open;
      await launcher(request);
    } on ReportBrowserLaunchException catch (error) {
      controller.errorMessage.value = error.message;
    } on Exception {
      controller.errorMessage.value =
          'Unable to open the report in Microsoft Edge.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: const ValueKey('report-screen-app-bar'),
            height: 82,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(bottom: BorderSide(color: colors.outlineVariant)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reports',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text('View and export Bold Reports in a browser window'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Obx(
                  () => IconButton.filledTonal(
                    key: const ValueKey('refresh-report-list'),
                    tooltip: 'Refresh report list',
                    onPressed: controller.isLoadingScreen.value
                        ? null
                        : () => unawaited(controller.loadScreen()),
                    icon: controller.isLoadingScreen.value
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : const Icon(Icons.refresh_rounded),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              final error = controller.errorMessage.value;
              final isLoading = controller.isLoadingScreen.value;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (error != null) ...[
                      _ErrorBanner(message: error),
                      const SizedBox(height: 16),
                    ],
                    if (isLoading) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: const LinearProgressIndicator(
                          key: ValueKey('report-screen-loading'),
                          minHeight: 5,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (!isLoading &&
                        controller.reports.isEmpty &&
                        error == null)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('No reports are available.'),
                        ),
                      ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 20.0;
                        const minimumCardWidth = 380.0;
                        final availableWidth = constraints.maxWidth;
                        final columns =
                            ((availableWidth + spacing) /
                                    (minimumCardWidth + spacing))
                                .floor()
                                .clamp(1, 4);
                        final cardWidth =
                            (availableWidth - spacing * (columns - 1)) /
                            columns;
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            for (final report in controller.reports)
                              _ReportCard(
                                width: cardWidth,
                                definition: report,
                                isLoading: controller.isLoading(report.key),
                                onTap: () => _openReport(report),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.width,
    required this.definition,
    required this.isLoading,
    required this.onTap,
  });

  final double width;
  final ReportDefinition definition;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      height: 132,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('report-card-${definition.key}'),
          onTap: isLoading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    definition.icon,
                    color: colors.onPrimaryContainer,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        definition.title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        definition.description,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (isLoading)
                  const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                else
                  Icon(Icons.open_in_new_rounded, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('report-error-banner'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colors.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
