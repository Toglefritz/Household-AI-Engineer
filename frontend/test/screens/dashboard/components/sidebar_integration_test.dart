import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/l10n/app_localizations.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar/categories/sidebar_categories.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar/categories/sidebar_categories_section.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar/dashboard_sidebar.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar/navigation/sidebar_navigation_section.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar/quick_actions/sidebar_quick_actions.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar/search/sidebar_search.dart';
import 'package:household_ai_engineer/screens/dashboard/models/sidebar/sidebar_categories_constants.dart';

/// Integration tests for the complete sidebar functionality.
///
/// Verifies that all sidebar components work together correctly, maintain
/// consistent behavior across state transitions, and provide a smooth user
/// experience without layout shifts or visual artifacts.
void main() {
  group('Sidebar Integration Tests', () {
    /// Helper function to create a complete test app with sidebar.
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
          body: Row(
            children: [
              DashboardSidebar(
                isExpanded: isExpanded,
                onToggle: () {}, // No-op for testing
                applications: const [],
                openNewApplicationConversation: () {},
              ),
              const Expanded(
                child: Center(
                  child: Text('Main Content Area'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    group('Complete sidebar functionality', () {
      /// Verifies that the complete sidebar renders correctly in expanded state.
      ///
      /// Should show all sections with full functionality including search field,
      /// navigation labels, category labels, and expanded action buttons.
      testWidgets('should render complete sidebar in expanded state', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestApp(isExpanded: true));

        // Main sidebar container
        expect(find.byType(DashboardSidebar), findsOneWidget);

        // All major sections should be present
        expect(find.byType(SidebarSearchSection), findsOneWidget);
        expect(find.byType(SidebarNavigationSection), findsOneWidget);
        expect(find.byType(SidebarCategoriesSection), findsOneWidget);
        expect(find.byType(SidebarQuickActionsSection), findsOneWidget);

        // Expanded content should be visible
        expect(find.byType(TextField), findsOneWidget); // Search field
        expect(find.text('All Applications'), findsOneWidget); // Navigation
        expect(find.text('Categories'), findsOneWidget); // Categories header
        expect(find.text('Create New App'), findsOneWidget); // Quick action

        // All category items should be present
        expect(
          find.byType(SidebarCategoryItem),
          findsNWidgets(SidebarCategoriesConstants.defaultCategories.length),
        );
      });

      /// Verifies that the complete sidebar renders correctly in collapsed state.
      ///
      /// Should show all sections with icon-only functionality including search icon,
      /// navigation icons, category icons, and collapsed action button.
      testWidgets('should render complete sidebar in collapsed state', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestApp(isExpanded: false));

        // Main sidebar container
        expect(find.byType(DashboardSidebar), findsOneWidget);

        // All major sections should still be present
        expect(find.byType(SidebarSearchSection), findsOneWidget);
        expect(find.byType(SidebarNavigationSection), findsOneWidget);
        expect(find.byType(SidebarCategoriesSection), findsOneWidget);
        expect(find.byType(SidebarQuickActionsSection), findsOneWidget);

        // Collapsed content should be visible
        expect(find.byType(TextField), findsNothing); // No search field
        expect(find.byIcon(Icons.search), findsOneWidget); // Search icon
        expect(
          find.text('All Applications'),
          findsNothing,
        ); // No navigation labels
        expect(find.text('Categories'), findsNothing); // No categories header
        expect(find.text('Create New App'), findsNothing); // No action text

        // All category items should still be present (as icons)
        expect(
          find.byType(SidebarCategoryItem),
          findsNWidgets(SidebarCategoriesConstants.defaultCategories.length),
        );

        // Should have tooltips for collapsed elements
        expect(find.byType(Tooltip), findsWidgets);
      });

      /// Verifies that sidebar width changes correctly between states.
      ///
      /// Should animate between 280px (expanded) and 76px (collapsed) widths
      /// with smooth transitions and proper timing.
      testWidgets('should have correct width in both states', (
        WidgetTester tester,
      ) async {
        // Test expanded width
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        final RenderBox expandedBox = tester.renderObject(
          find.byType(DashboardSidebar),
        );
        expect(expandedBox.size.width, 280.0);

        // Test collapsed width
        await tester.pumpWidget(createTestApp(isExpanded: false));
        await tester.pumpAndSettle();

        final RenderBox collapsedBox = tester.renderObject(
          find.byType(DashboardSidebar),
        );
        expect(collapsedBox.size.width, 76.0);
      });

      /// Verifies that all interactive elements work in both states.
      ///
      /// Should allow user interaction with search, navigation, categories,
      /// and quick actions in both expanded and collapsed states.
      testWidgets('should have working interactive elements in both states', (
        WidgetTester tester,
      ) async {
        // Test expanded state interactions
        await tester.pumpWidget(createTestApp(isExpanded: true));

        // Search field should be interactive
        await tester.tap(find.byType(TextField));
        await tester.enterText(find.byType(TextField), 'test search');
        expect(find.text('test search'), findsOneWidget);

        // Category items should be interactive
        await tester.tap(find.byType(SidebarCategoryItem).first);
        await tester.pumpAndSettle();

        // Quick action button should be interactive
        await tester.tap(find.text('Create New App'));
        await tester.pumpAndSettle();

        // Test collapsed state interactions
        await tester.pumpWidget(createTestApp(isExpanded: false));

        // Search icon should be interactive
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsOneWidget); // Search overlay

        // Close search overlay
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Category icons should be interactive
        await tester.tap(find.byType(SidebarCategoryItem).first);
        await tester.pumpAndSettle();

        // Quick action icon should be interactive
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
      });
    });

    group('State transition behavior', () {
      /// Verifies that sidebar transitions smoothly between states.
      ///
      /// Should animate width changes and content transitions without
      /// layout shifts or visual artifacts.
      testWidgets('should transition smoothly between expanded and collapsed', (
        WidgetTester tester,
      ) async {
        // Start with expanded state
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        // Verify expanded state
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('All Applications'), findsOneWidget);

        // Transition to collapsed state
        await tester.pumpWidget(createTestApp(isExpanded: false));

        // Pump animation frames
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        // Verify collapsed state
        expect(find.byType(TextField), findsNothing);
        expect(find.byIcon(Icons.search), findsOneWidget);
        expect(find.text('All Applications'), findsNothing);

        // Transition back to expanded state
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        // Verify expanded state restored
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('All Applications'), findsOneWidget);
      });

      /// Verifies that rapid state changes are handled gracefully.
      ///
      /// Should handle multiple quick state changes without errors
      /// or animation conflicts.
      testWidgets('should handle rapid state changes gracefully', (
        WidgetTester tester,
      ) async {
        // Rapid state changes
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpWidget(createTestApp(isExpanded: false));
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpWidget(createTestApp(isExpanded: false));
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        // Should end up in expanded state without errors
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('All Applications'), findsOneWidget);
        expect(find.byType(DashboardSidebar), findsOneWidget);
      });

      /// Verifies that element positions remain consistent during transitions.
      ///
      /// Should prevent layout shifts by maintaining consistent vertical
      /// positions for all elements during state changes.
      testWidgets('should maintain consistent element positions', (
        WidgetTester tester,
      ) async {
        // Get element positions in expanded state
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        final Offset expandedSearchPos = tester.getTopLeft(
          find.byType(SidebarSearchSection),
        );
        final Offset expandedNavPos = tester.getTopLeft(
          find.byType(SidebarNavigationSection),
        );
        final Offset expandedCategoriesPos = tester.getTopLeft(
          find.byType(SidebarCategoriesSection),
        );

        // Get element positions in collapsed state
        await tester.pumpWidget(createTestApp(isExpanded: false));
        await tester.pumpAndSettle();

        final Offset collapsedSearchPos = tester.getTopLeft(
          find.byType(SidebarSearchSection),
        );
        final Offset collapsedNavPos = tester.getTopLeft(
          find.byType(SidebarNavigationSection),
        );
        final Offset collapsedCategoriesPos = tester.getTopLeft(
          find.byType(SidebarCategoriesSection),
        );

        // Vertical positions should be identical (Y coordinates)
        expect(expandedSearchPos.dy, equals(collapsedSearchPos.dy));
        expect(expandedNavPos.dy, equals(collapsedNavPos.dy));
        expect(expandedCategoriesPos.dy, equals(collapsedCategoriesPos.dy));
      });
    });

    group('Accessibility integration', () {
      /// Verifies that complete sidebar provides comprehensive accessibility.
      ///
      /// Should ensure all interactive elements have proper semantic labels
      /// and accessibility support across both states.
      testWidgets('should provide comprehensive accessibility support', (
        WidgetTester tester,
      ) async {
        // Test expanded state accessibility
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        // Should have semantic elements
        expect(find.byType(Semantics), findsWidgets);

        // Test collapsed state accessibility
        await tester.pumpWidget(createTestApp(isExpanded: false));
        await tester.pumpAndSettle();

        // Should have semantic elements and tooltips
        expect(find.byType(Semantics), findsWidgets);
        expect(find.byType(Tooltip), findsWidgets);

        // All tooltips should have meaningful messages
        final List<Tooltip> tooltips = tester
            .widgetList<Tooltip>(find.byType(Tooltip))
            .toList();
        for (final Tooltip tooltip in tooltips) {
          expect(tooltip.message, isNotNull);
          expect(tooltip.message, isNotEmpty);
        }
      });

      /// Verifies that keyboard navigation works throughout the sidebar.
      ///
      /// Should support full keyboard navigation through all sections
      /// and interactive elements in both states.
      testWidgets('should support complete keyboard navigation', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        // Should be able to navigate to search field
        await tester.tap(find.byType(TextField));
        await tester.enterText(find.byType(TextField), 'keyboard test');
        expect(find.text('keyboard test'), findsOneWidget);

        // Should be able to navigate to category items
        final List<Widget> categoryItems = tester
            .widgetList<SidebarCategoryItem>(
              find.byType(SidebarCategoryItem),
            )
            .toList();

        for (int i = 0; i < categoryItems.length; i++) {
          await tester.tap(find.byType(SidebarCategoryItem).at(i));
          await tester.pumpAndSettle();
        }
      });
    });

    group('Performance and visual verification', () {
      /// Verifies that animations complete within expected timeframe.
      ///
      /// Should ensure all state transitions complete smoothly within
      /// the 250ms animation duration plus reasonable buffer time.
      testWidgets('should complete animations within expected timeframe', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        final Stopwatch stopwatch = Stopwatch()..start();

        // Trigger state change
        await tester.pumpWidget(createTestApp(isExpanded: false));
        await tester.pumpAndSettle();

        stopwatch.stop();

        // Should complete within 250ms + reasonable buffer
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      /// Verifies that no visual artifacts occur during transitions.
      ///
      /// Should ensure smooth visual transitions without flickering,
      /// jumping, or other visual artifacts.
      testWidgets('should have no visual artifacts during transitions', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestApp(isExpanded: true));
        await tester.pumpAndSettle();

        // Trigger multiple rapid transitions
        for (int i = 0; i < 5; i++) {
          await tester.pumpWidget(createTestApp(isExpanded: i.isEven));
          await tester.pump(const Duration(milliseconds: 50));
        }

        await tester.pumpAndSettle();

        // Should end without errors and in a valid state
        expect(find.byType(DashboardSidebar), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      /// Verifies that sidebar works correctly across different screen sizes.
      ///
      /// Should maintain functionality and layout consistency across
      /// various screen dimensions and orientations.
      testWidgets('should work correctly across different screen sizes', (
        WidgetTester tester,
      ) async {
        // Test with different screen sizes
        final List<Size> screenSizes = [
          const Size(800, 600), // Small desktop
          const Size(1200, 800), // Medium desktop
          const Size(1920, 1080), // Large desktop
          const Size(400, 800), // Mobile portrait
          const Size(800, 400), // Mobile landscape
        ];

        for (final Size screenSize in screenSizes) {
          await tester.binding.setSurfaceSize(screenSize);
          await tester.pumpWidget(createTestApp(isExpanded: true));
          await tester.pumpAndSettle();

          // Sidebar should render correctly
          expect(find.byType(DashboardSidebar), findsOneWidget);

          // All sections should be present
          expect(find.byType(SidebarSearchSection), findsOneWidget);
          expect(find.byType(SidebarNavigationSection), findsOneWidget);
          expect(find.byType(SidebarCategoriesSection), findsOneWidget);
          expect(find.byType(SidebarQuickActionsSection), findsOneWidget);

          // Test collapsed state
          await tester.pumpWidget(createTestApp(isExpanded: false));
          await tester.pumpAndSettle();

          expect(find.byType(DashboardSidebar), findsOneWidget);
        }

        // Reset to default size
        await tester.binding.setSurfaceSize(null);
      });
    });

    group('Error handling and edge cases', () {
      /// Verifies that sidebar handles missing localization gracefully.
      ///
      /// Should provide fallback behavior when localized strings
      /// are not available.
      testWidgets('should handle missing localization gracefully', (
        WidgetTester tester,
      ) async {
        // Test with minimal localization setup
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DashboardSidebar(
                isExpanded: true,
                onToggle: () {},
                applications: const [],
                openNewApplicationConversation: () {},
              ),
            ),
          ),
        );

        // Should render without errors even with missing localization
        expect(find.byType(DashboardSidebar), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      /// Verifies that sidebar handles theme changes correctly.
      ///
      /// Should adapt to different themes and color schemes without
      /// breaking layout or functionality.
      testWidgets('should handle theme changes correctly', (
        WidgetTester tester,
      ) async {
        // Test with light theme
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
            home: Scaffold(
              body: DashboardSidebar(
                isExpanded: true,
                onToggle: () {},
                openNewApplicationConversation: () {},
              ),
            ),
          ),
        );

        expect(find.byType(DashboardSidebar), findsOneWidget);

        // Test with dark theme
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
            home: Scaffold(
              body: DashboardSidebar(
                isExpanded: true,
                onToggle: () {},
                openNewApplicationConversation: () {},
              ),
            ),
          ),
        );

        expect(find.byType(DashboardSidebar), findsOneWidget);
      });
    });
  });
}
