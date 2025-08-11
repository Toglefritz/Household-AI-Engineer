import 'package:flutter/material.dart';

/// Data class containing visual information for connection status display.
///
/// Encapsulates the color, icon, and label information needed to display a connection status in the status bar with 
/// consistent styling.
class ConnectionStatusInfo {
  /// Creates connection status information with the specified properties.
  ///
  /// @param color Color to use for the status indicator and text
  /// @param icon Icon to display next to the status indicator
  /// @param label Text label describing the connection status
  const ConnectionStatusInfo({
    required this.color,
    required this.icon,
    required this.label,
  });

  /// Color to use for the status indicator dot, icon, and text.
  ///
  /// Should be semantically appropriate for the status (green for good, red for error, yellow for warning, etc.).
  final Color color;

  /// Icon to display next to the status indicator.
  ///
  /// Should visually represent the connection state and be easily recognizable at small sizes.
  final IconData icon;

  /// Text label describing the current connection status.
  ///
  /// Should be concise and immediately understandable by users.
  final String label;
}
