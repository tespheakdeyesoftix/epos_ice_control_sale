import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'receipt_template.dart';

typedef ReceiptPdfBuilder =
    Future<Uint8List> Function(ReceiptTemplate template);

Future<void> showPrintPreviewReceipt(
  BuildContext context, {
  required String saleName,
  required List<ReceiptTemplate> templates,
  required ReceiptTemplate selectedTemplate,
  required ReceiptPdfBuilder buildPdf,
  ValueChanged<ReceiptTemplate>? onTemplateChanged,
}) async {
  final zoomController = TransformationController();
  var zoom = 1.0;
  var currentTemplate = selectedTemplate;
  try {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final windowSize = MediaQuery.sizeOf(dialogContext);
        var isPrinting = false;
        var isExporting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void updateZoom(double value) {
              zoom = value.clamp(.6, 2.4);
              zoomController.value = Matrix4.diagonal3Values(zoom, zoom, 1);
              setDialogState(() {});
            }

            return Dialog(
              key: const ValueKey('print-preview-receipt-dialog'),
              insetPadding: const EdgeInsets.all(18),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: windowSize.width >= 960 ? 860 : windowSize.width * .92,
                height: windowSize.height * .90,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 8, 8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.preview_rounded),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Print Preview Invoice — $saleName',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              FilledButton.icon(
                                key: const ValueKey('preview-print-button'),
                                onPressed: isPrinting || isExporting
                                    ? null
                                    : () async {
                                        setDialogState(() => isPrinting = true);
                                        try {
                                          await Printing.layoutPdf(
                                            name: '$saleName.pdf',
                                            format: currentTemplate.pageFormat,
                                            dynamicLayout: false,
                                            onLayout: (_) =>
                                                buildPdf(currentTemplate),
                                          );
                                        } finally {
                                          if (dialogContext.mounted) {
                                            setDialogState(
                                              () => isPrinting = false,
                                            );
                                          }
                                        }
                                      },
                                icon: isPrinting
                                    ? const SizedBox.square(
                                        dimension: 17,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.print_outlined,
                                        size: 19,
                                      ),
                                label: const Text('Print'),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                key: const ValueKey('preview-export-button'),
                                onPressed: isPrinting || isExporting
                                    ? null
                                    : () async {
                                        setDialogState(
                                          () => isExporting = true,
                                        );
                                        try {
                                          final bytes = await buildPdf(
                                            currentTemplate,
                                          );
                                          await Printing.sharePdf(
                                            bytes: bytes,
                                            filename: '$saleName.pdf',
                                          );
                                        } finally {
                                          if (dialogContext.mounted) {
                                            setDialogState(
                                              () => isExporting = false,
                                            );
                                          }
                                        }
                                      },
                                icon: isExporting
                                    ? const SizedBox.square(
                                        dimension: 17,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.ios_share_rounded,
                                        size: 19,
                                      ),
                                label: const Text('Share / Export'),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Close',
                                onPressed: isPrinting || isExporting
                                    ? null
                                    : () => Navigator.pop(dialogContext),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (templates.length > 1) ...[
                                const Icon(
                                  Icons.description_outlined,
                                  size: 19,
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 250,
                                  child:
                                      DropdownButtonFormField<ReceiptTemplate>(
                                        initialValue: currentTemplate,
                                        isDense: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Receipt template',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                        ),
                                        items: [
                                          for (final template in templates)
                                            DropdownMenuItem(
                                              value: template,
                                              child: Text(
                                                template.templateName.isEmpty
                                                    ? template.name
                                                    : template.templateName,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                        ],
                                        onChanged: isPrinting || isExporting
                                            ? null
                                            : (template) {
                                                if (template == null) return;
                                                setDialogState(() {
                                                  currentTemplate = template;
                                                  onTemplateChanged?.call(
                                                    template,
                                                  );
                                                });
                                              },
                                      ),
                                ),
                              ],
                              const Spacer(),
                              IconButton.outlined(
                                tooltip: 'Zoom out',
                                onPressed: zoom <= .6
                                    ? null
                                    : () => updateZoom(zoom - .2),
                                icon: const Icon(Icons.zoom_out_rounded),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: SizedBox(
                                  width: 54,
                                  child: Text(
                                    '${(zoom * 100).round()}%',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton.outlined(
                                tooltip: 'Zoom in',
                                onPressed: zoom >= 2.4
                                    ? null
                                    : () => updateZoom(zoom + .2),
                                icon: const Icon(Icons.zoom_in_rounded),
                              ),
                              const SizedBox(width: 6),
                              TextButton(
                                onPressed: zoom == 1
                                    ? null
                                    : () => updateZoom(1),
                                child: const Text('Reset'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: InteractiveViewer(
                        transformationController: zoomController,
                        minScale: .6,
                        maxScale: 2.4,
                        scaleEnabled: false,
                        onInteractionUpdate: (_) {
                          final nextZoom = zoomController.value
                              .getMaxScaleOnAxis();
                          if ((nextZoom - zoom).abs() >= .01) {
                            setDialogState(() => zoom = nextZoom);
                          }
                        },
                        child: PdfPreview(
                          key: ValueKey(currentTemplate.name),
                          build: (_) => buildPdf(currentTemplate),
                          initialPageFormat: currentTemplate.pageFormat,
                          canChangeOrientation: false,
                          canChangePageFormat: false,
                          canDebug: false,
                          allowPrinting: false,
                          allowSharing: false,
                          useActions: false,
                          shouldRepaint: true,
                          pdfFileName: '$saleName.pdf',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  } finally {
    zoomController.dispose();
  }
}
