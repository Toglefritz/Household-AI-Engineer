/// Unit tests for ApplicationTile model and related classes.
///
/// Tests model creation, JSON serialization/deserialization, validation,
/// and all utility methods to ensure reliable application management.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/models/models.dart';

void main() {
  group('LaunchType', () {
    test('should have all expected launch types', () {
      expect(LaunchType.values, hasLength(2));
      expect(LaunchType.values, contains(LaunchType.web));
      expect(LaunchType.values, contains(LaunchType.native));
    });

    test('should return correct display names', () {
      expect(LaunchType.web.displayName, equals('Web Application'));
      expect(LaunchType.native.displayName, equals('Native Application'));
    });

    test('should identify embedded types correctly', () {
      expect(LaunchType.web.isEmbedded, isTrue);
      expect(LaunchType.native.isEmbedded, isFalse);
    });

    test('should identify separate window types correctly', () {
      expect(LaunchType.native.usesSeparateWindow, isTrue);
      expect(LaunchType.web.usesSeparateWindow, isFalse);
    });
  });

  group('LaunchConfiguration', () {
    final testConfig = LaunchConfiguration(
      type: LaunchType.web,
      url: 'http://localhost:3000',
      windowTitle: 'Test Application',
      windowWidth: 800,
      windowHeight: 600,
      allowResize: true,
      showNavigationControls: false,
    );

    test('should create configuration with all fields', () {
      expect(testConfig.type, equals(LaunchType.web));
      expect(testConfig.url, equals('http://localhost:3000'));
      expect(testConfig.windowTitle, equals('Test Application'));
      expect(testConfig.windowWidth, equals(800));
      expect(testConfig.windowHeight, equals(600));
      expect(testConfig.allowResize, isTrue);
      expect(testConfig.showNavigationControls, isFalse);
    });

    test('should create configuration from JSON', () {
      final json = {
        'type': 'native',
        'url': '/usr/local/bin/myapp',
        'windowTitle': 'My Native App',
        'windowWidth': 1024,
        'windowHeight': 768,
        'allowResize': false,
        'showNavigationControls': true,
      };

      final config = LaunchConfiguration.fromJson(json);

      expect(config.type, equals(LaunchType.native));
      expect(config.url, equals('/usr/local/bin/myapp'));
      expect(config.windowTitle, equals('My Native App'));
      expect(config.windowWidth, equals(1024));
      expect(config.windowHeight, equals(768));
      expect(config.allowResize, isFalse);
      expect(config.showNavigationControls, isTrue);
    });

    test('should convert configuration to JSON correctly', () {
      final json = testConfig.toJson();

      expect(json['type'], equals('web'));
      expect(json['url'], equals('http://localhost:3000'));
      expect(json['windowTitle'], equals('Test Application'));
      expect(json['windowWidth'], equals(800));
      expect(json['windowHeight'], equals(600));
      expect(json['allowResize'], isTrue);
      expect(json['showNavigationControls'], isFalse);
    });
  });

  group('ApplicationTile', () {
    final testLaunchConfig = LaunchConfiguration(type: LaunchType.web, url: 'http://localhost:3000');

    final testProgress = DevelopmentProgress(
      percentage: 75,
      currentPhase: 'Running Tests',
      milestones: [
        DevelopmentMilestone(
          id: 'milestone_1',
          name: 'Generate Code',
          description: 'Generate application code',
          status: MilestoneStatus.completed,
          order: 1,
        ),
      ],
      recentLogs: [],
      lastUpdated: DateTime(2025, 1, 10, 14, 30),
    );

    final testTile = ApplicationTile(
      id: 'app_123',
      title: 'Chore Tracker',
      description: 'A family chore management application',
      status: ApplicationStatus.developing,
      createdAt: DateTime(2025, 1, 10, 14, 0),
      updatedAt: DateTime(2025, 1, 10, 14, 30),
      launchConfig: testLaunchConfig,
      iconUrl: 'https://example.com/icon.png',
      tags: ['household', 'chores', 'family'],
      progress: testProgress,
    );

    test('should create tile with all required fields', () {
      expect(testTile.id, equals('app_123'));
      expect(testTile.title, equals('Chore Tracker'));
      expect(testTile.description, equals('A family chore management application'));
      expect(testTile.status, equals(ApplicationStatus.developing));
      expect(testTile.createdAt, equals(DateTime(2025, 1, 10, 14, 0)));
      expect(testTile.updatedAt, equals(DateTime(2025, 1, 10, 14, 30)));
      expect(testTile.launchConfig, equals(testLaunchConfig));
      expect(testTile.iconUrl, equals('https://example.com/icon.png'));
      expect(testTile.tags, equals(['household', 'chores', 'family']));
      expect(testTile.progress, equals(testProgress));
    });

    test('should detect development status correctly', () {
      expect(testTile.isInDevelopment, isTrue);

      final readyTile = testTile.copyWith(status: ApplicationStatus.ready, progress: null);
      expect(readyTile.isInDevelopment, isFalse);
    });

    test('should detect launch capability correctly', () {
      expect(testTile.canLaunch, isFalse);

      final readyTile = testTile.copyWith(status: ApplicationStatus.ready);
      expect(readyTile.canLaunch, isTrue);

      final runningTile = testTile.copyWith(status: ApplicationStatus.running);
      expect(runningTile.canLaunch, isTrue);
    });

    test('should detect modification capability correctly', () {
      expect(testTile.canModify, isFalse);

      final readyTile = testTile.copyWith(status: ApplicationStatus.ready);
      expect(readyTile.canModify, isTrue);

      final failedTile = testTile.copyWith(status: ApplicationStatus.failed);
      expect(failedTile.canModify, isTrue);
    });

    test('should detect custom icon correctly', () {
      expect(testTile.hasCustomIcon, isTrue);

      final noIconTile = ApplicationTile(
        id: testTile.id,
        title: testTile.title,
        description: testTile.description,
        status: testTile.status,
        createdAt: testTile.createdAt,
        updatedAt: testTile.updatedAt,
        launchConfig: testTile.launchConfig,
        iconUrl: null,
        tags: testTile.tags,
        progress: testTile.progress,
      );
      expect(noIconTile.hasCustomIcon, isFalse);

      final emptyIconTile = ApplicationTile(
        id: testTile.id,
        title: testTile.title,
        description: testTile.description,
        status: testTile.status,
        createdAt: testTile.createdAt,
        updatedAt: testTile.updatedAt,
        launchConfig: testTile.launchConfig,
        iconUrl: '',
        tags: testTile.tags,
        progress: testTile.progress,
      );
      expect(emptyIconTile.hasCustomIcon, isFalse);
    });

    test('should detect tags correctly', () {
      expect(testTile.hasTags, isTrue);

      final noTagsTile = ApplicationTile(
        id: testTile.id,
        title: testTile.title,
        description: testTile.description,
        status: testTile.status,
        createdAt: testTile.createdAt,
        updatedAt: testTile.updatedAt,
        launchConfig: testTile.launchConfig,
        iconUrl: testTile.iconUrl,
        tags: [],
        progress: testTile.progress,
      );
      expect(noTagsTile.hasTags, isFalse);
    });

    test('should format creation time description correctly', () {
      final now = DateTime.now();

      final dayOldTile = testTile.copyWith(createdAt: now.subtract(const Duration(days: 2)));
      expect(dayOldTile.createdTimeDescription, equals('2 days ago'));

      final hourOldTile = testTile.copyWith(createdAt: now.subtract(const Duration(hours: 3)));
      expect(hourOldTile.createdTimeDescription, equals('3 hours ago'));

      final minuteOldTile = testTile.copyWith(createdAt: now.subtract(const Duration(minutes: 45)));
      expect(minuteOldTile.createdTimeDescription, equals('45 minutes ago'));

      final recentTile = testTile.copyWith(createdAt: now.subtract(const Duration(seconds: 30)));
      expect(recentTile.createdTimeDescription, equals('Just now'));
    });

    test('should format updated time description correctly', () {
      final now = DateTime.now();

      final dayOldTile = testTile.copyWith(updatedAt: now.subtract(const Duration(days: 1)));
      expect(dayOldTile.updatedTimeDescription, equals('Updated 1 day ago'));

      final hourOldTile = testTile.copyWith(updatedAt: now.subtract(const Duration(hours: 2)));
      expect(hourOldTile.updatedTimeDescription, equals('Updated 2 hours ago'));

      final minuteOldTile = testTile.copyWith(updatedAt: now.subtract(const Duration(minutes: 15)));
      expect(minuteOldTile.updatedTimeDescription, equals('Updated 15 minutes ago'));

      final recentTile = testTile.copyWith(updatedAt: now.subtract(const Duration(seconds: 10)));
      expect(recentTile.updatedTimeDescription, equals('Just updated'));
    });

    test('should create tile from JSON', () {
      final json = {
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

      final tile = ApplicationTile.fromJson(json);

      expect(tile.id, equals('app_456'));
      expect(tile.title, equals('Budget Tracker'));
      expect(tile.status, equals(ApplicationStatus.ready));
      expect(tile.tags, equals(['finance', 'budget']));
      expect(tile.progress, isNull);
    });

    test('should convert tile to JSON correctly', () {
      final json = testTile.toJson();

      expect(json['id'], equals('app_123'));
      expect(json['title'], equals('Chore Tracker'));
      expect(json['description'], equals('A family chore management application'));
      expect(json['status'], equals('developing'));
      expect(json['createdAt'], equals('2025-01-10T14:00:00.000'));
      expect(json['updatedAt'], equals('2025-01-10T14:30:00.000'));
      expect(json['launchConfig'], isA<Map<String, dynamic>>());
      expect(json['iconUrl'], equals('https://example.com/icon.png'));
      expect(json['tags'], equals(['household', 'chores', 'family']));
      expect(json['progress'], isA<Map<String, dynamic>>());
    });

    test('should create copy with updated fields', () {
      final updated = testTile.copyWith(
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
