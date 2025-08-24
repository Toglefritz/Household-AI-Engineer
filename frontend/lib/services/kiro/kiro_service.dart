import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../config/app_config.dart';
import '../user_application/user_application_service.dart';
import 'models/kiro_status.dart';

/// Service for communicating with the Kiro IDE through the communication bridge.
///
/// This service provides a focused interface for sending requests to the Kiro IDE
/// and receiving responses through the REST API endpoints provided by the
/// kiro-communication-bridge extension. It handles connection management,
/// request/response cycles, and status monitoring.
///
/// The service is designed to be lightweight and focused solely on communication
/// with Kiro, without knowledge of application management or conversation flow.
class KiroService {
  /// A service used to manage user applications.
  final UserApplicationService _applicationService = UserApplicationService();

  /// Base URL for the Kiro Bridge REST API.
  static String get _baseUrl => AppConfig.kiroBridgeBaseUrl;

  /// HTTP client for making requests to the bridge.
  final HttpClient _httpClient = HttpClient();

  /// Whether the service is currently connected to the Kiro Bridge.
  bool _isConnected = false;

  /// Stream controller for broadcasting Kiro status updates.
  final StreamController<KiroStatus> _statusController =
      StreamController<KiroStatus>.broadcast();

  /// Whether the service is currently connected to the Kiro Bridge.
  bool get isConnected => _isConnected;

  /// Stream of Kiro status updates.
  ///
  /// Emits status changes when Kiro becomes available, unavailable,
  /// or when its operational state changes.
  Stream<KiroStatus> get statusUpdates => _statusController.stream;

  /// Checks if the Kiro Bridge is available and responsive.
  ///
  /// Makes a simple GET request to the status endpoint to verify connectivity.
  /// Updates the internal connection state based on the response.
  ///
  /// Returns `true` if the bridge is available and responsive.
  Future<bool> checkAvailability() async {
    try {
      final Uri statusUri = Uri.parse('$_baseUrl/api/kiro/status');
      final HttpClientRequest request = await _httpClient.getUrl(statusUri);
      final HttpClientResponse response = await request.close();

      final bool wasConnected = _isConnected;
      _isConnected = response.statusCode == 200;

      // Emit status update if connection state changed
      if (wasConnected != _isConnected) {
        _statusController.add(
          _isConnected ? KiroStatus.available : KiroStatus.unavailable,
        );
      }

      return _isConnected;
    } catch (e) {
      final bool wasConnected = _isConnected;
      _isConnected = false;

      // Emit status update if we were previously connected
      if (wasConnected) {
        _statusController.add(KiroStatus.unavailable);
      }

      return false;
    }
  }

  /// Sets up the Kiro IDE for creating a new user application.
  ///
  /// This performs a three-step bootstrap:
  /// 1. **Create** a new, uniquely-named folder inside the apps/ directory.
  /// 2. **Create** the `.kiro/specs/user-application-template/` structure and copy
  ///    the three template Markdown files (design.md, requirements.md, tasks.md).
  /// 3. **Launch** the Kiro IDE pointing at the new folder and wait until the
  ///    Kiro Bridge becomes available.
  ///
  /// Throws a [FileSystemException] if the template files cannot be found or copied,
  /// and a [StateError] if the Kiro Bridge does not become available in time.
  Future<void> setupKiroForNewApplication() async {
    // Step 1: Create a new folder for the application.
    final String newAppPath = await _applicationService
        .createNewApplicationDirectory();
    final Directory newAppDir = Directory(newAppPath);

    // Step 2: Create the .kiro directory structure and copy template files.
    await _createKiroSpecStructure(newAppDir);

    // Step 2.5: Copy the manifest schema and template.
    await _copyManifestSchema(newAppDir);
    await _copyManifestTemplate(newAppDir);

    // Step 3: Open Kiro into the new application directory and wait for readiness.
    await _openKiroInAppsDir(newAppDir);
  }

