import 'package:flutter_test/flutter_test.dart';

import 'package:household_ai_engineer/services/application_launcher/models/application_launch_config.dart';
import 'package:household_ai_engineer/services/application_launcher/models/application_process.dart';
import 'package:household_ai_engineer/services/application_launcher/models/window_state.dart';

void main() {
  group('ApplicationProcess', () {
    late ApplicationLaunchConfig testConfig;
    late ApplicationProcess testProcess;

    setUp(() {
      testConfig = const ApplicationLaunchConfig(
        applicationType: ApplicationType.web,
        url: 'http://localhost:3000/test-app',
        windowTitle: 'Test Application',
        initialWidth: 1200,
        initialHeight: 800,
      );

      testProcess = ApplicationProcess(
        applicationId: 'test-app-1',
        applicationTitle: 'Test Application',
        launchConfig: testConfig,
        launchedAt: DateTime.now(),
      );
    });

    group('initialization', () {
      test('should initialize with correct values', () {
        expect(testProcess.applicationId, 'test-app-1');
        expect(testProcess.applicationTitle, 'Test Application');
        expect(testProcess.launchConfig, testConfig);
        expect(testProcess.status, ProcessStatus.starting);
        expect(testProcess.isHealthy, true);
        expect(testProcess.healthCheckError, null);
      });

      test('should initialize with window state when provided', () {
        final WindowState windowState = WindowState(
          x: 100,
          y: 200,
          width: 800,
          height: 600,
          lastUpdated: DateTime.now(),
        );

        final ApplicationProcess processWithState = ApplicationProcess(
          applicationId: 'test-app-2',
          applicationTitle: 'Test App 2',
          launchConfig: testConfig,
          windowState: windowState,
          launchedAt: DateTime.now(),
        );

        expect(processWithState.windowState, windowState);
      });
    });

    group('status management', () {
      test('should transition from starting to running', () {
        expect(testProcess.status, ProcessStatus.starting);
        expect(testProcess.isRunning, false);
        expect(testProcess.isTerminated, false);

        testProcess.markAsRunning();

        expect(testProcess.status, ProcessStatus.running);
        expect(testProcess.isRunning, true);
        expect(testProcess.isTerminated, false);
      });

      test('should transition to stopped', () {
        testProcess.markAsRunning();
        testProcess.markAsStopped();

        expect(testProcess.status, ProcessStatus.stopped);
        expect(testProcess.isRunning, false);
        expect(testProcess.isTerminated, true);
      });

      test('should transition to crashed with error message', () {
        testProcess.markAsRunning();
        testProcess.markAsCrashed('Application crashed unexpectedly');

        expect(testProcess.status, ProcessStatus.crashed);
        expect(testProcess.isRunning, false);
        expect(testProcess.isTerminated, true);
        expect(testProcess.isHealthy, false);
        expect(
          testProcess.healthCheckError,
          'Application crashed unexpectedly',
        );
      });
    });

    group('health check management', () {
      test('should update health check status successfully', () {
        final DateTime beforeUpdate = DateTime.now();

        testProcess.updateHealthCheck(healthy: true);

        expect(testProcess.isHealthy, true);
        expect(testProcess.healthCheckError, null);
        expect(testProcess.lastHealthCheck.isAfter(beforeUpdate), true);
      });

      test('should update health check status with failure', () {
        testProcess.markAsRunning();

        testProcess.updateHealthCheck(
          healthy: false,
          error: 'Connection timeout',
        );

        expect(testProcess.isHealthy, false);
        expect(testProcess.healthCheckError, 'Connection timeout');
        expect(testProcess.status, ProcessStatus.crashed);
      });

      test(
        'should not change status if not running during health check failure',
        () {
          // Process is still starting
          testProcess.updateHealthCheck(
            healthy: false,
            error: 'Health check failed',
          );

          expect(testProcess.isHealthy, false);
          expect(testProcess.healthCheckError, 'Health check failed');
          expect(
            testProcess.status,
            ProcessStatus.starting,
          ); // Should not change
        },
      );
    });

    group('time calculations', () {
      test('should calculate uptime correctly', () {
        final DateTime launchTime = DateTime.now().subtract(
          const Duration(minutes: 30),
        );
        final ApplicationProcess process = ApplicationProcess(
          applicationId: 'test-app',
          applicationTitle: 'Test App',
          launchConfig: testConfig,
          launchedAt: launchTime,
        );

        final Duration uptime = process.uptime;
        expect(uptime.inMinutes, greaterThanOrEqualTo(29));
        expect(uptime.inMinutes, lessThanOrEqualTo(31));
      });

      test('should calculate time since last access correctly', () {
        testProcess.updateLastAccessed();

        // Simulate some time passing
        final Duration timeSinceAccess = testProcess.timeSinceLastAccess;
        expect(timeSinceAccess.inMilliseconds, lessThan(100));
      });

      test('should calculate time since last health check correctly', () {
        testProcess.updateHealthCheck(healthy: true);

        final Duration timeSinceHealthCheck =
            testProcess.timeSinceLastHealthCheck;
        expect(timeSinceHealthCheck.inMilliseconds, lessThan(100));
      });
    });

    group('window state management', () {
      test('should update window state', () {
        final WindowState newState = WindowState(
          x: 150,
          y: 250,
          width: 900,
          height: 700,
          lastUpdated: DateTime.now(),
        );

        testProcess.updateWindowState(newState);

        expect(testProcess.windowState, newState);
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON correctly', () {
        testProcess.markAsRunning();
        testProcess.updateHealthCheck(healthy: true);

        final Map<String, dynamic> json = testProcess.toJson();

        expect(json['applicationId'], 'test-app-1');
        expect(json['applicationTitle'], 'Test Application');
        expect(json['status'], 'running');
        expect(json['isHealthy'], true);
        expect(json['launchConfig'], isA<Map<String, dynamic>>());
        expect(json['launchedAt'], isA<String>());
        expect(json['lastHealthCheck'], isA<String>());
        expect(json['lastAccessed'], isA<String>());
      });

      test('should deserialize from JSON correctly', () {
        final DateTime now = DateTime.now();
        final Map<String, dynamic> json = {
          'applicationId': 'test-app-2',
          'applicationTitle': 'Test App 2',
          'launchConfig': {
            'applicationType': 'web',
            'url': 'http://localhost:3000/test-app-2',
            'windowTitle': 'Test App 2',
            'initialWidth': 1000,
            'initialHeight': 700,
            'resizable': true,
            'showNavigationControls': true,
            'enableJavaScript': true,
            'enableLocalStorage': true,
          },
          'launchedAt': now.toIso8601String(),
          'status': 'running',
          'lastHealthCheck': now.toIso8601String(),
          'lastAccessed': now.toIso8601String(),
          'isHealthy': true,
          'healthCheckError': null,
        };

        final ApplicationProcess process = ApplicationProcess.fromJson(json);

        expect(process.applicationId, 'test-app-2');
        expect(process.applicationTitle, 'Test App 2');
        expect(process.status, ProcessStatus.running);
        expect(process.isHealthy, true);
        expect(process.launchConfig.url, 'http://localhost:3000/test-app-2');
      });

      test('should handle JSON with window state', () {
        final WindowState windowState = WindowState(
          x: 100,
          y: 200,
          width: 800,
          height: 600,
          lastUpdated: DateTime.now(),
        );

        testProcess.updateWindowState(windowState);
        final Map<String, dynamic> json = testProcess.toJson();

        expect(json['windowState'], isA<Map<String, dynamic>>());

        final ApplicationProcess deserializedProcess =
            ApplicationProcess.fromJson(json);
        expect(deserializedProcess.windowState, isNotNull);
        expect(deserializedProcess.windowState!.x, 100);
        expect(deserializedProcess.windowState!.y, 200);
      });
    });

    group('description methods', () {
      test('should provide uptime description for various durations', () {
        // Test seconds
        final ApplicationProcess secondsProcess = ApplicationProcess(
          applicationId: 'test',
          applicationTitle: 'Test',
          launchConfig: testConfig,
          launchedAt: DateTime.now().subtract(const Duration(seconds: 30)),
        );
        expect(secondsProcess.uptimeDescription, contains('30 seconds'));

        // Test minutes
        final ApplicationProcess minutesProcess = ApplicationProcess(
          applicationId: 'test',
          applicationTitle: 'Test',
          launchConfig: testConfig,
          launchedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        );
        expect(minutesProcess.uptimeDescription, contains('5 minutes'));

        // Test hours
        final ApplicationProcess hoursProcess = ApplicationProcess(
          applicationId: 'test',
          applicationTitle: 'Test',
          launchConfig: testConfig,
          launchedAt: DateTime.now().subtract(
            const Duration(hours: 2, minutes: 30),
          ),
        );
        expect(hoursProcess.uptimeDescription, contains('2 hours'));
        expect(hoursProcess.uptimeDescription, contains('30 minutes'));

        // Test days
        final ApplicationProcess daysProcess = ApplicationProcess(
          applicationId: 'test',
          applicationTitle: 'Test',
          launchConfig: testConfig,
          launchedAt: DateTime.now().subtract(
            const Duration(days: 1, hours: 3),
          ),
        );
        expect(daysProcess.uptimeDescription, contains('1 day'));
        expect(daysProcess.uptimeDescription, contains('3 hours'));
      });

      test('should provide last access description', () {
        testProcess.updateLastAccessed();
        expect(testProcess.lastAccessDescription, 'Just now');

        // We can't easily test other time ranges without mocking DateTime.now()
        // but the logic is similar to uptime description
      });
    });
  });

  group('ProcessStatus', () {
    test('should have correct display names', () {
      expect(ProcessStatus.starting.displayName, 'Starting');
      expect(ProcessStatus.running.displayName, 'Running');
      expect(ProcessStatus.stopped.displayName, 'Stopped');
      expect(ProcessStatus.crashed.displayName, 'Crashed');
    });

    test('should correctly identify active states', () {
      expect(ProcessStatus.starting.isActive, true);
      expect(ProcessStatus.running.isActive, true);
      expect(ProcessStatus.stopped.isActive, false);
      expect(ProcessStatus.crashed.isActive, false);
    });

    test('should correctly identify terminated states', () {
      expect(ProcessStatus.starting.isTerminated, false);
      expect(ProcessStatus.running.isTerminated, false);
      expect(ProcessStatus.stopped.isTerminated, true);
      expect(ProcessStatus.crashed.isTerminated, true);
    });
  });
}
