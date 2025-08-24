import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:household_ai_engineer/screens/dashboard/components/applications/bulk_selection_toolbar.dart';
import 'package:household_ai_engineer/services/user_application/models/application_status.dart';
import 'package:household_ai_engineer/services/user_application/models/user_application.dart';
import '../../../../test_helpers.dart';

/// Test suite for BulkSelectionToolbar widget.
///
/// Tests the bulk selection toolbar functionality including selection count display,
/// action buttons, and bulk operation confirmations.
void main() {
  group('BulkSelectionToolbar', () {
    late List<UserApplication> testApplications;

    setUp(() {
      testApplications = [
        UserApplication(
          id: 'app-1',
          title: 'Test App 1',
          description: 'First test application',
          status: ApplicationStatus.ready,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        UserApplication(
          id: 'app-2',
          title: 'Test App 2',
          description: 'Second test application',
          status: ApplicationStatus.running,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now(),
        ),
        UserApplication(
          id: 'app-3',
          title: 'Test App 3',
          description: 'Third test application',
          status: ApplicationStatus.failed,
          createdAt: DateTime.now().subtract(const Duration(hours: 12)),
          updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      ];
    });

    group('selection count display', () {
      testWidgets('shows correct selection count', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: BulkSelectionToolbar(
              selectedApplications: [testApplications[0], testApplications[1]],
              totalApplications: testApplications.length,
            ),
          ),
        );

        // Verify selection count is displayed
        expect(find.text('2 selected'), findsOneWidget);
      });

      testWidgets('shows single selection count', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: BulkSelectionToolbar(
              selectedApplications: [testApplications[0]],
              totalApplications: testApplications.length,
            ),
          ),
        );

        // Verify single selection count is displayed
        expect(find.text('1 selected'), findsOneWidget);
      });
    });

    group('select all/none functionality', () {
      testWidgets('shows select all when not all selected', (WidgetTester tester) async {
        bool selectAllCalled = false;

        await tester.pumpWidget(
          createTestApp(
            child: BulkSelectionToolbar(
              selectedApplications: [testApplications[0]],
              totalApplications: testApplications.length,
              onSelectAll: () {
                selectAllCalled = true;
              },
              onSelectNone: () {},
            ),
          ),
        );

        // Verify select all button is shown
        expect(find.text('Select All'), findsOneWidget);
        expect(find.text('Select None'), findsNothing);

        // Tap select all
        await tester.tap(find.text('Select All'));
        await tester.pump();

        // Verify callback was called
        expect(selectAllCalled, isTrue);
      });

      testWidgets('shows select none when all selected', (WidgetTester tester) async {
        bool selectNoneCalled = false;

        await tester.pumpWidget(
          createTestApp(
            child: BulkSelectionToolbar(
              selectedApplications: testApplications,
              totalApplications: testApplications.length,
              onSelectAll: () {},
              onSelectNone: () {
                selectNoneCalled = true;
              },
            ),
          ),
        );

        // Verify select none button is shown
        expect(find.text('Select None'), findsOneWidget);
        expect(find.text('Select All'), findsNothing);

        // Tap select none
        await tester.tap(find.text('Select None'));
        await tester.pump();

        // Verify callback was called
        expect(selectNoneCalled, isTrue);
      });
    });

    group('bulk delete functionality', () {
      testWidgets('shows delete button when deletable apps are selected', (WidgetTester tester) async {
        // Select apps that can be deleted (ready and failed)
        final List<UserApplication> deletableApps = [
          testApplications[0], // ready
          testApplications[2], // failed
        ];

        await tester.pumpWidget(
          createTestApp(
            child: BulkSelectionToolbar(
              selectedApplications: deletableApps,
              totalApplications: testApplications.length,
              onBulkDelete: (apps) {},
            ),
          ),
        );

        // Verify delete button is shown
        expect(find.text('Delete'), findsOneWidget);
      });

      testWidgets('shows confirmation dialog when delete is tapped', (WidgetTester tester) async {
        final List<UserApplication> deletableApps = [
          testApplications[0], // ready
          testApplications[2], // failed
        ];

        await tester.pumpWidget(
          createTestApp(
            child: BulkSelectionToolbar(
              selectedApplications: deletableApps,
              totalApplications: testApplications.length,
              onBulkDelete: (apps) {},
            ),
          ),
        );

        // Tap delete button
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Verify confirmation dialog is shown
        expect(find.text('Delete Applications'), findsOneWidget);
        expect(
          find.text('Are you sure you want to delete 2 applications? This action cannot be undone.'),
          findsOneWidget,
        );
        expect(find.text('Cancel'), findsOneWidget);
      });
    });
  });
}