  /// Creates the `.kiro/specs/user-application-template/` directory structure
  /// and copies the three template Markdown files from assets.
  ///
  /// This project involves the creation of bespoke applications on behalf of the user.
  /// These applications are created by the Kiro IDE, an agentic AI system. To guide
  /// the application creation process, three template files are provided:
  /// - design.md: Architecture and implementation approach
  /// - requirements.md: Functional requirements and acceptance criteria
  /// - tasks.md: Step-by-step implementation plan
  ///
  /// These files are stored as Flutter assets and copied to each new application
  /// directory to provide Kiro with the necessary context and guidance.
  Future<void> _createKiroSpecStructure(Directory destination) async {
    // Create the .kiro/specs/user-application-template/ directory structure
    final Directory kiroDir = Directory('${destination.path}/.kiro');
    final Directory specsDir = Directory('${kiroDir.path}/specs');
    final Directory templateDir = Directory(
      '${specsDir.path}/user-application-template',
    );

    // Ensure the directory structure exists
    await templateDir.create(recursive: true);

    // Define the three template files to copy
    final List<String> templateFiles = [
      'design.md',
      'requirements.md',
      'tasks.md',
    ];

    // Copy each template file from assets to the new directory
    for (final String fileName in templateFiles) {
      final String assetPath =
          'assets/templates/kiro/specs/user-application-template/$fileName';

      try {
        // Load the file content from assets
        final String content = await rootBundle.loadString(assetPath);

        // Write the content to the destination file
        final File destinationFile = File('${templateDir.path}/$fileName');
        await destinationFile.writeAsString(content, flush: true);
      } catch (e) {
        debugPrint(
          'Failed to copy template file $fileName from assets with exception, $e',
        );

        throw FileSystemException(
          'Failed to copy template file $fileName from assets with exception, $e',
          assetPath,
        );
      }
    }
  }

  /// Copies the manifest schema and creates initial manifest files.
  ///
  /// This method loads the `manifest_schema.json` from Flutter assets and writes it as `manifest_schema.json`
  /// (template for Kiro reference).
  ///
  ///
  /// Throws a [FileSystemException] if the asset cannot be loaded or written.
  Future<void> _copyManifestSchema(Directory destination) async {
    const String manifestSchemaAssetPath =
        'assets/templates/manifest/manifest_schema.json';

    try {
      // Load the schema content
      final String schemaContent = await rootBundle.loadString(
        manifestSchemaAssetPath,
      );

      // Write the schema file for Kiro reference
      final File exampleFileSchema = File(
        '${destination.path}/manifest_schema.json',
      );
      await exampleFileSchema.writeAsString(schemaContent, flush: true);
    } catch (e) {
      throw FileSystemException(
        'Failed to copy manifest schema from assets with exception, $e',
        manifestSchemaAssetPath,
      );
    }
  }

  /// Copies the manifest template and creates initial manifest files.
  ///
  /// This method loads the `manifest_example.json` from Flutter assets and writes it as `manifest_example.json`
  /// (template for Kiro reference).
  ///
  /// Throws a [FileSystemException] if the asset cannot be loaded or written.
  Future<void> _copyManifestTemplate(Directory destination) async {
    const String exampleManifestAssetPath =
        'assets/templates/manifest/manifest_example.json';

    try {
      // Load the template content and schema
      final String templateContent = await rootBundle.loadString(
        exampleManifestAssetPath,
      );

      // Write the example file for Kiro reference
      final File exampleFile = File(
        '${destination.path}/manifest_example.json',
      );
      await exampleFile.writeAsString(templateContent, flush: true);
    } catch (e) {
      throw FileSystemException(
        'Failed to copy manifest template from assets with exception, $e',
        exampleManifestAssetPath,
      );
    }
  }

  /// Launches the Kiro IDE with [targetDir] as the working directory and waits
  /// for the Kiro Bridge to become available before returning.
  Future<ProcessResult> _openKiroInAppsDir(Directory targetDir) async {
    debugPrint('Opening Kiro IDE in path, ${targetDir.path}');

    ProcessResult result;

    if (Platform.isMacOS) {
      // Launch Kiro and ask it to open the folder as a *document*.
      result = await Process.run(
        'open',
        ['-a', 'Kiro', targetDir.path],
      );

      if (result.exitCode != 0) {
        throw Exception(
          'Opening Kiro IDE in project directory failed with exit code, ${result.exitCode}',
        );
      }
    } else {
      throw UnsupportedError('Unsupported platform for opening Kiro IDE');
    }

    // Wait for the Kiro communication bridge extension to be available
    await _waitForKiroBridgeAvailable();

    return result;
  }

