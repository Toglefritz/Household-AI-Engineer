import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:household_ai_engineer/l10n/app_localizations.dart';
import 'package:household_ai_engineer/screens/dashboard/components/applications/application_context_menu.dart';
import 'package:household_ai_engineer/services/user_application/models/application_status.dart';
import 'package:household_ai_engineer/services/user_application/models/user_application.dart';
import '../../../../test_helpers.dart';

/// Test suite for ApplicationContextMenu widget.
///
/// Tests the context menu functionality including menu item generation,
/// action callbacks, and status-based menu item availability.
void main() {
  group('ApplicationContextMenu', () {
    late UserApplication testApplication;

    setUp(() {
      testApplication = UserApplication(
        id: 'test-app-1',
        title: 'Test Application',
        description: 'A test application for unit testing',
        status: ApplicationStatus.ready,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
      );
    });

    group('menu item generation', () {
      testWidgets('shows launch action for ready applications', (WidgetTester tester) async {
        bool launchCalled = false;

        await tester.pumpWidget(
          createTestApp(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    ApplicationContextMenu.show(
                      context: context,
                      position: const Offset(100, 100),
                      application: testApplication,
                      onLaunch: (app) {
                        launchCalled = true;
                      },
                    );
                  },
                  child: const Text('Show Menu'),
                );
              },
            ),
          ),
        );

        // Tap the button to show the menu
        await tester.tap(find.text('Show Menu'));
        await tester.pumpAndSettle();

        // Verify launch action is present
        expect(find.text('Launch'), findsOneWidget);

        // Tap the launch action
        await tester.tap(find.text('Launch'));
        await tester.pumpAndSettle();

        // Verify callback was called
        expect(launchCalled, isTrue);
      });

      testWidgets('shows bring to foreground for running applications', (WidgetTester tester) async {
        final UserApplication runningApp = testApplication.copyWith(
          status: ApplicationStatus.running,
        );

        bool launchCalled = false;

        await tester.pumpWidget(
          createTestApp(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    ApplicationContextMenu.show(
                      context: context,
                      position: const Offset(100, 100),
                      application: runningApp,
                      onLaunch: (app) {
                        launchCalled = true;
                      },
                    );
                  },
                  child: const Text('Show Menu'),
                );
              },
            ),
          ),
        );

        // Tap the button to show the menu
        await tester.tap(find.text('Show Menu'));
        await tester.pumpAndSettle();

        // Verify bring to foreground action is present
        expect(find.text('Bring to Foreground'), findsOneWidget);

        // Tap the action
        await tester.tap(find.text('Bring to Foreground'));
        await tester.pumpAndSettle();

        // Verify callback was called
        expect(launchCalled, isTrue);
      });

      testWidgets('shows modify action for modifiable applications', (WidgetTester tester) async {
        bool modifyCalled = false;

        await tester.pumpWidget(
          createTestApp(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    ApplicationContextMenu.show(
                      context: context,
                      position: const Offset(100, 100),
                      application: testApplication,
                      onModify: (app) {
                        modifyCalled = true;
                      },
                    );
                  },
                  child: const Text('Show Menu'),
                );
              },
            ),
          ),
        );

        // Tap the button to show the menu
        await tester.tap(find.text('Show Menu'));
        await tester.pumpAndSettle();

        // Verify modify action is present
        expect(find.text('Modify'), findsOneWidget);

        // Tap the modify action
        await tester.tap(find.text('Modify'));
        await tester.pumpAndSettle();

        // Verify callback was called
        expect(modifyCalled, isTrue);
      });

      testWidgets('always shows view details action', (WidgetTester tester) async {
        bool viewDetailsCalled = false;

        await tester.pumpWidget(
          createTestApp(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    ApplicationContextMenu.show(
                      context: context,
                      position: const Offset(100, 100),
                      application: testApplication,
                      onViewDetails: (app) {
                        viewDetailsCalled = true;
                      },
                    );
                  },
                  child: const Text('Show Menu'),
                );
              },
            ),
          ),
        );

        // Tap the button to show the menu
        await tester.tap(find.text('Show Menu'));
        await tester.pumpAndSettle();

        // Verify view details action is present
        expect(find.text('View Details'), findsOneWidget);

        // Tap the view details action
        await tester.tap(find.text('View Details'));
        await tester.pumpAndSettle();

        // Verify callback was called
        expect(viewDetailsCalled, isTrue);
      });
    });
  });
}
