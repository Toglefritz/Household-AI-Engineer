/// Unit tests for DevelopmentMilestone model and related enums.
///
/// Tests model creation, JSON serialization/deserialization, validation,
/// and all extension methods to ensure reliable milestone tracking.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/models/models.dart';

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

  group('DevelopmentMilestone', () {
    final DevelopmentMilestone testMilestone = DevelopmentMilestone(
      id: 'milestone_123',
      name: 'Generate Code',
      description: 'Generate application source code',
      status: MilestoneStatus.completed,
      order: 1,
      completedAt: DateTime(2025, 1, 10, 14, 30),
    );

    group('constructor', () {
      test('should create milestone with all required fields', () {
        expect(testMilestone.id, equals('milestone_123'));
        expect(testMilestone.name, equals('Generate Code'));
        expect(testMilestone.description, equals('Generate application source code'));
        expect(testMilestone.status, equals(MilestoneStatus.completed));
        expect(testMilestone.order, equals(1));
        expect(testMilestone.completedAt, equals(DateTime(2025, 1, 10, 14, 30)));
        expect(testMilestone.errorMessage, isNull);
      });
    });

    group('fromJson', () {
      test('should create milestone from valid JSON', () {
        final Map<String, dynamic> json = {
          'id': 'milestone_456',
          'name': 'Run Tests',
          'description': 'Execute automated test suite',
          'status': 'inProgress',
          'order': 2,
          'completedAt': null,
          'errorMessage': null,
        };

        final DevelopmentMilestone milestone = DevelopmentMilestone.fromJson(json);

        expect(milestone.id, equals('milestone_456'));
        expect(milestone.name, equals('Run Tests'));
        expect(milestone.description, equals('Execute automated test suite'));
        expect(milestone.status, equals(MilestoneStatus.inProgress));
        expect(milestone.order, equals(2));
        expect(milestone.completedAt, isNull);
        expect(milestone.errorMessage, isNull);
      });

      test('should handle completed milestone with timestamp', () {
        final Map<String, dynamic> json = {
          'id': 'milestone_789',
          'name': 'Build Container',
          'description': 'Create application container',
          'status': 'completed',
          'order': 3,
          'completedAt': '2025-01-10T15:45:00.000Z',
          'errorMessage': null,
        };

        final DevelopmentMilestone milestone = DevelopmentMilestone.fromJson(json);

        expect(milestone.status, equals(MilestoneStatus.completed));
        expect(milestone.completedAt, equals(DateTime.parse('2025-01-10T15:45:00.000Z')));
      });

      test('should handle failed milestone with error message', () {
        final Map<String, dynamic> json = {
          'id': 'milestone_error',
          'name': 'Deploy Application',
          'description': 'Deploy to production environment',
          'status': 'failed',
          'order': 4,
          'completedAt': null,
          'errorMessage': 'Deployment failed: insufficient resources',
        };

        final DevelopmentMilestone milestone = DevelopmentMilestone.fromJson(json);

        expect(milestone.status, equals(MilestoneStatus.failed));
        expect(milestone.errorMessage, equals('Deployment failed: insufficient resources'));
      });

      test('should throw FormatException for missing required fields', () {
        final Map<String, dynamic> invalidJson = {
          'name': 'Test Milestone',
          // Missing id, description, status, order
        };

        expect(() => DevelopmentMilestone.fromJson(invalidJson), throwsA(isA<FormatException>()));
      });

      test('should throw FormatException for invalid status', () {
        final Map<String, dynamic> invalidJson = {
          'id': 'milestone_invalid',
          'name': 'Test Milestone',
          'description': 'Test description',
          'status': 'invalid_status',
          'order': 1,
        };

        expect(() => DevelopmentMilestone.fromJson(invalidJson), throwsA(isA<FormatException>()));
      });
    });

    group('toJson', () {
      test('should convert milestone to JSON correctly', () {
        final Map<String, dynamic> json = testMilestone.toJson();

        expect(json['id'], equals('milestone_123'));
        expect(json['name'], equals('Generate Code'));
        expect(json['description'], equals('Generate application source code'));
        expect(json['status'], equals('completed'));
        expect(json['order'], equals(1));
        expect(json['completedAt'], equals('2025-01-10T14:30:00.000'));
        expect(json['errorMessage'], isNull);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final DevelopmentMilestone updated = testMilestone.copyWith(status: MilestoneStatus.failed, errorMessage: 'Test error');

        expect(updated.id, equals(testMilestone.id));
        expect(updated.name, equals(testMilestone.name));
        expect(updated.status, equals(MilestoneStatus.failed));
        expect(updated.errorMessage, equals('Test error'));
      });
    });

    group('equality and hashCode', () {
      test('should be equal for identical milestones', () {
        const DevelopmentMilestone milestone1 = DevelopmentMilestone(
          id: 'test_id',
          name: 'Test',
          description: 'Test description',
          status: MilestoneStatus.pending,
          order: 1,
        );

        const DevelopmentMilestone milestone2 = DevelopmentMilestone(
          id: 'test_id',
          name: 'Test',
          description: 'Test description',
          status: MilestoneStatus.pending,
          order: 1,
        );

        expect(milestone1, equals(milestone2));
        expect(milestone1.hashCode, equals(milestone2.hashCode));
      });

      test('should not be equal for different milestones', () {
        const DevelopmentMilestone milestone1 = DevelopmentMilestone(
          id: 'test_id_1',
          name: 'Test',
          description: 'Test description',
          status: MilestoneStatus.pending,
          order: 1,
        );

        const DevelopmentMilestone milestone2 = DevelopmentMilestone(
          id: 'test_id_2',
          name: 'Test',
          description: 'Test description',
          status: MilestoneStatus.pending,
          order: 1,
        );

        expect(milestone1, isNot(equals(milestone2)));
      });
    });
  });
}
