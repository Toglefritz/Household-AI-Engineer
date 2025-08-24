import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../user_application/models/user_application.dart';
import 'models/application_launch_config.dart';
import 'models/application_process.dart';
import 'models/launch_result.dart';
import 'models/window_state.dart';

/// Service for launching and managing household applications.
///
/// This service handles the complete application launching workflow including:
/// * WebView integration for web-based applications
/// * Application process monitoring and health checking
/// * Window state preservation and restoration
/// * Launch configuration management
///
/// All applications in the system are currently web-based and are launched
/// through embedded WebView components with proper navigation controls.
class ApplicationLauncherService {
  /// HTTP client for health checking and API communication.
  ///
  /// Used to verify application availability and perform health checks
  /// on running applications to ensure they remain responsive.
  final http.Client _httpClient;

  /// Shared preferences instance for persisting window states.
  ///
  /// Stores window positions, sizes, and other state information
  /// to restore applications to their previous state on relaunch.
  final SharedPreferences _preferences;

  /// Map of currently running application processes.
  ///
  /// Tracks active applications by their ID for process monitoring,
  /// health checking, and proper cleanup when applications are stopped.
  final Map<String, ApplicationProcess> _runningProcesses = {};

  /// Stream controller for broadcasting application launch events.
  ///
  /// Emits launch results and status updates for UI components
  /// to display appropriate feedback and update application states.
  final StreamController<LaunchResult> _launchEventsController = StreamController<LaunchResult>.broadcast();

  /// Timer for periodic health checks of running applications.
  ///
  /// Performs regular health checks to ensure running applications
  /// remain responsive and automatically handles failed applications.
  Timer? _healthCheckTimer;

  /// Creates a new application launcher service.
  ///
  /// @param httpClient HTTP client for health checking and API communication
  /// @param preferences Shared preferences for window state persistence
  ApplicationLauncherService(this._httpClient, this._preferences) {
    _startHealthCheckTimer();
  }

  /// Stream of application launch events and status updates.
  ///
  /// Emits [LaunchResult] objects containing launch success/failure information,
  /// application process details, and error messages for failed launches.
  Stream<LaunchResult> get launchEvents => _launchEventsController.stream;

  /// Returns a list of currently running application processes.
  ///
  /// Provides information about active applications including process IDs,
  /// launch times, health status, and resource usage information.
  List<ApplicationProcess> get runningProcesses => List.unmodifiable(_runningProcesses.values);

  /// Launches the specified application with optional configuration.
  ///
  /// This method handles the complete launch workflow:
  /// 1. Validates the application can be launched
  /// 2. Loads or creates launch configuration
  /// 3. Restores previous window state if available
  /// 4. Creates WebView component for web applications
  /// 5. Starts process monitoring and health checking
  /// 6. Emits launch result events for UI updates
  ///
  /// @param application The application to launch
  /// @param config Optional launch configuration overrides
  /// @returns Future that completes with launch result information
  ///
  /// @throws LaunchException if the application cannot be launched
  /// @throws ConfigurationException if launch configuration is invalid
  Future<LaunchResult> launchApplication(
    UserApplication application, {
    ApplicationLaunchConfig? config,
  }) async {
    debugPrint('Launching application: ${application.title} (${application.id})');

    try {
      // Validate application can be launched
      if (!application.canLaunch) {
        throw LaunchException(
          'Application cannot be launched in current state: ${application.status.name}',
          'INVALID_STATE',
        );
      }

      // Check if application is already running
      if (_runningProcesses.containsKey(application.id)) {
        debugPrint('Application already running, bringing to foreground: ${application.title}');
        final ApplicationProcess existingProcess = _runningProcesses[application.id]!;
        await _bringToForeground(existingProcess);

        final LaunchResult result = LaunchResult.success(
          application: application,
          process: existingProcess,
          message: 'Application brought to foreground',
        );
        _launchEventsController.add(result);
        return result;
      }

      // Load or create launch configuration
      final ApplicationLaunchConfig launchConfig = config ?? await _loadLaunchConfiguration(application);

      // Restore previous window state
      final WindowState? windowState = await _loadWindowState(application.id);

      // Create application process
      final ApplicationProcess process = ApplicationProcess(
        applicationId: application.id,
        applicationTitle: application.title,
        launchConfig: launchConfig,
        windowState: windowState,
        launchedAt: DateTime.now(),
      );

      // Start the application process
      await _startApplicationProcess(process);

      // Register the running process
      _runningProcesses[application.id] = process;

      debugPrint('Successfully launched application: ${application.title}');

      final LaunchResult result = LaunchResult.success(
        application: application,
        process: process,
        message: 'Application launched successfully',
      );
      _launchEventsController.add(result);
      return result;
    } catch (e) {
      debugPrint('Failed to launch application ${application.title}: $e');

      final LaunchResult result = LaunchResult.failure(
        application: application,
        error: e.toString(),
        errorCode: e is LaunchException ? e.code : 'LAUNCH_FAILED',
      );
      _launchEventsController.add(result);
      return result;
    }
  }

