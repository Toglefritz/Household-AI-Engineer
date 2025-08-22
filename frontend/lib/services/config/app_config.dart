import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Configuration service for application-wide settings and paths.
///
/// This service provides centralized access to configuration values that
/// are shared across multiple services, preventing coupling between services
/// that need the same configuration data.
///
/// The service handles path resolution, environment-specific settings,
/// and other configuration concerns that multiple services might need.
///
/// Path resolution now follows Apple's recommended Application Support location,
/// with no user customization included.
class AppConfig {
  /// Private constructor to prevent instantiation.
  const AppConfig._();

  static Directory? _cachedAppsDirectory;

  /// Returns a stable, writable apps directory under Application Support.
  ///
  /// On macOS, this resolves to something like:
  ///   ~/Library/Application Support/HouseholdAI/apps
  /// The directory is created if it does not already exist.
  static Future<Directory> get appsDirectory async {
    _cachedAppsDirectory ??= await ensureAppsDirectory();

    return _cachedAppsDirectory!;
  }

  /// Ensures the apps directory exists under Application Support and returns it.
  static Future<Directory> ensureAppsDirectory() async {
    // Get the Application Support directory
    final Directory supportDir = await getApplicationSupportDirectory();
    final Directory vendorDir = Directory('${supportDir.path}/HouseholdAI');
    final Directory appsDir = Directory('${vendorDir.path}/apps');
    await appsDir.create(recursive: true);

    debugPrint('Resolved apps directory as ${appsDir.absolute}');

    return appsDir;
  }

  /// Base URL for the Kiro Bridge REST API.
  ///
  /// Centralized configuration for the bridge endpoint that multiple
  /// services may need to access.
  static const String kiroBridgeBaseUrl = 'http://localhost:3001';

  /// Default timeout for Kiro Bridge operations.
  ///
  /// Used by services that need to wait for Kiro Bridge availability
  /// or perform operations with timeouts.
  static const Duration kiroBridgeTimeout = Duration(seconds: 30);

  /// Default polling interval for checking Kiro Bridge status.
  ///
  /// Used by services that need to periodically check bridge availability
  /// or poll for updates.
  static const Duration kiroBridgePollInterval = Duration(milliseconds: 500);
}
