import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../services/report_service.dart';
import 'report_definition.dart';

typedef ReportWebViewBuilder = Widget Function(BuildContext context, Uri url);

class ReportViewerDialog extends StatefulWidget {
  const ReportViewerDialog({
    super.key,
    required this.definition,
    required this.initialSession,
    required this.loadSession,
    required this.allowedHosts,
    this.webViewBuilder,
  });

  final ReportDefinition definition;
  final ReportEmbedSession initialSession;
  final Future<ReportEmbedSession?> Function() loadSession;
  final Set<String> allowedHosts;
  final ReportWebViewBuilder? webViewBuilder;

  @override
  State<ReportViewerDialog> createState() => _ReportViewerDialogState();
}

class _ReportViewerDialogState extends State<ReportViewerDialog> {
  late ReportEmbedSession _session;
  String? _errorMessage;
  int _progress = 0;
  bool _isRetrying = false;
  int _webViewRevision = 0;

  @override
  void initState() {
    super.initState();
    _session = widget.initialSession;
    if (_session.isExpired()) {
      _errorMessage = 'The report link has expired.';
    }
  }

  Future<void> _retry() async {
    if (_isRetrying) return;
    setState(() {
      _isRetrying = true;
      _errorMessage = null;
      _progress = 0;
    });
    final nextSession = await widget.loadSession();
    if (!mounted) return;
    setState(() {
      _isRetrying = false;
      if (nextSession == null) {
        _errorMessage = 'Unable to create a new report session.';
      } else {
        _session = nextSession;
        _webViewRevision++;
      }
    });
  }

  bool _isAllowed(Uri uri) {
    if (uri.scheme == 'about' || uri.scheme == 'data') return true;
    return uri.scheme == 'https' && widget.allowedHosts.contains(uri.host);
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
                'Secure Bold Reports viewer',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
          actions: [
            IconButton(
              key: const ValueKey('retry-report-viewer'),
              tooltip: 'Reload with a new secure link',
              onPressed: _isRetrying ? null : _retry,
              icon: const Icon(Icons.refresh_rounded),
            ),
            const SizedBox(width: 4),
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
            Positioned.fill(child: _buildBody(context)),
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

  Widget _buildBody(BuildContext context) {
    if (_isRetrying) {
      return const _ReportViewerMessage(
        icon: Icons.lock_clock_outlined,
        message: 'Creating a new secure report session…',
        showProgress: true,
      );
    }
    final error = _errorMessage;
    if (error != null) {
      return _ReportViewerMessage(
        icon: _isWebViewRuntimeError(error)
            ? Icons.web_asset_off_outlined
            : Icons.cloud_off_outlined,
        message: _isWebViewRuntimeError(error)
            ? 'Microsoft Edge WebView2 Runtime is required to view reports.'
            : error,
        actionLabel: 'Try again',
        onAction: _retry,
      );
    }
    final customBuilder = widget.webViewBuilder;
    if (customBuilder != null) {
      return customBuilder(context, _session.viewerUrl);
    }
    return InAppWebView(
      key: ValueKey('bold-report-webview-$_webViewRevision'),
      initialUrlRequest: URLRequest(url: WebUri.uri(_session.viewerUrl)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        useShouldOverrideUrlLoading: true,
        supportZoom: true,
        transparentBackground: false,
      ),
      onLoadStart: (webViewController, url) {
        if (mounted) setState(() => _progress = 5);
      },
      onProgressChanged: (_, progress) {
        if (mounted) setState(() => _progress = progress);
      },
      onLoadStop: (webViewController, url) {
        if (mounted) setState(() => _progress = 100);
      },
      onReceivedError: (_, request, error) {
        if (request.isForMainFrame != true || !mounted) return;
        setState(() => _errorMessage = error.description);
      },
      shouldOverrideUrlLoading: (_, action) async {
        final webUri = action.request.url;
        if (webUri == null) return NavigationActionPolicy.CANCEL;
        return _isAllowed(Uri.parse(webUri.toString()))
            ? NavigationActionPolicy.ALLOW
            : NavigationActionPolicy.CANCEL;
      },
      onCreateWindow: (webViewController, createWindowAction) async => false,
    );
  }
}

class _ReportViewerMessage extends StatelessWidget {
  const _ReportViewerMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.showProgress = false,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 54, color: colors.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              if (showProgress) ...[
                const SizedBox(height: 18),
                const CircularProgressIndicator(),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh_rounded),
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

bool _isWebViewRuntimeError(String message) {
  final normalized = message.toLowerCase();
  return normalized.contains('webview2') ||
      normalized.contains('environment_creation_failed') ||
      normalized.contains('runtime');
}
