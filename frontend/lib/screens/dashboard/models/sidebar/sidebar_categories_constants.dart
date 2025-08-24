import '../../../../services/user_application/models/application_category.dart';
import 'category_data.dart';

/// Constants and default data for sidebar categories.
///
/// Provides the standard set of application categories used throughout
/// the household management system. Categories are organized by common
/// household needs and activities.
class SidebarCategoriesConstants {
  /// Private constructor to prevent instantiation.
  const SidebarCategoriesConstants._();

  /// Default list of application categories.
  ///
  /// Generates category data from the ApplicationCategory enum to ensure
  /// consistency between the model and UI representation. Each category
  /// includes the appropriate icon and descriptive label from the enum.
  ///
  /// Categories are ordered by typical usage frequency and importance
  /// in household management workflows. Matches the categories defined
  /// in the manifest schema for consistency.
  static List<CategoryData> get defaultCategories {
    return ApplicationCategory.values.map((ApplicationCategory category) {
      return CategoryData(
        icon: category.icon,
        label: category.displayName,
        count: 0,
      );
    }).toList();
  }

  /// Gets the category data for a specific category by label.
  ///
  /// Searches through the default categories to find one with the
  /// specified label. Useful for looking up category information
  /// when only the label is known.
  ///
  /// @param label The category label to search for
  /// @returns CategoryData if found, null otherwise
  static CategoryData? getCategoryByLabel(String label) {
    try {
      return defaultCategories.firstWhere(
        (CategoryData category) => category.label == label,
      );
    } catch (e) {
      return null;
    }
  }

  /// Gets the category data for a specific ApplicationCategory enum.
  ///
  /// Creates CategoryData from the enum's properties. Useful for converting
  /// between the enum representation and UI display data.
  ///
  /// @param category The ApplicationCategory enum value
  /// @param count Optional application count for this category
  /// @returns CategoryData with enum's icon and display name
  static CategoryData getCategoryData(
    ApplicationCategory category, {
    int count = 0,
  }) {
    return CategoryData(
      icon: category.icon,
      label: category.displayName,
      count: count,
    );
  }

  /// Gets all category labels as a list of strings.
  ///
  /// Useful for validation, dropdown lists, or other scenarios
  /// where only the category names are needed.
  ///
  /// @returns List of all category labels
  static List<String> get categoryLabels {
    return defaultCategories
        .map((CategoryData category) => category.label)
        .toList();
  }

  /// Gets the total number of applications across all categories.
  ///
  /// Calculates the sum of application counts from all categories.
  /// Useful for displaying overall statistics or validation.
  ///
  /// @returns Total application count across all categories
  static int get totalApplicationCount {
    return defaultCategories.fold<int>(
      0,
      (int sum, CategoryData category) => sum + category.count,
    );
  }

  /// Updates the application count for a specific category.
  ///
  /// Creates a new list with the updated count for the specified category.
  /// Since the default categories are immutable, this returns a new list
  /// rather than modifying the existing one.
  ///
  /// @param label The category label to update
  /// @param newCount The new application count
  /// @returns New list with updated category, or original list if category not found
  static List<CategoryData> updateCategoryCount(String label, int newCount) {
    return defaultCategories.map((CategoryData category) {
      if (category.label == label) {
        return category.copyWith(count: newCount);
      }
      return category;
    }).toList();
  }
}
