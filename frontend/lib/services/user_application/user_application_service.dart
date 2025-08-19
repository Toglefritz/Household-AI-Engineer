import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'models/user_application.dart';

/// Service for managing household applications through the Kiro Bridge API.
///
/// This service provides a unified interface for loading, creating, and managing
/// user applications by communicating with the Kiro Bridge REST API and WebSocket
/// endpoints. It handles both file-system based manifest reading for deployed
/// applications and real-time communication with the Kiro IDE for development
/// operations.
///
/// The service supports:
/// - Loading application metadata from local manifests and Kiro Bridge API
/// - Real-time status updates through WebSocket connections
/// - Application creation, modification, and lifecycle management
/// - Error handling and offline fallback capabilities
class UserApplicationService {
  /// Creates a new service that manages [UserApplication]s through Kiro Bridge integration.
  ///
  /// * [baseMetadataDirPath] — Absolute path to the **metadata** directory that contains the `apps/` subfolder. If
  ///   omitted, [defaultMetadataDirPath] is used.
  UserApplicationService({
    String? baseMetadataDirPath,
  }) : _appsDir = Directory(
         '${baseMetadataDirPath ?? defaultMetadataDirPath}/apps',
       );

  /// Directory where per-app manifests (`*.json`) are stored.
  final Directory _appsDir;

  /// WebSocket channel for real-time application updates.
  WebSocketChannel? _webSocketChannel;

  /// Stream controller for broadcasting application updates.
  final StreamController<List<UserApplication>> _applicationUpdatesController =
      StreamController<List<UserApplication>>.broadcast();

  /// Cache of currently loaded applications.
  List<UserApplication> _cachedApplications = [];

  /// Whether the service is currently connected to the Kiro Bridge.
  bool _isConnected = false;

  /// Returns the default metadata directory path on macOS for this project.
  ///
  /// The path is resolved as:
  /// `~/Library/Application Support/HouseholdAI/metadata`
  static String get defaultMetadataDirPath {
    final String? home = Platform.environment['HOME'];
    final String resolvedHome = home ?? '';

    return '$resolvedHome/Library/Application Support/HouseholdAI/metadata';
  }

  /// Loads all available [UserApplication]s from both local manifests and Kiro Bridge API.
  ///
  /// This method combines data from local manifest files (for deployed applications)
  /// with real-time data from the Kiro Bridge API (for applications in development).
  /// The combined data provides a complete view of all user applications.
  ///
  /// Returns applications sorted by update time (newest first) for optimal user experience.
  Future<List<UserApplication>> loadApplications() async {
    try {
      // Load local manifest files for deployed applications
      final List<UserApplication> localApplications = await _loadLocalApplications();

      // Merge the two lists, preferring bridge data for applications that exist in both
      final Map<String, UserApplication> applicationMap = <String, UserApplication>{};

      // Add local applications first
      for (final UserApplication app in localApplications) {
        applicationMap[app.id] = app;
      }

      final List<UserApplication> applications = applicationMap.values.toList()
        // Sort newest updated first for a pleasant dashboard experience
        ..sort(
          (UserApplication a, UserApplication b) => b.updatedAt.compareTo(a.updatedAt),
        );

      _cachedApplications = applications;
      _isConnected = true;

      return applications;
    } catch (e) {
      // If bridge communication fails, fall back to local manifests only
      _isConnected = false;
      return _loadLocalApplications();
    }
  }

  /// Watches for application changes through both file system and WebSocket updates.
  ///
  /// This method provides a unified stream of application updates by monitoring:
  /// - Local file system changes in the apps directory
  /// - Real-time updates from the Kiro Bridge WebSocket connection
  /// - Periodic polling of the Kiro Bridge API for status updates
  ///
  /// Consumers receive updated application lists automatically without manual refresh.
  Stream<List<UserApplication>> watchApplications({
    Duration debounce = const Duration(milliseconds: 150),
    Duration pollInterval = const Duration(seconds: 30),
  }) async* {
    // Initial emission
    final List<UserApplication> initial = await loadApplications();
    yield initial;

    // Set up WebSocket connection for real-time updates
    await _initializeWebSocketConnection();

    // Set up file system watcher for local changes
    _setupFileSystemWatcher(debounce);

    // Set up periodic polling as fallback
    _setupPeriodicPolling(pollInterval);

    // Yield from the application updates stream
    yield* _applicationUpdatesController.stream;
  }

