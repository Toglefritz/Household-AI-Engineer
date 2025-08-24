import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/screens/dashboard/dashboard_route.dart';

import '../../test_helpers.dart';

/// Integration test for the dashboard with conversation interface.
///
/// Tests the integration between the dashboard and conversation modal
/// to ensure the conversational interface can be accessed and used.
void main() {
  group('Dashboard Integration', () {
    testWidgets(
      'displays floating action button for creating new applications',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const DashboardRoute(),
          ),
        );

        // Wait for the dashboard to load
        await tester.pumpAndSettle();

        // Should display the floating action button
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.text('Create New App'), findsOneWidget);
        expect(find.byIcon(Icons.chat), findsOneWidget);
      },
    );

    testWidgets('displays create new app button in empty state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          child: const DashboardRoute(),
        ),
      );

      // Wait for the dashboard to load
      await tester.pumpAndSettle();

      // Should display the empty state with create button
      // Note: This assumes no applications are loaded by default
      expect(find.text('No Applications Yet'), findsOneWidget);
      expect(
        find.text('Create your first application to get started'),
        findsOneWidget,
      );
    });

    testWidgets('can tap floating action button without errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          child: const DashboardRoute(),
        ),
      );

      // Wait for the dashboard to load
      await tester.pumpAndSettle();

      // Tap the floating action button
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      // Should not throw any errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('displays application tiles when applications exist', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          child: const DashboardRoute(),
        ),
      );

      // Wait for the dashboard to load
      await tester.pumpAndSettle();

      // Should display application tiles (from sample data)
      expect(find.textContaining('Family Chore Tracker'), findsOneWidget);
      expect(find.textContaining('Budget Planner'), findsOneWidget);
      expect(find.textContaining('Home Maintenance Log'), findsOneWidget);
    });

    testWidgets('displays different application statuses correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          child: const DashboardRoute(),
        ),
      );

      // Wait for the dashboard to load
      await tester.pumpAndSettle();

      // Should display various status indicators
      expect(find.text('Running'), findsAtLeastNWidgets(1));
      expect(find.text('Developing'), findsAtLeastNWidgets(1));
      expect(find.text('Ready'), findsAtLeastNWidgets(1));
      expect(find.text('Failed'), findsAtLeastNWidgets(1));
    });

    testWidgets('can tap application tiles without errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          child: const DashboardRoute(),
        ),
      );

      // Wait for the dashboard to load
      await tester.pumpAndSettle();

      // Find and tap an application tile
      final Finder applicationTile = find.textContaining(
        'Family Chore Tracker',
      );
      if (tester.any(applicationTile)) {
        await tester.tap(applicationTile);
        await tester.pump();

        // Should not throw any errors
        expect(tester.takeException(), isNull);
      }
    });
  });
}
