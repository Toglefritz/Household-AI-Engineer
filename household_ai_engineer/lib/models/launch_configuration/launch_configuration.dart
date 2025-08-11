import 'launch_type.dart';

/// Configuration for launching an application.
///
/// Contains platform-specific settings and parameters needed to
/// properly launch and manage running applications.
class LaunchConfiguration {
  /// Creates a new launch configuration.
  ///
  /// All parameters are required to ensure complete launch information
  /// for proper application startup and management.
  const LaunchConfiguration({
    required this.type,
    required this.url,
    this.windowTitle,
    this.windowWidth,
    this.windowHeight,
    this.allowResize = true,
    this.showNavigationControls = false,
  });

  /// Type of application launch (web or native).
  ///
  /// Determines how the application will be launched and managed.
  final LaunchType type;

  /// URL or path for launching the application.
  ///
  /// For web applications, this is the HTTP URL.
  /// For native applications, this is the executable path or command.
  final String url;

  /// Title for the application window.
  ///
  /// Used as the window title when launching the application.
  /// Defaults to the application title if not specified.
  final String? windowTitle;

  /// Initial width of the application window in pixels.
  ///
  /// Used for web applications launched in embedded WebView.
  /// Null means use default or full-screen width.
  final int? windowWidth;

  /// Initial height of the application window in pixels.
  ///
  /// Used for web applications launched in embedded WebView.
  /// Null means use default or full-screen height.
  final int? windowHeight;

  /// Whether the application window can be resized by the user.
  ///
  /// Controls window resize behavior for embedded applications.
  final bool allowResize;

  /// Whether to show navigation controls (back, forward, refresh).
  ///
  /// Only applies to web applications launched in embedded WebView.
  final bool showNavigationControls;

  /// Creates a LaunchConfiguration from JSON data.
  ///
  /// Parses launch configuration data and creates a properly typed
  /// configuration object with validation and defaults.
  ///
  /// Throws [FormatException] if the JSON structure is invalid or
  /// required fields are missing.
  factory LaunchConfiguration.fromJson(Map<String, dynamic> json) {
    try {
      return LaunchConfiguration(
        type: _parseLaunchType(json['type'] as String?),
        url: json['url'] as String? ?? (throw ArgumentError('Missing required field: url')),
        windowTitle: json['windowTitle'] as String?,
        windowWidth: json['windowWidth'] as int?,
        windowHeight: json['windowHeight'] as int?,
        allowResize: json['allowResize'] as bool? ?? true,
        showNavigationControls: json['showNavigationControls'] as bool? ?? false,
      );
    } catch (e) {
      throw FormatException('Failed to parse LaunchConfiguration from JSON: $e');
    }
  }

  /// Converts this launch configuration to JSON format.
  ///
  /// Creates a JSON representation suitable for API communication
  /// and local storage with proper type conversion.
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'url': url,
      'windowTitle': windowTitle,
      'windowWidth': windowWidth,
      'windowHeight': windowHeight,
      'allowResize': allowResize,
      'showNavigationControls': showNavigationControls,
    };
  }

  /// Creates a copy of this configuration with updated fields.
  ///
  /// Allows updating specific fields while preserving others.
  /// Commonly used when modifying application launch settings.
  LaunchConfiguration copyWith({
    LaunchType? type,
    String? url,
    String? windowTitle,
    int? windowWidth,
    int? windowHeight,
    bool? allowResize,
    bool? showNavigationControls,
  }) {
    return LaunchConfiguration(
      type: type ?? this.type,
      url: url ?? this.url,
      windowTitle: windowTitle ?? this.windowTitle,
      windowWidth: windowWidth ?? this.windowWidth,
      windowHeight: windowHeight ?? this.windowHeight,
      allowResize: allowResize ?? this.allowResize,
      showNavigationControls: showNavigationControls ?? this.showNavigationControls,
    );
  }

  /// Parses a launch type string into the corresponding enum value.
  ///
  /// Handles case-insensitive parsing and provides clear error messages
  /// for invalid launch type values.
  static LaunchType _parseLaunchType(String? typeString) {
    if (typeString == null) {
      throw ArgumentError('Missing required field: type');
    }

    switch (typeString.toLowerCase()) {
      case 'web':
        return LaunchType.web;
      case 'native':
        return LaunchType.native;
      default:
        throw ArgumentError('Invalid launch type: $typeString');
    }
  }
}