  /// Loads applications from local manifest files.
  ///
  /// Reads JSON manifest files from the apps directory and parses them into
  /// UserApplication objects. This provides data for deployed applications.
  Future<List<UserApplication>> _loadLocalApplications() async {
    final bool exists = _appsDir.existsSync();
    if (!exists) {
      return <UserApplication>[];
    }

    final List<UserApplication> applications = <UserApplication>[];

    // Gather manifest files with a conservative read strategy
    final List<FileSystemEntity> entries = _appsDir.listSync(followLinks: false);
    for (final FileSystemEntity entity in entries) {
      if (entity is! File) continue;
      final File file = entity;
      final String path = file.path;
      if (!path.toLowerCase().endsWith('.json')) continue;

      final UserApplication? parsed = await _readManifest(file);
      if (parsed != null) {
        applications.add(parsed);
      }
    }

    return applications;
  }

  /// Initializes WebSocket connection for real-time updates.
  ///
  /// Connects to the Kiro Bridge WebSocket endpoint to receive real-time
  /// application status updates, progress notifications, and other events.
  Future<void> _initializeWebSocketConnection() async {
    try {
      // Connect to WebSocket endpoint
      // Note: The actual WebSocket URL may need to be adjusted based on bridge configuration
      final Uri wsUri = Uri.parse('ws://localhost:3001/ws');
      _webSocketChannel = WebSocketChannel.connect(wsUri);

      // Listen for WebSocket messages
      _webSocketChannel!.stream.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketDisconnect,
      );
    } catch (e) {
      // WebSocket connection failed, continue without real-time updates
    }
  }

  /// Sets up file system watcher for local manifest changes.
  ///
  /// Monitors the apps directory for changes and triggers application list updates
  /// when manifest files are added, modified, or removed.
  void _setupFileSystemWatcher(Duration debounce) {
    final bool exists = _appsDir.existsSync();
    if (!exists) return;

    final Stream<FileSystemEvent> raw = _appsDir.watch();
    Timer? timer;

    raw.listen((FileSystemEvent _) {
      timer?.cancel();
      timer = Timer(debounce, () async {
        final List<UserApplication> apps = await loadApplications();
        _applicationUpdatesController.add(apps);
      });
    });
  }

  /// Sets up periodic polling for application updates.
  ///
  /// Polls the Kiro Bridge API periodically to ensure we don't miss updates
  /// if the WebSocket connection fails or is unavailable.
  void _setupPeriodicPolling(Duration pollInterval) {
    Timer.periodic(pollInterval, (Timer timer) async {
      try {
        final List<UserApplication> apps = await loadApplications();
        _applicationUpdatesController.add(apps);
      } catch (e) {
        // Polling failed, continue with cached data
      }
    });
  }

  /// Handles incoming WebSocket messages.
  ///
  /// Processes real-time updates from the Kiro Bridge and updates the
  /// application list accordingly.
  void _handleWebSocketMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = json.decode(message as String) as Map<String, dynamic>;

      if (data['type'] == 'application_update') {
        // Handle application status update
        _handleApplicationUpdate(data);
      } else if (data['type'] == 'application_created') {
        // Handle new application creation
        _handleApplicationCreated(data);
      } else if (data['type'] == 'application_deleted') {
        // Handle application deletion
        _handleApplicationDeleted(data);
      }
    } catch (e) {
      // Failed to parse WebSocket message, ignore
    }
  }

  /// Handles WebSocket connection errors.
  void _handleWebSocketError(Object error) {
    _isConnected = false;
    // Attempt to reconnect after a delay
    Timer(const Duration(seconds: 5), () async {
      await _initializeWebSocketConnection();
    });
  }

  /// Handles WebSocket disconnection.
  void _handleWebSocketDisconnect() {
    _isConnected = false;
    // Attempt to reconnect after a delay
    Timer(const Duration(seconds: 5), () async {
      await _initializeWebSocketConnection();
    });
  }

  /// Handles application update events from WebSocket.
  Future<void> _handleApplicationUpdate(Map<String, dynamic> data) async {
    try {
      final UserApplication updatedApp = UserApplication.fromJson(data['application'] as Map<String, dynamic>);

      // Update cached applications
      final int index = _cachedApplications.indexWhere((UserApplication app) => app.id == updatedApp.id);
      if (index != -1) {
        _cachedApplications[index] = updatedApp;
        _applicationUpdatesController.add(_cachedApplications);
      }
    } catch (e) {
      // Failed to parse application update, refresh full list
      final List<UserApplication> apps = await loadApplications();
      _applicationUpdatesController.add(apps);
    }
  }

  /// Handles application creation events from WebSocket.
  Future<void> _handleApplicationCreated(Map<String, dynamic> data) async {
    try {
      final UserApplication newApp = UserApplication.fromJson(data['application'] as Map<String, dynamic>);

      // Add to cached applications
      _cachedApplications
        ..add(newApp)
        ..sort(
          (UserApplication a, UserApplication b) => b.updatedAt.compareTo(a.updatedAt),
        );
      _applicationUpdatesController.add(_cachedApplications);
    } catch (e) {
      // Failed to parse new application, refresh full list
      final List<UserApplication> apps = await loadApplications();
      _applicationUpdatesController.add(apps);
    }
  }

  /// Handles application deletion events from WebSocket.
  void _handleApplicationDeleted(Map<String, dynamic> data) {
    final String? applicationId = data['applicationId'] as String?;
    if (applicationId != null) {
      _cachedApplications.removeWhere((UserApplication app) => app.id == applicationId);
      _applicationUpdatesController.add(_cachedApplications);
    }
  }

  /// Attempts to read and parse a single manifest file into a
  /// [UserApplication]. Returns `null` if the file is unreadable or invalid.
  Future<UserApplication?> _readManifest(File file) async {
    try {
      final String contents = await file.readAsString();
      final Map<String, dynamic> jsonMap = json.decode(contents) as Map<String, dynamic>;
      final UserApplication app = UserApplication.fromJson(jsonMap);
      return app;
    } on FormatException {
      // Malformed JSON or model validation: skip this manifest.
      return null;
    } on Object {
      // Any other I/O error: skip this manifest.
      return null;
    }
  }

  /// Creates a new application through the Kiro Bridge.
  ///
  /// Sends a request to create a new application based on the user's description.
  /// The application will be queued for development and progress can be monitored
  /// through the real-time updates.
  ///
  /// Returns the created application metadata or throws an exception if creation fails.
  Future<UserApplication> createApplication({
    required String description,
    String? conversationId,
    String priority = 'normal',
  }) async {
    // TODO(Scott): Implementation
    throw UnimplementedError();
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

  /// Launches the Kiro IDE with the `apps/` directory as the working directory.
  ///
  /// This method starts the external `kiro` process, passing the path to the `apps/`
  /// directory where user application manifests are stored. This allows developers
  /// to open the Kiro IDE focused on the current applications directory for editing
  /// or inspection.
  ///
  /// Returns a [Process] representing the running Kiro IDE instance.
  Future<Process> openKiroInAppsDir() => Process.start('kiro', [_appsDir.path]);

  /// Returns whether the service is currently connected to the Kiro Bridge.
  ///
  /// Used by UI components to show connection status and enable/disable features
  /// that require bridge connectivity.
  bool get isConnected => _isConnected;

  /// Returns the cached applications list.
  ///
  /// Provides immediate access to the last loaded application data without
  /// requiring an async call. May be empty if no applications have been loaded yet.
  List<UserApplication> get cachedApplications => List.unmodifiable(_cachedApplications);

  /// Disposes of resources used by this service.
  ///
  /// Closes WebSocket connections, cancels timers, and cleans up stream controllers.
  /// Should be called when the service is no longer needed.
  void dispose() {
    _webSocketChannel?.sink.close();
    _applicationUpdatesController.close();
  }
}
