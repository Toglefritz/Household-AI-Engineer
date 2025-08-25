import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import 'models/user_application.dart';

/// Service for managing household applications through the file system.
///
/// Each user application created by this system exists in a directory within the
/// apps/ directory. Each of these user application directories contains a "manifest"
/// JSON file that contains metadata about the application.
///
/// This service provides a unified interface for loading, creating, and managing
/// user applications stored in the local file system. It handles reading the manifest
/// files for user applications and returning the user application metadata from
/// these JSON files. It also handles the creation of new user applications, the
/// modification of existing user applications, and the deletion of user applications.
class UserApplicationService {
  /// Directory where per-app manifests (`*.json`) are stored.
  ///
  /// Delegates to the shared configuration service to avoid coupling
  /// with other services that need the same path.
  static Future<Directory> get appsDir => AppConfig.appsDirectory;

  /// Stream controller for broadcasting application updates.
  final StreamController<List<UserApplication>> _applicationUpdatesController =
      StreamController<List<UserApplication>>.broadcast();

  /// Loads all available [UserApplication]s from local manifests.
  ///
  /// This method reads the JSON manifest files for all current user applications. Each of
  /// these JSON files is used to create a [UserApplication] object. The resulting list
  /// of user applications is returned.
  ///
  /// Returns applications sorted by update time (newest first) for optimal user experience.
  Future<List<UserApplication>> _loadApplications() async {
    try {
      // Load local manifest files for deployed applications
      final List<UserApplication> localApplications = await _loadLocalApplications();

      final List<UserApplication> applications = localApplications
        // Sort newest updated first for a pleasant dashboard experience
        ..sort(
          (UserApplication a, UserApplication b) => b.updatedAt.compareTo(a.updatedAt),
        );

      // Return the sorted list of applications.
      return applications;
    } catch (e) {
      // If bridge communication fails, fall back to local manifests only
      return _loadLocalApplications();
    }
  }

  /// Watches for application changes through the file system.
  ///
  /// This method monitors the local file system for changes in the apps/ directory
  /// and all subdirectories. When user applications are added, removed, or modified,
  /// including changes to manifest.json files, this [Stream] returns the updated
  /// user applications list.
  ///
  /// The watcher responds to:
  /// * New application directories being created
  /// * Application directories being removed
  /// * Changes to manifest.json files (development progress updates)
  /// * Any other relevant file changes within application directories
  ///
  /// Consumers receive updated application lists automatically without manual refresh.
  Stream<List<UserApplication>> watchApplications({
    Duration debounce = const Duration(milliseconds: 150),
    Duration pollInterval = const Duration(seconds: 30),
  }) async* {
    // Initial emission
    final List<UserApplication> initial = await _loadApplications();
    yield initial;

    // Set up file system watcher for local changes
    await _setupFileSystemWatcher(debounce);

    // Yield from the application updates stream
    yield* _applicationUpdatesController.stream;
  }

  /// Manually refreshes the application list and notifies listeners.
  ///
  /// This method can be called to force a refresh of the application list
  /// without waiting for file system events. Useful for:
  /// * Manual refresh buttons in the UI
  /// * Recovering from file system watcher failures
  /// * Initial loading when file system events might be missed
  ///
  /// Returns the updated list of applications for immediate use.
  Future<List<UserApplication>> refreshApplications() async {
    final List<UserApplication> apps = await _loadApplications();
    _applicationUpdatesController.add(apps);

    return apps;
  }

