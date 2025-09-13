import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../l10n/app_localizations.dart';
import '../../services/application_launcher/models/application_process.dart';
import '../../services/application_launcher/models/window_state.dart';
import 'application_webview.dart';

/// Window for launching and managing individual applications.
///
/// This widget creates a separate window for each launched application,
/// providing proper window management, state preservation, and integration
/// with the macOS window system.
class ApplicationLauncherWindow extends StatefulWidget {
  /// Creates a new application launcher window.
  ///
  /// @param process The application process to display
  /// @param onWindowStateChanged Callback for window state changes
  /// @param onApplicationClosed Callback when the application is closed
  const ApplicationLauncherWindow({
    required this.process,
    this.onWindowStateChanged,
    this.onApplicationClosed,
    super.key,
  });

  /// The application process being displayed in this window.
  ///
  /// Contains launch configuration, window state, and process information
  /// needed to properly configure and manage the window.
  final ApplicationProcess process;

  /// Callback invoked when the window state changes.
  ///
  /// Called when the user resizes, moves, or otherwise modifies the window
  /// to allow the launcher service to save state for restoration.
  final void Function(WindowState windowState)? onWindowStateChanged;

  /// Callback invoked when the application is closed.
  ///
  /// Called when the user closes the application window to notify
  /// the launcher service that the process should be terminated.
  final void Function(String applicationId)? onApplicationClosed;

  @override
  State<ApplicationLauncherWindow> createState() => _ApplicationLauncherWindowState();
}

class _ApplicationLauncherWindowState extends State<ApplicationLauncherWindow> with WindowListener {
  /// Current window state for this application.
  WindowState? _currentWindowState;

  /// Whether the window has been initialized.
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeWindow();
  }

  /// Initializes the window with appropriate settings and state.
  ///
  /// Configures window size, position, and properties based on the
  /// launch configuration and any saved window state.
  Future<void> _initializeWindow() async {
    try {
      // Add window listener for state changes
      windowManager.addListener(this);

      // Configure window properties
      await _configureWindow();

      // Restore window state if available
      await _restoreWindowState();

      setState(() {
        _isInitialized = true;
      });

      debugPrint(
        'Application window initialized: ${widget.process.applicationTitle}',
      );
    } catch (e) {
      debugPrint('Failed to initialize application window: $e');
      setState(() {
        _isInitialized = true; // Continue even if initialization partially failed
      });
    }
  }

  /// Configures basic window properties.
  ///
  /// Sets up window title, minimum size, and other properties
  /// based on the application launch configuration.
  Future<void> _configureWindow() async {
    final config = widget.process.launchConfig;

    // Set window title
    await windowManager.setTitle(config.windowTitle);

    // Set minimum window size
    await windowManager.setMinimumSize(const Size(400, 300));

    // Configure resizability
    await windowManager.setResizable(config.resizable);

    // Ensure window is visible
    await windowManager.show();
    await windowManager.focus();
  }

  /// Restores window state from saved configuration.
  ///
  /// Applies previously saved window position, size, and special states
  /// (maximized, minimized, fullscreen) if available and valid.
  Future<void> _restoreWindowState() async {
    final WindowState? savedState = widget.process.windowState;

    if (savedState != null && savedState.isValid()) {
      try {
        if (savedState.isFullscreen) {
          await windowManager.setFullScreen(true);
        } else if (savedState.isMaximized) {
          await windowManager.maximize();
        } else if (savedState.isMinimized) {
          await windowManager.minimize();
        } else {
          // Restore normal window position and size
          await windowManager.setSize(
            Size(savedState.width, savedState.height),
          );
          await windowManager.setPosition(Offset(savedState.x, savedState.y));
        }

        _currentWindowState = savedState;
        debugPrint('Restored window state: ${savedState.description}');
      } catch (e) {
        debugPrint('Failed to restore window state: $e');
        await _setDefaultWindowState();
      }
    } else {
      await _setDefaultWindowState();
    }
  }

  /// Sets default window state for new applications.
  ///
  /// Applies default window size and position when no saved state
  /// is available or when saved state is invalid.
  Future<void> _setDefaultWindowState() async {
    final config = widget.process.launchConfig;

    try {
      await windowManager.setSize(
        Size(
          config.initialWidth.toDouble(),
          config.initialHeight.toDouble(),
        ),
      );

      // Center the window on screen
      await windowManager.center();

      _currentWindowState = WindowState.defaultState(
        width: config.initialWidth.toDouble(),
        height: config.initialHeight.toDouble(),
      );

      debugPrint(
        'Set default window state: ${_currentWindowState?.description}',
      );
    } catch (e) {
      debugPrint('Failed to set default window state: $e');
    }
  }

  /// Captures and saves the current window state.
  ///
  /// Called when window properties change to preserve state
  /// for future restoration.
  Future<void> _captureWindowState() async {
    try {
      final Size size = await windowManager.getSize();
      final Offset position = await windowManager.getPosition();
      final bool isMaximized = await windowManager.isMaximized();
      final bool isMinimized = await windowManager.isMinimized();
      final bool isFullscreen = await windowManager.isFullScreen();

      final WindowState newState = WindowState(
        x: position.dx,
        y: position.dy,
        width: size.width,
        height: size.height,
        isMaximized: isMaximized,
        isMinimized: isMinimized,
        isFullscreen: isFullscreen,
        lastUpdated: DateTime.now(),
      );

      // Only update if state actually changed
      if (_currentWindowState != newState) {
        _currentWindowState = newState;
        widget.onWindowStateChanged?.call(newState);

        // Update the process with new window state
        widget.process.updateWindowState(newState);

        debugPrint('Captured window state: ${newState.description}');
      }
    } catch (e) {
      debugPrint('Failed to capture window state: $e');
    }
  }

  /// Handles the application close event.
  ///
  /// Called when the user closes the application window or when
  /// the application needs to be terminated.
  void _handleApplicationClose() {
    debugPrint(
      'Application window closing: ${widget.process.applicationTitle}',
    );
    widget.onApplicationClosed?.call(widget.process.applicationId);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(AppLocalizations.of(context)!.initializingApplicationWindow),
              ),
            ],
          ),
        ),
      );
    }

    return ApplicationWebView(
      process: widget.process,
      onWindowStateChanged: (WindowState windowState) {
        _currentWindowState = windowState;
        widget.onWindowStateChanged?.call(windowState);
      },
      onClose: _handleApplicationClose,
    );
  }

  // WindowListener implementation

  @override
  void onWindowResize() {
    super.onWindowResize();
    _captureWindowState();
  }

  @override
  void onWindowMove() {
    super.onWindowMove();
    _captureWindowState();
  }

  @override
  void onWindowMaximize() {
    super.onWindowMaximize();
    _captureWindowState();
  }

  @override
  void onWindowUnmaximize() {
    super.onWindowUnmaximize();
    _captureWindowState();
  }

  @override
  void onWindowMinimize() {
    super.onWindowMinimize();
    _captureWindowState();
  }

  @override
  void onWindowRestore() {
    super.onWindowRestore();
    _captureWindowState();
  }

  @override
  void onWindowEnterFullScreen() {
    super.onWindowEnterFullScreen();
    _captureWindowState();
  }

  @override
  void onWindowLeaveFullScreen() {
    super.onWindowLeaveFullScreen();
    _captureWindowState();
  }

  @override
  void onWindowClose() {
    super.onWindowClose();
    _handleApplicationClose();
  }

  @override
  void dispose() {
    // Remove window listener
    windowManager.removeListener(this);
    super.dispose();
  }
}
