import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/l10n/app_localizations.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar/dashboard_sidebar.dart';

/// Basic functionality tests for the sidebar.
///
/// Verifies core sidebar functionality without complex visual verification.
/// Focuses on ensuring the sidebar renders and transitions work without errors.
void main() {
  group('Sidebar Basic Functionality', () {
    /// Helper function to create a test app with sidebar.
    Widget createTestApp({required bool isExpanded}) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: DashboardSidebar(
            isExpanded: isExpanded,
            onToggle: () {},
            applications: const [],
            openNewApplicationConversation: () {},
          ),
        ),
      );
    }

    group('Basic rendering', () {
      /// Verifies that the sidebar renders in expanded state.
      testWidgets('should render in expanded state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        expect(find.byType(DashboardSidebar), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      /// Verifies that the sidebar renders in collapsed state.
      testWidgets('should render in collapsed state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp(isExpanded: false));
        await tester.pumpAndSettle();

        expect(find.byType(DashboardSidebar), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      /// Verifies that the sidebar can transition between states.
      testWidgets('should transition between states without errors', (WidgetTester tester) async {
        // Start expanded
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();
        expect(find.byType(DashboardSidebar), findsOneWidget);

        // Transition to collapsed
        await tester.pumpWidget(createTestApp(isExpanded: false));
        await tester.pumpAndSettle();
        expect(find.byType(DashboardSidebar), findsOneWidget);

        // Transition back to expanded
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();
        expect(find.byType(DashboardSidebar), findsOneWidget);

        // Should not have any exceptions
        expect(tester.takeException(), isNull);
      });

      /// Verifies that rapid state changes don't cause errors.
      testWidgets('should handle rapid state changes', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        // Rapid transitions
        for (int i = 0; i < 5; i++) {
          await tester.pumpWidget(createTestApp(isExpanded: i.isEven));
          await tester.pump(const Duration(milliseconds: 50));
        }

        await tester.pumpAndSettle();
        expect(find.byType(DashboardSidebar), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Width behavior', () {
      /// Verifies that sidebar has different widths in different states.
      testWidgets('should have different widths for expanded vs collapsed', (WidgetTester tester) async {
        // Test expanded width
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();
        final double expandedWidth = tester.getSize(find.byType(DashboardSidebar)).width;

        // Test collapsed width
        await tester.pumpWidget(createTestApp(isExpanded: false));
        await tester.pumpAndSettle();
        final double collapsedWidth = tester.getSize(find.byType(DashboardSidebar)).width;

        // Widths should be different
        expect(expandedWidth, greaterThan(collapsedWidth));
        expect(expandedWidth, equals(280.0));
        expect(collapsedWidth, equals(76.0));
      });
    });

    group('Animation stability', () {
      /// Verifies that animations complete without leaving pending timers.
      testWidgets('should complete animations cleanly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        // Trigger animation
        await tester.pumpWidget(createTestApp(isExpanded: false));

        // Wait for animation to complete
        await tester.pumpAndSettle();

        // Should not have pending timers or exceptions
        expect(tester.takeException(), isNull);
      });
    });
  });
}
