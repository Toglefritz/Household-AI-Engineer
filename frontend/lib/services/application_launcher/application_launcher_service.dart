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

/// Internal class for tracking index.html search results.
///
/// This class encapsulates the results of searching for index.html files
/// across multiple potential locations, including successful finds,
/// all searched paths, and any access errors encountered during the search.
class _IndexSearchResult {
  /// The full path to the found index.html file, or null if not found.
  ///
  /// When not null, this path can be used directly to create the file:// URL
  /// for launching the application. The path is absolute and verified to exist.
  final String? foundPath;

  /// List of all paths that were searched during the discovery process.
  ///
  /// Includes both successful and unsuccessful search locations.
  /// Used for comprehensive error reporting when no index.html is found.
  final List<String> searchedPaths;

  /// List of access errors encountered during the search process.
  ///
  /// Contains error messages for paths that could not be accessed due to
  /// permission issues or other file system errors. Used for debugging
  /// and detailed error reporting.
  final List<String> accessErrors;

  /// Creates a new index search result.
  ///
  /// @param searchedPaths All paths that were searched during discovery
  /// @param accessErrors Any access errors encountered during the search
  /// @param foundPath The path where index.html was found, or null if not found
  const _IndexSearchResult({
    required this.searchedPaths,
    required this.accessErrors,
    this.foundPath,
  });

  /// Whether index.html was successfully found.
  ///
  /// Returns true if [foundPath] is not null, indicating that a valid
  /// index.html file was located and is accessible.
  bool get found => foundPath != null;

