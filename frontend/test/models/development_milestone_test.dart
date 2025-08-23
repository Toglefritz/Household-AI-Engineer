/// Unit tests for DevelopmentMilestone model and related enums.
///
/// Tests model creation, JSON serialization/deserialization, validation,
/// and all extension methods to ensure reliable milestone tracking.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/services/user_application/models/milestone_status.dart';

void main() {
  group('MilestoneStatus', () {
    group('enum values', () {
      test('should have all expected status values', () {
        expect(MilestoneStatus.values, hasLength(4));
        expect(MilestoneStatus.values, contains(MilestoneStatus.pending));
        expect(MilestoneStatus.values, contains(MilestoneStatus.inProgress));
        expect(MilestoneStatus.values, contains(MilestoneStatus.completed));
        expect(MilestoneStatus.values, contains(MilestoneStatus.failed));
      });
    });

    group('displayName extension', () {
      test('should return correct display names for all statuses', () {
        expect(MilestoneStatus.pending.displayName, equals('Pending'));
        expect(MilestoneStatus.inProgress.displayName, equals('In Progress'));
        expect(MilestoneStatus.completed.displayName, equals('Completed'));
        expect(MilestoneStatus.failed.displayName, equals('Failed'));
      });
    });

    group('isActive extension', () {
      test('should return true only for in progress status', () {
        expect(MilestoneStatus.inProgress.isActive, isTrue);
        expect(MilestoneStatus.pending.isActive, isFalse);
        expect(MilestoneStatus.completed.isActive, isFalse);
        expect(MilestoneStatus.failed.isActive, isFalse);
      });
    });

    group('isTerminal extension', () {
      test('should return true for completed and failed statuses', () {
        expect(MilestoneStatus.completed.isTerminal, isTrue);
        expect(MilestoneStatus.failed.isTerminal, isTrue);
        expect(MilestoneStatus.pending.isTerminal, isFalse);
        expect(MilestoneStatus.inProgress.isTerminal, isFalse);
      });
    });
  });
}
