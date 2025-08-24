/// Configuration for launching household applications.
///
/// This class defines all the settings and parameters needed to launch
/// an application, including window properties, security settings, and
/// application-specific configuration options.
class ApplicationLaunchConfig {
  /// Creates a new application launch configuration.
  ///
  /// @param applicationType Type of application (web or desktop)
  /// @param url URL for web applications
  /// @param windowTitle Title to display in the application window
  /// @param initialWidth Initial window width in pixels
  /// @param initialHeight Initial window height in pixels
  /// @param resizable Whether the window can be resized by the user
  /// @param showNavigationControls Whether to show browser navigation controls
  /// @param enableJavaScript Whether to enable JavaScript execution
  /// @param enableLocalStorage Whether to enable local storage access
  const ApplicationLaunchConfig({
    required this.applicationType,
    required this.url,
    required this.windowTitle,
    this.initialWidth = 1200,
    this.initialHeight = 800,
    this.resizable = true,
    this.showNavigationControls = true,
    this.enableJavaScript = true,
    this.enableLocalStorage = true,
  });

  /// Type of application being launched.
  ///
  /// Determines the launch mechanism and runtime environment.
  /// Currently supports web applications with desktop support planned.
  final ApplicationType applicationType;

  /// URL for web-based applications.
  ///
  /// The primary endpoint where the application is hosted.
  /// Must be a valid HTTP or HTTPS URL for web applications.
  final String url;

  /// Title to display in the application window.
  ///
  /// Used for window title bars, task manager entries, and
  /// other system-level application identification.
  final String windowTitle;

  /// Initial width of the application window in pixels.
  ///
  /// The window will open with this width, but may be resized
  /// by the user if [resizable] is true.
  final int initialWidth;

  /// Initial height of the application window in pixels.
  ///
  /// The window will open with this height, but may be resized
  /// by the user if [resizable] is true.
  final int initialHeight;

  /// Whether the application window can be resized by the user.
  ///
  /// When true, users can drag window edges to change size.
  /// When false, the window maintains its initial dimensions.
  final bool resizable;

  /// Whether to show browser navigation controls for web applications.
  ///
  /// When true, displays back/forward buttons, address bar, and refresh.
  /// When false, shows only the application content in a clean interface.
  final bool showNavigationControls;

  /// Whether to enable JavaScript execution in web applications.
  ///
  /// Most modern web applications require JavaScript to function properly.
  /// Disabling this may break application functionality.
  final bool enableJavaScript;

  /// Whether to enable local storage access for web applications.
  ///
  /// Allows applications to store data locally in the browser.
  /// Required for applications that need to persist user data.
  final bool enableLocalStorage;

  /// Creates a copy of this configuration with updated values.
  ///
  /// Allows modifying specific configuration options while preserving others.
  ApplicationLaunchConfig copyWith({
    ApplicationType? applicationType,
    String? url,
    String? windowTitle,
    int? initialWidth,
    int? initialHeight,
    bool? resizable,
    bool? showNavigationControls,
    bool? enableJavaScript,
    bool? enableLocalStorage,
  }) {
    return ApplicationLaunchConfig(
      applicationType: applicationType ?? this.applicationType,
      url: url ?? this.url,
      windowTitle: windowTitle ?? this.windowTitle,
      initialWidth: initialWidth ?? this.initialWidth,
      initialHeight: initialHeight ?? this.initialHeight,
      resizable: resizable ?? this.resizable,
      showNavigationControls: showNavigationControls ?? this.showNavigationControls,
      enableJavaScript: enableJavaScript ?? this.enableJavaScript,
      enableLocalStorage: enableLocalStorage ?? this.enableLocalStorage,
    );
  }

  /// Converts this configuration to JSON format.
  ///
  /// Creates a JSON representation suitable for storage and transmission.
  Map<String, dynamic> toJson() {
    return {
      'applicationType': applicationType.name,
      'url': url,
      'windowTitle': windowTitle,
      'initialWidth': initialWidth,
      'initialHeight': initialHeight,
      'resizable': resizable,
      'showNavigationControls': showNavigationControls,
      'enableJavaScript': enableJavaScript,
      'enableLocalStorage': enableLocalStorage,
    };
  }

  /// Creates a configuration from JSON data.
  ///
  /// Parses JSON representation and creates a properly typed configuration object.
  factory ApplicationLaunchConfig.fromJson(Map<String, dynamic> json) {
    return ApplicationLaunchConfig(
      applicationType: ApplicationType.values.firstWhere(
        (ApplicationType type) => type.name == json['applicationType'],
        orElse: () => ApplicationType.web,
      ),
      url: json['url'] as String,
      windowTitle: json['windowTitle'] as String,
      initialWidth: json['initialWidth'] as int? ?? 1200,
      initialHeight: json['initialHeight'] as int? ?? 800,
      resizable: json['resizable'] as bool? ?? true,
      showNavigationControls: json['showNavigationControls'] as bool? ?? true,
      enableJavaScript: json['enableJavaScript'] as bool? ?? true,
      enableLocalStorage: json['enableLocalStorage'] as bool? ?? true,
    );
  }
}

/// Enumeration of supported application types.
///
/// Defines the different types of applications that can be launched
/// by the household application system.
enum ApplicationType {
  /// Web-based applications accessed through a WebView.
  ///
  /// These applications run in a browser-like environment with
  /// configurable security and navigation settings.
  web,

  /// Native desktop applications.
  ///
  /// These applications run as separate processes with their own
  /// windows and system integration. Currently not implemented.
  desktop,
}

/// Extension methods for [ApplicationType] enum.
extension ApplicationTypeExtension on ApplicationType {
  /// Returns a human-readable display name for the application type.
  String get displayName {
    switch (this) {
      case ApplicationType.web:
        return 'Web Application';
      case ApplicationType.desktop:
        return 'Desktop Application';
    }
  }

  /// Returns true if this application type is currently supported.
  bool get isSupported {
    switch (this) {
      case ApplicationType.web:
        return true;
      case ApplicationType.desktop:
        return false; // Not yet implemented
    }
  }
}
