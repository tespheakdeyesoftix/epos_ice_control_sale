import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../services/report_file_service.dart';
import 'report_definition.dart';

typedef ReportWebViewBuilder =
    Widget Function(BuildContext context, ReportLaunchRequest request);

class ReportViewerDialog extends StatefulWidget {
  const ReportViewerDialog({
    super.key,
    required this.definition,
    required this.initialRequest,
    required this.loadRequest,
    this.webViewBuilder,
  });

  final ReportDefinition definition;
  final ReportLaunchRequest initialRequest;
  final Future<ReportLaunchRequest?> Function() loadRequest;
  final ReportWebViewBuilder? webViewBuilder;

  @override
  State<ReportViewerDialog> createState() => _ReportViewerDialogState();
}

class _ReportViewerDialogState extends State<ReportViewerDialog> {
  late ReportLaunchRequest _request;
  String? _errorMessage;
  int _progress = 0;
  int _webViewRevision = 0;
  bool _isReloading = false;
  bool _hasCompletedInitialLoad = false;

  @override
  void initState() {
    super.initState();
    _request = widget.initialRequest;
  }

  Future<void> _reload() async {
    if (_isReloading) return;
    setState(() {
      _isReloading = true;
      _errorMessage = null;
      _progress = 0;
      _hasCompletedInitialLoad = false;
    });
    final request = await widget.loadRequest();
    if (!mounted) return;
    setState(() {
      _isReloading = false;
      if (request == null) {
        _errorMessage = 'Unable to reload report_viewer.html.';
      } else {
        _request = request;
        _webViewRevision++;
      }
    });
  }

  void _openPopupWindow(int windowId) {
    if (!mounted) return;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ReportPopupDialog(windowId: windowId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dialog.fullscreen(
      key: const ValueKey('report-viewer-dialog'),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.definition.title),
              Text(
                'Bold report viewer',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
          actions: [
            IconButton(
              key: const ValueKey('reload-report-viewer'),
              tooltip: 'Reload report file',
              onPressed: _isReloading ? null : _reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              key: const ValueKey('close-report-viewer'),
              tooltip: 'Close report',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(child: _buildBody()),
            if (_progress > 0 && _progress < 100 && _errorMessage == null)
              Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(value: _progress / 100),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isReloading) {
      return const _ReportViewerMessage(
        icon: Icons.refresh_rounded,
        message: 'Reloading report_viewer.html…',
        showProgress: true,
      );
    }
    final error = _errorMessage;
    if (error != null) {
      final missingRuntime = _isWebViewRuntimeError(error);
      return _ReportViewerMessage(
        icon: missingRuntime
            ? Icons.web_asset_off_outlined
            : Icons.error_outline_rounded,
        message: missingRuntime
            ? 'Microsoft Edge WebView2 Runtime is required to view reports.'
            : error,
        actionLabel: 'Try again',
        onAction: _reload,
      );
    }

    final customBuilder = widget.webViewBuilder;
    if (customBuilder != null) return customBuilder(context, _request);

    return InAppWebView(
      key: ValueKey('report-file-webview-$_webViewRevision'),
      initialUrlRequest: URLRequest(url: WebUri.uri(_request.viewerUri)),
      initialSettings: _reportWebViewSettings(allowLocalFileAccess: true),
      onLoadStart: (_, _) {
        if (mounted) setState(() => _progress = 5);
      },
      onProgressChanged: (_, progress) {
        if (mounted) setState(() => _progress = progress);
      },
      onLoadStop: (_, _) {
        if (mounted) {
          setState(() {
            _progress = 100;
            _hasCompletedInitialLoad = true;
          });
        }
      },
      onConsoleMessage: (_, message) {
        debugPrint(
          '[Bold Report WebView][${message.messageLevel}] ${message.message}',
        );
      },
      onReceivedError: (_, request, error) {
        if (request.isForMainFrame != true || !mounted) return;
        if (_hasCompletedInitialLoad &&
            isExpectedWebViewNavigationAbort(error)) {
          // WebView2 reports a cancelled/aborted main-frame navigation when
          // Bold turns an export response into a download or opens printing.
          // The already loaded viewer must remain mounted in that case.
          setState(() => _progress = 100);
          return;
        }
        setState(() => _errorMessage = error.description);
      },
      onCreateWindow: (_, action) async {
        if (!mounted) return false;
        _openPopupWindow(action.windowId);
        return true;
      },
    );
  }
}

class _ReportPopupDialog extends StatefulWidget {
  const _ReportPopupDialog({required this.windowId});

  final int windowId;

  @override
  State<_ReportPopupDialog> createState() => _ReportPopupDialogState();
}

class _ReportPopupDialogState extends State<_ReportPopupDialog> {
  int _progress = 0;
  String? _errorMessage;

  void _close() {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      key: const ValueKey('report-popup-dialog'),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Print report'),
          actions: [
            IconButton(
              key: const ValueKey('close-report-popup'),
              tooltip: 'Close print window',
              onPressed: _close,
              icon: const Icon(Icons.close_rounded),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: InAppWebView(
                windowId: widget.windowId,
                initialSettings: _reportWebViewSettings(),
                onProgressChanged: (_, progress) {
                  if (mounted) setState(() => _progress = progress);
                },
                onConsoleMessage: (_, message) {
                  debugPrint(
                    '[Bold Report Popup][${message.messageLevel}] '
                    '${message.message}',
                  );
                },
                onReceivedError: (_, request, error) {
                  if (request.isForMainFrame != true || !mounted) return;
                  if (isExpectedWebViewNavigationAbort(error)) return;
                  setState(() => _errorMessage = error.description);
                },
                onCloseWindow: (_) => _close(),
              ),
            ),
            if (_progress < 100 && _errorMessage == null)
              Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress / 100 : null,
                ),
              ),
            if (_errorMessage case final message?)
              Center(
                child: _ReportViewerMessage(
                  icon: Icons.error_outline_rounded,
                  message: message,
                  actionLabel: 'Close',
                  actionIcon: Icons.close_rounded,
                  onAction: _close,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReportViewerMessage extends StatelessWidget {
  const _ReportViewerMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.actionIcon = Icons.refresh_rounded,
    this.onAction,
    this.showProgress = false,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              if (showProgress) ...[
                const SizedBox(height: 18),
                const CircularProgressIndicator(),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: Icon(actionIcon),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

InAppWebViewSettings _reportWebViewSettings({
  bool allowLocalFileAccess = false,
}) {
  return InAppWebViewSettings(
    javaScriptEnabled: true,
    javaScriptCanOpenWindowsAutomatically: true,
    javaScriptBridgeEnabled: true,
    supportMultipleWindows: true,
    supportZoom: true,
    cacheEnabled: true,
    databaseEnabled: true,
    domStorageEnabled: true,
    thirdPartyCookiesEnabled: true,
    loadsImagesAutomatically: true,
    blockNetworkLoads: false,
    mediaPlaybackRequiresUserGesture: false,
    disableContextMenu: false,
    transparentBackground: false,
    allowFileAccessFromFileURLs: allowLocalFileAccess,
    allowUniversalAccessFromFileURLs: allowLocalFileAccess,
  );
}

bool _isWebViewRuntimeError(String message) {
  final normalized = message.toLowerCase();
  return normalized.contains('webview2') ||
      normalized.contains('environment_creation_failed') ||
      normalized.contains('runtime');
}

@visibleForTesting
bool isExpectedWebViewNavigationAbort(WebResourceError error) {
  return error.type == WebResourceErrorType.CONNECTION_ABORTED ||
      error.type == WebResourceErrorType.CANCELLED;
}
