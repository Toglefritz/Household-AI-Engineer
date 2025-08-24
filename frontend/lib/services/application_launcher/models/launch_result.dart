import '../../user_application/models/user_application.dart';
import 'application_process.dart';

/// Result of an application launch operation.
///
/// This class provides structured information about the outcome of launching
/// an application, including success/failure status, process information,
/// and error details for failed launches.
class LaunchResult {
  /// Creates a new launch result.
  ///
  /// @param success Whether the launch operation was successful
  /// @param application The application that was launched (if available)
  /// @param applicationId ID of the application (for operations without full app data)
  /// @param process The created application process (for successful launches)
  /// @param message Human-readable message describing the result
  /// @param error Error message for failed operations
  /// @param errorCode Machine-readable error code for failed operations
  /// @param timestamp When this result was created
  const LaunchResult({
    required this.success,
    this.application,
    this.applicationId,
    this.process,
    this.message,
    this.error,
    this.errorCode,
    required this.timestamp,
  });

  /// Whether the launch operation was successful.
  ///
  /// True for successful launches, false for failures or errors.
  final bool success;

  /// The application that was launched.
  ///
  /// Available for operations that have access to the full application data.
  /// May be null for operations that only have the application ID.
  final UserApplication? application;

  /// ID of the application involved in this operation.
  ///
  /// Always available, even when the full application object is not.
  /// Used for tracking and correlation of launch events.
  final String? applicationId;

  /// The application process created by a successful launch.
  ///
  /// Contains process information, configuration, and runtime state.
  /// Only available for successful launch operations.
  final ApplicationProcess? process;

  /// Human-readable message describing the result.
  ///
  /// Provides user-friendly information about what happened during
  /// the launch operation. Suitable for display in notifications or logs.
  final String? message;

  /// Error message for failed operations.
  ///
  /// Contains detailed information about what went wrong during
  /// a failed launch attempt. Suitable for debugging and user feedback.
  final String? error;

  /// Machine-readable error code for failed operations.
  ///
  /// Provides structured error identification for programmatic handling
  /// and error recovery logic. Follows consistent error code conventions.
  final String? errorCode;

  /// Timestamp when this result was created.
  ///
  /// Used for ordering events, calculating operation duration,
  /// and managing result history and cleanup.
  final DateTime timestamp;

  /// Returns the application ID from either the application object or direct ID.
  ///
  /// Provides a consistent way to get the application ID regardless of
  /// which data is available in this result.
  String? get effectiveApplicationId => application?.id ?? applicationId;

  /// Returns the application title from either the application or process.
  ///
  /// Provides a consistent way to get a display name for the application
  /// involved in this launch operation.
  String? get effectiveApplicationTitle => application?.title ?? process?.applicationTitle;

  /// Creates a successful launch result.
  ///
  /// @param application The application that was launched
  /// @param process The created application process
  /// @param message Optional success message
  /// @returns LaunchResult indicating successful launch
  factory LaunchResult.success({
    required UserApplication application,
    required ApplicationProcess process,
    String? message,
  }) {
    return LaunchResult(
      success: true,
      application: application,
      applicationId: application.id,
      process: process,
      message: message ?? 'Application launched successfully',
      timestamp: DateTime.now(),
    );
  }

  /// Creates a failed launch result.
  ///
  /// @param application The application that failed to launch (if available)
  /// @param applicationId ID of the application (if application object not available)
  /// @param error Error message describing the failure
  /// @param errorCode Machine-readable error code
  /// @returns LaunchResult indicating launch failure
  factory LaunchResult.failure({
    UserApplication? application,
    String? applicationId,
    required String error,
    String? errorCode,
  }) {
    return LaunchResult(
      success: false,
      application: application,
      applicationId: applicationId ?? application?.id,
      error: error,
      errorCode: errorCode ?? 'LAUNCH_FAILED',
      timestamp: DateTime.now(),
    );
  }

  /// Creates a result for an application that was stopped.
  ///
  /// @param applicationId ID of the application that was stopped
  /// @param message Optional message describing the stop operation
  /// @returns LaunchResult indicating application was stopped
  factory LaunchResult.stopped({
    required String applicationId,
    String? message,
  }) {
    return LaunchResult(
      success: true,
      applicationId: applicationId,
      message: message ?? 'Application stopped successfully',
      timestamp: DateTime.now(),
    );
  }

  /// Creates a result for a failed health check.
  ///
  /// @param applicationId ID of the application with failed health check
  /// @param error Error message from the health check
  /// @returns LaunchResult indicating health check failure
  factory LaunchResult.healthCheckFailed({
    required String applicationId,
    required String error,
  }) {
    return LaunchResult(
      success: false,
      applicationId: applicationId,
      error: error,
      errorCode: 'HEALTH_CHECK_FAILED',
      message: 'Application health check failed',
      timestamp: DateTime.now(),
    );
  }

  /// Converts this result to JSON format.
  ///
  /// Creates a JSON representation suitable for logging, storage, or transmission.
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'application': application?.toJson(),
      'applicationId': applicationId,
      'process': process?.toJson(),
      'message': message,
      'error': error,
      'errorCode': errorCode,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Creates a launch result from JSON data.
  ///
  /// Parses JSON representation and creates a properly typed result object.
  factory LaunchResult.fromJson(Map<String, dynamic> json) {
    return LaunchResult(
      success: json['success'] as bool,
      application: json['application'] != null
          ? UserApplication.fromJson(json['application'] as Map<String, dynamic>)
          : null,
      applicationId: json['applicationId'] as String?,
      process: json['process'] != null ? ApplicationProcess.fromJson(json['process'] as Map<String, dynamic>) : null,
      message: json['message'] as String?,
      error: json['error'] as String?,
      errorCode: json['errorCode'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Returns a formatted string describing this launch result.
  ///
  /// Provides human-readable information suitable for logging or display.
  String get description {
    final String appName = effectiveApplicationTitle ?? effectiveApplicationId ?? 'Unknown';

    if (success) {
      return message ?? 'Successfully launched $appName';
    } else {
      return error ?? 'Failed to launch $appName';
    }
  }

  @override
  String toString() {
    return 'LaunchResult(success: $success, app: $effectiveApplicationId, message: ${message ?? error})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LaunchResult &&
        other.success == success &&
        other.applicationId == applicationId &&
        other.message == message &&
        other.error == error &&
        other.errorCode == errorCode;
  }

  @override
  int get hashCode {
    return Object.hash(
      success,
      applicationId,
      message,
      error,
      errorCode,
    );
  }
}
