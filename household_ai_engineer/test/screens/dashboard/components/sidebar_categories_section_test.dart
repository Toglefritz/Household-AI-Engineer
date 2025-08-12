import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar_categories_section.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar_category_item.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar_categories_constants.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar_spacing.dart';
import 'package:household_ai_engineer/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Widget tests for the SidebarCategoriesSection component.
///
/// Verifies that the categories section renders correctly in both expanded
/// and collapsed states, maintains consistent dimensions, and handles
/// state transitions properly.
void main() {
  group('SidebarCategoriesSection', () {
    /// Helper function to create a test widget with localization support.
    ///
    /// Wraps the categories section in a MaterialApp with proper localization
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
          body: SidebarCategoriesSection(
            showExpandedContent: showExpandedContent,
          ),
        ),
      );
    }

    group('expanded state', () {
      /// Verifies that the categories section renders correctly when expanded.
      ///
      /// Should show the section header with title and all category items
      /// with their full information (icon, label, count).
      testWidgets('should render expanded categories section', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));

        expect(find.byType(SidebarCategoriesSection), findsOneWidget);
        expect(find.text('Categories'), findsOneWidget);

        // Should show all category items
        expect(find.byType(SidebarCategoryItem), findsNWidgets(SidebarCategoriesConstants.defaultCategories.length));
      });

      /// Verifies that the expanded section shows the categories header.
      ///
      /// Should display the "Categories" title with proper styling
      /// and positioning within the fixed header height.
      testWidgets('should show categories header in expanded state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));

        expect(find.text('Categories'), findsOneWidget);

        // Header should be within a SizedBox with fixed height
        final SizedBox headerContainer = tester.widget<SizedBox>(
          find
              .descendant(
                of: find.byType(SidebarCategoriesSection),
                matching: find.byType(SizedBox),
              )
              .first,
        );

        expect(headerContainer.height, SidebarSpacing.headerHeight);
      });

      /// Verifies that all default categories are displayed in expanded state.
      ///
      /// Should show each category from the constants with proper
      /// icon, label, and count information.
      testWidgets('should display all default categories in expanded state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));

        for (final category in SidebarCategoriesConstants.defaultCategories) {
          expect(find.text(category.label), findsOneWidget);
          expect(find.text(category.count.toString()), findsOneWidget);
          expect(find.byIcon(category.icon), findsOneWidget);
        }
      });

      /// Verifies that category items are interactive in expanded state.
      ///
      /// Should allow users to tap on category items for filtering
      /// functionality with proper visual feedback.
      testWidgets('should have interactive category items in expanded state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));

        final List<Widget> categoryItems = tester
            .widgetList<SidebarCategoryItem>(
              find.byType(SidebarCategoryItem),
            )
            .toList();

        expect(categoryItems.length, greaterThan(0));

        // Should be able to tap the first category item
        await tester.tap(find.byType(SidebarCategoryItem).first);
        await tester.pumpAndSettle();
      });
    });

    group('collapsed state', () {
      /// Verifies that the categories section renders correctly when collapsed.
      ///
      /// Should show only category icons without the header text,
      /// maintaining the same vertical space allocation.
      testWidgets('should render collapsed categories section', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));

        expect(find.byType(SidebarCategoriesSection), findsOneWidget);
        expect(find.text('Categories'), findsNothing);

        // Should still show all category items (as icons only)
        expect(find.byType(SidebarCategoryItem), findsNWidgets(SidebarCategoriesConstants.defaultCategories.length));
      });

      /// Verifies that the collapsed section maintains header spacing.
      ///
      /// Should preserve the same vertical space as the expanded header
      /// to prevent layout shifts during state transitions.
      testWidgets('should maintain header spacing in collapsed state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));

        // Header area should still have fixed height
        final SizedBox headerContainer = tester.widget<SizedBox>(
          find
              .descendant(
                of: find.byType(SidebarCategoriesSection),
                matching: find.byType(SizedBox),
              )
              .first,
        );

        expect(headerContainer.height, SidebarSpacing.headerHeight);
      });

      /// Verifies that category icons are displayed in collapsed state.
      ///
      /// Should show all category icons even when labels and counts
      /// are hidden, maintaining visual recognition.
      testWidgets('should display category icons in collapsed state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));

        for (final category in SidebarCategoriesConstants.defaultCategories) {
          expect(find.byIcon(category.icon), findsOneWidget);
        }
      });

      /// Verifies that category labels are not visible in collapsed state.
      ///
      /// Should hide text labels to save space while maintaining
      /// icon visibility for category recognition.
      testWidgets('should not display category labels in collapsed state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));

        for (final category in SidebarCategoriesConstants.defaultCategories) {
          expect(find.text(category.label), findsNothing);
          expect(find.text(category.count.toString()), findsNothing);
        }
      });

      /// Verifies that tooltips are available in collapsed state.
      ///
      /// Should provide category information through tooltips when
      /// labels are not visible.
      testWidgets('should provide tooltips in collapsed state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));

        // Should have tooltips for category information
        expect(find.byType(Tooltip), findsNWidgets(SidebarCategoriesConstants.defaultCategories.length));
      });
    });

    group('state consistency', () {
      /// Verifies that both states show the same number of category items.
      ///
      /// Should maintain the same category count regardless of expansion
      /// state to ensure consistent functionality.
      testWidgets('should show same number of categories in both states', (WidgetTester tester) async {
        // Test expanded state
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));
        final int expandedCategoryCount = tester
            .widgetList<SidebarCategoryItem>(
              find.byType(SidebarCategoryItem),
            )
            .length;

        // Test collapsed state
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));
        final int collapsedCategoryCount = tester
            .widgetList<SidebarCategoryItem>(
              find.byType(SidebarCategoryItem),
            )
            .length;

        expect(expandedCategoryCount, equals(collapsedCategoryCount));
        expect(expandedCategoryCount, equals(SidebarCategoriesConstants.defaultCategories.length));
      });

      /// Verifies that header area maintains consistent height across states.
      ///
      /// Should prevent layout shifts by ensuring the header area
      /// occupies the same vertical space in both states.
      testWidgets('should maintain consistent header height across states', (WidgetTester tester) async {
        // Test expanded state header height
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));
        final SizedBox expandedHeader = tester.widget<SizedBox>(
          find
              .descendant(
                of: find.byType(SidebarCategoriesSection),
                matching: find.byType(SizedBox),
              )
              .first,
        );

        // Test collapsed state header height
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));
        final SizedBox collapsedHeader = tester.widget<SizedBox>(
          find
              .descendant(
                of: find.byType(SidebarCategoriesSection),
                matching: find.byType(SizedBox),
              )
              .first,
        );

        expect(expandedHeader.height, equals(collapsedHeader.height));
        expect(expandedHeader.height, equals(SidebarSpacing.headerHeight));
      });

      /// Verifies that the section handles state changes gracefully.
      ///
      /// Should transition between expanded and collapsed states without
      /// errors or visual artifacts.
      testWidgets('should handle state changes gracefully', (WidgetTester tester) async {
        // Start with expanded state
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));
        expect(find.text('Categories'), findsOneWidget);
        expect(find.byType(Tooltip), findsNothing);

        // Change to collapsed state
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));
        expect(find.text('Categories'), findsNothing);
        expect(find.byType(Tooltip), findsNWidgets(SidebarCategoriesConstants.defaultCategories.length));

        // Change back to expanded state
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));
        expect(find.text('Categories'), findsOneWidget);
        expect(find.byType(Tooltip), findsNothing);
      });

      /// Verifies that category icons are present in both states.
      ///
      /// Should always show category icons regardless of expansion
      /// state for visual consistency and recognition.
      testWidgets('should show category icons in both states', (WidgetTester tester) async {
        // Test expanded state
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));
        for (final category in SidebarCategoriesConstants.defaultCategories) {
          expect(find.byIcon(category.icon), findsOneWidget);
        }

        // Test collapsed state
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));
        for (final category in SidebarCategoriesConstants.defaultCategories) {
          expect(find.byIcon(category.icon), findsOneWidget);
        }
      });
    });

    group('layout and styling', () {
      /// Verifies that the section has proper padding and spacing.
      ///
      /// Should maintain consistent horizontal padding and vertical
      /// spacing between elements for visual hierarchy.
      testWidgets('should have proper padding and spacing', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));

        // Should have Padding widget for horizontal spacing
        expect(find.byType(Padding), findsWidgets);

        // Should have Column layout for vertical arrangement
        expect(find.byType(Column), findsOneWidget);
      });

      /// Verifies that the section uses proper column layout.
      ///
      /// Should arrange header and category items vertically with
      /// appropriate cross-axis alignment.
      testWidgets('should use column layout with proper alignment', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));

        final Column column = tester.widget<Column>(find.byType(Column));
        expect(column.crossAxisAlignment, CrossAxisAlignment.start);
        expect(column.children.length, greaterThan(2)); // Header + spacing + categories
      });

      /// Verifies that category items are properly spaced.
      ///
      /// Should have appropriate vertical spacing between the header
      /// and category items for visual separation.
      testWidgets('should have proper spacing between header and items', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));

        // Should have spacing between header and category items
        final List<Widget> paddingWidgets = tester.widgetList<Padding>(find.byType(Padding)).toList();
        expect(paddingWidgets.length, greaterThan(0));
      });
    });
  });
}
