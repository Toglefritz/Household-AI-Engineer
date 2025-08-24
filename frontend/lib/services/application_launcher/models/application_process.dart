import 'application_launch_config.dart';
import 'window_state.dart';

/// Represents a running application process.
///
/// This class tracks the runtime state of a launched application including
/// process information, health status, resource usage, and window state.
/// Used for monitoring, management, and cleanup of running applications.
class ApplicationProcess {
  /// Creates a new application process.
  ///
  /// @param applicationId Unique identifier of the application
  /// @param applicationTitle Display title of the application
  /// @param launchConfig Configuration used to launch the application
  /// @param windowState Optional window state for restoration
  /// @param launchedAt Timestamp when the application was launched
  ApplicationProcess({
    required this.applicationId,
    required this.applicationTitle,
    required this.launchConfig,
    required this.launchedAt,
    this.windowState,
  }) : _status = ProcessStatus.starting,
       _lastHealthCheck = DateTime.now(),
       _lastAccessed = DateTime.now();

  /// Unique identifier of the application.
  ///
  /// Matches the application ID from the UserApplication model
  /// for consistent tracking across the system.
  final String applicationId;

  /// Display title of the application.
  ///
  /// Used for process identification in system monitors,
  /// task managers, and user interface displays.
  final String applicationTitle;

  /// Configuration used to launch this application.
  ///
  /// Contains all launch parameters including window settings,
  /// security configuration, and application-specific options.
  final ApplicationLaunchConfig launchConfig;

  /// Current window state of the application.
  ///
  /// Tracks window position, size, and other state information
  /// for restoration when the application is relaunched.
  WindowState? windowState;

  /// Timestamp when this application was launched.
  ///
  /// Used for calculating uptime and managing process lifecycle.
  final DateTime launchedAt;

  /// Current status of the application process.
  ProcessStatus _status;

  /// Timestamp of the last health check performed on this process.
  DateTime _lastHealthCheck;

  /// Timestamp when this application was last accessed by the user.
  DateTime _lastAccessed;

  /// Whether the last health check was successful.
  bool _isHealthy = true;

  /// Error message from the last failed health check.
  String? _healthCheckError;

  /// Current status of the application process.
  ProcessStatus get status => _status;

  /// Whether the last health check was successful.
  bool get isHealthy => _isHealthy;

  /// Error message from the last failed health check.
  String? get healthCheckError => _healthCheckError;

  /// Timestamp of the last health check performed on this process.
  DateTime get lastHealthCheck => _lastHealthCheck;

  /// Timestamp when this application was last accessed by the user.
  DateTime get lastAccessed => _lastAccessed;

  /// Duration since this application was launched.
  Duration get uptime => DateTime.now().difference(launchedAt);

  /// Duration since the last health check was performed.
  Duration get timeSinceLastHealthCheck =>
      DateTime.now().difference(_lastHealthCheck);

  /// Duration since this application was last accessed by the user.
  Duration get timeSinceLastAccess => DateTime.now().difference(_lastAccessed);

  /// Returns true if this process is currently running.
  bool get isRunning => _status == ProcessStatus.running;

  /// Returns true if this process is in a terminal state.
  bool get isTerminated =>
      _status == ProcessStatus.stopped || _status == ProcessStatus.crashed;

  /// Marks this process as running.
  ///
  /// Called when the application has successfully started and is ready for use.
  void markAsRunning() {
    _status = ProcessStatus.running;
    _lastAccessed = DateTime.now();
  }

  /// Marks this process as stopped.
  ///
  /// Called when the application is gracefully shut down by the user or system.
  void markAsStopped() {
    _status = ProcessStatus.stopped;
  }

  /// Marks this process as crashed.
  ///
  /// Called when the application terminates unexpectedly due to an error.
  ///
  /// @param error Optional error message describing the crash
  void markAsCrashed([String? error]) {
    _status = ProcessStatus.crashed;
    _healthCheckError = error;
    _isHealthy = false;
  }

  /// Updates the last accessed timestamp.
  ///
  /// Called when the user interacts with the application or brings it to foreground.
  void updateLastAccessed() {
    _lastAccessed = DateTime.now();
  }

  /// Updates the health check status and timestamp.
  ///
  /// Called after performing a health check on the application to update
  /// its health status and record any errors encountered.
  ///
  /// @param healthy Whether the health check was successful
  /// @param error Optional error message if health check failed
  void updateHealthCheck({required bool healthy, String? error}) {
    _lastHealthCheck = DateTime.now();
    _isHealthy = healthy;
    _healthCheckError = error;

    // If health check failed and process was running, mark as crashed
    if (!healthy && _status == ProcessStatus.running) {
      markAsCrashed(error);
    }
  }

  /// Updates the window state for this process.
  ///
  /// Called when the application window is moved, resized, or otherwise
  /// modified to preserve state for future restoration.
  ///
  /// @param newWindowState Updated window state information
  // ignore: use_setters_to_change_properties
  void updateWindowState(WindowState newWindowState) {
    windowState = newWindowState;
  }