  /// Whether any access errors occurred during the search.
  ///
  /// Returns true if any paths could not be accessed due to permission
  /// issues or other file system errors.
  bool get hasAccessErrors => accessErrors.isNotEmpty;
}

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
  /// Static list of search paths for index.html locations.
  ///
  /// These paths are searched in priority order when the main index.html
  /// file is not found in the application root directory. The search
  /// follows common web application directory structures.
  static const List<String> _indexSearchPaths = [
    'index.html', // Root level - highest priority
    'src/index.html', // Source directory
    'public/index.html', // Public assets directory
    'dist/index.html', // Distribution/build output
    'build/index.html', // Alternative build output
  ];

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
    debugPrint(
      'Launching application: ${application.title} (${application.id})',
    );

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
        debugPrint(
          'Application already running, bringing to foreground: ${application.title}',
        );
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

      // Enhanced error logging for LaunchException with detailed context
      if (e is LaunchException) {
        debugPrint('=== Launch Exception Details ===');
        debugPrint('Error Code: ${e.code}');
        debugPrint('Error Message: ${e.message}');

        if (e.hasSearchContext) {
          debugPrint('Searched Paths (${e.searchedPaths!.length}):');
          for (int i = 0; i < e.searchedPaths!.length; i++) {
            debugPrint('  ${i + 1}. ${e.searchedPaths![i]}');
          }
        }

        if (e.hasAccessErrors) {
          debugPrint('Access Errors (${e.accessErrors!.length}):');
          for (int i = 0; i < e.accessErrors!.length; i++) {
            debugPrint('  ${i + 1}. ${e.accessErrors![i]}');
          }
        }

        if (e.context.isNotEmpty) {
          debugPrint('Additional Context:');
          e.context.forEach((String key, dynamic value) {
            debugPrint('  $key: $value');
          });
        }

        if (e.cause != null) {
          debugPrint('Underlying Cause: ${e.cause}');
        }

        debugPrint('=== End Launch Exception Details ===');
      }

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
      await Future<void>.delayed(const Duration(milliseconds: 500));
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

    debugPrint(
      'Performing health checks on ${_runningProcesses.length} running applications',
    );

    final List<Future<void>> healthCheckFutures = _runningProcesses.values.map(_performHealthCheck).toList();

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
      final List<FileSystemEntity> entries = appsDirectory.listSync(
        followLinks: false,
      );

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

      // Search for index.html in common locations
      final _IndexSearchResult searchResult = await _findIndexHtml(applicationPath);

      if (!searchResult.found) {
        // Use the enhanced LaunchException factory for comprehensive error reporting
        throw LaunchException.fileNotFound(
          applicationId: application.id,
          searchedPaths: searchResult.searchedPaths,
          accessErrors: searchResult.hasAccessErrors ? searchResult.accessErrors : null,
        );
      }

      // Create file:// URL for the found HTML file
      final File indexFile = File(searchResult.foundPath!);
      final String fileUrl = 'file://${indexFile.absolute.path}';

      debugPrint('Using index.html from: ${searchResult.foundPath}');

      debugPrint('Application ${application.id} will be loaded from: $fileUrl');

      return ApplicationLaunchConfig(
        applicationType: ApplicationType.web,
        url: fileUrl,
        windowTitle: application.title,
        showNavigationControls: false, // Disable navigation for local files
      );
    } catch (e) {
      debugPrint('=== Launch Configuration Error ===');
      debugPrint('Application ID: ${application.id}');
      debugPrint('Application Title: ${application.title}');
      debugPrint('Error Type: ${e.runtimeType}');
      debugPrint('Error Details: $e');

      if (e is LaunchException) {
        debugPrint('Launch Exception Code: ${e.code}');
        if (e.hasSearchContext) {
          debugPrint('This error includes search context with ${e.searchedPaths!.length} searched paths');
        }
        if (e.hasAccessErrors) {
          debugPrint('This error includes ${e.accessErrors!.length} access errors');
        }
      }

      debugPrint('=== End Launch Configuration Error ===');
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

  /// Searches for index.html in common locations within the application directory.
  ///
  /// This method implements a sequential search through predefined locations
  /// where web applications commonly place their main HTML files. The search
  /// follows priority order with root level having highest priority.
  ///
  /// The search process:
  /// 1. Iterates through each path in [_indexSearchPaths]
  /// 2. Constructs full file path by joining application path with search path
  /// 3. Validates file existence and accessibility
  /// 4. Returns first valid index.html file found
  /// 5. Collects all searched paths and access errors for comprehensive reporting
  ///
  /// Enhanced error handling includes:
  /// * Graceful handling of permission denied errors
  /// * Detailed logging of each search attempt and outcome
  /// * Comprehensive collection of access errors for debugging
  /// * Proper categorization of different error types
  /// * Symbolic link resolution and validation
  /// * Inaccessible directory handling with graceful degradation
  /// * Multiple index.html file handling with priority order
  /// * Robust file system I/O exception handling
  ///
  /// Edge cases handled:
  /// * Symbolic links in application directories are followed and validated
  /// * Inaccessible directories are skipped with error logging
  /// * Multiple index.html files use first-found priority order
  /// * File system I/O exceptions are caught and categorized appropriately
  ///
  /// @param applicationPath The root directory path of the application
  /// @returns [_IndexSearchResult] containing the search outcome and details
  Future<_IndexSearchResult> _findIndexHtml(String applicationPath) async {
    final List<String> searchedPaths = <String>[];
    final List<String> accessErrors = <String>[];
    final DateTime searchStartTime = DateTime.now();

    debugPrint('=== Starting index.html search ===');
    debugPrint('Application path: $applicationPath');
    debugPrint('Search paths to check: ${_indexSearchPaths.length}');

    // Log all paths that will be searched
    for (int i = 0; i < _indexSearchPaths.length; i++) {
      debugPrint(
        '  ${i + 1}. ${_indexSearchPaths[i]} (priority: ${i == 0
            ? 'highest'
            : i == _indexSearchPaths.length - 1
            ? 'lowest'
            : 'medium'})',
      );
    }

    for (int i = 0; i < _indexSearchPaths.length; i++) {
      final String searchPath = _indexSearchPaths[i];
      final String fullPath = '$applicationPath/$searchPath';
      searchedPaths.add(fullPath);

      debugPrint('--- Search attempt ${i + 1}/${_indexSearchPaths.length} ---');
      debugPrint('Checking path: $fullPath');

      try {
        // Handle edge case: Check if the directory containing the file is accessible
        final String directoryPath = fullPath.substring(0, fullPath.lastIndexOf('/'));
        final Directory containingDirectory = Directory(directoryPath);

        // Edge case handling: Gracefully handle inaccessible directories
        if (!await _isDirectoryAccessible(containingDirectory)) {
          final String errorDetail = 'Directory inaccessible or does not exist: $directoryPath';
          accessErrors.add('$fullPath: $errorDetail');
          debugPrint('Directory access error: $errorDetail');
          debugPrint('Skipping this location and continuing search...');
          continue;
        }

        // Edge case handling: Resolve symbolic links if present
        final String resolvedPath = await _resolveSymbolicLinks(fullPath);
        if (resolvedPath != fullPath) {
          debugPrint('Symbolic link detected: $fullPath -> $resolvedPath');
          searchedPaths.add('$resolvedPath (resolved from $fullPath)');
        }

        // Validate the index file at this location (using resolved path)
        await _validateIndexFile(resolvedPath);

        final Duration searchDuration = DateTime.now().difference(searchStartTime);
        debugPrint('=== Search successful ===');
        debugPrint('Found valid index.html at: $resolvedPath');
        if (resolvedPath != fullPath) {
          debugPrint('Original path (symbolic link): $fullPath');
        }
        debugPrint('Search completed in ${searchDuration.inMilliseconds}ms after ${i + 1} attempts');
        debugPrint('Final result: SUCCESS');

        // Edge case handling: Return the resolved path for actual file access
        return _IndexSearchResult(
          foundPath: resolvedPath,
          searchedPaths: searchedPaths,
          accessErrors: accessErrors,
        );
      } on LaunchException catch (e) {
        debugPrint('LaunchException at $fullPath: ${e.code} - ${e.message}');

        // Categorize and collect different types of errors
        if (e.code == 'FILE_ACCESS_DENIED' || e.code == 'FILE_SYSTEM_ERROR') {
          final String errorDetail = 'Permission/access error: ${e.message}';
          accessErrors.add('$fullPath: $errorDetail');
          debugPrint('Access error recorded: $errorDetail');
        } else if (e.code == 'INVALID_FILE_CONTENT') {
          final String errorDetail = 'Invalid content: ${e.message}';
          accessErrors.add('$fullPath: $errorDetail');
          debugPrint('Content validation error recorded: $errorDetail');
        } else if (e.code == 'FILE_NOT_FOUND') {
          debugPrint('File not found (expected for most paths): $fullPath');
        } else if (e.code == 'SYMBOLIC_LINK_ERROR') {
          final String errorDetail = 'Symbolic link error: ${e.message}';
          accessErrors.add('$fullPath: $errorDetail');
          debugPrint('Symbolic link error recorded: $errorDetail');
        } else {
          final String errorDetail = 'Unexpected error: ${e.message}';
          accessErrors.add('$fullPath: $errorDetail');
          debugPrint('Unexpected error recorded: $errorDetail');
        }

        // Continue searching other locations
        debugPrint('Continuing search to next location...');
        continue;
      } catch (e) {
        // Handle any unexpected non-LaunchException errors with enhanced categorization
        final String errorDetail = _categorizeUnexpectedError(e, fullPath);
        accessErrors.add('$fullPath: $errorDetail');
        debugPrint('Unexpected system error at $fullPath: $e');
        debugPrint('Error recorded and continuing search...');
        continue;
      }
    }

    final Duration searchDuration = DateTime.now().difference(searchStartTime);
    debugPrint('=== Search completed unsuccessfully ===');
    debugPrint('No valid index.html found after searching ${searchedPaths.length} locations');
    debugPrint('Total search time: ${searchDuration.inMilliseconds}ms');
    debugPrint('Access errors encountered: ${accessErrors.length}');

    if (accessErrors.isNotEmpty) {
      debugPrint('Access error summary:');
      for (int i = 0; i < accessErrors.length; i++) {
        debugPrint('  ${i + 1}. ${accessErrors[i]}');
      }
    }

    debugPrint('Final result: FAILURE - No valid index.html found');

    return _IndexSearchResult(
      searchedPaths: searchedPaths,
      accessErrors: accessErrors,
    );
  }

  /// Validates that the index.html file exists and is readable.
  ///
  /// This method performs comprehensive validation of an index.html file:
  /// 1. Checks file existence using File.existsSync()
  /// 2. Attempts to read file content to verify accessibility
  /// 3. Performs basic content validation to ensure it's a valid HTML file
  /// 4. Provides detailed error reporting with specific error types
  ///
  /// @param filePath The full path to the index.html file to validate
  /// @throws [LaunchException] with specific error codes for different failure modes:
  ///   - FILE_NOT_FOUND: File does not exist at the specified path
  ///   - FILE_ACCESS_DENIED: File exists but cannot be read (permission issues)
  ///   - INVALID_FILE_CONTENT: File exists but does not contain valid HTML content
  Future<void> _validateIndexFile(String filePath) async {
    debugPrint('Validating index file: $filePath');

    final File indexFile = File(filePath);

    // Check if file exists
    if (!indexFile.existsSync()) {
      debugPrint('Index file does not exist: $filePath');
      throw const LaunchException(
        'Index file does not exist',
        'FILE_NOT_FOUND',
      );
    }

    debugPrint('Index file exists, checking accessibility: $filePath');

    try {
      // Attempt to read the file to verify accessibility
      final String content = await indexFile.readAsString();
      debugPrint('Successfully read index file (${content.length} characters): $filePath');

      // Basic validation: ensure it contains HTML content
      if (content.trim().isEmpty) {
        debugPrint('Index file is empty: $filePath');
        throw LaunchException.invalidFile(
          filePath: filePath,
          expectedType: 'HTML',
          cause: 'File is empty',
        );
      }

      // Check for basic HTML structure (case-insensitive)
      final String lowerContent = content.toLowerCase();
      if (!lowerContent.contains('<html') && !lowerContent.contains('<!doctype')) {
        debugPrint('Index file does not contain valid HTML structure: $filePath');
        throw LaunchException.invalidFile(
          filePath: filePath,
          expectedType: 'HTML',
          cause: 'Missing HTML or DOCTYPE declaration',
        );
      }

      debugPrint('Index file validation successful: $filePath');
    } on FileSystemException catch (e) {
      // Handle specific file system errors with detailed context
      debugPrint('File system error accessing index file: $filePath - $e');

      if (e.osError?.errorCode == 13 || e.message.toLowerCase().contains('permission')) {
        // Permission denied error
        throw LaunchException.fileAccessDenied(
          filePath: filePath,
          cause: e,
        );
      } else {
        // Other file system errors
        throw LaunchException(
          'File system error accessing index file: ${e.message}',
          'FILE_SYSTEM_ERROR',
          cause: e,
          context: {
            'filePath': filePath,
            'osErrorCode': e.osError?.errorCode,
            'osErrorMessage': e.osError?.message,
          },
        );
      }
    } catch (e) {
      if (e is LaunchException) {
        rethrow;
      }

      // Handle other unexpected errors during file access
      debugPrint('Unexpected error validating index file: $filePath - $e');
      throw LaunchException.fileAccessDenied(
        filePath: filePath,
        cause: e,
      );
    }
  }

  /// Checks if a directory is accessible for file system operations.
  ///
  /// This method performs comprehensive accessibility checks for directories:
  /// 1. Verifies directory existence
  /// 2. Attempts to list directory contents to verify read permissions
  /// 3. Handles various file system errors gracefully
  /// 4. Provides detailed logging for debugging purposes
  ///
  /// Edge cases handled:
  /// * Non-existent directories return false without throwing
  /// * Permission denied errors are caught and logged
  /// * Symbolic links to directories are followed and validated
  /// * Network file system timeouts are handled gracefully
  ///
  /// @param directory The directory to check for accessibility
  /// @returns True if the directory exists and is accessible, false otherwise
  Future<bool> _isDirectoryAccessible(Directory directory) async {
    final String directoryPath = directory.path;
    debugPrint('Checking directory accessibility: $directoryPath');

    try {
      // Check if directory exists
      if (!directory.existsSync()) {
        debugPrint('Directory does not exist: $directoryPath');
        return false;
      }

      // Attempt to list directory contents to verify read permissions
      // Use a timeout to handle network file systems or slow storage
      final List<FileSystemEntity> contents = await directory
          .list(followLinks: false)
          .toList()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException(
              'Directory listing timeout',
              const Duration(seconds: 5),
            ),
          );

      debugPrint('Directory is accessible with ${contents.length} entries: $directoryPath');
      return true;
    } on FileSystemException catch (e) {
      debugPrint('File system error accessing directory: $directoryPath - ${e.message}');

      // Log specific error types for debugging
      if (e.osError?.errorCode == 13) {
        debugPrint('Permission denied for directory: $directoryPath');
      } else if (e.osError?.errorCode == 2) {
        debugPrint('Directory not found: $directoryPath');
      } else {
        debugPrint('Other file system error (code ${e.osError?.errorCode}): $directoryPath');
      }

      return false;
    } on TimeoutException catch (e) {
      debugPrint('Timeout accessing directory: $directoryPath - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error accessing directory: $directoryPath - $e');
      return false;
    }
  }

  /// Resolves symbolic links to their target paths.
  ///
  /// This method handles symbolic link resolution with comprehensive error handling:
  /// 1. Checks if the path is a symbolic link
  /// 2. Resolves the link to its ultimate target
  /// 3. Validates that the target exists and is accessible
  /// 4. Handles circular references and broken links gracefully
  ///
  /// Edge cases handled:
  /// * Circular symbolic link references are detected and reported
  /// * Broken symbolic links (pointing to non-existent targets) are handled
  /// * Multiple levels of symbolic links are resolved recursively
  /// * Permission errors during link resolution are caught and reported
  ///
  /// @param filePath The file path that may be a symbolic link
  /// @returns The resolved path if it's a symbolic link, or the original path if not
  /// @throws [LaunchException] with SYMBOLIC_LINK_ERROR code for link resolution failures
  Future<String> _resolveSymbolicLinks(String filePath) async {
    debugPrint('Checking for symbolic links: $filePath');

    try {
      final Link link = Link(filePath);

      // Check if this is a symbolic link
      if (!link.existsSync()) {
        debugPrint('Not a symbolic link: $filePath');
        return filePath;
      }

      debugPrint('Symbolic link detected, resolving: $filePath');

      // Resolve the symbolic link with circular reference protection
      final String resolvedPath = await _resolveSymbolicLinkRecursive(
        filePath,
        <String>{}, // Set to track visited paths for circular reference detection
        0, // Recursion depth counter
      );

      debugPrint('Symbolic link resolved: $filePath -> $resolvedPath');

      // Verify that the resolved target exists
      final File resolvedFile = File(resolvedPath);
      if (!resolvedFile.existsSync()) {
        debugPrint('Symbolic link target does not exist: $resolvedPath');
        throw LaunchException(
          'Symbolic link points to non-existent file: $filePath -> $resolvedPath',
          'SYMBOLIC_LINK_ERROR',
          context: {
            'originalPath': filePath,
            'resolvedPath': resolvedPath,
            'errorType': 'broken_link',
          },
        );
      }

      return resolvedPath;
    } on FileSystemException catch (e) {
      debugPrint('File system error resolving symbolic link: $filePath - ${e.message}');
      throw LaunchException(
        'Failed to resolve symbolic link due to file system error: ${e.message}',
        'SYMBOLIC_LINK_ERROR',
        cause: e,
        context: {
          'filePath': filePath,
          'osErrorCode': e.osError?.errorCode,
          'osErrorMessage': e.osError?.message,
        },
      );
    } catch (e) {
      if (e is LaunchException) {
        rethrow;
      }

      debugPrint('Unexpected error resolving symbolic link: $filePath - $e');
      throw LaunchException(
        'Unexpected error resolving symbolic link: $e',
        'SYMBOLIC_LINK_ERROR',
        cause: e,
        context: {
          'filePath': filePath,
          'errorType': 'unexpected_error',
        },
      );
    }
  }

  /// Recursively resolves symbolic links with circular reference protection.
  ///
  /// This helper method provides safe recursive resolution of symbolic links:
  /// 1. Tracks visited paths to detect circular references
  /// 2. Limits recursion depth to prevent infinite loops
  /// 3. Resolves multiple levels of symbolic links
  /// 4. Provides detailed error reporting for resolution failures
  ///
  /// @param currentPath The current path being resolved
  /// @param visitedPaths Set of paths already visited (for circular detection)
  /// @param depth Current recursion depth
  /// @returns The final resolved path
  /// @throws [LaunchException] for circular references or excessive recursion
  Future<String> _resolveSymbolicLinkRecursive(
    String currentPath,
    Set<String> visitedPaths,
    int depth,
  ) async {
    // Prevent excessive recursion (max 10 levels of symbolic links)
    if (depth > 10) {
      throw LaunchException(
        'Symbolic link resolution exceeded maximum depth (10 levels): $currentPath',
        'SYMBOLIC_LINK_ERROR',
        context: {
          'currentPath': currentPath,
          'depth': depth,
          'errorType': 'excessive_recursion',
        },
      );
    }

    // Check for circular references
    if (visitedPaths.contains(currentPath)) {
      throw LaunchException(
        'Circular symbolic link reference detected: $currentPath',
        'SYMBOLIC_LINK_ERROR',
        context: {
          'currentPath': currentPath,
          'visitedPaths': visitedPaths.toList(),
          'errorType': 'circular_reference',
        },
      );
    }

    // Add current path to visited set
    visitedPaths.add(currentPath);

    final Link link = Link(currentPath);

    try {
      // Get the target of this symbolic link
      final String target = await link.target();
      debugPrint('Symbolic link level $depth: $currentPath -> $target');

      // If target is relative, resolve it relative to the link's directory
      final String resolvedTarget;
      if (target.startsWith('/')) {
        // Absolute path
        resolvedTarget = target;
      } else {
        // Relative path - resolve relative to the link's directory
        final String linkDirectory = currentPath.substring(0, currentPath.lastIndexOf('/'));
        resolvedTarget = '$linkDirectory/$target';
      }

      // Check if the target is also a symbolic link
      final Link targetLink = Link(resolvedTarget);
      if (targetLink.existsSync()) {
        // Target is also a symbolic link, resolve recursively
        return _resolveSymbolicLinkRecursive(resolvedTarget, visitedPaths, depth + 1);
      } else {
        // Target is not a symbolic link, return the resolved path
        return resolvedTarget;
      }
    } on FileSystemException catch (e) {
      throw LaunchException(
        'Failed to read symbolic link target: ${e.message}',
        'SYMBOLIC_LINK_ERROR',
        cause: e,
        context: {
          'currentPath': currentPath,
          'depth': depth,
          'osErrorCode': e.osError?.errorCode,
        },
      );
    }
  }

  /// Categorizes unexpected errors for better error reporting and debugging.
  ///
  /// This method analyzes unexpected exceptions and provides meaningful
  /// categorization for error reporting and logging purposes:
  /// 1. Identifies common error patterns and types
  /// 2. Provides user-friendly error descriptions
  /// 3. Includes technical details for debugging
  /// 4. Suggests potential resolution approaches
  ///
  /// @param error The unexpected error that occurred
  /// @param filePath The file path where the error occurred
  /// @returns A categorized error description suitable for logging and user feedback
  String _categorizeUnexpectedError(Object error, String filePath) {
    final String errorType = error.runtimeType.toString();
    final String errorMessage = error.toString();

    // Categorize based on error type and message patterns
    if (error is ArgumentError) {
      return 'Invalid argument error: $errorMessage';
    } else if (error is StateError) {
      return 'Invalid state error: $errorMessage';
    } else if (error is FormatException) {
      return 'Data format error: $errorMessage';
    } else if (error is TimeoutException) {
      return 'Operation timeout: $errorMessage';
    } else if (errorMessage.toLowerCase().contains('permission')) {
      return 'Permission-related error: $errorMessage';
    } else if (errorMessage.toLowerCase().contains('network')) {
      return 'Network-related error: $errorMessage';
    } else if (errorMessage.toLowerCase().contains('memory')) {
      return 'Memory-related error: $errorMessage';
    } else if (errorMessage.toLowerCase().contains('disk') || errorMessage.toLowerCase().contains('storage')) {
      return 'Storage-related error: $errorMessage';
    } else {
      return 'Unexpected system error ($errorType): $errorMessage';
    }
  }

  /// Loads saved window state for the specified application.
  ///
  /// Retrieves previously saved window position, size, and other state
  /// information from shared preferences for restoration.
  Future<WindowState?> _loadWindowState(String applicationId) async {
    try {
      final String? stateJson = _preferences.getString(
        'window_state_$applicationId',
      );
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
        await _preferences.setString(
          'window_state_${process.applicationId}',
          stateJson,
        );
        debugPrint('Saved window state for ${process.applicationId}');
      }
    } catch (e) {
      debugPrint(
        'Failed to save window state for ${process.applicationId}: $e',
      );
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
      case ApplicationType.desktop:
        throw const LaunchException(
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
    debugPrint(
      'Web application validated and ready: ${process.applicationTitle}',
    );
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
            context: {
              'filePath': uri.toFilePath(),
              'url': url,
              'validationType': 'file_existence',
            },
          );
        }

        // Try to read the file to ensure it's accessible
        try {
          await file.readAsString();
          debugPrint('Application file is accessible: $url');
        } on FileSystemException catch (e) {
          debugPrint('File system error accessing application file: $url - $e');
          throw LaunchException.fileAccessDenied(
            filePath: uri.toFilePath(),
            cause: e,
          );
        }
      } else if (uri.scheme == 'http' || uri.scheme == 'https') {
        // For HTTP URLs, perform the original health check
        final http.Response response = await _httpClient
            .get(
              uri,
              headers: {'User-Agent': 'HouseholdAI-Dashboard/1.0'},
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode >= 200 && response.statusCode < 400) {
          debugPrint('Application URL is accessible: $url (status: ${response.statusCode})');
        } else {
          debugPrint('Application URL returned error status: $url (status: ${response.statusCode})');
          throw LaunchException(
            'Application URL returned status ${response.statusCode}: $url\n\n'
                'The application server may be down or the URL may be incorrect. '
                'Please check the application status and try again.',
            'URL_NOT_ACCESSIBLE',
            context: {
              'url': url,
              'statusCode': response.statusCode,
              'responseHeaders': response.headers,
              'validationType': 'http_health_check',
            },
          );
        }
      } else {
        debugPrint('Unsupported URL scheme encountered: ${uri.scheme} for URL: $url');
        throw LaunchException(
          'Unsupported URL scheme: ${uri.scheme}\n\n'
              'Only file://, http://, and https:// URLs are supported for application launching.',
          'UNSUPPORTED_SCHEME',
          context: {
            'url': url,
            'scheme': uri.scheme,
            'supportedSchemes': ['file', 'http', 'https'],
          },
        );
      }
    } on LaunchException {
      // Re-throw LaunchExceptions without modification
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error during URL validation: $url - $e');
      throw LaunchException(
        'Failed to validate application URL due to unexpected error: $e\n\n'
            'This may be due to network connectivity issues or system configuration problems.',
        'URL_VALIDATION_FAILED',
        cause: e,
        context: {
          'url': url,
          'errorType': e.runtimeType.toString(),
        },
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
    debugPrint(
      'Bringing application to foreground: ${process.applicationTitle}',
    );

    // Update last accessed time
    process.updateLastAccessed();

    // For web applications, window management happens in the UI layer
    debugPrint(
      'Application brought to foreground: ${process.applicationTitle}',
    );
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
    final List<Future<void>> stopFutures = _runningProcesses.keys.map(stopApplication).toList();
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
/// for programmatic handling, user-friendly messages, and detailed
/// context about the failure including searched paths and access errors.
class LaunchException implements Exception {
  /// Human-readable error message suitable for display to users.
  ///
  /// This message should be clear, actionable, and free of technical jargon.
  /// It should guide users toward resolution when possible.
  final String message;

  /// Unique error code for programmatic error handling.
  ///
  /// Format: "CATEGORY_SPECIFIC" (e.g., "INDEX_NOT_FOUND", "FILE_NOT_ACCESSIBLE")
  /// Used by error tracking systems and automated recovery logic.
  final String code;

  /// List of file paths that were searched during the operation.
  ///
  /// Provides complete context about where the system looked for files,
  /// enabling comprehensive error reporting and debugging. Particularly
  /// useful for index.html fallback search operations.
  final List<String>? searchedPaths;

  /// List of access errors encountered during file system operations.
  ///
  /// Contains detailed error messages for paths that could not be accessed
  /// due to permission issues, file system errors, or other I/O problems.
  /// Used for debugging and detailed error reporting.
  final List<String>? accessErrors;

  /// Optional underlying cause of this error.
  ///
  /// When this error wraps another exception, the original exception
  /// is preserved here for debugging and logging purposes.
  final Object? cause;

  /// Additional context information for debugging and error analysis.
  ///
  /// May include application IDs, user IDs, timestamps, file paths,
  /// or other relevant data that helps with troubleshooting.
  final Map<String, dynamic> context;

  /// Creates a new launch exception with comprehensive error information.
  ///
  /// @param message User-friendly error description
  /// @param code Unique error identifier for programmatic handling
  /// @param searchedPaths Optional list of paths that were searched
  /// @param accessErrors Optional list of access errors encountered
  /// @param cause Optional underlying exception that caused this error
  /// @param context Additional debugging information
  const LaunchException(
    this.message,
    this.code, {
    this.searchedPaths,
    this.accessErrors,
    this.cause,
    this.context = const {},
  });

  /// Creates a launch exception for file not found scenarios.
  ///
  /// Specifically designed for index.html search failures, this factory
  /// constructor creates comprehensive error messages that list all
  /// searched locations and any access errors encountered.
  ///
  /// @param applicationId ID of the application that failed to launch
  /// @param searchedPaths All paths that were searched for the file
  /// @param accessErrors Any access errors encountered during search
  /// @returns LaunchException with detailed file not found information
  factory LaunchException.fileNotFound({
    required String applicationId,
    required List<String> searchedPaths,
    List<String>? accessErrors,
  }) {
    final StringBuffer errorMessage = StringBuffer()
      ..writeln('Application index.html not found for $applicationId.')
      ..writeln('Searched locations:');

    for (final String searchedPath in searchedPaths) {
      errorMessage.writeln('- $searchedPath');
    }

    if (accessErrors != null && accessErrors.isNotEmpty) {
      errorMessage.writeln('\nAccess errors encountered:');
      for (final String accessError in accessErrors) {
        errorMessage.writeln('- $accessError');
      }
    }

    errorMessage.writeln('\nPlease ensure your application has an index.html file in one of these locations.');

    return LaunchException(
      errorMessage.toString().trim(),
      'INDEX_NOT_FOUND',
      searchedPaths: searchedPaths,
      accessErrors: accessErrors,
      context: {
        'applicationId': applicationId,
        'searchCount': searchedPaths.length,
        'accessErrorCount': accessErrors?.length ?? 0,
      },
    );
  }

  /// Creates a launch exception for file access permission errors.
  ///
  /// Used when a file exists but cannot be accessed due to permission
  /// restrictions or other file system security constraints.
  ///
  /// @param filePath The path to the file that could not be accessed
  /// @param cause The underlying exception that caused the access failure
  /// @returns LaunchException with file access error information
  factory LaunchException.fileAccessDenied({
    required String filePath,
    Object? cause,
  }) {
    return LaunchException(
      'Cannot access file due to permission restrictions: $filePath\n\n'
          'Please check that the application has read permissions for this file '
          'and that the file is not locked by another process.',
      'FILE_ACCESS_DENIED',
      cause: cause,
      context: {
        'filePath': filePath,
        'errorType': 'permission_denied',
      },
    );
  }

  /// Creates a launch exception for invalid or corrupted files.
  ///
  /// Used when a file exists and is accessible but does not contain
  /// valid content for the expected file type.
  ///
  /// @param filePath The path to the invalid file
  /// @param expectedType Description of what type of content was expected
  /// @param cause The underlying validation error
  /// @returns LaunchException with file validation error information
  factory LaunchException.invalidFile({
    required String filePath,
    required String expectedType,
    Object? cause,
  }) {
    return LaunchException(
      'File exists but does not contain valid $expectedType content: $filePath\n\n'
          'Please ensure the file contains properly formatted $expectedType data.',
      'INVALID_FILE_CONTENT',
      cause: cause,
      context: {
        'filePath': filePath,
        'expectedType': expectedType,
        'errorType': 'invalid_content',
      },
    );
  }

  /// Creates a launch exception for symbolic link resolution errors.
  ///
  /// Used when symbolic links cannot be resolved due to circular references,
  /// broken links, or other symbolic link-related issues.
  ///
  /// @param filePath The path to the symbolic link that failed to resolve
  /// @param errorType The specific type of symbolic link error
  /// @param cause The underlying exception that caused the resolution failure
  /// @returns LaunchException with symbolic link error information
  factory LaunchException.symbolicLinkError({
    required String filePath,
    required String errorType,
    Object? cause,
  }) {
    String message;
    switch (errorType) {
      case 'circular_reference':
        message =
            'Circular symbolic link reference detected: $filePath\n\n'
            'The symbolic link chain contains a loop that prevents resolution.';
      case 'broken_link':
        message =
            'Symbolic link points to non-existent target: $filePath\n\n'
            'The symbolic link target does not exist or is inaccessible.';
      case 'excessive_recursion':
        message =
            'Symbolic link chain too deep: $filePath\n\n'
            'The symbolic link chain exceeds the maximum resolution depth.';
      default:
        message =
            'Failed to resolve symbolic link: $filePath\n\n'
            'An error occurred while following the symbolic link.';
    }

    return LaunchException(
      message,
      'SYMBOLIC_LINK_ERROR',
      cause: cause,
      context: {
        'filePath': filePath,
        'errorType': errorType,
        'category': 'symbolic_link',
      },
    );
  }

  /// Whether this exception includes information about searched paths.
  ///
  /// Returns true if the exception contains details about file system
  /// search operations, indicating this was likely a file discovery failure.
  bool get hasSearchContext => searchedPaths != null && searchedPaths!.isNotEmpty;

  /// Whether this exception includes information about access errors.
  ///
  /// Returns true if the exception contains details about file system
  /// access failures, indicating permission or I/O issues were encountered.
  bool get hasAccessErrors => accessErrors != null && accessErrors!.isNotEmpty;

  /// Returns a comprehensive error report including all available context.
  ///
  /// Provides detailed information suitable for logging, debugging, and
  /// technical support. Includes searched paths, access errors, and
  /// additional context information.
  String get detailedReport {
    final StringBuffer report = StringBuffer()
      ..writeln('LaunchException Details:')
      ..writeln('Code: $code')
      ..writeln('Message: $message');

    if (hasSearchContext) {
      report.writeln('\nSearched Paths (${searchedPaths!.length}):');
      for (int i = 0; i < searchedPaths!.length; i++) {
        report.writeln('  ${i + 1}. ${searchedPaths![i]}');
      }
    }

    if (hasAccessErrors) {
      report.writeln('\nAccess Errors (${accessErrors!.length}):');
      for (int i = 0; i < accessErrors!.length; i++) {
        report.writeln('  ${i + 1}. ${accessErrors![i]}');
      }
    }

    if (context.isNotEmpty) {
      report.writeln('\nAdditional Context:');
      context.forEach((String key, dynamic value) {
        report.writeln('  $key: $value');
      });
    }

    if (cause != null) {
      report
        ..writeln('\nUnderlying Cause:')
        ..writeln('  $cause');
    }

    return report.toString().trim();
  }

  @override
  String toString() => 'LaunchException($code): $message';
}