  /// Closes the Kiro IDE process gracefully.
  ///
  /// This method attempts to terminate the Kiro IDE process by running a platform-appropriate
  /// system command. On macOS and Linux, it uses `pkill -f kiro` to kill the process.
  ///
  /// After executing the command, it resets the internal connection state to indicate
  /// that the Kiro Bridge is no longer connected.
  ///
  /// Returns a [ProcessResult] representing the result of the kill command.
  Future<ProcessResult> closeKiro() async {
    // Close Kiro using a command appropriate for the current platform
    ProcessResult result;
    if (Platform.isMacOS || Platform.isLinux) {
      result = await Process.run('pkill', ['-f', 'kiro']);
    } else if (Platform.isWindows) {
      result = await Process.run('taskkill', ['/IM', 'kiro.exe', '/F']);
    } else {
      throw UnsupportedError('Unsupported platform for closing Kiro IDE');
    }

    // Reset the connection state
    _isConnected = false;

    return result;
  }

  /// Waits for the Kiro Bridge REST API to become available by polling the `/api/kiro/status` endpoint.
  ///
  /// This method repeatedly attempts to connect to the bridge status endpoint until a successful
  /// response (HTTP 200) is received or the specified [timeout] duration elapses.
  ///
  /// The polling interval between attempts is controlled by [pollInterval].
  ///
  /// Throws a [StateError] if the bridge does not become available within the timeout.
  ///
  /// Returns `true` if the bridge becomes available within the timeout.
  Future<bool> _waitForKiroBridgeAvailable({
    Duration? timeout,
    Duration? pollInterval,
  }) async {
    final Duration actualTimeout = timeout ?? AppConfig.kiroBridgeTimeout;
    final Duration actualPollInterval =
        pollInterval ?? AppConfig.kiroBridgePollInterval;
    final Uri statusUri = Uri.parse('$_baseUrl/api/kiro/status');
    final DateTime deadline = DateTime.now().add(actualTimeout);
    final HttpClient client = HttpClient();

    while (DateTime.now().isBefore(deadline)) {
      try {
        final HttpClientRequest request = await client.getUrl(statusUri);
        final HttpClientResponse response = await request.close();

        if (response.statusCode == 200) {
          client.close(force: true);

          // Set the flag to indicate that the Kiro IDE is running
          _isConnected = true;

          return true;
        }
      } catch (_) {
        // Ignore errors and continue polling until timeout.
      }

      await Future<void>.delayed(actualPollInterval);
    }

    client.close(force: true);

    throw StateError('Timed out waiting for Kiro Bridge to become available.');
  }

  /// Sends a message to Kiro and returns the response.
  ///
  /// This is a basic request/response method that will be expanded
  /// as the communication protocol is developed incrementally.
  ///
  /// @param message The message content to send to Kiro
  /// @returns The response from Kiro as a string
  /// @throws [StateError] if not connected to the bridge
  /// @throws [HttpException] if the request fails
  Future<void> sendMessage(String message) async {
    debugPrint('Sending user message to Kiro IDE');

    if (!_isConnected) {
      throw StateError('Not connected to Kiro Bridge');
    }

    final Uri uri = Uri.parse('$_baseUrl/api/kiro/execute');

    // Assemble the payload using the kiroAgent.sendMainUserInput command.
    final Map<String, Object?> payload = <String, Object?>{
      'command': 'kiroAgent.sendMainUserInput',
      'args': <String?>[message],
    };

    // Create the request to the Kiro communication bridge
    final HttpClientRequest request = await _httpClient.postUrl(uri);
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    request.add(utf8.encode(jsonEncode(payload)));

    // Get a response from the bridge.
    final HttpClientResponse response = await request.close();

    // Parse the response
    final String body = await response.transform(utf8.decoder).join();

    if (response.statusCode != 200) {
      debugPrint(
        'Sending message to Kiro IDE failed with status code, ${response.statusCode}',
      );

      throw HttpException('HTTP ${response.statusCode}: $body', uri: uri);
    }

    // TODO(Scott): process the result according to the data it contains
  }

  /// Disposes of resources used by this service.
  ///
  /// Closes HTTP connections and stream controllers.
  /// Should be called when the service is no longer needed.
  void dispose() {
    _httpClient.close();
    _statusController.close();
  }
}
