/// Severity levels for build log entries.
///
/// Defines the importance and type of logged events during development.
/// Used for filtering, styling, and prioritizing log information.
enum LogLevel {
  /// Debug-level information for detailed troubleshooting.
  ///
  /// Verbose information typically only useful for developers
  /// debugging specific issues in the development process.
  debug,

  /// Informational messages about normal development progress.
  ///
  /// General progress updates and status information that
  /// indicate normal operation of the development system.
  info,

  /// Warning messages about potential issues or unusual conditions.
  ///
  /// Non-critical issues that don't prevent development from continuing
  /// but may indicate problems or suboptimal conditions.
  warning,

  /// Error messages about failures or critical issues.
  ///
  /// Critical problems that prevent development from continuing
  /// or indicate serious issues requiring immediate attention.
  error,
}

/// Extension methods for LogLevel enum.
///
/// Provides utility methods for working with log level values,
/// including display formatting and severity comparison.
extension LogLevelExtension on LogLevel {
  /// Returns a human-readable display name for the log level.
  ///
  /// These names are suitable for display in log viewers and
  /// follow consistent capitalization conventions.
  String get displayName {
    switch (this) {
      case LogLevel.debug:
        return 'Debug';
      case LogLevel.info:
        return 'Info';
      case LogLevel.warning:
        return 'Warning';
      case LogLevel.error:
        return 'Error';
    }
  }

  /// Returns true if this log level indicates a problem.
  ///
  /// Warning and error levels are considered problematic and
  /// may require user attention or system intervention.
  bool get isProblematic {
    return this == LogLevel.warning || this == LogLevel.error;
  }

  /// Returns the numeric severity of this log level.
  ///
  /// Higher numbers indicate more severe issues. Used for
  /// sorting and filtering log entries by importance.
  int get severity {
    switch (this) {
      case LogLevel.debug:
        return 0;
      case LogLevel.info:
        return 1;
      case LogLevel.warning:
        return 2;
      case LogLevel.error:
        return 3;
    }
  }
}
