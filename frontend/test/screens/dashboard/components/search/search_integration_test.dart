/// Integration tests for the search and filtering system.
///
/// Tests the complete search and filtering workflow including
/// real-time search, filter application, sorting, and result display.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/screens/dashboard/components/search/search_and_filter_interface.dart';
import 'package:household_ai_engineer/services/user_application/models/application_category.dart';
import 'package:household_ai_engineer/services/user_application/models/application_status.dart';
import 'package:household_ai_engineer/services/user_application/models/user_application.dart';

void main() {
  group('Search and Filter Integration', () {
    late List<UserApplication> testApplications;

    setUp(() {
      testApplications = [
        UserApplication(
          id: 'app1',
          title: 'Budget Tracker',
          description: 'Track your household expenses and income',
          category: ApplicationCategory.finance,
          status: ApplicationStatus.ready,
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 20),
        ),
        UserApplication(
          id: 'app2',
          title: 'Chore Manager',
          description: 'Manage family chores and responsibilities',
          category: ApplicationCategory.homeManagement,
          status: ApplicationStatus.running,
          createdAt: DateTime(2024, 2, 10),
          updatedAt: DateTime(2024, 2, 15),
        ),
        UserApplication(
          id: 'app3',
          title: 'Meal Planner',
          description: 'Plan weekly meals and shopping lists',
          category: ApplicationCategory.planning,
          status: ApplicationStatus.developing,
          createdAt: DateTime(2024, 3, 5),
          updatedAt: DateTime(2024, 3, 10),
        ),
      ];
    });

    testWidgets('should filter applications in real-time', (WidgetTester tester) async {
      List<UserApplication> filteredResults = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchAndFilterInterface(
              applications: testApplications,
              onResultsChanged: (results) {
                filteredResults = results;
              },
            ),
          ),
        ),
      );

      // Initially should show all applications
      expect(filteredResults.length, equals(3));

      // Find and tap the search field
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Enter search text
      await tester.enterText(searchField, 'Budget');
      await tester.pump();

      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 400));

      // Should filter to only Budget Tracker
      expect(filteredResults.length, equals(1));
      expect(filteredResults.first.title, equals('Budget Tracker'));
    });

    testWidgets('should show filter panel when toggle is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchAndFilterInterface(
              applications: testApplications,
              onResultsChanged: (results) {},
            ),
          ),
        ),
      );

      // Find the filter toggle button
      final filterToggle = find.byIcon(Icons.filter_list);
      expect(filterToggle, findsOneWidget);

      // Tap to show filter panel
      await tester.tap(filterToggle);
      await tester.pumpAndSettle();

      // Should show filter panel with categories
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
    });

    testWidgets('should display sort controls', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchAndFilterInterface(
              applications: testApplications,
              onResultsChanged: (results) {},
            ),
          ),
        ),
      );

      // Should show sort controls
      expect(find.byIcon(Icons.sort), findsOneWidget);
      expect(find.text('Sort by'), findsOneWidget);
    });

    testWidgets('should show result count', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchAndFilterInterface(
              applications: testApplications,
              onResultsChanged: (results) {},
            ),
          ),
        ),
      );

      // Should show application count
      expect(find.text('3 applications'), findsOneWidget);
    });
  });
}
