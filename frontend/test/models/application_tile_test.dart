import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/services/user_application/models/application_status.dart';
import 'package:household_ai_engineer/services/user_application/models/development_progress.dart';
import 'package:household_ai_engineer/services/user_application/models/user_application.dart';

void main() {
  group('ApplicationTile', () {
    final DevelopmentProgress testProgress = DevelopmentProgress(
      percentage: 75,
      currentPhase: 'Running Tests',
      lastUpdated: DateTime(2025, 1, 10, 14, 30),
    );

    final UserApplication testTile = UserApplication(
      id: 'app_123',
      title: 'Chore Tracker',
      description: 'A family chore management application',
      status: ApplicationStatus.developing,
      createdAt: DateTime(2025, 1, 10, 14),
      updatedAt: DateTime(2025, 1, 10, 14, 30),
      iconUrl: 'https://example.com/icon.png',
      tags: ['household', 'chores', 'family'],
      progress: testProgress,
    );

    test('should create tile with all required fields', () {
      expect(testTile.id, equals('app_123'));
      expect(testTile.title, equals('Chore Tracker'));
      expect(
        testTile.description,
        equals('A family chore management application'),
      );
      expect(testTile.status, equals(ApplicationStatus.developing));
      expect(testTile.createdAt, equals(DateTime(2025, 1, 10, 14)));
      expect(testTile.updatedAt, equals(DateTime(2025, 1, 10, 14, 30)));
      expect(testTile.iconUrl, equals('https://example.com/icon.png'));
      expect(testTile.tags, equals(['household', 'chores', 'family']));
      expect(testTile.progress, equals(testProgress));
    });

    test('should detect development status correctly', () {
      expect(testTile.isInDevelopment, isTrue);

      final UserApplication readyTile = testTile.copyWith(
        status: ApplicationStatus.ready,
      );
      expect(readyTile.isInDevelopment, isFalse);
    });

    test('should detect launch capability correctly', () {
      expect(testTile.canLaunch, isFalse);

      final UserApplication readyTile = testTile.copyWith(
        status: ApplicationStatus.ready,
      );
      expect(readyTile.canLaunch, isTrue);

      final UserApplication runningTile = testTile.copyWith(
        status: ApplicationStatus.running,
      );
      expect(runningTile.canLaunch, isTrue);
    });

    test('should detect modification capability correctly', () {
      expect(testTile.canModify, isFalse);

      final UserApplication readyTile = testTile.copyWith(
        status: ApplicationStatus.ready,
      );
      expect(readyTile.canModify, isTrue);

      final UserApplication failedTile = testTile.copyWith(
        status: ApplicationStatus.failed,
      );
      expect(failedTile.canModify, isTrue);
    });

    test('should detect custom icon correctly', () {
      expect(testTile.hasCustomIcon, isTrue);

      final UserApplication noIconTile = UserApplication(
        id: testTile.id,
        title: testTile.title,
        description: testTile.description,
        status: testTile.status,
        createdAt: testTile.createdAt,
        updatedAt: testTile.updatedAt,
        tags: testTile.tags,
        progress: testTile.progress,
      );
      expect(noIconTile.hasCustomIcon, isFalse);

      final UserApplication emptyIconTile = UserApplication(
        id: testTile.id,
        title: testTile.title,
        description: testTile.description,
        status: testTile.status,
        createdAt: testTile.createdAt,
        updatedAt: testTile.updatedAt,
        iconUrl: '',
        tags: testTile.tags,
        progress: testTile.progress,
      );
      expect(emptyIconTile.hasCustomIcon, isFalse);
    });

    test('should detect tags correctly', () {
      expect(testTile.hasTags, isTrue);

      final UserApplication noTagsTile = UserApplication(
        id: testTile.id,
        title: testTile.title,
        description: testTile.description,
        status: testTile.status,
        createdAt: testTile.createdAt,
        updatedAt: testTile.updatedAt,
        iconUrl: testTile.iconUrl,
        tags: [],
        progress: testTile.progress,
      );
      expect(noTagsTile.hasTags, isFalse);
    });

    test('should format creation time description correctly', () {
      final DateTime now = DateTime.now();

      final UserApplication dayOldTile = testTile.copyWith(
        createdAt: now.subtract(const Duration(days: 2)),
      );
      expect(dayOldTile.createdTimeDescription, equals('2 days ago'));

      final UserApplication hourOldTile = testTile.copyWith(
        createdAt: now.subtract(const Duration(hours: 3)),
      );
      expect(hourOldTile.createdTimeDescription, equals('3 hours ago'));

      final UserApplication minuteOldTile = testTile.copyWith(
        createdAt: now.subtract(const Duration(minutes: 45)),
      );
      expect(minuteOldTile.createdTimeDescription, equals('45 minutes ago'));

      final UserApplication recentTile = testTile.copyWith(
        createdAt: now.subtract(const Duration(seconds: 30)),
      );
      expect(recentTile.createdTimeDescription, equals('Just now'));
    });

    test('should format updated time description correctly', () {
      final DateTime now = DateTime.now();

      final UserApplication dayOldTile = testTile.copyWith(
        updatedAt: now.subtract(const Duration(days: 1)),
      );
      expect(dayOldTile.updatedTimeDescription, equals('Updated 1 day ago'));

      final UserApplication hourOldTile = testTile.copyWith(
        updatedAt: now.subtract(const Duration(hours: 2)),
      );
      expect(hourOldTile.updatedTimeDescription, equals('Updated 2 hours ago'));

      final UserApplication minuteOldTile = testTile.copyWith(
        updatedAt: now.subtract(const Duration(minutes: 15)),
      );
      expect(
        minuteOldTile.updatedTimeDescription,
        equals('Updated 15 minutes ago'),
      );

      final UserApplication recentTile = testTile.copyWith(
        updatedAt: now.subtract(const Duration(seconds: 10)),
      );
      expect(recentTile.updatedTimeDescription, equals('Just updated'));
    });

    test('should create tile from JSON', () {
      final Map<String, dynamic> json = {
        'id': 'app_456',
        'title': 'Budget Tracker',
        'description': 'Personal finance management',
        'status': 'ready',
        'createdAt': '2025-01-10T14:00:00.000Z',
        'updatedAt': '2025-01-10T14:30:00.000Z',
        'launchConfig': {'type': 'web', 'url': 'http://localhost:4000'},
        'iconUrl': 'https://example.com/budget-icon.png',
        'tags': ['finance', 'budget'],
        'progress': null,
      };

      final UserApplication tile = UserApplication.fromJson(json);

      expect(tile.id, equals('app_456'));
      expect(tile.title, equals('Budget Tracker'));
      expect(tile.status, equals(ApplicationStatus.ready));
      expect(tile.tags, equals(['finance', 'budget']));
      expect(tile.progress, isNull);
    });

    test('should convert tile to JSON correctly', () {
      final Map<String, dynamic> json = testTile.toJson();

      expect(json['id'], equals('app_123'));
      expect(json['title'], equals('Chore Tracker'));
      expect(
        json['description'],
        equals('A family chore management application'),
      );
      expect(json['status'], equals('developing'));
      expect(json['createdAt'], equals('2025-01-10T14:00:00.000'));
      expect(json['updatedAt'], equals('2025-01-10T14:30:00.000'));
      expect(json['launchConfig'], isA<Map<String, dynamic>>());
      expect(json['iconUrl'], equals('https://example.com/icon.png'));
      expect(json['tags'], equals(['household', 'chores', 'family']));
      expect(json['progress'], isA<Map<String, dynamic>>());
    });

    test('should create copy with updated fields', () {
      final UserApplication updated = testTile.copyWith(
        title: 'Updated Chore Tracker',
        status: ApplicationStatus.ready,
        tags: ['updated', 'tags'],
      );

      expect(updated.id, equals(testTile.id));
      expect(updated.title, equals('Updated Chore Tracker'));
      expect(updated.status, equals(ApplicationStatus.ready));
      expect(updated.tags, equals(['updated', 'tags']));
      expect(updated.description, equals(testTile.description));
    });
  });
}
