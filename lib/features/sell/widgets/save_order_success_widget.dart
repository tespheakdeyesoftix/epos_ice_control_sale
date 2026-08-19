import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

Future<void> showSaveOrderSuccessDialog(
  BuildContext context, {
  required Map<String, dynamic> savedOrder,
  String title = 'រក្សាទុកការលក់បានជោគជ័យ',
  bool Function()? pauseCountdown,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => SaveOrderSuccessWidget(
      savedOrder: savedOrder,
      title: title,
      pauseCountdown: pauseCountdown,
    ),
  );
}

class SaveOrderSuccessWidget extends StatefulWidget {
  const SaveOrderSuccessWidget({
    super.key,
    required this.savedOrder,
    this.title = 'រក្សាទុកការលក់បានជោគជ័យ',
    this.secondsToClose = 5,
    this.pauseCountdown,
  });

  final Map<String, dynamic> savedOrder;
  final String title;
  final int secondsToClose;
  final bool Function()? pauseCountdown;

  @override
  State<SaveOrderSuccessWidget> createState() => _SaveOrderSuccessWidgetState();
}

class _SaveOrderSuccessWidgetState extends State<SaveOrderSuccessWidget> {
  Timer? _timer;
  late int _secondsRemaining;

  String get _orderNumber {
    final value =
        widget.savedOrder['name'] ??
        widget.savedOrder['id'] ??
        widget.savedOrder['reference_number'];
    return value?.toString().trim() ?? '';
  }

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.secondsToClose;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (widget.pauseCountdown?.call() == true) return;
      if (ModalRoute.of(context)?.isCurrent != true) return;
      if (_secondsRemaining <= 1) {
        timer.cancel();
        Navigator.of(context).pop();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semanticColors = AppSemanticColors.of(context);
    return PopScope(
      canPop: false,
      child: Dialog(
        key: const ValueKey('save-order-success-dialog'),
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: 430,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: semanticColors.success.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: semanticColors.success,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_orderNumber.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Text(
                        'លេខការលក់៖ $_orderNumber',
                        key: const ValueKey('saved-order-number'),
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'ផ្ទាំងនេះនឹងបិទក្នុង $_secondsRemaining វិនាទី',
                      key: const ValueKey('save-order-countdown'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: _secondsRemaining / widget.secondsToClose,
                      color: semanticColors.success,
                      backgroundColor: colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        key: const ValueKey('close-save-order-success-button'),
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: semanticColors.success,
                          foregroundColor: colors.onPrimary,
                        ),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('បិទ'),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  key: const ValueKey('close-save-order-success'),
                  tooltip: 'បិទ',
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: colors.error.withValues(alpha: 0.1),
                  ),
                  icon: Icon(
                    Icons.close_rounded,
                    color: colors.error,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