  /// Loads applications from local manifest files.
  ///
  /// Reads manifest.json files from subdirectories within the apps directory
  /// and parses them into UserApplication objects. Each user application
  /// exists in its own subdirectory containing a manifest.json file.
  Future<List<UserApplication>> _loadLocalApplications() async {
    // Resolve the base apps/ directory.
    final Directory appsDirectory = await AppConfig.appsDirectory;

    debugPrint(
      'Getting user applications from directory, ${appsDirectory.path}',
    );

    // Check that the directory exists.
    final bool exists = appsDirectory.existsSync();
    if (!exists) {
      debugPrint('Apps directory does not exist: ${appsDirectory.path}');
      return <UserApplication>[];
    }

    final List<UserApplication> applications = <UserApplication>[];

    // Iterate through each subdirectory in the apps directory
    final List<FileSystemEntity> entries = appsDirectory.listSync(
      followLinks: false,
    );
    debugPrint('Found ${entries.length} entries in apps directory');

    for (final FileSystemEntity entity in entries) {
      // Skip if not a directory - each app should be in its own folder
      if (entity is! Directory) {
        debugPrint('Skipping non-directory: ${entity.path}');
        continue;
      }
      final Directory appDirectory = entity;
      debugPrint('Checking app directory: ${appDirectory.path}');

      // Look for manifest.json file within this app directory
      final File manifestFile = File('${appDirectory.path}/manifest.json');

      // Skip if manifest.json doesn't exist in this directory
      if (!manifestFile.existsSync()) {
        debugPrint('No manifest.json found in: ${appDirectory.path}');
        continue;
      }

      debugPrint('Found manifest.json in: ${appDirectory.path}');

      // Attempt to read and parse the manifest file
      final UserApplication? parsed = await _readManifest(manifestFile);
      if (parsed != null) {
        applications.add(parsed);
        debugPrint('Successfully loaded application: ${parsed.title}');
      } else {
        debugPrint('Failed to parse manifest in ${appDirectory.path}');
      }
    }

    debugPrint('Loaded ${applications.length} applications total');
    return applications;
  }

  /// Sets up file system watcher for local manifest changes.
  ///
  /// Monitors the apps directory and all application subdirectories for changes.
  /// This includes watching for:
  /// * New application directories being created or removed
  /// * Changes to manifest.json files within application directories
  /// * Any other file changes that might affect application state
  ///
  /// The watcher uses recursive monitoring to detect changes at any level
  /// within the application directory structure.
  Future<void> _setupFileSystemWatcher(Duration debounce) async {
    // Resolve the base apps/ directory.
    final Directory appsDirectory = await AppConfig.appsDirectory;

    // Check that the directory exists.
    final bool exists = appsDirectory.existsSync();
    if (!exists) return;

    // Set up recursive watching for the entire apps directory tree
    final Stream<FileSystemEvent> raw = appsDirectory.watch(recursive: true);
    Timer? timer;

    // Add a listener for all file system changes within the apps directory
    raw.listen((FileSystemEvent event) {
      // Only trigger updates for relevant file changes
      if (_shouldTriggerUpdate(event)) {
        timer?.cancel();
        timer = Timer(debounce, () async {
          final List<UserApplication> apps = await _loadApplications();
          _applicationUpdatesController.add(apps);
        });
      }
    });
  }

  /// Determines whether a file system event should trigger an application update.
  ///
  /// This method filters file system events to only respond to changes that
  /// could affect the application list or individual application state.
  ///
  /// Triggers updates for:
  /// * Changes to manifest.json files (development progress updates)
  /// * Directory creation/deletion (new apps or app removal)
  /// * Any changes within application directories
  ///
  /// Ignores:
  /// * Temporary files and system files
  /// * Non-manifest JSON files that don't affect application state
  bool _shouldTriggerUpdate(FileSystemEvent event) {
    final String path = event.path;

    debugPrint('File system event: ${event.type} at $path');

    // Always trigger for directory changes (app creation/deletion)
    if (event.type == FileSystemEvent.create || event.type == FileSystemEvent.delete) {
      debugPrint('Triggering update for directory change: $path');

      return true;
    }

    // Trigger for manifest.json file changes
    if (path.endsWith('manifest.json')) {
      debugPrint('Triggering update for manifest.json change: $path');
      return true;
    }

    // Trigger for any changes within application directories
    // This catches cases where files are moved or renamed
    if (path.contains('/') && !path.endsWith('.tmp') && !path.contains('.DS_Store')) {
      debugPrint('Triggering update for file change in app directory: $path');

      return true;
    }

    debugPrint('Ignoring file system event: $path');

    // Ignore other file changes (temporary files, system files, etc.)
    return false;
  }