  /// Converts this process to JSON format.
  ///
  /// Creates a JSON representation suitable for storage and transmission.
  Map<String, dynamic> toJson() {
    return {
      'applicationId': applicationId,
      'applicationTitle': applicationTitle,
      'launchConfig': launchConfig.toJson(),
      'windowState': windowState?.toJson(),
      'launchedAt': launchedAt.toIso8601String(),
      'status': _status.name,
      'lastHealthCheck': _lastHealthCheck.toIso8601String(),
      'lastAccessed': _lastAccessed.toIso8601String(),
      'isHealthy': _isHealthy,
      'healthCheckError': _healthCheckError,
    };
  }

  /// Creates a process from JSON data.
  ///
  /// Parses JSON representation and creates a properly typed process object.
  factory ApplicationProcess.fromJson(Map<String, dynamic> json) {
    final ApplicationProcess process =
        ApplicationProcess(
            applicationId: json['applicationId'] as String,
            applicationTitle: json['applicationTitle'] as String,
            launchConfig: ApplicationLaunchConfig.fromJson(
              json['launchConfig'] as Map<String, dynamic>,
            ),
            windowState: json['windowState'] != null
                ? WindowState.fromJson(
                    json['windowState'] as Map<String, dynamic>,
                  )
                : null,
            launchedAt: DateTime.parse(json['launchedAt'] as String),
          )
          // Restore internal state
          .._status = ProcessStatus.values.firstWhere(
            (ProcessStatus status) => status.name == json['status'],
            orElse: () => ProcessStatus.starting,
          )
          .._lastHealthCheck = DateTime.parse(json['lastHealthCheck'] as String)
          .._lastAccessed = DateTime.parse(json['lastAccessed'] as String)
          .._isHealthy = json['isHealthy'] as bool? ?? true
          .._healthCheckError = json['healthCheckError'] as String?;

    return process;
  }

  /// Returns a formatted string describing the process uptime.
  ///
  /// Provides human-readable uptime information suitable for display in monitoring interfaces.
  String get uptimeDescription {
    final Duration uptime = this.uptime;

    if (uptime.inDays > 0) {
      return '${uptime.inDays} day${uptime.inDays == 1 ? '' : 's'}, ${uptime.inHours % 24} hour${uptime.inHours % 24 == 1 ? '' : 's'}';
    } else if (uptime.inHours > 0) {
      return '${uptime.inHours} hour${uptime.inHours == 1 ? '' : 's'}, ${uptime.inMinutes % 60} minute${uptime.inMinutes % 60 == 1 ? '' : 's'}';
    } else if (uptime.inMinutes > 0) {
      return '${uptime.inMinutes} minute${uptime.inMinutes == 1 ? '' : 's'}';
    } else {
      return '${uptime.inSeconds} second${uptime.inSeconds == 1 ? '' : 's'}';
    }
  }

  /// Returns a formatted string describing when this process was last accessed.
  ///
  /// Provides human-readable last access information for monitoring and management.
  String get lastAccessDescription {
    final Duration timeSinceAccess = timeSinceLastAccess;

    if (timeSinceAccess.inDays > 0) {
      return '${timeSinceAccess.inDays} day${timeSinceAccess.inDays == 1 ? '' : 's'} ago';
    } else if (timeSinceAccess.inHours > 0) {
      return '${timeSinceAccess.inHours} hour${timeSinceAccess.inHours == 1 ? '' : 's'} ago';
    } else if (timeSinceAccess.inMinutes > 0) {
      return '${timeSinceAccess.inMinutes} minute${timeSinceAccess.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

/// Enumeration of application process states.
///
/// Defines the possible states an application process can be in
/// throughout its lifecycle from launch to termination.
enum ProcessStatus {
  /// Process is starting up but not yet ready for use.
  ///
  /// Initial state when an application is being launched but
  /// has not yet completed initialization.
  starting,

  /// Process is running and ready for user interaction.
  ///
  /// The application has successfully started and is actively
  /// serving requests or waiting for user input.
  running,

  /// Process has been gracefully stopped.
  ///
  /// The application was shut down normally by user request
  /// or system shutdown procedures.
  stopped,

  /// Process has crashed or terminated unexpectedly.
  ///
  /// The application stopped due to an error, exception,
  /// or other unexpected condition.
  crashed,
}

/// Extension methods for [ProcessStatus] enum.
extension ProcessStatusExtension on ProcessStatus {
  /// Returns a human-readable display name for the process status.
  String get displayName {
    switch (this) {
      case ProcessStatus.starting:
        return 'Starting';
      case ProcessStatus.running:
        return 'Running';
      case ProcessStatus.stopped:
        return 'Stopped';
      case ProcessStatus.crashed:
        return 'Crashed';
    }
  }

  /// Returns true if this status indicates an active process.
  bool get isActive {
    return this == ProcessStatus.starting || this == ProcessStatus.running;
  }

  /// Returns true if this status indicates a terminated process.
  bool get isTerminated {
    return this == ProcessStatus.stopped || this == ProcessStatus.crashed;
  }
}
