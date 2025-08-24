import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/services/user_application/models/application_category.dart';
import 'package:household_ai_engineer/services/user_application/models/application_status.dart';
import 'package:household_ai_engineer/services/user_application/models/user_application.dart';

/// Test suite for UserApplication model functionality.
///
/// This test suite covers JSON serialization/deserialization, category handling,
/// and the integration with the new ApplicationCategory enum system.
void main() {
  group('UserApplication', () {
    group('category enum integration', () {
      /// Tests that applications can be created with ApplicationCategory enum values.
      ///
      /// Verifies that the enum integration works correctly and that category
      /// properties are properly accessible through the model.
      test('should create application with category enum', () {
        final DateTime now = DateTime.now();
        final UserApplication app = UserApplication(
          id: 'test-app-1',
          title: 'Test Application',
          description: 'A test application for unit testing',
          status: ApplicationStatus.ready,
          createdAt: now,
          updatedAt: now,
          category: ApplicationCategory.homeManagement,
          tags: const ['test', 'example'],
        );

        expect(app.category, equals(ApplicationCategory.homeManagement));
        expect(app.hasCategory, isTrue);
        expect(app.category?.displayName, equals('Home Management'));
        expect(app.category?.icon, isNotNull);
      });

      /// Tests JSON serialization with category enum values.
      ///
      /// Verifies that ApplicationCategory enums are properly converted to
      /// their string representation during JSON serialization.
      test('should serialize category enum to JSON', () {
        final DateTime now = DateTime.now();
        final UserApplication app = UserApplication(
          id: 'test-app-1',
          title: 'Test Application',
          description: 'A test application for unit testing',
          status: ApplicationStatus.ready,
          createdAt: now,
          updatedAt: now,
          category: ApplicationCategory.finance,
        );

        final Map<String, dynamic> json = app.toJson();

        expect(json['category'], equals('finance'));
      });

      /// Tests JSON deserialization with category enum values.
      ///
      /// Verifies that category strings from JSON are properly parsed into
      /// ApplicationCategory enum values during deserialization.
      test('should deserialize category from JSON', () {
        final Map<String, dynamic> json = {
          'id': 'test-app-1',
          'title': 'Test Application',
          'description': 'A test application for unit testing',
          'status': 'ready',
          'createdAt': '2025-01-10T10:00:00.000Z',
          'updatedAt': '2025-01-10T10:00:00.000Z',
          'category': 'healthAndFitness',
          'tags': ['test', 'example'],
        };

        final UserApplication app = UserApplication.fromJson(json);

        expect(app.category, equals(ApplicationCategory.healthAndFitness));
        expect(app.category?.displayName, equals('Health & Fitness'));
      });

      /// Tests handling of null category values.
      ///
      /// Verifies that applications without categories are handled gracefully
      /// and that hasCategory returns false for null categories.
      test('should handle null category gracefully', () {
        final DateTime now = DateTime.now();
        final UserApplication app = UserApplication(
          id: 'test-app-1',
          title: 'Test Application',
          description: 'A test application for unit testing',
          status: ApplicationStatus.ready,
          createdAt: now,
          updatedAt: now,
          category: null,
        );

        expect(app.category, isNull);
        expect(app.hasCategory, isFalse);
      });

      /// Tests handling of invalid category strings during JSON parsing.
      ///
      /// Verifies that invalid category values are handled gracefully by
      /// returning null rather than throwing exceptions.
      test('should handle invalid category strings gracefully', () {
        final Map<String, dynamic> json = {
          'id': 'test-app-1',
          'title': 'Test Application',
          'description': 'A test application for unit testing',
          'status': 'ready',
          'createdAt': '2025-01-10T10:00:00.000Z',
          'updatedAt': '2025-01-10T10:00:00.000Z',
          'category': 'invalidCategory',
          'tags': ['test', 'example'],
        };

        final UserApplication app = UserApplication.fromJson(json);

        expect(app.category, isNull);
        expect(app.hasCategory, isFalse);
      });

      /// Tests copyWith functionality with category enum.
      ///
      /// Verifies that the copyWith method properly handles ApplicationCategory
      /// enum values and creates new instances with updated categories.
      test('should copy application with updated category', () {
        final DateTime now = DateTime.now();
        final UserApplication originalApp = UserApplication(
          id: 'test-app-1',
          title: 'Test Application',
          description: 'A test application for unit testing',
          status: ApplicationStatus.ready,
          createdAt: now,
          updatedAt: now,
          category: ApplicationCategory.utilities,
        );

        final UserApplication updatedApp = originalApp.copyWith(
          category: ApplicationCategory.entertainment,
        );

        expect(originalApp.category, equals(ApplicationCategory.utilities));
        expect(updatedApp.category, equals(ApplicationCategory.entertainment));
        expect(updatedApp.id, equals(originalApp.id)); // Other fields unchanged
      });
    });

    group('ApplicationCategory enum', () {
      /// Tests that all category enum values have proper display names.
      ///
      /// Verifies that every ApplicationCategory enum value has a non-empty
      /// display name suitable for UI presentation.
      test('should have display names for all categories', () {
        for (final ApplicationCategory category in ApplicationCategory.values) {
          expect(category.displayName, isNotEmpty);
          expect(category.displayName, isNot(equals(category.name)));
        }
      });

      /// Tests that all category enum values have associated icons.
      ///
      /// Verifies that every ApplicationCategory enum value has a valid
      /// Material Design icon for UI representation.
      test('should have icons for all categories', () {
        for (final ApplicationCategory category in ApplicationCategory.values) {
          expect(category.icon, isNotNull);
        }
      });

      /// Tests category parsing from various string formats.
      ///
      /// Verifies that ApplicationCategory.fromString can handle different
      /// string formats including enum names and display names.
      test('should parse categories from different string formats', () {
        // Test enum name parsing
        expect(
          ApplicationCategory.fromString('homeManagement'),
          equals(ApplicationCategory.homeManagement),
        );

        // Test display name parsing (with spaces and special characters)
        expect(
          ApplicationCategory.fromString('Health & Fitness'),
          equals(ApplicationCategory.healthAndFitness),
        );

        // Test case insensitive parsing
        expect(
          ApplicationCategory.fromString('FINANCE'),
          equals(ApplicationCategory.finance),
        );
      });

      /// Tests error handling for invalid category strings.
      ///
      /// Verifies that ApplicationCategory.fromString throws appropriate
      /// errors for invalid input values.
      test('should throw error for invalid category strings', () {
        expect(
          () => ApplicationCategory.fromString('invalidCategory'),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => ApplicationCategory.fromString(''),
          throwsA(isA<ArgumentError>()),
        );
      });

      /// Tests that category lists are properly generated.
      ///
      /// Verifies that the static methods for getting category lists
      /// return the expected number of categories and proper values.
      test('should provide complete category lists', () {
        final List<String> displayNames = ApplicationCategory.allDisplayNames;
        final List<String> enumNames = ApplicationCategory.allEnumNames;

        expect(displayNames.length, equals(ApplicationCategory.values.length));
        expect(enumNames.length, equals(ApplicationCategory.values.length));
        expect(displayNames, contains('Home Management'));
        expect(enumNames, contains('homeManagement'));
      });
    });
  });
}