  /// Attempts to read and parse a single manifest file into a
  /// [UserApplication]. Returns `null` if the file is unreadable or invalid.
  ///
  /// This method handles various error conditions gracefully:
  /// * File I/O errors (permissions, file not found, etc.)
  /// * JSON parsing errors (malformed JSON syntax)
  /// * Model validation errors (missing required fields, invalid data types)
  ///
  /// All errors are logged for debugging purposes but do not prevent
  /// the application from continuing to load other valid manifests.
  Future<UserApplication?> _readManifest(File file) async {
    try {
      // Read the manifest JSON file
      final String contents = await file.readAsString();
      final Map<String, dynamic> jsonMap = json.decode(contents) as Map<String, dynamic>;

      // Convert the JSON to a UserApplication object
      final UserApplication app = UserApplication.fromJson(jsonMap);

      debugPrint('Successfully loaded application: ${app.title} (${app.id})');
      return app;
    } on FormatException catch (e) {
      debugPrint('Failed to parse JSON in manifest file ${file.path}: $e');
      // Malformed JSON or model validation: skip this manifest.
      return null;
    } on FileSystemException catch (e) {
      debugPrint('Failed to read manifest file ${file.path}: $e');
      // File I/O error: skip this manifest.
      return null;
    } on Object catch (e) {
      debugPrint('Unexpected error reading manifest file ${file.path}: $e');
      // Any other error: skip this manifest.
      return null;
    }
  }

  /// Creates a new folder under the apps/ directory for the user application to be created.
  ///
  /// Each user application exists in a separate folder within the *apps/* directory to keep
  /// applications compartmentalized. This method creates a uniquely named folder (random
  /// lowercase alphanumeric id) and returns its absolute path.
  /// Creates a new folder under the apps/ directory for the user application to be created.
  ///
  /// Each user application exists in a separate folder within the *apps/* directory to keep
  /// applications compartmentalized. This method creates a uniquely named folder (random
  /// lowercase alphanumeric id) and returns its absolute path.
  Future<String> createNewApplicationDirectory() async {
    // Resolve the base apps/ directory.
    final Directory appsDirectory = await AppConfig.appsDirectory;

    // Generate a unique folder name.
    String id;
    Directory newDir;
    do {
      id = _generateRandomId();
      newDir = Directory('${appsDirectory.path}/$id');
    } while (newDir.existsSync());

    // Create the directory.
    await newDir.create(recursive: true);

    // Return the absolute path for convenience.
    return newDir.absolute.path;
  }

  /// Generates a random lowercase alphanumeric identifier of the given [length].
  String _generateRandomId([int length = 6]) {
    // Create a list of characters from which the random identifier will be created
    const String chars = 'abcdefghijklmnopqrstuvwxyz0123456789';

    // Build a random string from the list of characters.
    final Random rng = Random.secure();
    final StringBuffer buf = StringBuffer();
    for (int i = 0; i < length; i++) {
      buf.write(chars[rng.nextInt(chars.length)]);
    }

    // Return the random identifier.
    return buf.toString();
  }

  /// Modifies an existing application through the Kiro Bridge.
  ///
  /// Sends a request to modify an existing application based on the user's
  /// modification description. The application will be updated and may enter
  /// a development state if significant changes are required.
  Future<UserApplication> modifyApplication({
    required String applicationId,
    required String modifications,
    String? conversationId,
  }) async {
    // TODO(Scott): Implementation
    throw UnimplementedError();
  }

  /// Updates the favorite status of an application.
  ///
  /// Modifies the manifest.json file to set the isFavorite field
  /// and triggers a refresh of the application list.
  ///
  /// @param applicationId The ID of the application to update
  /// @param isFavorite Whether the application should be marked as favorite
  Future<void> updateFavoriteStatus(String applicationId, bool isFavorite) async {
    debugPrint('Updating favorite status for application: $applicationId to $isFavorite');

    try {
      // Find the application directory and manifest file
      final Directory appsDirectory = await AppConfig.appsDirectory;
      final List<FileSystemEntity> entries = appsDirectory.listSync(
        followLinks: false,
      );

      for (final FileSystemEntity entity in entries) {
        if (entity is! Directory) continue;

        final Directory appDirectory = entity;
        final File manifestFile = File('${appDirectory.path}/manifest.json');

        if (!manifestFile.existsSync()) continue;

        // Read the current manifest
        final UserApplication? app = await _readManifest(manifestFile);
        if (app != null && app.id == applicationId) {
          // Update the application with new favorite status
          final UserApplication updatedApp = app.copyWith(
            isFavorite: isFavorite,
            updatedAt: DateTime.now(),
          );

          // Write the updated manifest back to the file
          final String updatedJson = json.encode(updatedApp.toJson());
          await manifestFile.writeAsString(updatedJson);

          debugPrint('Successfully updated favorite status for application: ${app.title}');

          // Trigger a refresh to notify listeners
          await refreshApplications();
          return;
        }
      }

      // If we get here, the application was not found
      throw Exception('Application not found: $applicationId');
    } catch (e) {
      debugPrint('Failed to update favorite status for application $applicationId: $e');
      rethrow;
    }
  }