  /// Stops the specified running application.
  ///
  /// Gracefully shuts down the application process, saves window state
  /// for future restoration, and cleans up associated resources.
  ///
  /// @param applicationId ID of the application to stop
  /// @returns Future that completes when the application is stopped
  Future<void> stopApplication(String applicationId) async {
    debugPrint('Stopping application: $applicationId');

    final ApplicationProcess? process = _runningProcesses[applicationId];
    if (process == null) {
      debugPrint('Application not running: $applicationId');
      return;
    }

    try {
      // Save current window state before stopping
      await _saveWindowState(process);

      // Stop the application process
      await _stopApplicationProcess(process);

      // Remove from running processes
      _runningProcesses.remove(applicationId);

      debugPrint('Successfully stopped application: $applicationId');

      final LaunchResult result = LaunchResult.stopped(
        applicationId: applicationId,
        message: 'Application stopped successfully',
      );
      _launchEventsController.add(result);
    } catch (e) {
      debugPrint('Error stopping application $applicationId: $e');

      final LaunchResult result = LaunchResult.failure(
        applicationId: applicationId,
        error: e.toString(),
        errorCode: 'STOP_FAILED',
      );
      _launchEventsController.add(result);
    }
  }

  /// Restarts the specified application.
  ///
  /// Stops the current instance and launches a new one, preserving
  /// window state and configuration settings.
  ///
  /// @param application The application to restart
  /// @returns Future that completes with the restart result
  Future<LaunchResult> restartApplication(UserApplication application) async {
    debugPrint('Restarting application: ${application.title}');

    // Stop the current instance if running
    if (_runningProcesses.containsKey(application.id)) {
      await stopApplication(application.id);

      // Wait a moment for cleanup to complete
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Launch a new instance
    return launchApplication(application);
  }

  /// Checks if the specified application is currently running.
  ///
  /// @param applicationId ID of the application to check
  /// @returns True if the application is currently running
  bool isApplicationRunning(String applicationId) {
    return _runningProcesses.containsKey(applicationId);
  }

  /// Gets the process information for a running application.
  ///
  /// @param applicationId ID of the application
  /// @returns Process information or null if not running
  ApplicationProcess? getApplicationProcess(String applicationId) {
    return _runningProcesses[applicationId];
  }

  /// Performs health checks on all running applications.
  ///
  /// Verifies that applications are still responsive and handles
  /// failed applications by updating their status and notifying users.
  ///
  /// @returns Future that completes when health checks are finished
  Future<void> performHealthChecks() async {
    if (_runningProcesses.isEmpty) {
      return;
    }

    debugPrint('Performing health checks on ${_runningProcesses.length} running applications');

    final List<Future<void>> healthCheckFutures = _runningProcesses.values
        .map((ApplicationProcess process) => _performHealthCheck(process))
        .toList();

    await Future.wait(healthCheckFutures);
  }

  /// Loads launch configuration for the specified application.
  ///
  /// Creates configuration for web applications by locating the application's
  /// HTML file in the apps directory and creating a file:// URL.
  Future<ApplicationLaunchConfig> _loadLaunchConfiguration(
    UserApplication application,
  ) async {
    try {
      // Import the app config to get the apps directory
      final Directory appsDirectory = await _getAppsDirectory();

      // Look for the application directory
      final List<FileSystemEntity> entries = appsDirectory.listSync(followLinks: false);

      String? applicationPath;
      for (final FileSystemEntity entity in entries) {
        if (entity is Directory) {
          // Check if this directory contains a manifest for our application
          final File manifestFile = File('${entity.path}/manifest.json');
          if (manifestFile.existsSync()) {
            try {
              final String manifestContent = await manifestFile.readAsString();
              final Map<String, dynamic> manifest = json.decode(manifestContent) as Map<String, dynamic>;

              if (manifest['id'] == application.id) {
                applicationPath = entity.path;
                break;
              }
            } catch (e) {
              // Skip invalid manifest files
              continue;
            }
          }
        }
      }

      if (applicationPath == null) {
        throw LaunchException(
          'Application directory not found for ${application.id}',
          'APP_NOT_FOUND',
        );
      }

      // Look for index.html in the application directory
      final File indexFile = File('$applicationPath/index.html');
      if (!indexFile.existsSync()) {
        throw LaunchException(
          'Application index.html not found for ${application.id}',
          'INDEX_NOT_FOUND',
        );
      }

      // Create file:// URL for the HTML file
      final String fileUrl = 'file://${indexFile.absolute.path}';

      debugPrint('Application ${application.id} will be loaded from: $fileUrl');

      return ApplicationLaunchConfig(
        applicationType: ApplicationType.web,
        url: fileUrl,
        windowTitle: application.title,
        initialWidth: 1200,
        initialHeight: 800,
        resizable: true,
        showNavigationControls: false, // Disable navigation for local files
        enableJavaScript: true,
        enableLocalStorage: true,
      );
    } catch (e) {
      debugPrint('Failed to load launch configuration for ${application.id}: $e');
      rethrow;
    }
  }

  /// Gets the apps directory using the same logic as the UserApplicationService.
  ///
  /// This ensures consistency in how we locate application files.
  Future<Directory> _getAppsDirectory() async {
    // Import path_provider for getting application support directory
    final Directory supportDir = await getApplicationSupportDirectory();
    final Directory vendorDir = Directory('${supportDir.path}/HouseholdAI');
    final Directory appsDir = Directory('${vendorDir.path}/apps');

    return appsDir;
  }

  /// Loads saved window state for the specified application.
  ///
  /// Retrieves previously saved window position, size, and other state
  /// information from shared preferences for restoration.
  Future<WindowState?> _loadWindowState(String applicationId) async {
    try {
      final String? stateJson = _preferences.getString('window_state_$applicationId');
      if (stateJson == null) {
        return null;
      }

      final Map<String, dynamic> stateMap = json.decode(stateJson) as Map<String, dynamic>;
      return WindowState.fromJson(stateMap);
    } catch (e) {
      debugPrint('Failed to load window state for $applicationId: $e');
      return null;
    }
  }

  /// Saves current window state for the specified application process.
  ///
  /// Persists window position, size, and other state information
  /// to shared preferences for future restoration.
  Future<void> _saveWindowState(ApplicationProcess process) async {
    try {
      if (process.windowState != null) {
        final String stateJson = json.encode(process.windowState!.toJson());
        await _preferences.setString('window_state_${process.applicationId}', stateJson);
        debugPrint('Saved window state for ${process.applicationId}');
      }
    } catch (e) {
      debugPrint('Failed to save window state for ${process.applicationId}: $e');
    }
  }

  /// Starts the application process with the specified configuration.
  ///
  /// Creates the appropriate runtime environment for the application
  /// based on its type (currently only web applications are supported).
  Future<void> _startApplicationProcess(ApplicationProcess process) async {
    debugPrint('Starting application process: ${process.applicationTitle}');

    switch (process.launchConfig.applicationType) {
      case ApplicationType.web:
        await _startWebApplication(process);
        break;
      case ApplicationType.desktop:
        throw LaunchException(
          'Desktop applications are not yet supported',
          'UNSUPPORTED_TYPE',
        );
    }

    // Mark process as running
    process.markAsRunning();
  }

  /// Starts a web application using WebView integration.
  ///
  /// Creates the WebView component and configures it with the appropriate
  /// settings for the application including navigation controls and security.
  Future<void> _startWebApplication(ApplicationProcess process) async {
    debugPrint('Starting web application: ${process.launchConfig.url}');

    // Validate URL is accessible
    await _validateApplicationUrl(process.launchConfig.url);

    // Web applications are handled by the WebView widget in the UI
    // The actual WebView creation happens in the UI layer
    debugPrint('Web application validated and ready: ${process.applicationTitle}');
  }

  /// Validates that the application URL is accessible.
  ///
  /// For file:// URLs, checks that the file exists and is readable.
  /// For http:// URLs, performs a health check to ensure availability.
  Future<void> _validateApplicationUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);

