/// Build Log Entry Model
///
/// Represents a single entry in the development build log with
/// timestamp, severity level, message, and source information.

import 'log_level.dart';

/// Represents a single entry in the development build log.
///
/// Build log entries provide detailed information about specific
/// development activities, including timestamps, severity levels,
/// and descriptive messages for debugging and monitoring.
class BuildLogEntry {
  /// Creates a new build log entry.
  ///
  /// All parameters are required to ensure complete log information
  /// for debugging and progress tracking purposes.
  const BuildLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    required this.source,
  });

  /// Timestamp when this log entry was created.
  ///
  /// Used for chronological ordering of log entries and
  /// correlating events across different development phases.
  final DateTime timestamp;

  /// Severity level of this log entry.
  ///
  /// Indicates the importance and type of the logged event.
  /// Used for filtering and visual styling in log viewers.
  final LogLevel level;

  /// Descriptive message for this log entry.
  ///
  /// Human-readable description of the development activity or event.
  /// Should be clear and actionable for debugging purposes.
  final String message;

  /// Source component that generated this log entry.
  ///
  /// Identifies which part of the development system created this log.
  /// Examples: "code-generator", "test-runner", "container-builder"
  final String source;

  /// Creates a BuildLogEntry from JSON data.
  ///
  /// Parses log entry data received from the backend development system
  /// and creates a properly typed log entry object with validation.
  ///
  /// Throws [FormatException] if the JSON structure is invalid or
  /// required fields are missing.
  factory BuildLogEntry.fromJson(Map<String, dynamic> json) {
    try {
      return BuildLogEntry(
        timestamp: DateTime.parse(
          json['timestamp'] as String? ??
              (throw ArgumentError('Missing required field: timestamp')),
        ),
        level: _parseLogLevel(json['level'] as String?),
        message:
            json['message'] as String? ??
            (throw ArgumentError('Missing required field: message')),
        source:
            json['source'] as String? ??
            (throw ArgumentError('Missing required field: source')),
      );
    } catch (e) {
      throw FormatException('Failed to parse BuildLogEntry from JSON: $e');
    }
  }

  /// Converts this log entry to JSON format.
  ///
  /// Creates a JSON representation suitable for API communication
  /// and local storage with proper type conversion.
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'message': message,
      'source': source,
    };
  }

  /// Parses a log level string into the corresponding enum value.
  ///
  /// Handles case-insensitive parsing and provides clear error messages
  /// for invalid log level values.
  static LogLevel _parseLogLevel(String? levelString) {
    if (levelString == null) {
      throw ArgumentError('Missing required field: level');
    }

    switch (levelString.toLowerCase()) {
      case 'debug':
        return LogLevel.debug;
      case 'info':
        return LogLevel.info;
      case 'warning':
      case 'warn':
        return LogLevel.warning;
      case 'error':
        return LogLevel.error;
      default:
        throw ArgumentError('Invalid log level: $levelString');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BuildLogEntry &&
        other.timestamp == timestamp &&
        other.level == level &&
        other.message == message &&
        other.source == source;
  }

  @override
  int get hashCode {
    return Object.hash(timestamp, level, message, source);
  }

  @override
  String toString() {
    return 'BuildLogEntry('
        'timestamp: $timestamp, '
        'level: $level, '
        'message: $message, '
        'source: $source'
        ')';
  }
}