  /// Deletes an application through the file system.
  ///
  /// Removes the application directory and all associated files.
  /// This operation cannot be undone.
  ///
  /// @param applicationId The ID of the application to delete
  Future<void> deleteApplication(String applicationId) async {
    debugPrint('Deleting application: $applicationId');

    try {
      // Find the application directory
      final Directory appsDirectory = await AppConfig.appsDirectory;
      final List<FileSystemEntity> entries = appsDirectory.listSync(
        followLinks: false,
      );

      for (final FileSystemEntity entity in entries) {
        if (entity is! Directory) continue;

        final Directory appDirectory = entity;
        final File manifestFile = File('${appDirectory.path}/manifest.json');

        if (!manifestFile.existsSync()) continue;

        // Read the manifest to check if this is the application to delete
        final UserApplication? app = await _readManifest(manifestFile);
        if (app != null && app.id == applicationId) {
          // Delete the entire application directory
          await appDirectory.delete(recursive: true);
          debugPrint('Successfully deleted application directory: ${appDirectory.path}');
          return;
        }
      }

      // If we get here, the application was not found
      throw Exception('Application not found: $applicationId');
    } catch (e) {
      debugPrint('Failed to delete application $applicationId: $e');
      rethrow;
    }
  }

  /// Launches an application through the application launcher service.
  ///
  /// Starts the specified application and returns launch information.
  /// The application must be in a ready state to be launched.
  Future<void> launchApplication(String applicationId) async {
    debugPrint('Launching application: $applicationId');

    // Get the application to launch
    final UserApplication? application = await getApplicationById(
      applicationId,
    );
    if (application == null) {
      throw Exception('Application not found: $applicationId');
    }

    // Validate application can be launched
    if (!application.canLaunch) {
      throw Exception(
        'Application cannot be launched in current state: ${application.status.name}',
      );
    }

    // For now, we'll simulate launching by updating the status to running
    // In a real implementation, this would integrate with the Kiro Bridge
    // to actually start the application process
    debugPrint('Application launch simulated for: ${application.title}');

    // The actual launch will be handled by the ApplicationLauncherService
    // when it's integrated into the dashboard controller
  }

  /// Gets a specific application by its ID.
  ///
  /// This method loads the current application list and returns the application
  /// with the matching ID. Returns null if no application with the given ID exists.
  ///
  /// This is useful for:
  /// * Refreshing individual application data
  /// * Checking current status of a specific application
  /// * Validating application existence before operations
  Future<UserApplication?> getApplicationById(String applicationId) async {
    final List<UserApplication> applications = await _loadApplications();
    try {
      return applications.firstWhere(
        (UserApplication app) => app.id == applicationId,
      );
    } catch (e) {
      // No application found with the given ID
      return null;
    }
  }

  /// Gets the current list of applications without setting up watchers.
  ///
  /// This method provides a one-time snapshot of the current application state
  /// without establishing ongoing file system monitoring. Useful for:
  /// * One-time data retrieval
  /// * Testing and debugging
  /// * Situations where streaming updates are not needed
  Future<List<UserApplication>> getApplications() async {
    return _loadApplications();
  }

  /// Disposes of resources used by this service.
  ///
  /// Closes the stream controller and cleans up any active file system watchers.
  /// Should be called when the service is no longer needed to prevent memory leaks.
  void dispose() {
    _applicationUpdatesController.close();
  }
}
