/// Unit tests for ApplicationStatus enum and its extension methods.
///
/// Tests all enum values, extension methods, and edge cases to ensure
/// reliable behavior across different application states.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/services/user_application/models/application_status.dart';

void main() {
  group('ApplicationStatus', () {
    group('enum values', () {
      test('should have all expected status values', () {
        expect(ApplicationStatus.values, hasLength(7));
        expect(ApplicationStatus.values, contains(ApplicationStatus.requested));
        expect(
          ApplicationStatus.values,
          contains(ApplicationStatus.developing),
        );
        expect(ApplicationStatus.values, contains(ApplicationStatus.testing));
        expect(ApplicationStatus.values, contains(ApplicationStatus.ready));
        expect(ApplicationStatus.values, contains(ApplicationStatus.running));
        expect(ApplicationStatus.values, contains(ApplicationStatus.failed));
        expect(ApplicationStatus.values, contains(ApplicationStatus.updating));
      });
    });

    group('displayName extension', () {
      test('should return correct display names for all statuses', () {
        expect(ApplicationStatus.requested.displayName, equals('Requested'));
        expect(ApplicationStatus.developing.displayName, equals('Developing'));
        expect(ApplicationStatus.testing.displayName, equals('Testing'));
        expect(ApplicationStatus.ready.displayName, equals('Ready'));
        expect(ApplicationStatus.running.displayName, equals('Running'));
        expect(ApplicationStatus.failed.displayName, equals('Failed'));
        expect(ApplicationStatus.updating.displayName, equals('Updating'));
      });
    });

    group('isActive extension', () {
      test('should return true for active development states', () {
        expect(ApplicationStatus.developing.isActive, isTrue);
        expect(ApplicationStatus.testing.isActive, isTrue);
        expect(ApplicationStatus.updating.isActive, isTrue);
      });

      test('should return false for non-active states', () {
        expect(ApplicationStatus.requested.isActive, isFalse);
        expect(ApplicationStatus.ready.isActive, isFalse);
        expect(ApplicationStatus.running.isActive, isFalse);
        expect(ApplicationStatus.failed.isActive, isFalse);
      });
    });

    group('isTerminal extension', () {
      test('should return true for terminal states', () {
        expect(ApplicationStatus.ready.isTerminal, isTrue);
        expect(ApplicationStatus.running.isTerminal, isTrue);
        expect(ApplicationStatus.failed.isTerminal, isTrue);
      });

      test('should return false for non-terminal states', () {
        expect(ApplicationStatus.requested.isTerminal, isFalse);
        expect(ApplicationStatus.developing.isTerminal, isFalse);
        expect(ApplicationStatus.testing.isTerminal, isFalse);
        expect(ApplicationStatus.updating.isTerminal, isFalse);
      });
    });

    group('canLaunch extension', () {
      test('should return true for launchable states', () {
        expect(ApplicationStatus.ready.canLaunch, isTrue);
        expect(ApplicationStatus.running.canLaunch, isTrue);
      });

      test('should return false for non-launchable states', () {
        expect(ApplicationStatus.requested.canLaunch, isFalse);
        expect(ApplicationStatus.developing.canLaunch, isFalse);
        expect(ApplicationStatus.testing.canLaunch, isFalse);
        expect(ApplicationStatus.failed.canLaunch, isFalse);
        expect(ApplicationStatus.updating.canLaunch, isFalse);
      });
    });

    group('canModify extension', () {
      test('should return true for modifiable states', () {
        expect(ApplicationStatus.ready.canModify, isTrue);
        expect(ApplicationStatus.running.canModify, isTrue);
        expect(ApplicationStatus.failed.canModify, isTrue);
      });

      test('should return false for non-modifiable states', () {
        expect(ApplicationStatus.requested.canModify, isFalse);
        expect(ApplicationStatus.developing.canModify, isFalse);
        expect(ApplicationStatus.testing.canModify, isFalse);
        expect(ApplicationStatus.updating.canModify, isFalse);
      });
    });
  });
}
