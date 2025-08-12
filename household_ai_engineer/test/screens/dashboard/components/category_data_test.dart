import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/screens/dashboard/components/category_data.dart';

/// Unit tests for the CategoryData model.
///
/// Verifies that the category data model behaves correctly for
/// data storage, equality comparisons, and immutable updates.
void main() {
  group('CategoryData', () {
    /// Test data for category testing.
    const IconData testIcon = Icons.home;
    const String testLabel = 'Test Category';
    const int testCount = 5;

    /// Creates a test CategoryData instance.
    CategoryData createTestCategory() {
      return const CategoryData(
        icon: testIcon,
        label: testLabel,
        count: testCount,
      );
    }

    group('constructor', () {
      /// Verifies that CategoryData can be created with valid parameters.
      ///
      /// Should store all provided values correctly and make them
      /// accessible through getter properties.
      test('should create category with valid parameters', () {
        final CategoryData category = createTestCategory();

        expect(category.icon, testIcon);
        expect(category.label, testLabel);
        expect(category.count, testCount);
      });

      /// Verifies that CategoryData can be created as a const instance.
      ///
      /// Should support compile-time constant creation for better
      /// performance and memory usage.
      test('should support const constructor', () {
        const CategoryData category = CategoryData(
          icon: Icons.test,
          label: 'Const Category',
          count: 10,
        );

        expect(category.icon, Icons.test);
        expect(category.label, 'Const Category');
        expect(category.count, 10);
      });
    });

    group('copyWith', () {
      /// Verifies that copyWith creates a new instance with updated icon.
      ///
      /// Should preserve other properties while updating only the
      /// specified icon value.
      test('should create copy with updated icon', () {
        final CategoryData original = createTestCategory();
        final CategoryData updated = original.copyWith(icon: Icons.star);

        expect(updated.icon, Icons.star);
        expect(updated.label, testLabel);
        expect(updated.count, testCount);
        expect(updated, isNot(same(original)));
      });

      /// Verifies that copyWith creates a new instance with updated label.
      ///
      /// Should preserve other properties while updating only the
      /// specified label value.
      test('should create copy with updated label', () {
        final CategoryData original = createTestCategory();
        final CategoryData updated = original.copyWith(label: 'Updated Label');

        expect(updated.icon, testIcon);
        expect(updated.label, 'Updated Label');
        expect(updated.count, testCount);
        expect(updated, isNot(same(original)));
      });

      /// Verifies that copyWith creates a new instance with updated count.
      ///
      /// Should preserve other properties while updating only the
      /// specified count value.
      test('should create copy with updated count', () {
        final CategoryData original = createTestCategory();
        final CategoryData updated = original.copyWith(count: 10);

        expect(updated.icon, testIcon);
        expect(updated.label, testLabel);
        expect(updated.count, 10);
        expect(updated, isNot(same(original)));
      });

      /// Verifies that copyWith can update multiple properties at once.
      ///
      /// Should allow updating any combination of properties in a
      /// single operation while preserving unspecified properties.
      test('should create copy with multiple updated properties', () {
        final CategoryData original = createTestCategory();
        final CategoryData updated = original.copyWith(
          icon: Icons.star,
          count: 15,
        );

        expect(updated.icon, Icons.star);
        expect(updated.label, testLabel); // Preserved
        expect(updated.count, 15);
        expect(updated, isNot(same(original)));
      });

      /// Verifies that copyWith with no parameters creates an identical copy.
      ///
      /// Should create a new instance with all the same property values
      /// when no update parameters are provided.
      test('should create identical copy when no parameters provided', () {
        final CategoryData original = createTestCategory();
        final CategoryData copy = original.copyWith();

        expect(copy.icon, original.icon);
        expect(copy.label, original.label);
        expect(copy.count, original.count);
        expect(copy, equals(original));
        expect(copy, isNot(same(original)));
      });
    });

    group('equality', () {
      /// Verifies that CategoryData instances with same values are equal.
      ///
      /// Should implement proper equality comparison based on all
      /// property values rather than object identity.
      test('should be equal when all properties match', () {
        final CategoryData category1 = createTestCategory();
        final CategoryData category2 = createTestCategory();

        expect(category1, equals(category2));
        expect(category1.hashCode, equals(category2.hashCode));
      });

      /// Verifies that CategoryData instances with different icons are not equal.
      ///
      /// Should distinguish between categories based on their icon
      /// property values.
      test('should not be equal when icons differ', () {
        final CategoryData category1 = createTestCategory();
        final CategoryData category2 = category1.copyWith(icon: Icons.star);

        expect(category1, isNot(equals(category2)));
        expect(category1.hashCode, isNot(equals(category2.hashCode)));
      });

      /// Verifies that CategoryData instances with different labels are not equal.
      ///
      /// Should distinguish between categories based on their label
      /// property values.
      test('should not be equal when labels differ', () {
        final CategoryData category1 = createTestCategory();
        final CategoryData category2 = category1.copyWith(label: 'Different Label');

        expect(category1, isNot(equals(category2)));
        expect(category1.hashCode, isNot(equals(category2.hashCode)));
      });

      /// Verifies that CategoryData instances with different counts are not equal.
      ///
      /// Should distinguish between categories based on their count
      /// property values.
      test('should not be equal when counts differ', () {
        final CategoryData category1 = createTestCategory();
        final CategoryData category2 = category1.copyWith(count: 10);

        expect(category1, isNot(equals(category2)));
        expect(category1.hashCode, isNot(equals(category2.hashCode)));
      });

      /// Verifies that CategoryData is not equal to objects of different types.
      ///
      /// Should properly handle equality comparisons with non-CategoryData
      /// objects without throwing exceptions.
      test('should not be equal to objects of different types', () {
        final CategoryData category = createTestCategory();

        expect(category, isNot(equals('string')));
        expect(category, isNot(equals(42)));
        expect(category, isNot(equals(null)));
      });

      /// Verifies that CategoryData is equal to itself (reflexive property).
      ///
      /// Should satisfy the reflexive property of equality where
      /// an object is always equal to itself.
      test('should be equal to itself', () {
        final CategoryData category = createTestCategory();

        expect(category, equals(category));
        expect(identical(category, category), isTrue);
      });
    });

    group('toString', () {
      /// Verifies that toString provides meaningful string representation.
      ///
      /// Should include all property values in a readable format
      /// for debugging and logging purposes.
      test('should provide meaningful string representation', () {
        final CategoryData category = createTestCategory();
        final String stringRepresentation = category.toString();

        expect(stringRepresentation, contains('CategoryData'));
        expect(stringRepresentation, contains(testIcon.toString()));
        expect(stringRepresentation, contains(testLabel));
        expect(stringRepresentation, contains(testCount.toString()));
      });

      /// Verifies that toString handles different property values correctly.
      ///
      /// Should adapt the string representation based on the actual
      /// property values of the instance.
      test('should handle different property values in string representation', () {
        const CategoryData category = CategoryData(
          icon: Icons.star,
          label: 'Special Category',
          count: 99,
        );
        final String stringRepresentation = category.toString();

        expect(stringRepresentation, contains('Special Category'));
        expect(stringRepresentation, contains('99'));
      });
    });
  });
}
