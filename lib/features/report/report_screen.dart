import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/report_service.dart';
import 'report_controller.dart';
import 'report_definition.dart';
import 'report_viewer_dialog.dart';

typedef ReportDialogBuilder =
    Widget Function(
      BuildContext context,
      ReportDefinition definition,
      ReportEmbedSession session,
      Future<ReportEmbedSession?> Function() retry,
    );

class ReportScreen extends GetView<ReportController> {
  const ReportScreen({super.key, this.dialogBuilder});

  final ReportDialogBuilder? dialogBuilder;

  Future<void> _openReport(
    BuildContext context,
    ReportDefinition definition,
  ) async {
    final session = await controller.createSession(definition);
    if (session == null || !context.mounted) return;

    final customDialogBuilder = dialogBuilder;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (dialogContext) => customDialogBuilder != null
          ? customDialogBuilder(
              dialogContext,
              definition,
              session,
              () => controller.createSession(definition),
            )
          : ReportViewerDialog(
              definition: definition,
              initialSession: session,
              loadSession: () => controller.createSession(definition),
              allowedHosts: {
                session.viewerUrl.host,
                'report-server-dev.aagj7.com',
              },
            ),
    );
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
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reports',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 2),
                Text('View and export secured Bold Reports'),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              final error = controller.errorMessage.value;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (error != null) ...[
                      _ErrorBanner(message: error),
                      const SizedBox(height: 16),
                    ],
                    Wrap(
                      spacing: 18,
                      runSpacing: 18,
                      children: [
                        for (final report in controller.reports)
                          _ReportCard(
                            definition: report,
                            isLoading: controller.isLoading(report.key),
                            onTap: () => _openReport(context, report),
                          ),
                      ],
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
    required this.definition,
    required this.isLoading,
    required this.onTap,
  });

  final ReportDefinition definition;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 340,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('report-card-${definition.key}'),
          onTap: isLoading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    definition.icon,
                    color: colors.onPrimaryContainer,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        definition.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        definition.description,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
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
                  Icon(Icons.open_in_full_rounded, color: colors.primary),
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
