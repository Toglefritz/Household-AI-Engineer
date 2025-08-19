import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/models/launch_configuration/launch_configuration.dart';
import 'package:household_ai_engineer/models/launch_configuration/launch_type.dart';
import 'package:household_ai_engineer/screens/dashboard/components/applications/application_tile.dart';
import 'package:household_ai_engineer/services/user_application/models/application_status.dart';
import 'package:household_ai_engineer/services/user_application/models/development_progress.dart';
import 'package:household_ai_engineer/services/user_application/models/user_application.dart';

import '../../../test_helpers.dart';

/// Test suite for [ApplicationTile] widget.
///
/// Covers rendering, interaction, and visual state management
/// for application tiles across different application statuses.
void main() {
  group('ApplicationTile', () {
    late UserApplication sampleApplication;

    setUp(() {
      sampleApplication = UserApplication(
        id: 'test_app_001',
        title: 'Test Application',
        description: 'A test application for widget testing',
        status: ApplicationStatus.ready,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        launchConfig: const LaunchConfiguration(
          type: LaunchType.web,
          url: 'http://localhost:3000',
        ),
        tags: ['test', 'widget'],
      );
    });

    group('rendering', () {
      testWidgets('displays application title and description', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: ApplicationTile(application: sampleApplication),
          ),
        );

        expect(find.text('Test Application'), findsOneWidget);
        expect(find.text('A test application for widget testing'), findsOneWidget);
      });

      testWidgets('displays status indicator for ready application', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: ApplicationTile(application: sampleApplication),
          ),
        );

        expect(find.text('Ready'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('displays running status indicator', (WidgetTester tester) async {
        final UserApplication runningApp = sampleApplication.copyWith(
          status: ApplicationStatus.running,
        );

        await tester.pumpWidget(
          createTestApp(
            child: ApplicationTile(application: runningApp),
          ),
        );

        expect(find.text('Running'), findsOneWidget);
      });

      testWidgets('displays failed status indicator', (WidgetTester tester) async {
        final UserApplication failedApp = sampleApplication.copyWith(
          status: ApplicationStatus.failed,
        );

        await tester.pumpWidget(
          createTestApp(
            child: ApplicationTile(application: failedApp),
          ),
        );

        expect(find.text('Failed'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
      });

      testWidgets('displays progress indicator for developing application', (WidgetTester tester) async {
        final UserApplication developingApp = sampleApplication.copyWith(
          status: ApplicationStatus.developing,
          progress: DevelopmentProgress(
            percentage: 65.0,
            currentPhase: 'Building User Interface',
            milestones: [],
            lastUpdated: DateTime.now(),
          ),
        );

        await tester.pumpWidget(
          createTestApp(
            child: ApplicationTile(application: developingApp),
          ),
        );

        expect(find.text('Developing'), findsOneWidget);
        expect(find.text('65% • Building User Interface'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('displays updated time description', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: ApplicationTile(application: sampleApplication),
          ),
        );

        expect(find.textContaining('Updated'), findsOneWidget);
      });
    });

    group('interactions', () {
      testWidgets('calls onTap callback when tapped', (WidgetTester tester) async {
        bool tapCalled = false;

        await tester.pumpWidget(
          createTestApp(
            child: ApplicationTile(
              application: sampleApplication,
              onTap: () => tapCalled = true,
            ),
          ),
        );

        await tester.tap(find.byType(ApplicationTile));
        expect(tapCalled, isTrue);
      });

      testWidgets('calls onSecondaryTap callback when right-clicked', (WidgetTester tester) async {
        bool secondaryTapCalled = false;

        await tester.pumpWidget(
          createTestApp(
            child: ApplicationTile(
              application: sampleApplication,
              onSecondaryTap: () => secondaryTapCalled = true,
            ),
          ),
        );

        await tester.tap(find.byType(ApplicationTile), buttons: kSecondaryMouseButton);
        expect(secondaryTapCalled, isTrue);
      });

      testWidgets('does not call callbacks when they are null', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: ApplicationTile(application: sampleApplication),
          ),
        );

        // Should not throw when tapping without callbacks
        await tester.tap(find.byType(ApplicationTile));
        await tester.tap(find.byType(ApplicationTile), buttons: kSecondaryMouseButton);
      });
    });

    group('visual states', () {
      testWidgets('shows selection styling when selected', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: ApplicationTile(
              application: sampleApplication,
              isSelected: true,
            ),
          ),
        );

        final Container container = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(ApplicationTile),
                matching: find.byType(Container),
              )
              .first,
        );

        final BoxDecoration decoration = container.decoration! as BoxDecoration;
        expect(decoration.border?.top.width, equals(2));
      });

      testWidgets('shows default styling when not selected', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: ApplicationTile(
              application: sampleApplication,
            ),
          ),
        );

        final Container container = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(ApplicationTile),
                matching: find.byType(Container),
              )
              .first,
        );

        final BoxDecoration decoration = container.decoration! as BoxDecoration;
        expect(decoration.border?.top.width, equals(1));
      });
    });

    group('different application statuses', () {
      testWidgets('renders requested status correctly', (WidgetTester tester) async {
        final UserApplication requestedApp = sampleApplication.copyWith(
          status: ApplicationStatus.requested,
        );

        await tester.pumpWidget(
          createTestApp(
            child: ApplicationTile(application: requestedApp),
          ),
        );

        expect(find.text('Queued'), findsOneWidget);
        expect(find.byIcon(Icons.schedule), findsOneWidget);
      });

      testWidgets('renders testing status correctly', (WidgetTester tester) async {
        final UserApplication testingApp = sampleApplication.copyWith(
          status: ApplicationStatus.testing,
          progress: DevelopmentProgress(
            percentage: 90.0,
            currentPhase: 'Running Integration Tests',
            milestones: [],
            lastUpdated: DateTime.now(),
          ),
        );

        await tester.pumpWidget(
          createTestApp(
            child: ApplicationTile(application: testingApp),
          ),
        );

        expect(find.text('Testing'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('90% • Running Integration Tests'), findsOneWidget);
      });

      testWidgets('renders updating status correctly', (WidgetTester tester) async {
        final UserApplication updatingApp = sampleApplication.copyWith(
          status: ApplicationStatus.updating,
          progress: DevelopmentProgress(
            percentage: 25.0,
            currentPhase: 'Applying Updates',
            milestones: [],
            lastUpdated: DateTime.now(),
          ),
        );

        await tester.pumpWidget(
          createTestApp(
            child: ApplicationTile(application: updatingApp),
          ),
        );

        expect(find.text('Updating'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('25% • Applying Updates'), findsOneWidget);
      });
    });

    group('accessibility', () {
      testWidgets('has proper semantic labels', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: ApplicationTile(application: sampleApplication),
          ),
        );

        // Verify the tile is accessible and renders correctly
        expect(find.byType(ApplicationTile), findsOneWidget);
        expect(find.text('Test Application'), findsOneWidget);
        expect(find.text('Ready'), findsOneWidget);
      });
    });
  });
}
