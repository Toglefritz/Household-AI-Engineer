/// Represents the state of an application window.
///
/// This class captures window position, size, and other state information
/// that can be preserved and restored when applications are relaunched.
/// Used for providing a consistent user experience across application sessions.
class WindowState {
  /// Creates a new window state.
  ///
  /// @param x Horizontal position of the window in pixels
  /// @param y Vertical position of the window in pixels
  /// @param width Width of the window in pixels
  /// @param height Height of the window in pixels
  /// @param isMaximized Whether the window is maximized
  /// @param isMinimized Whether the window is minimized
  /// @param isFullscreen Whether the window is in fullscreen mode
  /// @param lastUpdated Timestamp when this state was last updated
  const WindowState({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.isMaximized = false,
    this.isMinimized = false,
    this.isFullscreen = false,
    required this.lastUpdated,
  });

  /// Horizontal position of the window in pixels from the left edge of the screen.
  ///
  /// Used to restore the window to its previous position when relaunched.
  /// May be adjusted if the saved position is outside the current screen bounds.
  final double x;

  /// Vertical position of the window in pixels from the top edge of the screen.
  ///
  /// Used to restore the window to its previous position when relaunched.
  /// May be adjusted if the saved position is outside the current screen bounds.
  final double y;

  /// Width of the window in pixels.
  ///
  /// Used to restore the window to its previous size when relaunched.
  /// May be constrained by minimum and maximum window size limits.
  final double width;

  /// Height of the window in pixels.
  ///
  /// Used to restore the window to its previous size when relaunched.
  /// May be constrained by minimum and maximum window size limits.
  final double height;

  /// Whether the window is maximized.
  ///
  /// When true, the window fills the entire screen (excluding dock/taskbar).
  /// Takes precedence over position and size values when restoring.
  final bool isMaximized;

  /// Whether the window is minimized.
  ///
  /// When true, the window is hidden from view but still running.
  /// Used to restore the minimized state when relaunching.
  final bool isMinimized;

  /// Whether the window is in fullscreen mode.
  ///
  /// When true, the window fills the entire screen including dock/taskbar areas.
  /// Takes precedence over all other position and size values.
  final bool isFullscreen;

  /// Timestamp when this window state was last updated.
  ///
  /// Used to determine the freshness of saved state and for cleanup
  /// of old state information that may no longer be relevant.
  final DateTime lastUpdated;

  /// Returns true if this window state represents a normal (non-special) window.
  ///
  /// Normal windows are not maximized, minimized, or in fullscreen mode.
  /// These windows use the explicit position and size values.
  bool get isNormal => !isMaximized && !isMinimized && !isFullscreen;

  /// Returns the age of this window state.
  ///
  /// Calculated as the time between when the state was last updated and now.
  /// Used for determining if saved state is still relevant.
  Duration get age => DateTime.now().difference(lastUpdated);

  /// Creates a copy of this window state with updated values.
  ///
  /// Allows modifying specific state properties while preserving others.
  /// Automatically updates the lastUpdated timestamp.
  WindowState copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    bool? isMaximized,
    bool? isMinimized,
    bool? isFullscreen,
    DateTime? lastUpdated,
  }) {
    return WindowState(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      isMaximized: isMaximized ?? this.isMaximized,
      isMinimized: isMinimized ?? this.isMinimized,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  /// Converts this window state to JSON format.
  ///
  /// Creates a JSON representation suitable for storage in shared preferences
  /// or other persistence mechanisms.
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'isMaximized': isMaximized,
      'isMinimized': isMinimized,
      'isFullscreen': isFullscreen,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Creates a window state from JSON data.
  ///
  /// Parses JSON representation and creates a properly typed window state object.
  /// Provides default values for missing or invalid data.
  factory WindowState.fromJson(Map<String, dynamic> json) {
    return WindowState(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 1200.0,
      height: (json['height'] as num?)?.toDouble() ?? 800.0,
      isMaximized: json['isMaximized'] as bool? ?? false,
      isMinimized: json['isMinimized'] as bool? ?? false,
      isFullscreen: json['isFullscreen'] as bool? ?? false,
      lastUpdated: json['lastUpdated'] != null ? DateTime.parse(json['lastUpdated'] as String) : DateTime.now(),
    );
  }

  /// Creates a default window state for new applications.
  ///
  /// Provides sensible defaults for applications that don't have
  /// previously saved window state information.
  ///
  /// @param width Optional initial width (defaults to 1200)
  /// @param height Optional initial height (defaults to 800)
  /// @returns WindowState with default positioning and size
  factory WindowState.defaultState({
    double width = 1200.0,
    double height = 800.0,
  }) {
    return WindowState(
      x: 100.0, // Offset from screen edge
      y: 100.0, // Offset from screen edge
      width: width,
      height: height,
      lastUpdated: DateTime.now(),
    );
  }

  /// Validates that this window state is within reasonable bounds.
  ///
  /// Checks that position and size values are positive and within
  /// expected ranges for typical screen configurations.
  ///
  /// @returns True if the window state appears valid
  bool isValid() {
    // Check for reasonable position values (not negative, not extremely large)
    if (x < -1000 || x > 10000 || y < -1000 || y > 10000) {
      return false;
    }

    // Check for reasonable size values (not too small, not extremely large)
    if (width < 100 || width > 10000 || height < 100 || height > 10000) {
      return false;
    }

    // Check that state is not too old (older than 30 days)
    if (age.inDays > 30) {
      return false;
    }

    return true;
  }

  /// Returns a formatted string describing this window state.
  ///
  /// Provides human-readable information about window position, size, and special states.
  String get description {
    if (isFullscreen) {
      return 'Fullscreen';
    } else if (isMaximized) {
      return 'Maximized';
    } else if (isMinimized) {
      return 'Minimized';
    } else {
      return '${width.toInt()}×${height.toInt()} at (${x.toInt()}, ${y.toInt()})';
    }
  }

  @override
  String toString() {
    return 'WindowState(${description}, updated: ${lastUpdated.toIso8601String()})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WindowState &&
        other.x == x &&
        other.y == y &&
        other.width == width &&
        other.height == height &&
        other.isMaximized == isMaximized &&
        other.isMinimized == isMinimized &&
        other.isFullscreen == isFullscreen;
  }

  @override
  int get hashCode {
    return Object.hash(
      x,
      y,
      width,
      height,
      isMaximized,
      isMinimized,
      isFullscreen,
    );
  }
}
