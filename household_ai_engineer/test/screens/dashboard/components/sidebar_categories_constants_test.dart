import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/screens/dashboard/components/category_data.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar_categories_constants.dart';

/// Unit tests for the SidebarCategoriesConstants class.
///
/// Verifies that the category constants provide correct default data
/// and utility methods for category management.
void main() {
  group('SidebarCategoriesConstants', () {
    group('defaultCategories', () {
      /// Verifies that default categories list is not empty.
      ///
      /// Should provide a reasonable set of default categories
      /// for household application organization.
      test('should provide non-empty default categories', () {
        expect(SidebarCategoriesConstants.defaultCategories, isNotEmpty);
        expect(SidebarCategoriesConstants.defaultCategories.length, greaterThan(0));
      });

      /// Verifies that all default categories have valid data.
      ///
      /// Should ensure that each category has proper icon, label,
      /// and count values without null or invalid data.
      test('should have valid data for all default categories', () {
        for (final CategoryData category in SidebarCategoriesConstants.defaultCategories) {
          expect(category.icon, isNotNull);
          expect(category.label, isNotNull);
          expect(category.label, isNotEmpty);
          expect(category.count, greaterThanOrEqualTo(0));
        }
      });

      /// Verifies that default categories have unique labels.
      ///
      /// Should prevent duplicate category names that could cause
      /// confusion or conflicts in the user interface.
      test('should have unique labels for all categories', () {
        final List<String> labels = SidebarCategoriesConstants.defaultCategories
            .map((CategoryData category) => category.label)
            .toList();
        final Set<String> uniqueLabels = labels.toSet();

        expect(labels.length, equals(uniqueLabels.length));
      });

      /// Verifies that default categories include expected household categories.
      ///
      /// Should provide categories that are relevant for typical
      /// household management applications.
      test('should include expected household categories', () {
        final List<String> labels = SidebarCategoriesConstants.categoryLabels;

        expect(labels, contains('Home Management'));
        expect(labels, contains('Finance'));
        expect(labels, contains('Planning'));
        expect(labels, contains('Health & Fitness'));
        expect(labels, contains('Education'));
      });
    });

    group('getCategoryByLabel', () {
      /// Verifies that getCategoryByLabel returns correct category for valid label.
      ///
      /// Should find and return the category data for labels that exist
      /// in the default categories list.
      test('should return category for valid label', () {
        const String testLabel = 'Home Management';
        final CategoryData? category = SidebarCategoriesConstants.getCategoryByLabel(testLabel);

        expect(category, isNotNull);
        expect(category!.label, equals(testLabel));
        expect(category.icon, equals(Icons.home));
      });

      /// Verifies that getCategoryByLabel returns null for invalid label.
      ///
      /// Should handle cases where the requested category label
      /// does not exist in the default categories.
      test('should return null for invalid label', () {
        const String invalidLabel = 'Nonexistent Category';
        final CategoryData? category = SidebarCategoriesConstants.getCategoryByLabel(invalidLabel);

        expect(category, isNull);
      });

      /// Verifies that getCategoryByLabel handles empty string.
      ///
      /// Should gracefully handle edge cases like empty strings
      /// without throwing exceptions.
      test('should return null for empty label', () {
        final CategoryData? category = SidebarCategoriesConstants.getCategoryByLabel('');

        expect(category, isNull);
      });

      /// Verifies that getCategoryByLabel is case-sensitive.
      ///
      /// Should distinguish between labels with different casing
      /// to ensure precise matching.
      test('should be case-sensitive for label matching', () {
        final CategoryData? category = SidebarCategoriesConstants.getCategoryByLabel('home management');

        expect(category, isNull); // Should not match 'Home Management'
      });
    });

    group('categoryLabels', () {
      /// Verifies that categoryLabels returns all category labels.
      ///
      /// Should provide a complete list of all category names
      /// from the default categories.
      test('should return all category labels', () {
        final List<String> labels = SidebarCategoriesConstants.categoryLabels;
        final int expectedCount = SidebarCategoriesConstants.defaultCategories.length;

        expect(labels.length, equals(expectedCount));

        for (final CategoryData category in SidebarCategoriesConstants.defaultCategories) {
          expect(labels, contains(category.label));
        }
      });

      /// Verifies that categoryLabels returns labels in same order as categories.
      ///
      /// Should maintain the same ordering as the default categories
      /// list for consistency.
      test('should return labels in same order as default categories', () {
        final List<String> labels = SidebarCategoriesConstants.categoryLabels;
        final List<String> expectedLabels = SidebarCategoriesConstants.defaultCategories
            .map((CategoryData category) => category.label)
            .toList();

        expect(labels, equals(expectedLabels));
      });
    });

    group('totalApplicationCount', () {
      /// Verifies that totalApplicationCount sums all category counts.
      ///
      /// Should calculate the correct total by adding up the count
      /// values from all default categories.
      test('should sum all category counts', () {
        final int total = SidebarCategoriesConstants.totalApplicationCount;
        final int expectedTotal = SidebarCategoriesConstants.defaultCategories.fold<int>(
          0,
          (int sum, CategoryData category) => sum + category.count,
        );

        expect(total, equals(expectedTotal));
        expect(total, greaterThan(0)); // Should have some applications
      });

      /// Verifies that totalApplicationCount matches manual calculation.
      ///
      /// Should produce the same result as manually adding up the
      /// known category counts.
      test('should match manual calculation of total count', () {
        int manualTotal = 0;
        for (final CategoryData category in SidebarCategoriesConstants.defaultCategories) {
          manualTotal += category.count;
        }

        expect(SidebarCategoriesConstants.totalApplicationCount, equals(manualTotal));
      });
    });

    group('updateCategoryCount', () {
      /// Verifies that updateCategoryCount updates the correct category.
      ///
      /// Should create a new list with the updated count for the
      /// specified category while preserving other categories.
      test('should update count for existing category', () {
        const String testLabel = 'Finance';
        const int newCount = 10;

        final List<CategoryData> updatedCategories = SidebarCategoriesConstants.updateCategoryCount(
          testLabel,
          newCount,
        );

        final CategoryData? updatedCategory = updatedCategories
            .where((CategoryData category) => category.label == testLabel)
            .firstOrNull;

        expect(updatedCategory, isNotNull);
        expect(updatedCategory!.count, equals(newCount));
        expect(updatedCategories.length, equals(SidebarCategoriesConstants.defaultCategories.length));
      });

      /// Verifies that updateCategoryCount preserves other categories.
      ///
      /// Should not modify categories other than the one being updated
      /// and maintain the same list structure.
      test('should preserve other categories when updating', () {
        const String testLabel = 'Finance';
        const int newCount = 10;

        final List<CategoryData> updatedCategories = SidebarCategoriesConstants.updateCategoryCount(
          testLabel,
          newCount,
        );

        // Check that other categories are unchanged
        for (final CategoryData originalCategory in SidebarCategoriesConstants.defaultCategories) {
          if (originalCategory.label != testLabel) {
            final CategoryData? updatedCategory = updatedCategories
                .where((CategoryData category) => category.label == originalCategory.label)
                .firstOrNull;

            expect(updatedCategory, equals(originalCategory));
          }
        }
      });

      /// Verifies that updateCategoryCount returns original list for invalid label.
      ///
      /// Should handle cases where the specified category label
      /// does not exist without modifying the list.
      test('should return original list for invalid label', () {
        const String invalidLabel = 'Nonexistent Category';
        const int newCount = 10;

        final List<CategoryData> updatedCategories = SidebarCategoriesConstants.updateCategoryCount(
          invalidLabel,
          newCount,
        );

        expect(updatedCategories.length, equals(SidebarCategoriesConstants.defaultCategories.length));

        // All categories should be unchanged
        for (int i = 0; i < updatedCategories.length; i++) {
          expect(updatedCategories[i], equals(SidebarCategoriesConstants.defaultCategories[i]));
        }
      });

      /// Verifies that updateCategoryCount handles zero and negative counts.
      ///
      /// Should accept any integer value for the count, including
      /// zero and negative numbers for edge cases.
      test('should handle zero and negative counts', () {
        const String testLabel = 'Planning';

        // Test zero count
        final List<CategoryData> zeroCategories = SidebarCategoriesConstants.updateCategoryCount(testLabel, 0);
        final CategoryData? zeroCategory = zeroCategories
            .where((CategoryData category) => category.label == testLabel)
            .firstOrNull;
        expect(zeroCategory!.count, equals(0));

        // Test negative count
        final List<CategoryData> negativeCategories = SidebarCategoriesConstants.updateCategoryCount(testLabel, -1);
        final CategoryData? negativeCategory = negativeCategories
            .where((CategoryData category) => category.label == testLabel)
            .firstOrNull;
        expect(negativeCategory!.count, equals(-1));
      });
    });
  });
}
