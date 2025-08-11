/// Unit tests for DevelopmentProgress model and related classes.
///
/// Tests model creation, JSON serialization/deserialization, validation,
/// and all utility methods to ensure reliable progress tracking.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/models/models.dart';

void main() {
  group('DevelopmentProgress', () {
    final List<DevelopmentMilestone> testMilestones = [
      DevelopmentMilestone(
        id: 'milestone_1',
        name: 'Generate Code',
        description: 'Generate application code',
        status: MilestoneStatus.completed,
        order: 1,
        completedAt: DateTime(2025, 1, 10, 14),
      ),
      const DevelopmentMilestone(
        id: 'milestone_2',
        name: 'Run Tests',
        description: 'Execute test suite',
        status: MilestoneStatus.inProgress,
        order: 2,
      ),
      const DevelopmentMilestone(
        id: 'milestone_3',
        name: 'Build Container',
        description: 'Create container image',
        status: MilestoneStatus.pending,
        order: 3,
      ),
    ];

    final DevelopmentProgress testProgress = DevelopmentProgress(
      percentage: 65.5,
      currentPhase: 'Running Tests',
      milestones: testMilestones,
      lastUpdated: DateTime(2025, 1, 10, 14, 32),
      estimatedCompletion: DateTime(2025, 1, 10, 15),
    );

    group('constructor', () {
      test('should create progress with all required fields', () {
        expect(testProgress.percentage, equals(65.5));
        expect(testProgress.currentPhase, equals('Running Tests'));
        expect(testProgress.milestones, hasLength(3));
        expect(testProgress.lastUpdated, equals(DateTime(2025, 1, 10, 14, 32)));
        expect(testProgress.estimatedCompletion, equals(DateTime(2025, 1, 10, 15)));
      });
    });

    group('utility methods', () {
      test('should find current milestone correctly', () {
        final currentMilestone = testProgress.currentMilestone;
        expect(currentMilestone, isNotNull);
        expect(currentMilestone!.name, equals('Run Tests'));
        expect(currentMilestone.status, equals(MilestoneStatus.inProgress));
      });

      test('should count completed milestones correctly', () {
        expect(testProgress.completedMilestoneCount, equals(1));
      });

      test('should return total milestone count correctly', () {
        expect(testProgress.totalMilestoneCount, equals(3));
      });

      test('should detect failure correctly', () {
        expect(testProgress.hasFailed, isFalse);

        final DevelopmentProgress failedProgress = testProgress.copyWith(
          milestones: [
            ...testMilestones,
            const DevelopmentMilestone(
              id: 'failed_milestone',
              name: 'Failed Step',
              description: 'This step failed',
              status: MilestoneStatus.failed,
              order: 4,
              errorMessage: 'Something went wrong',
            ),
          ],
        );

        expect(failedProgress.hasFailed, isTrue);
      });

      test('should detect completion correctly', () {
        expect(testProgress.isComplete, isFalse);

        final List<DevelopmentMilestone> completedMilestones = testMilestones.map((m) => m.copyWith(status: MilestoneStatus.completed)).toList();

        final DevelopmentProgress completedProgress = testProgress.copyWith(milestones: completedMilestones);

        expect(completedProgress.isComplete, isTrue);
      });
    });

    group('fromJson', () {
      test('should create progress from valid JSON', () {
        final Map<String, dynamic> json = {
          'percentage': 75.0,
          'currentPhase': 'Building Container',
          'milestones': [
            {
              'id': 'milestone_test',
              'name': 'Test Milestone',
              'description': 'Test description',
              'status': 'completed',
              'order': 1,
              'completedAt': '2025-01-10T14:00:00.000Z',
              'errorMessage': null,
            },
          ],
          'recentLogs': [
            {'timestamp': '2025-01-10T14:30:00.000Z', 'level': 'info', 'message': 'Test log', 'source': 'test-source'},
          ],
          'lastUpdated': '2025-01-10T14:32:00.000Z',
          'estimatedCompletion': '2025-01-10T15:00:00.000Z',
        };

        final DevelopmentProgress progress = DevelopmentProgress.fromJson(json);

        expect(progress.percentage, equals(75.0));
        expect(progress.currentPhase, equals('Building Container'));
        expect(progress.milestones, hasLength(1));
      });
    });

    group('toJson', () {
      test('should convert progress to JSON correctly', () {
        final Map<String, dynamic> json = testProgress.toJson();

        expect(json['percentage'], equals(65.5));
        expect(json['currentPhase'], equals('Running Tests'));
        expect(json['milestones'], hasLength(3));
        expect(json['recentLogs'], hasLength(2));
        expect(json['lastUpdated'], equals('2025-01-10T14:32:00.000'));
        expect(json['estimatedCompletion'], equals('2025-01-10T15:00:00.000'));
      });
    });
  });
}
