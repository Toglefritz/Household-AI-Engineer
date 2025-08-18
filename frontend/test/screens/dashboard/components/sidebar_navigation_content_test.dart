import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/l10n/app_localizations.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar/categories/sidebar_categories_section.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar/navigation/sidebar_navigation_content.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar/navigation/sidebar_navigation_section.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar/quick_actions/sidebar_quick_actions.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar/search/sidebar_search.dart';

/// Widget tests for the SidebarNavigationContent component.
///
/// Verifies that the navigation content renders all sections correctly
/// in both expanded and collapsed states, maintains consistent structure,
/// and handles state transitions properly.
void main() {
  group('SidebarNavigationContent', () {
    /// Helper function to create a test widget with localization support.
    ///
    /// Wraps the navigation content in a MaterialApp with proper localization
    /// delegates to ensure localized strings are available during testing.
    Widget createTestWidget({required bool showExpandedContent}) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: SidebarNavigationContent(
            showExpandedContent: showExpandedContent,
            openNewApplicationConversation: () {},
          ),
        ),
      );
    }

    group('structure and layout', () {
      /// Verifies that the navigation content renders with ListView structure.
      ///
      /// Should use a scrollable ListView to accommodate all sections
      /// and provide proper scrolling behavior when needed.
      testWidgets('should render with ListView structure', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));

        expect(find.byType(SidebarNavigationContent), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);
      });

      /// Verifies that all major sections are present in both states.
      ///
      /// Should always include search, navigation, categories, and quick actions
      /// sections regardless of expansion state to prevent layout shifts.
      testWidgets('should include all major sections in both states', (WidgetTester tester) async {
        // Test expanded state
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));

        expect(find.byType(SidebarSearchSection), findsOneWidget);
        expect(find.byType(SidebarNavigationSection), findsOneWidget);
        expect(find.byType(SidebarCategoriesSection), findsOneWidget);
        expect(find.byType(SidebarQuickActionsSection), findsOneWidget);

        // Test collapsed state
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));

        expect(find.byType(SidebarSearchSection), findsOneWidget);
        expect(find.byType(SidebarNavigationSection), findsOneWidget);
        expect(find.byType(SidebarCategoriesSection), findsOneWidget);
        expect(find.byType(SidebarQuickActionsSection), findsOneWidget);
      });

      /// Verifies that ListView has proper padding configuration.
      ///
      /// Should apply appropriate vertical padding to the ListView
      /// for proper visual spacing and content positioning.
      testWidgets('should have proper ListView padding', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));

        final ListView listView = tester.widget<ListView>(find.byType(ListView));
        expect(listView.padding, isNotNull);
      });
    });

    group('expanded state', () {
      /// Verifies that all sections receive correct expanded state parameter.
      ///
      /// Should pass showExpandedContent=true to all child sections
      /// when the navigation content is in expanded state.
      testWidgets('should pass expanded state to all sections', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));

        final SidebarSearchSection searchSection = tester.widget<SidebarSearchSection>(
          find.byType(SidebarSearchSection),
        );
        expect(searchSection.showExpandedContent, isTrue);

        final SidebarNavigationSection navigationSection = tester.widget<SidebarNavigationSection>(
          find.byType(SidebarNavigationSection),
        );
        expect(navigationSection.showExpandedContent, isTrue);

        final SidebarCategoriesSection categoriesSection = tester.widget<SidebarCategoriesSection>(
          find.byType(SidebarCategoriesSection),
        );
        expect(categoriesSection.showExpandedContent, isTrue);

        final SidebarQuickActionsSection quickActionsSection = tester.widget<SidebarQuickActionsSection>(
          find.byType(SidebarQuickActionsSection),
        );
        expect(quickActionsSection.showExpandedContent, isTrue);
      });

      /// Verifies that expanded content shows full functionality.
      ///
      /// Should display search field, navigation labels, category labels,
      /// and expanded quick action buttons.
      testWidgets('should show full functionality in expanded state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));

        // Search field should be visible
        expect(find.byType(TextField), findsOneWidget);

        // Navigation labels should be visible
        expect(find.text('All Applications'), findsOneWidget);
        expect(find.text('Recent'), findsOneWidget);

        // Category section title should be visible
        expect(find.text('Categories'), findsOneWidget);

        // Quick action button with text should be visible
        expect(find.text('Create New App'), findsOneWidget);
      });
    });

    group('collapsed state', () {
      /// Verifies that all sections receive correct collapsed state parameter.
      ///
      /// Should pass showExpandedContent=false to all child sections
      /// when the navigation content is in collapsed state.
      testWidgets('should pass collapsed state to all sections', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));

        final SidebarSearchSection searchSection = tester.widget<SidebarSearchSection>(
          find.byType(SidebarSearchSection),
        );
        expect(searchSection.showExpandedContent, isFalse);

        final SidebarNavigationSection navigationSection = tester.widget<SidebarNavigationSection>(
          find.byType(SidebarNavigationSection),
        );
        expect(navigationSection.showExpandedContent, isFalse);

        final SidebarCategoriesSection categoriesSection = tester.widget<SidebarCategoriesSection>(
          find.byType(SidebarCategoriesSection),
        );
        expect(categoriesSection.showExpandedContent, isFalse);

        final SidebarQuickActionsSection quickActionsSection = tester.widget<SidebarQuickActionsSection>(
          find.byType(SidebarQuickActionsSection),
        );
        expect(quickActionsSection.showExpandedContent, isFalse);
      });

      /// Verifies that collapsed content shows icon-only functionality.
      ///
      /// Should display search icon, navigation icons, category icons,
      /// and collapsed quick action button.
      testWidgets('should show icon-only functionality in collapsed state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));

        // Search field should not be visible, but search icon should be
        expect(find.byType(TextField), findsNothing);
        expect(find.byIcon(Icons.search), findsOneWidget);

        // Navigation labels should not be visible
        expect(find.text('All Applications'), findsNothing);
        expect(find.text('Recent'), findsNothing);

        // Category section title should not be visible
        expect(find.text('Categories'), findsNothing);

        // Quick action button text should not be visible
        expect(find.text('Create New App'), findsNothing);
      });

      /// Verifies that tooltips are available in collapsed state.
      ///
      /// Should provide tooltips for interactive elements when
      /// text labels are not visible.
      testWidgets('should provide tooltips in collapsed state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));

        // Should have tooltips for various interactive elements
        expect(find.byType(Tooltip), findsWidgets);
      });
    });

    group('state transitions', () {
      /// Verifies that content handles state changes gracefully.
      ///
      /// Should transition between expanded and collapsed states without
      /// errors or visual artifacts.
      testWidgets('should handle state changes gracefully', (WidgetTester tester) async {
        // Start with expanded state
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('All Applications'), findsOneWidget);

        // Change to collapsed state
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));
        expect(find.byType(TextField), findsNothing);
        expect(find.text('All Applications'), findsNothing);

        // Change back to expanded state
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('All Applications'), findsOneWidget);
      });

      /// Verifies that section count remains consistent across states.
      ///
      /// Should maintain the same number of major sections regardless
      /// of expansion state to prevent layout shifts.
      testWidgets('should maintain consistent section count across states', (WidgetTester tester) async {
        // Test expanded state
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));

        int expandedSectionCount = 0;
        expandedSectionCount += tester.widgetList<SidebarSearchSection>(find.byType(SidebarSearchSection)).length;
        expandedSectionCount += tester
            .widgetList<SidebarNavigationSection>(find.byType(SidebarNavigationSection))
            .length;
        expandedSectionCount += tester
            .widgetList<SidebarCategoriesSection>(find.byType(SidebarCategoriesSection))
            .length;
        expandedSectionCount += tester
            .widgetList<SidebarQuickActionsSection>(find.byType(SidebarQuickActionsSection))
            .length;

        // Test collapsed state
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));

        int collapsedSectionCount = 0;
        collapsedSectionCount += tester.widgetList<SidebarSearchSection>(find.byType(SidebarSearchSection)).length;
        collapsedSectionCount += tester
            .widgetList<SidebarNavigationSection>(find.byType(SidebarNavigationSection))
            .length;
        collapsedSectionCount += tester
            .widgetList<SidebarCategoriesSection>(find.byType(SidebarCategoriesSection))
            .length;
        collapsedSectionCount += tester
            .widgetList<SidebarQuickActionsSection>(find.byType(SidebarQuickActionsSection))
            .length;

        expect(expandedSectionCount, equals(collapsedSectionCount));
        expect(expandedSectionCount, equals(4)); // Search, Navigation, Categories, Quick Actions
      });
    });

    group('scrolling behavior', () {
      /// Verifies that ListView is scrollable when content exceeds viewport.
      ///
      /// Should allow users to scroll through all sections when the
      /// content height exceeds the available screen space.
      testWidgets('should be scrollable when content exceeds viewport', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));

        final ListView listView = tester.widget<ListView>(find.byType(ListView));
        expect(listView.physics, isNot(const NeverScrollableScrollPhysics()));
      });

      /// Verifies that all sections are accessible through scrolling.
      ///
      /// Should ensure that users can reach all sections even when
      /// the sidebar content is taller than the viewport.
      testWidgets('should make all sections accessible through scrolling', (WidgetTester tester) async {
        // Create a constrained height to force scrolling
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
            home: Scaffold(
              body: SizedBox(
                height: 300, // Constrained height
                child: SidebarNavigationContent(
                  showExpandedContent: true,
                  openNewApplicationConversation: () {},
                ),
              ),
            ),
          ),
        );

        // All sections should still be findable (even if not visible)
        expect(find.byType(SidebarSearchSection), findsOneWidget);
        expect(find.byType(SidebarNavigationSection), findsOneWidget);
        expect(find.byType(SidebarCategoriesSection), findsOneWidget);
        expect(find.byType(SidebarQuickActionsSection), findsOneWidget);
      });
    });

    group('accessibility', () {
      /// Verifies that the navigation content is accessible to screen readers.
      ///
      /// Should provide proper semantic structure and labels for
      /// assistive technology users.
      testWidgets('should be accessible to screen readers', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));

        // Should have semantic structure for screen readers
        expect(find.byType(ListView), findsOneWidget);

        // Interactive elements should be accessible
        final List<Widget> interactiveElements = [
          ...tester.widgetList<IconButton>(find.byType(IconButton)),
          ...tester.widgetList<ElevatedButton>(find.byType(ElevatedButton)),
          ...tester.widgetList<TextField>(find.byType(TextField)),
        ];

        expect(interactiveElements.length, greaterThan(0));
      });

      /// Verifies that tooltips provide accessibility information.
      ///
      /// Should include tooltips for collapsed state elements to
      /// provide context for screen reader users.
      testWidgets('should provide accessibility through tooltips', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));

        // Should have tooltips for accessibility in collapsed state
        final List<Tooltip> tooltips = tester.widgetList<Tooltip>(find.byType(Tooltip)).toList();
        expect(tooltips.length, greaterThan(0));

        // Tooltips should have meaningful messages
        for (final Tooltip tooltip in tooltips) {
          expect(tooltip.message, isNotNull);
          expect(tooltip.message, isNotEmpty);
        }
      });
    });
  });
}
