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

  /// Watches for application changes through both file system.
  ///
  /// This method monitors the local file system for changes in the apps/ directory.
  /// When a user applications is added, removed, or modified, this [Stream]
  /// returns the resulting user applications.
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

  /// Loads applications from local manifest files.
  ///
  /// Reads manifest.json files from subdirectories within the apps directory
  /// and parses them into UserApplication objects. Each user application
  /// exists in its own subdirectory containing a manifest.json file.
  Future<List<UserApplication>> _loadLocalApplications() async {
    // Resolve the base apps/ directory.
    final Directory appsDirectory = await AppConfig.appsDirectory;

    debugPrint('Getting user applications from directory, ${appsDirectory.path}');

    // Check that the directory exists.
    final bool exists = appsDirectory.existsSync();
    if (!exists) {
      return <UserApplication>[];
    }

    final List<UserApplication> applications = <UserApplication>[];

    // Iterate through each subdirectory in the apps directory
    final List<FileSystemEntity> entries = appsDirectory.listSync(followLinks: false);
    for (final FileSystemEntity entity in entries) {
      // Skip if not a directory - each app should be in its own folder
      if (entity is! Directory) continue;
      final Directory appDirectory = entity;

      // Look for manifest.json file within this app directory
      final File manifestFile = File('${appDirectory.path}/manifest.json');

      // Skip if manifest.json doesn't exist in this directory
      if (!manifestFile.existsSync()) continue;

      // Attempt to read and parse the manifest file
      final UserApplication? parsed = await _readManifest(manifestFile);
      if (parsed != null) {
        applications.add(parsed);
      }
    }

    return applications;
  }

  /// Sets up file system watcher for local manifest changes.
  ///
  /// Monitors the apps directory for changes and triggers application list updates
  /// when manifest files are added, modified, or removed.
  Future<void> _setupFileSystemWatcher(Duration debounce) async {
    // Resolve the base apps/ directory.
    final Directory appsDirectory = await AppConfig.appsDirectory;

    // Check that the directory exists.
    final bool exists = appsDirectory.existsSync();
    if (!exists) return;

    final Stream<FileSystemEvent> raw = appsDirectory.watch();
    Timer? timer;

    // Add a listener for local file system changes
    raw.listen((FileSystemEvent _) {
      timer?.cancel();
      timer = Timer(debounce, () async {
        final List<UserApplication> apps = await _loadApplications();
        _applicationUpdatesController.add(apps);
      });
    });
  }

  /// Attempts to read and parse a single manifest file into a
  /// [UserApplication]. Returns `null` if the file is unreadable or invalid.
  Future<UserApplication?> _readManifest(File file) async {
    try {
      // Read the manifest JSON file
      final String contents = await file.readAsString();
      final Map<String, dynamic> jsonMap = json.decode(contents) as Map<String, dynamic>;

      // Convert the JSON to a UserApplication object
      final UserApplication app = UserApplication.fromJson(jsonMap);

      return app;
    } on FormatException {
      debugPrint('Failed to read user application manifest with exception, $e');

      // Malformed JSON or model validation: skip this manifest.
      return null;
    } on Object {
      debugPrint('Failed to read user application manifest with exception, $e');

      // Any other I/O error: skip this manifest.
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

  /// Deletes an application through the Kiro Bridge.
  ///
  /// Removes the application from the system and cleans up associated resources.
  /// This operation cannot be undone.
  Future<void> deleteApplication(String applicationId) async {
    // TODO(Scott): Implementation
    throw UnimplementedError();
  }

  /// Launches an application through the Kiro Bridge.
  ///
  /// Starts the specified application and returns launch information.
  /// The application must be in a ready state to be launched.
  Future<void> launchApplication(String applicationId) async {
    // TODO(Scott): Implementation
    throw UnimplementedError();
  }

  /// Disposes of resources used by this service.
  void dispose() {
    _applicationUpdatesController.close();
  }
}
