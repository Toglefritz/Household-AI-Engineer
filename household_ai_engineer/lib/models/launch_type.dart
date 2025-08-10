/// Launch Type Enumeration
///
/// Determines how applications are launched and managed within the dashboard.

/// Types of application launches supported by the system.
///
/// Determines how applications are launched and managed within
/// the dashboard environment.
enum LaunchType {
  /// Web application launched in embedded WebView.
  ///
  /// The application runs in a web browser context within
  /// the dashboard interface with optional navigation controls.
  web,

  /// Native application launched in separate window.
  ///
  /// The application runs as a separate process with its own
  /// native window managed by the operating system.
  native,
}

/// Extension methods for LaunchType enum.
///
/// Provides utility methods for working with launch type values,
/// including display formatting and behavior determination.
extension LaunchTypeExtension on LaunchType {
  /// Returns a human-readable display name for the launch type.
  ///
  /// These names are suitable for display in configuration interfaces
  /// and follow consistent terminology conventions.
  String get displayName {
    switch (this) {
      case LaunchType.web:
        return 'Web Application';
      case LaunchType.native:
        return 'Native Application';
    }
  }

  /// Returns true if this launch type uses embedded display.
  ///
  /// Embedded applications run within the dashboard interface
  /// rather than in separate windows.
  bool get isEmbedded {
    return this == LaunchType.web;
  }

  /// Returns true if this launch type uses separate windows.
  ///
  /// Separate window applications run independently of the
  /// dashboard interface in their own native windows.
  bool get usesSeparateWindow {
    return this == LaunchType.native;
  }
}
