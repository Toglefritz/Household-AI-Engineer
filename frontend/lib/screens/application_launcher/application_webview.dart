import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../../services/application_launcher/models/application_launch_config.dart';
import '../../services/application_launcher/models/application_process.dart';
import '../../services/application_launcher/models/window_state.dart';

/// WebView component for launching and displaying web-based applications.
///
/// This widget provides a full-featured web browser interface for running
/// household applications that are web-based. It includes navigation controls,
/// error handling, and integration with the application launcher system.
class ApplicationWebView extends StatefulWidget {
  /// Creates a new application WebView.
  ///
  /// @param process The application process to display
  /// @param onWindowStateChanged Callback for window state changes
  /// @param onClose Callback when the application should be closed
  const ApplicationWebView({
    required this.process,
    this.onWindowStateChanged,
    this.onClose,
    super.key,
  });

  /// The application process being displayed.
  ///
  /// Contains launch configuration, window state, and process information
  /// needed to properly configure and manage the WebView.
  final ApplicationProcess process;

  /// Callback invoked when the window state changes.
  ///
  /// Called when the user resizes, moves, or otherwise modifies the window
  /// to allow the launcher service to save state for restoration.
  final void Function(WindowState windowState)? onWindowStateChanged;

  /// Callback invoked when the application should be closed.
  ///
  /// Called when the user clicks the close button or uses keyboard shortcuts
  /// to close the application window.
  final VoidCallback? onClose;

  @override
  State<ApplicationWebView> createState() => _ApplicationWebViewState();
}

class _ApplicationWebViewState extends State<ApplicationWebView> {
  /// WebView controller for managing the web content.
  late final WebViewController _webViewController;

  /// Whether the WebView is currently loading content.
  bool _isLoading = true;

  /// Current page title from the web application.
  String? _pageTitle;

  /// Whether navigation controls should be shown.
  bool get _showNavigationControls => widget.process.launchConfig.showNavigationControls;

  /// Launch configuration for this application.
  ApplicationLaunchConfig get _config => widget.process.launchConfig;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  /// Initializes the WebView controller with appropriate settings.
  ///
  /// Configures security settings, navigation handlers, and loads the
  /// initial application URL based on the launch configuration.
  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(
        _config.enableJavaScript ? JavaScriptMode.unrestricted : JavaScriptMode.disabled,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _updatePageTitle();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
            _showErrorSnackBar(error.description);
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow navigation within the same domain
            final Uri requestUri = Uri.parse(request.url);
            final Uri configUri = Uri.parse(_config.url);

            if (requestUri.host == configUri.host) {
              return NavigationDecision.navigate;
            } else {
              // For external links, could open in system browser
              debugPrint('Blocked external navigation to: ${request.url}');
              return NavigationDecision.prevent;
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_config.url));

    // Configure local storage if enabled
    if (_config.enableLocalStorage) {
      _webViewController.setUserAgent('HouseholdAI-Dashboard/1.0');
    }
  }

  /// Updates the page title from the web content.
  ///
  /// Retrieves the current page title and updates the window title
  /// to reflect the content being displayed.
  Future<void> _updatePageTitle() async {
    try {
      final String? title = await _webViewController.getTitle();
      if (title != null && title.isNotEmpty) {
        setState(() {
          _pageTitle = title;
        });
      }
    } catch (e) {
      debugPrint('Failed to get page title: $e');
    }
  }

  /// Shows an error message in a snackbar.
  ///
  /// Displays user-friendly error information when web content
  /// fails to load or encounters other issues.
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorLoadingApplication(message)),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _reloadPage,
          ),
        ),
      );
    }
  }

  /// Reloads the current page in the WebView.
  ///
  /// Called when the user requests a refresh or when recovering from errors.
  void _reloadPage() {
    _webViewController.reload();
  }

  /// Navigates back in the WebView history.
  ///
  /// Only available when navigation controls are enabled and
  /// there is history to navigate back to.
  Future<void> _goBack() async {
    if (await _webViewController.canGoBack()) {
      await _webViewController.goBack();
    }
  }

  /// Navigates forward in the WebView history.
  ///
  /// Only available when navigation controls are enabled and
  /// there is forward history available.
  Future<void> _goForward() async {
    if (await _webViewController.canGoForward()) {
      await _webViewController.goForward();
    }
  }

  /// Handles the close button press.
  ///
  /// Notifies the parent component that the application should be closed
  /// and performs any necessary cleanup.
  void _handleClose() {
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle ?? _config.windowTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _handleClose,
          tooltip: AppLocalizations.of(context)!.close,
        ),
        actions: [
          if (_showNavigationControls) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _goBack,
              tooltip: AppLocalizations.of(context)!.back,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: _goForward,
              tooltip: AppLocalizations.of(context)!.forward,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reloadPage,
              tooltip: AppLocalizations.of(context)!.refresh,
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isLoading)
            ColoredBox(
              color: Theme.of(
                context,
              ).scaffoldBackgroundColor.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.loadingApplication),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // WebView controller cleanup is handled automatically
    super.dispose();
  }
}
