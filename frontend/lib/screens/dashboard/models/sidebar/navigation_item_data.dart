import 'package:flutter/material.dart';

/// Data class representing a navigation item in the sidebar.
///
/// Contains all the information needed to display and handle a navigation item including its visual state and metadata.
class NavigationItemData {
  /// Creates a navigation item with the specified properties.
  ///
  /// @param icon Icon to display for this navigation item
  /// @param label Text label to show when sidebar is expanded
  /// @param isSelected Whether this item is currently selected
  /// @param badge Optional badge text to display (e.g., count)
  const NavigationItemData({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.badge,
  });

  /// Icon to display for this navigation item.
  ///
  /// Should be a recognizable icon that represents the navigation destination or filter category.
  final IconData icon;

  /// Text label to display when the sidebar is expanded.
  ///
  /// Should be concise but descriptive of the navigation destination.
  final String label;

  /// Whether this navigation item is currently selected.
  ///
  /// Selected items are highlighted with different colors and styling to indicate the current location or active
  /// filter.
  final bool isSelected;

  /// Optional badge text to display next to the label.
  ///
  /// Commonly used to show counts, notifications, or status indicators. Only displayed when the sidebar is expanded.
  final String? badge;
}
