import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/l10n/app_localizations.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar/categories/sidebar_categories.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar/categories/sidebar_categories_section.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar/search/sidebar_search.dart';

/// Tests for sidebar animation behavior and performance.
///
/// Verifies that sidebar components transition smoothly between states
/// with proper animation timing and without visual artifacts.
void main() {
  group('Sidebar Animations', () {
    /// Helper function to create a test widget with localization support.
    Widget createTestApp({required Widget child}) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(body: child),
      );
    }

    group('SidebarSearchSection animations', () {
      /// Verifies that search section uses AnimatedSwitcher for transitions.
      ///
      /// Should include AnimatedSwitcher widget to provide smooth transitions
      /// between expanded and collapsed states.
      testWidgets('should use AnimatedSwitcher for smooth transitions', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          createTestApp(
            child: const SidebarSearchSection(showExpandedContent: true),
          ),
        );

        expect(find.byType(AnimatedSwitcher), findsOneWidget);
      });

      /// Verifies that search section animation has correct duration.
      ///
      /// Should use 250ms duration to match the sidebar expansion animation
      /// for consistent timing across all transitions.
      testWidgets('should have correct animation duration', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          createTestApp(
            child: const SidebarSearchSection(showExpandedContent: true),
          ),
        );

        final AnimatedSwitcher switcher = tester.widget<AnimatedSwitcher>(
          find.byType(AnimatedSwitcher),
        );
        expect(switcher.duration, const Duration(milliseconds: 250));
      });

      /// Verifies that search section transitions smoothly between states.
      ///
      /// Should animate between expanded and collapsed states without
      /// jarring jumps or visual artifacts.
      testWidgets('should transition smoothly between states', (
        WidgetTester tester,
      ) async {
        Widget buildSearchSection({required bool expanded}) {
          return createTestApp(
            child: SidebarSearchSection(showExpandedContent: expanded),
          );
        }

        // Start with expanded state
        await tester.pumpWidget(buildSearchSection(expanded: true));
        expect(find.byType(TextField), findsOneWidget);

        // Change to collapsed state and pump animation
        await tester.pumpWidget(buildSearchSection(expanded: false));
        await tester.pump(const Duration(milliseconds: 125)); // Mid-animation
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsNothing);
        expect(find.byType(IconButton), findsOneWidget);
      });

      /// Verifies that search section handles rapid state changes gracefully.
      ///
      /// Should handle multiple quick state changes without errors
      /// or animation conflicts.
      testWidgets('should handle rapid state changes gracefully', (
        WidgetTester tester,
      ) async {
        Widget buildSearchSection({required bool expanded}) {
          return createTestApp(
            child: SidebarSearchSection(showExpandedContent: expanded),
          );
        }

        // Rapid state changes
        await tester.pumpWidget(buildSearchSection(expanded: true));
        await tester.pumpWidget(buildSearchSection(expanded: false));
        await tester.pumpWidget(buildSearchSection(expanded: true));
        await tester.pumpWidget(buildSearchSection(expanded: false));
        await tester.pumpAndSettle();

        // Should end up in collapsed state without errors
        expect(find.byType(IconButton), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
      });
    });

    group('SidebarCategoryItem animations', () {
      /// Test data for category item testing.
      const IconData testIcon = Icons.home;
      const String testLabel = 'Test Category';
      const int testCount = 5;

      /// Verifies that category item uses AnimatedSwitcher for transitions.
      ///
      /// Should include AnimatedSwitcher widget to provide smooth transitions
      /// between expanded and collapsed presentations.
      testWidgets('should use AnimatedSwitcher for smooth transitions', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          createTestApp(
            child: const SidebarCategoryItem(
              icon: testIcon,
              label: testLabel,
              count: testCount,
              showExpandedContent: true,
            ),
          ),
        );

        expect(find.byType(AnimatedSwitcher), findsOneWidget);
      });

      /// Verifies that category item animation has correct duration.
      ///
      /// Should use 250ms duration to match other sidebar animations
      /// for consistent timing.
      testWidgets('should have correct animation duration', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          createTestApp(
            child: const SidebarCategoryItem(
              icon: testIcon,
              label: testLabel,
              count: testCount,
              showExpandedContent: true,
            ),
          ),
        );

        final AnimatedSwitcher switcher = tester.widget<AnimatedSwitcher>(
          find.byType(AnimatedSwitcher),
        );
        expect(switcher.duration, const Duration(milliseconds: 250));
      });

      /// Verifies that category item transitions smoothly between states.
      ///
      /// Should animate between expanded (icon + label + count) and
      /// collapsed (icon only) states smoothly.
      testWidgets('should transition smoothly between states', (
        WidgetTester tester,
      ) async {
        Widget buildCategoryItem({required bool expanded}) {
          return createTestApp(
            child: SidebarCategoryItem(
              icon: testIcon,
              label: testLabel,
              count: testCount,
              showExpandedContent: expanded,
            ),
          );
        }

        // Start with expanded state
        await tester.pumpWidget(buildCategoryItem(expanded: true));
        expect(find.text(testLabel), findsOneWidget);
        expect(find.text(testCount.toString()), findsOneWidget);

        // Change to collapsed state and pump animation
        await tester.pumpWidget(buildCategoryItem(expanded: false));
        await tester.pump(const Duration(milliseconds: 125)); // Mid-animation
        await tester.pumpAndSettle();

        expect(find.text(testLabel), findsNothing);
        expect(find.text(testCount.toString()), findsNothing);
        expect(find.byType(Tooltip), findsOneWidget);
      });

      /// Verifies that category item maintains consistent height during animation.
      ///
      /// Should keep the same height throughout the transition to prevent
      /// layout shifts in the sidebar.
      testWidgets('should maintain consistent height during animation', (
        WidgetTester tester,
      ) async {
        Widget buildCategoryItem({required bool expanded}) {
          return createTestApp(
            child: SidebarCategoryItem(
              icon: testIcon,
              label: testLabel,
              count: testCount,
              showExpandedContent: expanded,
            ),
          );
        }

        // Start with expanded state
        await tester.pumpWidget(buildCategoryItem(expanded: true));
        final RenderBox expandedBox = tester.renderObject(
          find.byType(SidebarCategoryItem),
        );
        final double expandedHeight = expandedBox.size.height;

        // Change to collapsed state
        await tester.pumpWidget(buildCategoryItem(expanded: false));
        await tester.pumpAndSettle();
        final RenderBox collapsedBox = tester.renderObject(
          find.byType(SidebarCategoryItem),
        );
        final double collapsedHeight = collapsedBox.size.height;

        expect(expandedHeight, equals(collapsedHeight));
      });
    });

    group('SidebarCategoriesSection animations', () {
      /// Verifies that categories section header uses AnimatedSwitcher.
      ///
      /// Should include AnimatedSwitcher for smooth transitions between
      /// header text and empty spacing.
      testWidgets('should use AnimatedSwitcher for header transitions', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          createTestApp(
            child: const SidebarCategoriesSection(showExpandedContent: true),
          ),
        );

        expect(find.byType(AnimatedSwitcher), findsWidgets);
      });

      /// Verifies that categories section transitions smoothly.
      ///
      /// Should animate the header appearance/disappearance while
      /// maintaining consistent spacing.
      testWidgets('should transition header smoothly between states', (
        WidgetTester tester,
      ) async {
        Widget buildCategoriesSection({required bool expanded}) {
          return createTestApp(
            child: SidebarCategoriesSection(showExpandedContent: expanded),
          );
        }

        // Start with expanded state
        await tester.pumpWidget(buildCategoriesSection(expanded: true));
        expect(find.text('Categories'), findsOneWidget);

        // Change to collapsed state and pump animation
        await tester.pumpWidget(buildCategoriesSection(expanded: false));
        await tester.pump(const Duration(milliseconds: 125)); // Mid-animation
        await tester.pumpAndSettle();

        expect(find.text('Categories'), findsNothing);
      });

      /// Verifies that categories section maintains layout during animation.
      ///
      /// Should keep the same overall structure and spacing even when
      /// individual category items are animating.
      testWidgets('should maintain layout during category item animations', (
        WidgetTester tester,
      ) async {
        Widget buildCategoriesSection({required bool expanded}) {
          return createTestApp(
            child: SidebarCategoriesSection(showExpandedContent: expanded),
          );
        }

        // Start with expanded state
        await tester.pumpWidget(buildCategoriesSection(expanded: true));
        final RenderBox expandedBox = tester.renderObject(
          find.byType(SidebarCategoriesSection),
        );
        final double expandedHeight = expandedBox.size.height;

        // Change to collapsed state
        await tester.pumpWidget(buildCategoriesSection(expanded: false));
        await tester.pumpAndSettle();
        final RenderBox collapsedBox = tester.renderObject(
          find.byType(SidebarCategoriesSection),
        );
        final double collapsedHeight = collapsedBox.size.height;

        // Height should remain consistent (or very close due to text vs spacing)
        expect((expandedHeight - collapsedHeight).abs(), lessThan(10.0));
      });
    });

    group('Animation performance', () {
      /// Verifies that animations use FadeTransition for smooth visual effects.
      ///
      /// Should use fade transitions rather than slide or scale transitions
      /// for better performance and visual appeal.
      testWidgets('should use FadeTransition for smooth visual effects', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          createTestApp(
            child: const SidebarSearchSection(showExpandedContent: true),
          ),
        );

        final AnimatedSwitcher switcher = tester.widget<AnimatedSwitcher>(
          find.byType(AnimatedSwitcher),
        );

        // Test the transition builder
        final Widget testChild = Container();
        const Animation<double> testAnimation = AlwaysStoppedAnimation<double>(
          1.0,
        );
        final Widget result = switcher.transitionBuilder(
          testChild,
          testAnimation,
        );

        expect(result, isA<FadeTransition>());
      });

      /// Verifies that animations complete within expected timeframe.
      ///
      /// Should complete all animations within the specified 250ms duration
      /// plus a small buffer for processing time.
      testWidgets('should complete animations within expected timeframe', (
        WidgetTester tester,
      ) async {
        Widget buildSearchSection({required bool expanded}) {
          return createTestApp(
            child: SidebarSearchSection(showExpandedContent: expanded),
          );
        }

        await tester.pumpWidget(buildSearchSection(expanded: true));

        final Stopwatch stopwatch = Stopwatch()..start();

        // Trigger state change
        await tester.pumpWidget(buildSearchSection(expanded: false));
        await tester.pumpAndSettle();

        stopwatch.stop();

        // Should complete within 250ms + reasonable buffer
        expect(stopwatch.elapsedMilliseconds, lessThan(400));
      });

      /// Verifies that multiple simultaneous animations don't cause performance issues.
      ///
      /// Should handle multiple components animating at the same time
      /// without significant performance degradation.
      testWidgets('should handle multiple simultaneous animations', (
        WidgetTester tester,
      ) async {
        Widget buildMultipleComponents({required bool expanded}) {
          return createTestApp(
            child: Column(
              children: [
                SidebarSearchSection(showExpandedContent: expanded),
                SidebarCategoriesSection(showExpandedContent: expanded),
                const SidebarCategoryItem(
                  icon: Icons.home,
                  label: 'Test',
                  count: 1,
                  showExpandedContent: true,
                ),
              ],
            ),
          );
        }

        await tester.pumpWidget(buildMultipleComponents(expanded: true));

        // Trigger multiple animations simultaneously
        await tester.pumpWidget(buildMultipleComponents(expanded: false));
        await tester.pumpAndSettle();

        // Should complete without errors
        expect(find.byType(SidebarSearchSection), findsOneWidget);
        expect(find.byType(SidebarCategoriesSection), findsOneWidget);
        expect(find.byType(SidebarCategoryItem), findsOneWidget);
      });
    });
  });
}
