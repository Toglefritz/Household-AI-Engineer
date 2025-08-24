import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/l10n/app_localizations.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar/dashboard_sidebar.dart';

/// Tests for the two-stage sidebar animation system.
///
/// Verifies that the sidebar correctly implements two-stage animations to prevent
/// overflow errors and text wrapping issues during state transitions.
void main() {
  group('Sidebar Two-Stage Animation', () {
    /// Helper function to create a test app with sidebar.
    Widget createTestApp({required bool isExpanded, VoidCallback? onToggle}) {
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
            onToggle: onToggle ?? () {},
            applications: const [],
            openNewApplicationConversation: () {},
          ),
        ),
      );
    }

    group('Animation staging', () {
      /// Verifies that content transitions before width changes when collapsing.
      ///
      /// This is the key test that ensures overflow prevention by confirming
      /// that content changes to collapsed state before the width shrinks.
      testWidgets('should transition content before width when collapsing', (
        WidgetTester tester,
      ) async {
        bool isExpanded = true;

        await tester.pumpWidget(
          createTestApp(
            isExpanded: isExpanded,
            onToggle: () => isExpanded = !isExpanded,
          ),
        );
        await tester.pumpAndSettle();

        // Verify initial expanded state
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Create New App'), findsOneWidget);

        final double initialWidth = tester
            .getSize(find.byType(DashboardSidebar))
            .width;
        expect(initialWidth, equals(280.0));

        // Trigger collapse
        await tester.pumpWidget(createTestApp(isExpanded: false));

        // Pump a small amount to start content transition
        await tester.pump(const Duration(milliseconds: 50));

        // Content should start transitioning but width should still be wide
        final double earlyWidth = tester
            .getSize(find.byType(DashboardSidebar))
            .width;
        expect(
          earlyWidth,
          greaterThan(200.0),
        ); // Still wide during content transition

        // Pump more to complete content transition
        await tester.pump(const Duration(milliseconds: 100));

        // Content should be collapsed but width might still be transitioning
        expect(find.byType(TextField), findsNothing);
        expect(find.text('Create New App'), findsNothing);
        expect(find.byIcon(Icons.search), findsOneWidget);

        // Complete the animation
        await tester.pumpAndSettle();

        // Final state should be fully collapsed
        final double finalWidth = tester
            .getSize(find.byType(DashboardSidebar))
            .width;
        expect(finalWidth, equals(76.0));
      });

      /// Verifies that width transitions before content when expanding.
      ///
      /// When expanding, width should expand first to provide space,
      /// then content should transition to prevent cramped appearance.
      testWidgets('should transition width before content when expanding', (
        WidgetTester tester,
      ) async {
        bool isExpanded = false;

        await tester.pumpWidget(
          createTestApp(
            isExpanded: isExpanded,
            onToggle: () => isExpanded = !isExpanded,
          ),
        );
        await tester.pumpAndSettle();

        // Verify initial collapsed state
        expect(find.byType(TextField), findsNothing);
        expect(find.byIcon(Icons.search), findsOneWidget);

        final double initialWidth = tester
            .getSize(find.byType(DashboardSidebar))
            .width;
        expect(initialWidth, equals(76.0));

        // Trigger expansion
        await tester.pumpWidget(createTestApp(isExpanded: true));

        // Pump to start width animation
        await tester.pump(const Duration(milliseconds: 75));

        // Width should start expanding but content should still be collapsed
        final double earlyWidth = tester
            .getSize(find.byType(DashboardSidebar))
            .width;
        expect(earlyWidth, greaterThan(76.0));
        expect(find.byType(TextField), findsNothing); // Content still collapsed
        expect(find.byIcon(Icons.search), findsOneWidget);

        // Pump more to complete width expansion and start content transition
        await tester.pump(const Duration(milliseconds: 150));

        // Width should be expanded, content might be transitioning
        final double midWidth = tester
            .getSize(find.byType(DashboardSidebar))
            .width;
        expect(midWidth, greaterThan(200.0));

        // Complete the animation
        await tester.pumpAndSettle();

        // Final state should be fully expanded
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Create New App'), findsOneWidget);

        final double finalWidth = tester
            .getSize(find.byType(DashboardSidebar))
            .width;
        expect(finalWidth, equals(280.0));
      });

      /// Verifies that animation timing is appropriate for preventing overflow.
      ///
      /// Should ensure that content transition completes before width transition
      /// begins when collapsing.
      testWidgets('should have appropriate timing to prevent overflow', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        final Stopwatch stopwatch = Stopwatch()..start();

        // Trigger collapse
        await tester.pumpWidget(createTestApp(isExpanded: false));

        // Check that content transitions quickly
        await tester.pump(const Duration(milliseconds: 100));

        // Content should be collapsed by now
        expect(find.byType(TextField), findsNothing);
        expect(find.text('Create New App'), findsNothing);

        // But width might still be transitioning
        final double midWidth = tester
            .getSize(find.byType(DashboardSidebar))
            .width;
        expect(midWidth, greaterThan(76.0));

        // Complete animation
        await tester.pumpAndSettle();
        stopwatch.stop();

        // Total animation should complete within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(400));

        // Final width should be collapsed
        final double finalWidth = tester
            .getSize(find.byType(DashboardSidebar))
            .width;
        expect(finalWidth, equals(76.0));
      });
    });

    group('Overflow prevention', () {
      /// Verifies that no overflow errors occur during collapse animation.
      ///
      /// This test ensures that the two-stage animation successfully prevents
      /// the overflow issues that occurred with the previous implementation.
      testWidgets('should not cause overflow errors during collapse', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        // Trigger collapse and pump through animation frames
        await tester.pumpWidget(createTestApp(isExpanded: false));

        // Pump multiple frames during animation
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 15));

          // Should not have any exceptions during animation
          expect(tester.takeException(), isNull);
        }

        await tester.pumpAndSettle();

        // Final state should be valid
        expect(find.byType(DashboardSidebar), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      /// Verifies that text wrapping issues are prevented.
      ///
      /// Should ensure that button text doesn't wrap awkwardly during
      /// the width transition by transitioning content first.
      testWidgets('should prevent text wrapping during animation', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        // Verify initial state has full button text
        expect(find.text('Create New App'), findsOneWidget);

        // Trigger collapse
        await tester.pumpWidget(createTestApp(isExpanded: false));

        // Pump through content transition phase
        await tester.pump(const Duration(milliseconds: 75));

        // Text should be gone (preventing wrapping) even if width is still wide
        expect(find.text('Create New App'), findsNothing);

        // Complete animation
        await tester.pumpAndSettle();

        // Should end in proper collapsed state
        expect(find.byIcon(Icons.add), findsOneWidget);
        expect(find.text('Create New App'), findsNothing);
      });

      /// Verifies that rapid state changes don't cause issues.
      ///
      /// Should handle multiple quick state changes without overflow
      /// or animation conflicts.
      testWidgets('should handle rapid state changes without overflow', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        // Rapid state changes
        for (int i = 0; i < 5; i++) {
          await tester.pumpWidget(createTestApp(isExpanded: i.isEven));
          await tester.pump(const Duration(milliseconds: 50));

          // Should not cause exceptions
          expect(tester.takeException(), isNull);
        }

        await tester.pumpAndSettle();

        // Should end in a valid state
        expect(find.byType(DashboardSidebar), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Animation smoothness', () {
      /// Verifies that the two-stage animation still feels smooth.
      ///
      /// Should ensure that despite the staging, the overall animation
      /// feels natural and smooth to users.
      testWidgets('should provide smooth overall animation experience', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        // Trigger collapse and measure smoothness
        await tester.pumpWidget(createTestApp(isExpanded: false));

        final List<double> widthSamples = [];

        // Sample width during animation
        for (int i = 0; i < 15; i++) {
          await tester.pump(const Duration(milliseconds: 20));
          final double width = tester
              .getSize(find.byType(DashboardSidebar))
              .width;
          widthSamples.add(width);
        }

        await tester.pumpAndSettle();

        // Width should transition smoothly (no sudden jumps)
        for (int i = 1; i < widthSamples.length; i++) {
          final double change = (widthSamples[i] - widthSamples[i - 1]).abs();
          expect(change, lessThan(50.0)); // No sudden large changes
        }
      });

      /// Verifies that content transitions are smooth within their stage.
      ///
      /// Should ensure that individual content elements fade smoothly
      /// during their transition phase.
      testWidgets('should have smooth content transitions', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        // Trigger collapse
        await tester.pumpWidget(createTestApp(isExpanded: false));

        // Content should transition smoothly
        await tester.pump(
          const Duration(milliseconds: 50),
        ); // Mid content transition

        // Should still be in a valid state during transition
        expect(find.byType(DashboardSidebar), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpAndSettle();

        // Final state should be correct
        expect(find.byIcon(Icons.search), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      });
    });

    group('State consistency', () {
      /// Verifies that internal animation state stays consistent.
      ///
      /// Should ensure that the two-stage animation maintains consistent
      /// internal state throughout the transition process.
      testWidgets('should maintain consistent internal state', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        // All sections should be present in both states
        expect(find.byType(DashboardSidebar), findsOneWidget);

        // Trigger multiple transitions
        for (int i = 0; i < 3; i++) {
          await tester.pumpWidget(createTestApp(isExpanded: false));
          await tester.pump(const Duration(milliseconds: 100));

          await tester.pumpWidget(createTestApp(isExpanded: true));
          await tester.pump(const Duration(milliseconds: 100));
        }

        await tester.pumpAndSettle();

        // Should end in consistent state
        expect(find.byType(DashboardSidebar), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      /// Verifies that animation controllers are properly managed.
      ///
      /// Should ensure that the multiple animation controllers don't
      /// interfere with each other or cause memory leaks.
      testWidgets('should properly manage animation controllers', (
        WidgetTester tester,
      ) async {
        // Create and destroy multiple sidebar instances
        for (int i = 0; i < 3; i++) {
          await tester.pumpWidget(createTestApp(isExpanded: true));
          await tester.pumpAndSettle();

          await tester.pumpWidget(createTestApp(isExpanded: false));
          await tester.pumpAndSettle();

          // Clear the widget tree
          await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        }

        // Should not cause memory issues or exceptions
        expect(tester.takeException(), isNull);
      });
    });
  });
}
