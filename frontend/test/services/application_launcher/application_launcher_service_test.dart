import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:household_ai_engineer/services/application_launcher/application_launcher_service.dart';
import 'package:household_ai_engineer/services/application_launcher/models/application_launch_config.dart';
import 'package:household_ai_engineer/services/application_launcher/models/application_process.dart';
import 'package:household_ai_engineer/services/application_launcher/models/launch_result.dart';
import 'package:household_ai_engineer/services/application_launcher/models/window_state.dart';
import 'package:household_ai_engineer/services/user_application/models/application_status.dart';
import 'package:household_ai_engineer/services/user_application/models/user_application.dart';

import 'application_launcher_service_test.mocks.dart';

/// Mock classes for testing
@GenerateMocks([http.Client, SharedPreferences])
void main() {
  group('ApplicationLauncherService', () {
    late ApplicationLauncherService service;
    late MockClient mockHttpClient;
    late MockSharedPreferences mockPreferences;
    late UserApplication testApplication;

    setUp(() {
      mockHttpClient = MockClient();
      mockPreferences = MockSharedPreferences();
      service = ApplicationLauncherService(mockHttpClient, mockPreferences);

      // Create test application
      testApplication = UserApplication(
        id: 'test-app-1',
        title: 'Test Application',
        description: 'A test application for unit testing',
        status: ApplicationStatus.ready,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
      );

      // Set up default mock responses
      when(mockPreferences.getString(any)).thenReturn(null);
      when(mockPreferences.setString(any, any)).thenAnswer((_) async => true);
    });

    tearDown(() async {
      await service.dispose();
    });

    group('launchApplication', () {
      test(
        'should launch application successfully with valid configuration',
        () async {
          // Arrange
          when(
            mockHttpClient.get(
              any,
              headers: anyNamed('headers'),
            ),
          ).thenAnswer((_) async => http.Response('OK', 200));

          // Act
          final LaunchResult result = await service.launchApplication(
            testApplication,
          );

          // Assert
          expect(result.success, true);
          expect(result.application, testApplication);
          expect(result.process, isNotNull);
          expect(result.process!.applicationId, testApplication.id);
          expect(result.process!.applicationTitle, testApplication.title);
          expect(service.isApplicationRunning(testApplication.id), true);

          // Verify HTTP client was called for URL validation
          verify(
            mockHttpClient.get(
              argThat(
                predicate<Uri>(
                  (uri) => uri.toString().contains(testApplication.id),
                ),
              ),
              headers: anyNamed('headers'),
            ),
          ).called(1);
        },
      );

      test('should fail to launch application with invalid status', () async {
        // Arrange
        final UserApplication invalidApp = testApplication.copyWith(
          status: ApplicationStatus.developing,
        );

        // Act
        final LaunchResult result = await service.launchApplication(invalidApp);

        // Assert
        expect(result.success, false);
        expect(result.error, contains('cannot be launched'));
        expect(result.errorCode, 'INVALID_STATE');
        expect(service.isApplicationRunning(invalidApp.id), false);
      });

      test(
        'should bring existing application to foreground if already running',
        () async {
          // Arrange
          when(
            mockHttpClient.get(
              any,
              headers: anyNamed('headers'),
            ),
          ).thenAnswer((_) async => http.Response('OK', 200));

          // Launch application first time
          await service.launchApplication(testApplication);

          // Act - Launch same application again
          final LaunchResult result = await service.launchApplication(
            testApplication,
          );

          // Assert
          expect(result.success, true);
          expect(result.message, contains('brought to foreground'));
          expect(service.runningProcesses.length, 1);
        },
      );

      test('should fail when URL validation fails', () async {
        // Arrange
        when(
          mockHttpClient.get(
            any,
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response('Not Found', 404));

        // Act
        final LaunchResult result = await service.launchApplication(
          testApplication,
        );

        // Assert
        expect(result.success, false);
        expect(result.error, contains('status 404'));
        expect(result.errorCode, 'URL_NOT_ACCESSIBLE');
        expect(service.isApplicationRunning(testApplication.id), false);
      });

      test('should restore window state from preferences', () async {
        // Arrange
        final WindowState savedState = WindowState(
          x: 100,
          y: 200,
          width: 800,
          height: 600,
          lastUpdated: DateTime.now(),
        );

        when(
          mockPreferences.getString('window_state_${testApplication.id}'),
        ).thenReturn(
          '{"x":100,"y":200,"width":800,"height":600,"isMaximized":false,"isMinimized":false,"isFullscreen":false,"lastUpdated":"${savedState.lastUpdated.toIso8601String()}"}',
        );

        when(
          mockHttpClient.get(
            any,
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response('OK', 200));

        // Act
        final LaunchResult result = await service.launchApplication(
          testApplication,
        );

        // Assert
        expect(result.success, true);
        expect(result.process!.windowState, isNotNull);
        expect(result.process!.windowState!.x, 100);
        expect(result.process!.windowState!.y, 200);
        expect(result.process!.windowState!.width, 800);
        expect(result.process!.windowState!.height, 600);
      });
    });

    group('stopApplication', () {
      test('should stop running application successfully', () async {
        // Arrange
        when(
          mockHttpClient.get(
            any,
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response('OK', 200));

        // Launch application first
        await service.launchApplication(testApplication);
        expect(service.isApplicationRunning(testApplication.id), true);

        // Act
        await service.stopApplication(testApplication.id);

        // Assert
        expect(service.isApplicationRunning(testApplication.id), false);
        expect(service.runningProcesses.isEmpty, true);

        // Verify window state was saved
        verify(
          mockPreferences.setString(
            'window_state_${testApplication.id}',
            any,
          ),
        ).called(1);
      });

      test(
        'should handle stopping non-running application gracefully',
        () async {
          // Act
          await service.stopApplication('non-existent-app');

          // Assert - Should not throw exception
          expect(service.isApplicationRunning('non-existent-app'), false);
        },
      );
    });

    group('restartApplication', () {
      test('should restart running application successfully', () async {
        // Arrange
        when(
          mockHttpClient.get(
            any,
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response('OK', 200));

        // Launch application first
        final LaunchResult initialResult = await service.launchApplication(
          testApplication,
        );
        final DateTime initialLaunchTime = initialResult.process!.launchedAt;

        // Wait a moment to ensure different launch times
        await Future.delayed(const Duration(milliseconds: 10));

        // Act
        final LaunchResult restartResult = await service.restartApplication(
          testApplication,
        );

        // Assert
        expect(restartResult.success, true);
        expect(service.isApplicationRunning(testApplication.id), true);
        expect(
          restartResult.process!.launchedAt.isAfter(initialLaunchTime),
          true,
        );
      });
    });

    group('health checks', () {
      test('should perform health checks on running applications', () async {
        // Arrange
        when(
          mockHttpClient.get(
            any,
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response('OK', 200));

        // Launch application
        await service.launchApplication(testApplication);
        final ApplicationProcess process = service.getApplicationProcess(
          testApplication.id,
        )!;

        // Simulate time passing to trigger health check
        process.updateLastAccessed();
        await Future.delayed(const Duration(milliseconds: 10));

        // Act
        await service.performHealthChecks();

        // Assert
        expect(process.isHealthy, true);
        verify(
          mockHttpClient.get(
            any,
            headers: anyNamed('headers'),
          ),
        ).called(greaterThan(1)); // Initial launch + health check
      });

      test('should handle health check failures', () async {
        // Arrange
        when(
          mockHttpClient.get(
            any,
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response('OK', 200));

        // Launch application
        await service.launchApplication(testApplication);
        final ApplicationProcess process = service.getApplicationProcess(
          testApplication.id,
        )!;

        // Set up health check failure
        when(
          mockHttpClient.get(
            any,
            headers: anyNamed('headers'),
          ),
        ).thenThrow(Exception('Connection failed'));

        // Simulate time passing to trigger health check
        process.updateLastAccessed();
        await Future.delayed(const Duration(milliseconds: 10));

        // Listen for health check failure events
        LaunchResult? healthCheckResult;
        final StreamSubscription<LaunchResult> subscription = service
            .launchEvents
            .listen(
              (LaunchResult result) {
                if (result.errorCode == 'HEALTH_CHECK_FAILED') {
                  healthCheckResult = result;
                }
              },
            );

        // Act
        await service.performHealthChecks();

        // Wait for event to be emitted
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(process.isHealthy, false);
        expect(process.healthCheckError, contains('Connection failed'));
        expect(healthCheckResult, isNotNull);
        expect(healthCheckResult!.success, false);
        expect(healthCheckResult!.errorCode, 'HEALTH_CHECK_FAILED');

        await subscription.cancel();
      });
    });

    group('launch events', () {
      test('should emit launch events for successful operations', () async {
        // Arrange
        when(
          mockHttpClient.get(
            any,
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response('OK', 200));

        final List<LaunchResult> events = [];
        final StreamSubscription<LaunchResult> subscription = service
            .launchEvents
            .listen(
              (LaunchResult result) => events.add(result),
            );

        // Act
        await service.launchApplication(testApplication);
        await service.stopApplication(testApplication.id);

        // Wait for events to be emitted
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events.length, 2);
        expect(events[0].success, true); // Launch success
        expect(events[1].success, true); // Stop success

        await subscription.cancel();
      });

      test('should emit launch events for failed operations', () async {
        // Arrange
        when(
          mockHttpClient.get(
            any,
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response('Not Found', 404));

        final List<LaunchResult> events = [];
        final StreamSubscription<LaunchResult> subscription = service
            .launchEvents
            .listen(
              (LaunchResult result) => events.add(result),
            );

        // Act
        await service.launchApplication(testApplication);

        // Wait for events to be emitted
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events.length, 1);
        expect(events[0].success, false);
        expect(events[0].errorCode, 'URL_NOT_ACCESSIBLE');

        await subscription.cancel();
      });
    });

    group('window state management', () {
      test('should save and restore window state correctly', () async {
        // Arrange
        when(
          mockHttpClient.get(
            any,
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response('OK', 200));

        // Launch application
        final LaunchResult result = await service.launchApplication(
          testApplication,
        );
        final ApplicationProcess process = result.process!;

        // Update window state
        final WindowState newState = WindowState(
          x: 150,
          y: 250,
          width: 900,
          height: 700,
          lastUpdated: DateTime.now(),
        );
        process.updateWindowState(newState);

        // Act - Stop application (should save state)
        await service.stopApplication(testApplication.id);

        // Assert - Verify state was saved
        verify(
          mockPreferences.setString(
            'window_state_${testApplication.id}',
            argThat(contains('"x":150')),
          ),
        ).called(1);
      });
    });

    group('process management', () {
      test('should track running processes correctly', () async {
        // Arrange
        when(
          mockHttpClient.get(
            any,
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response('OK', 200));

        final UserApplication app1 = testApplication;
        final UserApplication app2 = testApplication.copyWith(
          id: 'test-app-2',
          title: 'Test Application 2',
        );

        // Act
        await service.launchApplication(app1);
        await service.launchApplication(app2);

        // Assert
        expect(service.runningProcesses.length, 2);
        expect(service.isApplicationRunning(app1.id), true);
        expect(service.isApplicationRunning(app2.id), true);

        final ApplicationProcess? process1 = service.getApplicationProcess(
          app1.id,
        );
        final ApplicationProcess? process2 = service.getApplicationProcess(
          app2.id,
        );

        expect(process1, isNotNull);
        expect(process2, isNotNull);
        expect(process1!.applicationTitle, app1.title);
        expect(process2!.applicationTitle, app2.title);
      });
    });
  });
}
