import 'package:flutter/material.dart';

/// Data model representing a category for application organization.
///
/// Contains the visual and descriptive information needed to display
/// a category in the sidebar, including icon, label, and application count.
/// Used to maintain consistent category data across the application.
class CategoryData {
  /// Creates a category data instance.
  ///
  /// @param icon Icon representing the category visually
  /// @param label Human-readable category name
  /// @param count Number of applications in this category
  const CategoryData({
    required this.icon,
    required this.label,
    required this.count,
  });

  /// Icon representing the category.
  ///
  /// Should be a recognizable Material Design icon that clearly
  /// represents the category type for easy user identification.
  final IconData icon;

  /// Human-readable category name.
  ///
  /// Should be concise but descriptive, suitable for display in
  /// both expanded sidebar and tooltip contexts.
  final String label;

  /// Number of applications currently in this category.
  ///
  /// Used to show users how many applications are available in
  /// each category for better organization and discovery.
  final int count;

  /// Creates a copy of this category data with updated values.
  ///
  /// Allows for immutable updates to category information, particularly
  /// useful for updating application counts when apps are added or removed.
  ///
  /// @param icon New icon, or null to keep current
  /// @param label New label, or null to keep current
  /// @param count New count, or null to keep current
  /// @returns New CategoryData instance with updated values
  CategoryData copyWith({
    IconData? icon,
    String? label,
    int? count,
  }) {
    return CategoryData(
      icon: icon ?? this.icon,
      label: label ?? this.label,
      count: count ?? this.count,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryData && other.icon == icon && other.label == label && other.count == count;
  }

  @override
  int get hashCode => Object.hash(icon, label, count);

  @override
  String toString() => 'CategoryData(icon: $icon, label: $label, count: $count)';
}
