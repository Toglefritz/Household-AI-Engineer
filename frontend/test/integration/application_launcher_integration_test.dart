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

import 'application_launcher_integration_test.mocks.dart';

/// Integration tests for the complete application launcher system.
///
/// These tests verify the end-to-end functionality of launching applications,
/// managing processes, monitoring health, and handling window state.
@GenerateMocks([http.Client, SharedPreferences])
void main() {
  group('Application Launcher Integration Tests', () {
    late ApplicationLauncherService launcherService;
    late MockClient mockHttpClient;
    late MockSharedPreferences mockPreferences;
    late List<UserApplication> testApplications;

    setUp(() {
      mockHttpClient = MockClient();
      mockPreferences = MockSharedPreferences();
      launcherService = ApplicationLauncherService(
        mockHttpClient,
        mockPreferences,
      );

      // Create test applications
      testApplications = [
        UserApplication(
          id: 'chore-tracker',
          title: 'Chore Tracker',
          description: 'Family chore management system',
          status: ApplicationStatus.ready,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        UserApplication(
          id: 'budget-planner',
          title: 'Budget Planner',
          description: 'Household budget management',
          status: ApplicationStatus.ready,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        UserApplication(
          id: 'meal-planner',
          title: 'Meal Planner',
          description: 'Weekly meal planning and shopping lists',
          status: ApplicationStatus.running,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
      ];

      // Set up default mock responses
      when(mockPreferences.getString(any)).thenReturn(null);
      when(mockPreferences.setString(any, any)).thenAnswer((_) async => true);
      when(
        mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response('OK', 200));
    });

    tearDown(() async {
      await launcherService.dispose();
    });

    group('Complete Application Launch Workflow', () {
      test('should launch multiple applications successfully', () async {
        // Arrange
        final List<LaunchResult> launchEvents = [];
        final StreamSubscription<LaunchResult> subscription = launcherService
            .launchEvents
            .listen(
              (LaunchResult result) => launchEvents.add(result),
            );

        // Act - Launch multiple applications
        final List<LaunchResult> results = [];
        for (final UserApplication app in testApplications.take(2)) {
          final LaunchResult result = await launcherService.launchApplication(
            app,
          );
          results.add(result);
        }

        // Wait for events to be emitted
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        expect(results.length, 2);
        expect(results.every((LaunchResult r) => r.success), true);
        expect(launcherService.runningProcesses.length, 2);

        // Verify launch events were emitted
        expect(launchEvents.length, 2);
        expect(launchEvents.every((LaunchResult r) => r.success), true);

        // Verify each application is tracked correctly
        for (final UserApplication app in testApplications.take(2)) {
          expect(launcherService.isApplicationRunning(app.id), true);

          final ApplicationProcess? process = launcherService
              .getApplicationProcess(app.id);
          expect(process, isNotNull);
          expect(process!.applicationId, app.id);
          expect(process.applicationTitle, app.title);
          expect(process.status, ProcessStatus.running);
        }

        await subscription.cancel();
      });

      test(
        'should handle mixed launch scenarios (success and failure)',
        () async {
          // Arrange - Set up one application to fail URL validation
          when(
            mockHttpClient.get(
              argThat(
                predicate<Uri>(
                  (uri) => uri.toString().contains('chore-tracker'),
                ),
              ),
              headers: anyNamed('headers'),
            ),
          ).thenAnswer((_) async => http.Response('Not Found', 404));

          when(
            mockHttpClient.get(
              argThat(
                predicate<Uri>(
                  (uri) => uri.toString().contains('budget-planner'),
                ),
              ),
              headers: anyNamed('headers'),
            ),
          ).thenAnswer((_) async => http.Response('OK', 200));

          final List<LaunchResult> launchEvents = [];
          final StreamSubscription<LaunchResult> subscription = launcherService
              .launchEvents
              .listen(
                (LaunchResult result) => launchEvents.add(result),
              );

          // Act
          final LaunchResult choreResult = await launcherService
              .launchApplication(testApplications[0]);
          final LaunchResult budgetResult = await launcherService
              .launchApplication(testApplications[1]);

          await Future.delayed(const Duration(milliseconds: 50));

          // Assert
          expect(choreResult.success, false);
          expect(choreResult.errorCode, 'URL_NOT_ACCESSIBLE');
          expect(budgetResult.success, true);

          expect(
            launcherService.isApplicationRunning(testApplications[0].id),
            false,
          );
          expect(
            launcherService.isApplicationRunning(testApplications[1].id),
            true,
          );
          expect(launcherService.runningProcesses.length, 1);

          // Verify events
          expect(launchEvents.length, 2);
          expect(launchEvents[0].success, false);
          expect(launchEvents[1].success, true);

          await subscription.cancel();
        },
      );
    });

    group('Process Management and Monitoring', () {
      test('should manage application lifecycle correctly', () async {
        // Arrange
        final UserApplication app = testApplications[0];

        // Act - Launch application
        final LaunchResult launchResult = await launcherService
            .launchApplication(app);
        expect(launchResult.success, true);

        final ApplicationProcess? process = launcherService
            .getApplicationProcess(app.id);
        expect(process, isNotNull);
        expect(process!.status, ProcessStatus.running);

        // Act - Stop application
        await launcherService.stopApplication(app.id);

        // Assert
        expect(launcherService.isApplicationRunning(app.id), false);
        expect(launcherService.runningProcesses.isEmpty, true);

        // Verify window state was saved
        verify(
          mockPreferences.setString(
            'window_state_${app.id}',
            any,
          ),
        ).called(1);
      });

      test('should restart applications correctly', () async {
        // Arrange
        final UserApplication app = testApplications[0];

        // Launch application initially
        final LaunchResult initialResult = await launcherService
            .launchApplication(app);
        final DateTime initialLaunchTime = initialResult.process!.launchedAt;

        // Wait to ensure different timestamps
        await Future.delayed(const Duration(milliseconds: 10));

        // Act - Restart application
        final LaunchResult restartResult = await launcherService
            .restartApplication(app);

        // Assert
        expect(restartResult.success, true);
        expect(launcherService.isApplicationRunning(app.id), true);
        expect(
          restartResult.process!.launchedAt.isAfter(initialLaunchTime),
          true,
        );

        // Should still have only one running process for this app
        expect(launcherService.runningProcesses.length, 1);
      });

      test('should bring existing applications to foreground', () async {
        // Arrange
        final UserApplication app = testApplications[0];

        // Launch application first time
        final LaunchResult firstResult = await launcherService
            .launchApplication(app);
        expect(firstResult.success, true);

        final ApplicationProcess originalProcess = firstResult.process!;
        final DateTime originalAccessTime = originalProcess.lastAccessed;

        // Wait to ensure different timestamps
        await Future.delayed(const Duration(milliseconds: 10));

        // Act - Launch same application again
        final LaunchResult secondResult = await launcherService
            .launchApplication(app);

        // Assert
        expect(secondResult.success, true);
        expect(secondResult.message, contains('brought to foreground'));
        expect(launcherService.runningProcesses.length, 1);

        // Verify the same process was reused but access time updated
        final ApplicationProcess currentProcess = launcherService
            .getApplicationProcess(app.id)!;
        expect(currentProcess.applicationId, originalProcess.applicationId);
        expect(currentProcess.lastAccessed.isAfter(originalAccessTime), true);
      });
    });

    group('Health Monitoring System', () {
      test('should perform health checks on running applications', () async {
        // Arrange
        final UserApplication app = testApplications[0];
        await launcherService.launchApplication(app);

        final ApplicationProcess process = launcherService
            .getApplicationProcess(app.id)!;

        // Simulate time passing to trigger health check
        process.updateLastAccessed();
        await Future.delayed(const Duration(milliseconds: 10));

        // Act
        await launcherService.performHealthChecks();

        // Assert
        expect(process.isHealthy, true);

        // Verify HTTP client was called for health check
        verify(
          mockHttpClient.get(
            any,
            headers: anyNamed('headers'),
          ),
        ).called(greaterThan(1)); // Initial launch + health check
      });

      test('should handle health check failures and emit events', () async {
        // Arrange
        final UserApplication app = testApplications[0];
        await launcherService.launchApplication(app);

        final ApplicationProcess process = launcherService
            .getApplicationProcess(app.id)!;

        // Set up health check failure
        when(
          mockHttpClient.get(
            any,
            headers: anyNamed('headers'),
          ),
        ).thenThrow(Exception('Connection timeout'));

        final List<LaunchResult> healthEvents = [];
        final StreamSubscription<LaunchResult> subscription = launcherService
            .launchEvents
            .listen(
              (LaunchResult result) {
                if (result.errorCode == 'HEALTH_CHECK_FAILED') {
                  healthEvents.add(result);
                }
              },
            );

        // Simulate time passing to trigger health check
        process.updateLastAccessed();
        await Future.delayed(const Duration(milliseconds: 10));

        // Act
        await launcherService.performHealthChecks();

        // Wait for events
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        expect(process.isHealthy, false);
        expect(process.healthCheckError, contains('Connection timeout'));
        expect(process.status, ProcessStatus.crashed);

        expect(healthEvents.length, 1);
        expect(healthEvents[0].success, false);
        expect(healthEvents[0].applicationId, app.id);

        await subscription.cancel();
      });
    });

    group('Window State Management', () {
      test('should save and restore window state across sessions', () async {
        // Arrange
        final UserApplication app = testApplications[0];

        // Set up saved window state
        final WindowState savedState = WindowState(
          x: 150,
          y: 200,
          width: 900,
          height: 700,
          lastUpdated: DateTime.now(),
        );

        when(mockPreferences.getString('window_state_${app.id}')).thenReturn(
          '{"x":150,"y":200,"width":900,"height":700,"isMaximized":false,"isMinimized":false,"isFullscreen":false,"lastUpdated":"${savedState.lastUpdated.toIso8601String()}"}',
        );

        // Act - Launch application (should restore window state)
        final LaunchResult result = await launcherService.launchApplication(
          app,
        );

        // Assert
        expect(result.success, true);
        expect(result.process!.windowState, isNotNull);
        expect(result.process!.windowState!.x, 150);
        expect(result.process!.windowState!.y, 200);
        expect(result.process!.windowState!.width, 900);
        expect(result.process!.windowState!.height, 700);

        // Update window state
        final WindowState newState = WindowState(
          x: 200,
          y: 250,
          width: 1000,
          height: 800,
          lastUpdated: DateTime.now(),
        );
        result.process!.updateWindowState(newState);

        // Act - Stop application (should save window state)
        await launcherService.stopApplication(app.id);

        // Assert - Verify state was saved
        verify(
          mockPreferences.setString(
            'window_state_${app.id}',
            argThat(
              allOf([
                contains('"x":200'),
                contains('"y":250'),
                contains('"width":1000'),
                contains('"height":800'),
              ]),
            ),
          ),
        ).called(1);
      });

      test('should handle invalid window state gracefully', () async {
        // Arrange
        final UserApplication app = testApplications[0];

        // Set up invalid window state JSON
        when(
          mockPreferences.getString('window_state_${app.id}'),
        ).thenReturn('invalid json');

        // Act - Should not throw exception
        final LaunchResult result = await launcherService.launchApplication(
          app,
        );

        // Assert - Should use default window state
        expect(result.success, true);
        expect(
          result.process!.windowState,
          isNull,
        ); // No state restored due to invalid JSON
      });
    });

    group('Concurrent Operations', () {
      test('should handle concurrent launches correctly', () async {
        // Arrange
        final List<Future<LaunchResult>> launchFutures = testApplications
            .take(2)
            .map(
              (UserApplication app) => launcherService.launchApplication(app),
            )
            .toList();

        // Act - Launch applications concurrently
        final List<LaunchResult> results = await Future.wait(launchFutures);

        // Assert
        expect(results.length, 2);
        expect(results.every((LaunchResult r) => r.success), true);
        expect(launcherService.runningProcesses.length, 2);

        // Verify each application is running independently
        for (int i = 0; i < 2; i++) {
          final UserApplication app = testApplications[i];
          expect(launcherService.isApplicationRunning(app.id), true);

          final ApplicationProcess? process = launcherService
              .getApplicationProcess(app.id);
          expect(process, isNotNull);
          expect(process!.applicationId, app.id);
        }
      });

      test(
        'should handle concurrent health checks without interference',
        () async {
          // Arrange - Launch multiple applications
          for (final UserApplication app in testApplications.take(2)) {
            await launcherService.launchApplication(app);
          }

          // Simulate time passing for all processes
          for (final ApplicationProcess process
              in launcherService.runningProcesses) {
            process.updateLastAccessed();
          }
          await Future.delayed(const Duration(milliseconds: 10));

          // Act - Perform health checks (should handle all processes)
          await launcherService.performHealthChecks();

          // Assert - All processes should remain healthy
          for (final ApplicationProcess process
              in launcherService.runningProcesses) {
            expect(process.isHealthy, true);
          }

          // Verify HTTP calls were made for each application
          verify(
            mockHttpClient.get(
              any,
              headers: anyNamed('headers'),
            ),
          ).called(greaterThan(2)); // Initial launches + health checks
        },
      );
    });

    group('Error Recovery and Resilience', () {
      test('should recover from temporary network failures', () async {
        // Arrange
        final UserApplication app = testApplications[0];

        // First attempt fails
        when(
          mockHttpClient.get(
            any,
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => throw Exception('Network error'));

        // Act - First launch attempt should fail
        final LaunchResult firstResult = await launcherService
            .launchApplication(app);
        expect(firstResult.success, false);
        expect(launcherService.isApplicationRunning(app.id), false);

        // Arrange - Network recovers
        when(
          mockHttpClient.get(
            any,
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response('OK', 200));

        // Act - Second launch attempt should succeed
        final LaunchResult secondResult = await launcherService
            .launchApplication(app);

        // Assert
        expect(secondResult.success, true);
        expect(launcherService.isApplicationRunning(app.id), true);
      });

      test('should handle service disposal gracefully', () async {
        // Arrange - Launch applications
        for (final UserApplication app in testApplications.take(2)) {
          await launcherService.launchApplication(app);
        }

        expect(launcherService.runningProcesses.length, 2);

        // Act - Dispose service
        await launcherService.dispose();

        // Assert - All processes should be stopped
        expect(launcherService.runningProcesses.isEmpty, true);

        // Verify cleanup was performed
        verify(
          mockPreferences.setString(any, any),
        ).called(greaterThanOrEqualTo(2));
      });
    });
  });
}
