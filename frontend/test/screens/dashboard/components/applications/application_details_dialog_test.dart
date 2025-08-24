import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:household_ai_engineer/screens/dashboard/components/applications/application_details_dialog.dart';
import 'package:household_ai_engineer/services/user_application/models/application_status.dart';
import 'package:household_ai_engineer/services/user_application/models/development_progress.dart';
import 'package:household_ai_engineer/services/user_application/models/milestone_status.dart';
import 'package:household_ai_engineer/services/user_application/models/user_application.dart';
import '../../../../test_helpers.dart';

/// Test suite for ApplicationDetailsDialog widget.
///
/// Tests the application details dialog functionality including information display,
/// action buttons, and status-specific content.
void main() {
  group('ApplicationDetailsDialog', () {
    late UserApplication testApplication;

    setUp(() {
      testApplication = UserApplication(
        id: 'test-app-1',
        title: 'Test Application',
        description: 'A comprehensive test application for unit testing purposes',
        status: ApplicationStatus.ready,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        tags: ['test', 'demo'],
      );
    });

    group('dialog display', () {
      testWidgets('shows application information correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    ApplicationDetailsDialog.show(
                      context: context,
                      application: testApplication,
                    );
                  },
                  child: const Text('Show Details'),
                );
              },
            ),
          ),
        );

        // Tap button to show dialog
        await tester.tap(find.text('Show Details'));
        await tester.pumpAndSettle();

        // Verify application information is displayed
        expect(find.text('Test Application'), findsOneWidget);
        expect(find.text('A comprehensive test application for unit testing purposes'), findsOneWidget);
        expect(find.text('Ready'), findsOneWidget);
        expect(find.text('Description'), findsOneWidget);
        expect(find.text('Information'), findsOneWidget);
      });

      testWidgets('can be closed with close button', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    ApplicationDetailsDialog.show(
                      context: context,
                      application: testApplication,
                    );
                  },
                  child: const Text('Show Details'),
                );
              },
            ),
          ),
        );

        // Tap button to show dialog
        await tester.tap(find.text('Show Details'));
        await tester.pumpAndSettle();

        // Verify dialog is shown
        expect(find.text('Test Application'), findsOneWidget);

        // Tap close button
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Verify dialog is closed
        expect(find.text('Test Application'), findsNothing);
      });
    });

    group('action buttons', () {
      testWidgets('shows launch button for ready applications', (WidgetTester tester) async {
        bool launchCalled = false;

        await tester.pumpWidget(
          createTestApp(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    ApplicationDetailsDialog.show(
                      context: context,
                      application: testApplication,
                      onLaunch: (app) {
                        launchCalled = true;
                      },
                    );
                  },
                  child: const Text('Show Details'),
                );
              },
            ),
          ),
        );

        // Tap button to show dialog
        await tester.tap(find.text('Show Details'));
        await tester.pumpAndSettle();

        // Verify launch button is present
        expect(find.text('Launch'), findsOneWidget);

        // Tap launch button
        await tester.tap(find.text('Launch'));
        await tester.pumpAndSettle();

        // Verify callback was called and dialog closed
        expect(launchCalled, isTrue);
        expect(find.text('Test Application'), findsNothing);
      });

      testWidgets('shows modify button for modifiable applications', (WidgetTester tester) async {
        bool modifyCalled = false;

        await tester.pumpWidget(
          createTestApp(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    ApplicationDetailsDialog.show(
                      context: context,
                      application: testApplication,
                      onModify: (app) {
                        modifyCalled = true;
                      },
                    );
                  },
                  child: const Text('Show Details'),
                );
              },
            ),
          ),
        );

        // Tap button to show dialog
        await tester.tap(find.text('Show Details'));
        await tester.pumpAndSettle();

        // Verify modify button is present
        expect(find.text('Modify'), findsOneWidget);

        // Tap modify button
        await tester.tap(find.text('Modify'));
        await tester.pumpAndSettle();

        // Verify callback was called and dialog closed
        expect(modifyCalled, isTrue);
        expect(find.text('Test Application'), findsNothing);
      });
    });
  });
}
