/// Unit tests for DevelopmentProgress model and related classes.
///
/// Tests model creation, JSON serialization/deserialization, validation,
/// and all utility methods to ensure reliable progress tracking.

import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/models/development_progress.dart';
import 'package:household_ai_engineer/models/development_milestone.dart';

void main() {
  group('LogLevel', () {
    group('enum values', () {
      test('should have all expected log levels', () {
        expect(LogLevel.values, hasLength(4));
        expect(LogLevel.values, contains(LogLevel.debug));
        expect(LogLevel.values, contains(LogLevel.info));
        expect(LogLevel.values, contains(LogLevel.warning));
        expect(LogLevel.values, contains(LogLevel.error));
      });
    });

    group('displayName extension', () {
      test('should return correct display names for all levels', () {
        expect(LogLevel.debug.displayName, equals('Debug'));
        expect(LogLevel.info.displayName, equals('Info'));
        expect(LogLevel.warning.displayName, equals('Warning'));
        expect(LogLevel.error.displayName, equals('Error'));
      });
    });

    group('isProblematic extension', () {
      test('should return true for warning and error levels', () {
        expect(LogLevel.warning.isProblematic, isTrue);
        expect(LogLevel.error.isProblematic, isTrue);
        expect(LogLevel.debug.isProblematic, isFalse);
        expect(LogLevel.info.isProblematic, isFalse);
      });
    });

    group('severity extension', () {
      test('should return correct severity values', () {
        expect(LogLevel.debug.severity, equals(0));
        expect(LogLevel.info.severity, equals(1));
        expect(LogLevel.warning.severity, equals(2));
        expect(LogLevel.error.severity, equals(3));
      });
    });
  });

  group('BuildLogEntry', () {
    final testLogEntry = BuildLogEntry(
      timestamp: DateTime(2025, 1, 10, 14, 30),
      level: LogLevel.info,
      message: 'Test log message',
      source: 'test-runner',
    );

    group('constructor', () {
      test('should create log entry with all required fields', () {
        expect(testLogEntry.timestamp, equals(DateTime(2025, 1, 10, 14, 30)));
        expect(testLogEntry.level, equals(LogLevel.info));
        expect(testLogEntry.message, equals('Test log message'));
        expect(testLogEntry.source, equals('test-runner'));
      });
    });

    group('fromJson', () {
      test('should create log entry from valid JSON', () {
        final json = {
          'timestamp': '2025-01-10T14:30:00.000Z',
          'level': 'error',
          'message': 'Build failed',
          'source': 'container-builder',
        };

        final logEntry = BuildLogEntry.fromJson(json);

        expect(
          logEntry.timestamp,
          equals(DateTime.parse('2025-01-10T14:30:00.000Z')),
        );
        expect(logEntry.level, equals(LogLevel.error));
        expect(logEntry.message, equals('Build failed'));
        expect(logEntry.source, equals('container-builder'));
      });

      test('should throw FormatException for missing required fields', () {
        final invalidJson = {
          'level': 'info',
          'message': 'Test message',
          // Missing timestamp and source
        };

        expect(
          () => BuildLogEntry.fromJson(invalidJson),
          throwsA(isA<FormatException>()),
        );
      });

      test('should throw FormatException for invalid log level', () {
        final invalidJson = {
          'timestamp': '2025-01-10T14:30:00.000Z',
          'level': 'invalid_level',
          'message': 'Test message',
          'source': 'test-source',
        };

        expect(
          () => BuildLogEntry.fromJson(invalidJson),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('toJson', () {
      test('should convert log entry to JSON correctly', () {
        final json = testLogEntry.toJson();

        expect(json['timestamp'], equals('2025-01-10T14:30:00.000'));
        expect(json['level'], equals('info'));
        expect(json['message'], equals('Test log message'));
        expect(json['source'], equals('test-runner'));
      });
    });
  });

  group('DevelopmentProgress', () {
    final testMilestones = [
      DevelopmentMilestone(
        id: 'milestone_1',
        name: 'Generate Code',
        description: 'Generate application code',
        status: MilestoneStatus.completed,
        order: 1,
        completedAt: DateTime(2025, 1, 10, 14, 0),
      ),
      DevelopmentMilestone(
        id: 'milestone_2',
        name: 'Run Tests',
        description: 'Execute test suite',
        status: MilestoneStatus.inProgress,
        order: 2,
      ),
      DevelopmentMilestone(
        id: 'milestone_3',
        name: 'Build Container',
        description: 'Create container image',
        status: MilestoneStatus.pending,
        order: 3,
      ),
    ];

    final testLogs = [
      BuildLogEntry(
        timestamp: DateTime(2025, 1, 10, 14, 30),
        level: LogLevel.info,
        message: 'Starting test execution',
        source: 'test-runner',
      ),
      BuildLogEntry(
        timestamp: DateTime(2025, 1, 10, 14, 31),
        level: LogLevel.error,
        message: 'Test failed: assertion error',
        source: 'test-runner',
      ),
    ];

    final testProgress = DevelopmentProgress(
      percentage: 65.5,
      currentPhase: 'Running Tests',
      milestones: testMilestones,
      recentLogs: testLogs,
      lastUpdated: DateTime(2025, 1, 10, 14, 32),
      estimatedCompletion: DateTime(2025, 1, 10, 15, 0),
    );

    group('constructor', () {
      test('should create progress with all required fields', () {
        expect(testProgress.percentage, equals(65.5));
        expect(testProgress.currentPhase, equals('Running Tests'));
        expect(testProgress.milestones, hasLength(3));
        expect(testProgress.recentLogs, hasLength(2));
        expect(testProgress.lastUpdated, equals(DateTime(2025, 1, 10, 14, 32)));
        expect(
          testProgress.estimatedCompletion,
          equals(DateTime(2025, 1, 10, 15, 0)),
        );
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

        final failedProgress = testProgress.copyWith(
          milestones: [
            ...testMilestones,
            DevelopmentMilestone(
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

        final completedMilestones = testMilestones
            .map((m) => m.copyWith(status: MilestoneStatus.completed))
            .toList();

        final completedProgress = testProgress.copyWith(
          milestones: completedMilestones,
        );

        expect(completedProgress.isComplete, isTrue);
      });

      test('should filter recent errors correctly', () {
        final recentErrors = testProgress.recentErrors;
        expect(recentErrors, hasLength(1));
        expect(recentErrors.first.level, equals(LogLevel.error));
        expect(
          recentErrors.first.message,
          equals('Test failed: assertion error'),
        );
      });
    });

    group('fromJson', () {
      test('should create progress from valid JSON', () {
        final json = {
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
            {
              'timestamp': '2025-01-10T14:30:00.000Z',
              'level': 'info',
              'message': 'Test log',
              'source': 'test-source',
            },
          ],
          'lastUpdated': '2025-01-10T14:32:00.000Z',
          'estimatedCompletion': '2025-01-10T15:00:00.000Z',
        };

        final progress = DevelopmentProgress.fromJson(json);

        expect(progress.percentage, equals(75.0));
        expect(progress.currentPhase, equals('Building Container'));
        expect(progress.milestones, hasLength(1));
        expect(progress.recentLogs, hasLength(1));
      });
    });

    group('toJson', () {
      test('should convert progress to JSON correctly', () {
        final json = testProgress.toJson();

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