      if (uri.scheme == 'file') {
        // For file URLs, check that the file exists and is readable
        final File file = File(uri.toFilePath());

        if (!file.existsSync()) {
          throw LaunchException(
            'Application file does not exist: ${uri.toFilePath()}',
            'FILE_NOT_FOUND',
          );
        }

        // Try to read the file to ensure it's accessible
        await file.readAsString();
        debugPrint('Application file is accessible: $url');
      } else if (uri.scheme == 'http' || uri.scheme == 'https') {
        // For HTTP URLs, perform the original health check
        final http.Response response = await _httpClient
            .get(
              uri,
              headers: {'User-Agent': 'HouseholdAI-Dashboard/1.0'},
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode >= 200 && response.statusCode < 400) {
          debugPrint('Application URL is accessible: $url');
        } else {
          throw LaunchException(
            'Application URL returned status ${response.statusCode}',
            'URL_NOT_ACCESSIBLE',
          );
        }
      } else {
        throw LaunchException(
          'Unsupported URL scheme: ${uri.scheme}',
          'UNSUPPORTED_SCHEME',
        );
      }
    } catch (e) {
      if (e is LaunchException) {
        rethrow;
      }
      throw LaunchException(
        'Failed to validate application URL: $e',
        'URL_VALIDATION_FAILED',
      );
    }
  }

  /// Stops the specified application process.
  ///
  /// Gracefully shuts down the application and cleans up resources.
  Future<void> _stopApplicationProcess(ApplicationProcess process) async {
    debugPrint('Stopping application process: ${process.applicationTitle}');

    // Mark process as stopped
    process.markAsStopped();

    // For web applications, the WebView cleanup happens in the UI layer
    debugPrint('Application process stopped: ${process.applicationTitle}');
  }

  /// Brings the specified application to the foreground.
  ///
  /// Makes the application window active and visible to the user.
  Future<void> _bringToForeground(ApplicationProcess process) async {
    debugPrint('Bringing application to foreground: ${process.applicationTitle}');

    // Update last accessed time
    process.updateLastAccessed();

    // For web applications, window management happens in the UI layer
    debugPrint('Application brought to foreground: ${process.applicationTitle}');
  }

  /// Performs a health check on the specified application process.
  ///
  /// Verifies the application is still responsive and updates its status.
  Future<void> _performHealthCheck(ApplicationProcess process) async {
    try {
      // Skip health check if process was recently accessed
      if (process.timeSinceLastAccess.inMinutes < 5) {
        return;
      }

      debugPrint('Performing health check: ${process.applicationTitle}');

      // For web applications, check if the URL is still accessible
      if (process.launchConfig.applicationType == ApplicationType.web) {
        await _validateApplicationUrl(process.launchConfig.url);
      }

      // Update health check timestamp
      process.updateHealthCheck(healthy: true);
    } catch (e) {
      debugPrint('Health check failed for ${process.applicationTitle}: $e');

      // Mark as unhealthy
      process.updateHealthCheck(healthy: false, error: e.toString());

      // Emit health check failure event
      final LaunchResult result = LaunchResult.healthCheckFailed(
        applicationId: process.applicationId,
        error: e.toString(),
      );
      _launchEventsController.add(result);
    }
  }

  /// Starts the periodic health check timer.
  ///
  /// Schedules regular health checks for all running applications
  /// to ensure they remain responsive and available.
  void _startHealthCheckTimer() {
    _healthCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => performHealthChecks(),
    );
  }

  /// Disposes of resources used by this service.
  ///
  /// Stops all running applications, cancels timers, and closes streams.
  /// Should be called when the service is no longer needed.
  Future<void> dispose() async {
    debugPrint('Disposing application launcher service');

    // Stop health check timer
    _healthCheckTimer?.cancel();

    // Stop all running applications
    final List<Future<void>> stopFutures = _runningProcesses.keys
        .map((String applicationId) => stopApplication(applicationId))
        .toList();
    await Future.wait(stopFutures);

    // Close stream controller
    await _launchEventsController.close();

    // Close HTTP client
    _httpClient.close();

    debugPrint('Application launcher service disposed');
  }
}

/// Exception thrown when application launch fails.
///
/// Provides structured error information including error codes
/// for programmatic handling and user-friendly messages.
class LaunchException implements Exception {
  /// Human-readable error message.
  final String message;

  /// Error code for programmatic handling.
  final String code;

  /// Creates a new launch exception.
  const LaunchException(this.message, this.code);

  @override
  String toString() => 'LaunchException($code): $message';
}
