import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/screens/dashboard/components/dashboard_sidebar.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar_search_section.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar_navigation_section.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar_categories_section.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar_quick_actions_section.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar_spacing.dart';
import 'package:household_ai_engineer/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Visual verification tests for sidebar layout consistency.
///
/// These tests verify that the sidebar redesign successfully eliminates
/// layout shifts and maintains visual consistency during state transitions.
/// They focus on measuring and comparing element positions, sizes, and
/// spacing to ensure the "no jumping elements" requirement is met.
void main() {
  group('Sidebar Visual Verification', () {
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
          ),
        ),
      );
    }

    group('Layout shift prevention', () {
      /// Verifies that no elements shift vertically during state transitions.
      ///
      /// This is the core test that validates the main requirement: preventing
      /// elements from "jumping" up the page when the sidebar state changes.
      testWidgets('should prevent vertical layout shifts during state transitions', (WidgetTester tester) async {
        // Capture element positions in expanded state
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        final Map<Type, Offset> expandedPositions = {
          SidebarSearchSection: tester.getTopLeft(find.byType(SidebarSearchSection)),
          SidebarNavigationSection: tester.getTopLeft(find.byType(SidebarNavigationSection)),
          SidebarCategoriesSection: tester.getTopLeft(find.byType(SidebarCategoriesSection)),
          SidebarQuickActionsSection: tester.getTopLeft(find.byType(SidebarQuickActionsSection)),
        };

        // Capture element positions in collapsed state
        await tester.pumpWidget(createTestApp(isExpanded: false));
        await tester.pumpAndSettle();

        final Map<Type, Offset> collapsedPositions = {
          SidebarSearchSection: tester.getTopLeft(find.byType(SidebarSearchSection)),
          SidebarNavigationSection: tester.getTopLeft(find.byType(SidebarNavigationSection)),
          SidebarCategoriesSection: tester.getTopLeft(find.byType(SidebarCategoriesSection)),
          SidebarQuickActionsSection: tester.getTopLeft(find.byType(SidebarQuickActionsSection)),
        };

        // Verify that Y positions (vertical) are identical
        for (final Type componentType in expandedPositions.keys) {
          final double expandedY = expandedPositions[componentType]!.dy;
          final double collapsedY = collapsedPositions[componentType]!.dy;

          expect(
            expandedY,
            equals(collapsedY),
            reason:
                '$componentType should not shift vertically between states. '
                'Expanded Y: $expandedY, Collapsed Y: $collapsedY',
          );
        }
      });

      /// Verifies that section heights remain consistent across states.
      ///
      /// Should ensure that major sections maintain their allocated vertical
      /// space to prevent layout shifts caused by height changes.
      testWidgets('should maintain consistent section heights', (WidgetTester tester) async {
        // Measure section heights in expanded state
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        final Map<Type, double> expandedHeights = {
          SidebarSearchSection: tester.getSize(find.byType(SidebarSearchSection)).height,
          SidebarNavigationSection: tester.getSize(find.byType(SidebarNavigationSection)).height,
          SidebarCategoriesSection: tester.getSize(find.byType(SidebarCategoriesSection)).height,
          SidebarQuickActionsSection: tester.getSize(find.byType(SidebarQuickActionsSection)).height,
        };

        // Measure section heights in collapsed state
        await tester.pumpWidget(createTestApp(isExpanded: false));
        await tester.pumpAndSettle();

        final Map<Type, double> collapsedHeights = {
          SidebarSearchSection: tester.getSize(find.byType(SidebarSearchSection)).height,
          SidebarNavigationSection: tester.getSize(find.byType(SidebarNavigationSection)).height,
          SidebarCategoriesSection: tester.getSize(find.byType(SidebarCategoriesSection)).height,
          SidebarQuickActionsSection: tester.getSize(find.byType(SidebarQuickActionsSection)).height,
        };

        // Verify that heights are consistent (allowing small variations for text vs spacing)
        for (final Type componentType in expandedHeights.keys) {
          final double expandedHeight = expandedHeights[componentType]!;
          final double collapsedHeight = collapsedHeights[componentType]!;
          final double heightDifference = (expandedHeight - collapsedHeight).abs();

          expect(
            heightDifference,
            lessThan(10.0), // Allow small variations for text vs spacing
            reason:
                '$componentType height should remain consistent between states. '
                'Expanded: $expandedHeight, Collapsed: $collapsedHeight, Diff: $heightDifference',
          );
        }
      });

      /// Verifies that spacing between sections remains consistent.
      ///
      /// Should ensure that the vertical gaps between sections don't change
      /// when the sidebar state transitions, maintaining visual rhythm.
      testWidgets('should maintain consistent spacing between sections', (WidgetTester tester) async {
        // Calculate spacing in expanded state
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        final double searchBottom = tester.getBottomLeft(find.byType(SidebarSearchSection)).dy;
        final double navTop = tester.getTopLeft(find.byType(SidebarNavigationSection)).dy;
        final double navBottom = tester.getBottomLeft(find.byType(SidebarNavigationSection)).dy;
        final double categoriesTop = tester.getTopLeft(find.byType(SidebarCategoriesSection)).dy;
        final double categoriesBottom = tester.getBottomLeft(find.byType(SidebarCategoriesSection)).dy;
        final double actionsTop = tester.getTopLeft(find.byType(SidebarQuickActionsSection)).dy;

        final Map<String, double> expandedSpacing = {
          'search-to-nav': navTop - searchBottom,
          'nav-to-categories': categoriesTop - navBottom,
          'categories-to-actions': actionsTop - categoriesBottom,
        };

        // Calculate spacing in collapsed state
        await tester.pumpWidget(createTestApp(isExpanded: false));
        await tester.pumpAndSettle();

        final double collapsedSearchBottom = tester.getBottomLeft(find.byType(SidebarSearchSection)).dy;
        final double collapsedNavTop = tester.getTopLeft(find.byType(SidebarNavigationSection)).dy;
        final double collapsedNavBottom = tester.getBottomLeft(find.byType(SidebarNavigationSection)).dy;
        final double collapsedCategoriesTop = tester.getTopLeft(find.byType(SidebarCategoriesSection)).dy;
        final double collapsedCategoriesBottom = tester.getBottomLeft(find.byType(SidebarCategoriesSection)).dy;
        final double collapsedActionsTop = tester.getTopLeft(find.byType(SidebarQuickActionsSection)).dy;

        final Map<String, double> collapsedSpacing = {
          'search-to-nav': collapsedNavTop - collapsedSearchBottom,
          'nav-to-categories': collapsedCategoriesTop - collapsedNavBottom,
          'categories-to-actions': collapsedActionsTop - collapsedCategoriesBottom,
        };

        // Verify that spacing is consistent
        for (final String spacingKey in expandedSpacing.keys) {
          final double expandedSpace = expandedSpacing[spacingKey]!;
          final double collapsedSpace = collapsedSpacing[spacingKey]!;

          expect(
            expandedSpace,
            equals(collapsedSpace),
            reason:
                'Spacing $spacingKey should be consistent between states. '
                'Expanded: $expandedSpace, Collapsed: $collapsedSpace',
          );
        }

        // Verify spacing matches expected values
        expect(expandedSpacing['search-to-nav'], equals(SidebarSpacing.sectionSpacing));
        expect(expandedSpacing['nav-to-categories'], equals(SidebarSpacing.sectionSpacing));
        expect(expandedSpacing['categories-to-actions'], equals(SidebarSpacing.sectionSpacing));
      });
    });

    group('Visual consistency verification', () {
      /// Verifies that sidebar width transitions are smooth and correct.
      ///
      /// Should ensure the sidebar animates between the correct widths
      /// (280px expanded, 76px collapsed) without visual artifacts.
      testWidgets('should have correct width transitions', (WidgetTester tester) async {
        // Test expanded width
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        final double expandedWidth = tester.getSize(find.byType(DashboardSidebar)).width;
        expect(expandedWidth, equals(280.0));

        // Test collapsed width
        await tester.pumpWidget(createTestApp(isExpanded: false));
        await tester.pumpAndSettle();

        final double collapsedWidth = tester.getSize(find.byType(DashboardSidebar)).width;
        expect(collapsedWidth, equals(76.0));

        // Test animation frames during transition
        await tester.pumpWidget(createTestApp(isExpanded: true));

        // Check intermediate widths during animation
        await tester.pump(const Duration(milliseconds: 50));
        final double width50ms = tester.getSize(find.byType(DashboardSidebar)).width;

        await tester.pump(const Duration(milliseconds: 100));
        final double width150ms = tester.getSize(find.byType(DashboardSidebar)).width;

        await tester.pump(const Duration(milliseconds: 100));
        final double width250ms = tester.getSize(find.byType(DashboardSidebar)).width;

        // Width should be increasing during expansion
        expect(width50ms, greaterThan(collapsedWidth));
        expect(width150ms, greaterThan(width50ms));
        expect(width250ms, greaterThanOrEqualTo(width150ms));
      });

      /// Verifies that content alignment remains consistent.
      ///
      /// Should ensure that content within sections maintains proper
      /// alignment and doesn't shift unexpectedly during transitions.
      testWidgets('should maintain consistent content alignment', (WidgetTester tester) async {
        // Test expanded content alignment
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        // Search field should be left-aligned within its container
        final Offset searchFieldPos = tester.getTopLeft(find.byType(TextField));
        final Offset searchSectionPos = tester.getTopLeft(find.byType(SidebarSearchSection));
        final double searchFieldLeftMargin = searchFieldPos.dx - searchSectionPos.dx;

        // Test collapsed content alignment
        await tester.pumpWidget(createTestApp(isExpanded: false));
        await tester.pumpAndSettle();

        // Search icon should be centered within its container
        final Offset searchIconPos = tester.getCenter(find.byIcon(Icons.search));
        final Offset collapsedSearchSectionPos = tester.getTopLeft(find.byType(SidebarSearchSection));
        final Size collapsedSearchSectionSize = tester.getSize(find.byType(SidebarSearchSection));
        final double expectedCenterX = collapsedSearchSectionPos.dx + (collapsedSearchSectionSize.width / 2);

        // Icon should be approximately centered (allowing for small variations)
        expect((searchIconPos.dx - expectedCenterX).abs(), lessThan(5.0));

        // Verify consistent margins for expanded content
        expect(searchFieldLeftMargin, greaterThan(0)); // Should have some left margin
        expect(searchFieldLeftMargin, lessThan(20)); // But not excessive
      });

      /// Verifies that visual hierarchy is maintained across states.
      ///
      /// Should ensure that the relative visual importance and organization
      /// of elements remains consistent between expanded and collapsed states.
      testWidgets('should maintain visual hierarchy across states', (WidgetTester tester) async {
        // Test expanded state hierarchy
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        // Verify section order (top to bottom)
        final List<double> expandedYPositions = [
          tester.getTopLeft(find.byType(SidebarSearchSection)).dy,
          tester.getTopLeft(find.byType(SidebarNavigationSection)).dy,
          tester.getTopLeft(find.byType(SidebarCategoriesSection)).dy,
          tester.getTopLeft(find.byType(SidebarQuickActionsSection)).dy,
        ];

        // Test collapsed state hierarchy
        await tester.pumpWidget(createTestApp(isExpanded: false));
        await tester.pumpAndSettle();

        final List<double> collapsedYPositions = [
          tester.getTopLeft(find.byType(SidebarSearchSection)).dy,
          tester.getTopLeft(find.byType(SidebarNavigationSection)).dy,
          tester.getTopLeft(find.byType(SidebarCategoriesSection)).dy,
          tester.getTopLeft(find.byType(SidebarQuickActionsSection)).dy,
        ];

        // Verify that order is maintained
        for (int i = 0; i < expandedYPositions.length - 1; i++) {
          expect(
            expandedYPositions[i],
            lessThan(expandedYPositions[i + 1]),
            reason: 'Section order should be maintained in expanded state',
          );

          expect(
            collapsedYPositions[i],
            lessThan(collapsedYPositions[i + 1]),
            reason: 'Section order should be maintained in collapsed state',
          );

          expect(
            expandedYPositions[i],
            equals(collapsedYPositions[i]),
            reason: 'Section positions should be identical between states',
          );
        }
      });
    });

    group('Animation smoothness verification', () {
      /// Verifies that animations complete without visual artifacts.
      ///
      /// Should ensure that state transitions are smooth and don't produce
      /// flickering, jumping, or other visual artifacts.
      testWidgets('should have smooth animations without artifacts', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        // Trigger rapid state changes to test for artifacts
        for (int i = 0; i < 10; i++) {
          await tester.pumpWidget(createTestApp(isExpanded: i.isEven));
          await tester.pump(const Duration(milliseconds: 25)); // Quarter of animation
        }

        await tester.pumpAndSettle();

        // Should complete without exceptions
        expect(tester.takeException(), isNull);

        // Sidebar should still be functional
        expect(find.byType(DashboardSidebar), findsOneWidget);
        expect(find.byType(SidebarSearchSection), findsOneWidget);
        expect(find.byType(SidebarNavigationSection), findsOneWidget);
        expect(find.byType(SidebarCategoriesSection), findsOneWidget);
        expect(find.byType(SidebarQuickActionsSection), findsOneWidget);
      });

      /// Verifies that animation timing is consistent.
      ///
      /// Should ensure that all animated elements use the same 250ms
      /// duration for consistent visual timing.
      testWidgets('should have consistent animation timing', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        final Stopwatch stopwatch = Stopwatch()..start();

        // Trigger state change
        await tester.pumpWidget(createTestApp(isExpanded: false));

        // Pump until animation completes
        while (tester.binding.hasScheduledFrame) {
          await tester.pump(const Duration(milliseconds: 16)); // ~60fps
        }

        stopwatch.stop();

        // Animation should complete within expected timeframe
        // 250ms animation + reasonable buffer for processing
        expect(stopwatch.elapsedMilliseconds, lessThan(400));
        expect(stopwatch.elapsedMilliseconds, greaterThan(200)); // Should take some time
      });

      /// Verifies that content transitions are synchronized.
      ///
      /// Should ensure that all content changes (text to icons, etc.)
      /// happen in sync with the width animation for cohesive transitions.
      testWidgets('should have synchronized content transitions', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        // Start transition to collapsed state
        await tester.pumpWidget(createTestApp(isExpanded: false));

        // Check state at various points during animation
        await tester.pump(const Duration(milliseconds: 50));

        // At this point, some content might be transitioning
        // but the overall structure should remain stable
        expect(find.byType(SidebarSearchSection), findsOneWidget);
        expect(find.byType(SidebarNavigationSection), findsOneWidget);
        expect(find.byType(SidebarCategoriesSection), findsOneWidget);
        expect(find.byType(SidebarQuickActionsSection), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 100));

        // Mid-animation - structure should still be stable
        expect(find.byType(SidebarSearchSection), findsOneWidget);
        expect(find.byType(SidebarNavigationSection), findsOneWidget);
        expect(find.byType(SidebarCategoriesSection), findsOneWidget);
        expect(find.byType(SidebarQuickActionsSection), findsOneWidget);

        await tester.pumpAndSettle();

        // Final state should be correct
        expect(find.byType(TextField), findsNothing);
        expect(find.byIcon(Icons.search), findsOneWidget);
      });
    });

    group('Cross-platform visual consistency', () {
      /// Verifies that layout is consistent across different pixel densities.
      ///
      /// Should ensure that the sidebar looks and behaves consistently
      /// across devices with different screen densities.
      testWidgets('should maintain layout across different pixel densities', (WidgetTester tester) async {
        final List<double> pixelRatios = [1.0, 1.5, 2.0, 3.0];

        Map<double, Map<Type, Offset>>? baselinePositions;

        for (final double pixelRatio in pixelRatios) {
          await tester.binding.setSurfaceSize(Size(800 * pixelRatio, 600 * pixelRatio));
          tester.view.devicePixelRatio = pixelRatio;

          await tester.pumpWidget(createTestApp(isExpanded: true));
          await tester.pumpAndSettle();

          final Map<Type, Offset> positions = {
            SidebarSearchSection: tester.getTopLeft(find.byType(SidebarSearchSection)),
            SidebarNavigationSection: tester.getTopLeft(find.byType(SidebarNavigationSection)),
            SidebarCategoriesSection: tester.getTopLeft(find.byType(SidebarCategoriesSection)),
            SidebarQuickActionsSection: tester.getTopLeft(find.byType(SidebarQuickActionsSection)),
          };

          if (baselinePositions == null) {
            baselinePositions = positions;
          } else {
            // Positions should be proportionally consistent
            for (final Type componentType in positions.keys) {
              final Offset currentPos = positions[componentType]!;
              final Offset baselinePos = baselinePositions[componentType]!;

              // Allow for small variations due to pixel density differences
              expect(
                (currentPos.dy - baselinePos.dy).abs(),
                lessThan(2.0),
                reason: '$componentType position should be consistent across pixel densities',
              );
            }
          }
        }

        // Reset to default
        await tester.binding.setSurfaceSize(null);
        tester.view.devicePixelRatio = 1.0;
      });

      /// Verifies that animations work correctly on different platforms.
      ///
      /// Should ensure that animation performance and behavior is consistent
      /// across different platform implementations.
      testWidgets('should have consistent animations across platforms', (WidgetTester tester) async {
        // Test animation behavior
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        // Measure animation performance
        final List<Duration> frameTimes = [];
        final Stopwatch frameStopwatch = Stopwatch();

        await tester.pumpWidget(createTestApp(isExpanded: false));

        while (tester.binding.hasScheduledFrame) {
          frameStopwatch.reset();
          frameStopwatch.start();
          await tester.pump(const Duration(milliseconds: 16));
          frameStopwatch.stop();
          frameTimes.add(frameStopwatch.elapsed);
        }

        // Should have reasonable frame times (not too slow)
        final double averageFrameTime =
            frameTimes.map((Duration d) => d.inMicroseconds).reduce((int a, int b) => a + b) / frameTimes.length;

        expect(averageFrameTime, lessThan(20000)); // Less than 20ms per frame
        expect(frameTimes.length, greaterThan(5)); // Should have multiple frames
      });
    });
  });
}
