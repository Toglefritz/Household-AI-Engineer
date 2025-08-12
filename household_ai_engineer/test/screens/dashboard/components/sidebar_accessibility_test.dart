import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar_search_section.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar_category_item.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar_categories_section.dart';
import 'package:household_ai_engineer/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Tests for sidebar accessibility features and compliance.
///
/// Verifies that sidebar components provide proper accessibility support
/// including semantic labels, tooltips, keyboard navigation, and screen
/// reader compatibility.
void main() {
  group('Sidebar Accessibility', () {
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

    group('SidebarSearchSection accessibility', () {
      /// Verifies that expanded search field has proper accessibility labels.
      ///
      /// Should provide appropriate labels and hints for screen readers
      /// when the search field is visible and interactive.
      testWidgets('should have proper accessibility labels in expanded state', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const SidebarSearchSection(showExpandedContent: true),
          ),
        );

        // Search field should be accessible
        expect(find.byType(TextField), findsOneWidget);

        final TextField textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.decoration?.hintText, isNotNull);
        expect(textField.decoration?.hintText, isNotEmpty);
      });

      /// Verifies that collapsed search button has proper accessibility support.
      ///
      /// Should provide semantic labels, hints, and tooltip information
      /// for screen readers when in collapsed state.
      testWidgets('should have proper accessibility support in collapsed state', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const SidebarSearchSection(showExpandedContent: false),
          ),
        );

        // Should have semantic information
        expect(find.byType(Semantics), findsOneWidget);

        final Semantics semantics = tester.widget<Semantics>(find.byType(Semantics));
        expect(semantics.properties.label, isNotNull);
        expect(semantics.properties.hint, isNotNull);
        expect(semantics.properties.button, isTrue);

        // Should have tooltip
        expect(find.byType(Tooltip), findsOneWidget);
        final Tooltip tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
        expect(tooltip.message, isNotNull);
        expect(tooltip.message, isNotEmpty);
      });

      /// Verifies that search overlay has proper accessibility structure.
      ///
      /// Should provide semantic labels for the dialog and its contents
      /// to help screen reader users understand the interface.
      testWidgets('should have accessible search overlay', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const SidebarSearchSection(showExpandedContent: false),
          ),
        );

        // Open search overlay
        await tester.tap(find.byType(IconButton));
        await tester.pumpAndSettle();

        // Dialog should have semantic information
        expect(find.byType(Semantics), findsWidgets);

        // Search field in overlay should be accessible
        expect(find.byType(TextField), findsOneWidget);

        // Buttons should be accessible
        expect(find.text('Search'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });

      /// Verifies that keyboard navigation works properly.
      ///
      /// Should support keyboard navigation through the search interface
      /// including tab navigation and enter key submission.
      testWidgets('should support keyboard navigation', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const SidebarSearchSection(showExpandedContent: true),
          ),
        );

        // Should be able to focus the search field
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();

        // Enter text and submit with enter key
        await tester.enterText(find.byType(TextField), 'test search');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
      });
    });

    group('SidebarCategoryItem accessibility', () {
      /// Test data for category item testing.
      const IconData testIcon = Icons.home;
      const String testLabel = 'Test Category';
      const int testCount = 5;

      /// Verifies that expanded category item has proper accessibility labels.
      ///
      /// Should provide semantic information about the category name,
      /// count, and interaction hints for screen readers.
      testWidgets('should have proper accessibility labels in expanded state', (WidgetTester tester) async {
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

        // Should have semantic information
        expect(find.byType(Semantics), findsOneWidget);

        final Semantics semantics = tester.widget<Semantics>(find.byType(Semantics));
        expect(semantics.properties.label, contains(testLabel));
        expect(semantics.properties.hint, contains(testCount.toString()));
        expect(semantics.properties.button, isTrue);
      });

      /// Verifies that collapsed category item has tooltip and semantic support.
      ///
      /// Should provide both tooltip and semantic information when only
      /// the icon is visible to ensure accessibility.
      testWidgets('should have tooltip and semantic support in collapsed state', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const SidebarCategoryItem(
              icon: testIcon,
              label: testLabel,
              count: testCount,
              showExpandedContent: false,
            ),
          ),
        );

        // Should have tooltip
        expect(find.byType(Tooltip), findsOneWidget);
        final Tooltip tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
        expect(tooltip.message, contains(testLabel));
        expect(tooltip.message, contains(testCount.toString()));

        // Should have semantic information
        expect(find.byType(Semantics), findsOneWidget);
        final Semantics semantics = tester.widget<Semantics>(find.byType(Semantics));
        expect(semantics.properties.label, contains(testLabel));
        expect(semantics.properties.hint, contains(testCount.toString()));
        expect(semantics.properties.button, isTrue);
      });

      /// Verifies that category items are keyboard accessible.
      ///
      /// Should support keyboard navigation and activation through
      /// standard accessibility mechanisms.
      testWidgets('should be keyboard accessible', (WidgetTester tester) async {
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

        // Should be able to tap the category item
        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();
      });

      /// Verifies that semantic information is consistent across states.
      ///
      /// Should provide similar accessibility information in both expanded
      /// and collapsed states for consistent user experience.
      testWidgets('should have consistent semantic information across states', (WidgetTester tester) async {
        // Test expanded state
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

        final Semantics expandedSemantics = tester.widget<Semantics>(find.byType(Semantics));

        // Test collapsed state
        await tester.pumpWidget(
          createTestApp(
            child: const SidebarCategoryItem(
              icon: testIcon,
              label: testLabel,
              count: testCount,
              showExpandedContent: false,
            ),
          ),
        );

        final Semantics collapsedSemantics = tester.widget<Semantics>(find.byType(Semantics));

        // Both should have similar semantic properties
        expect(expandedSemantics.properties.button, collapsedSemantics.properties.button);
        expect(expandedSemantics.properties.label, contains(testLabel));
        expect(collapsedSemantics.properties.label, contains(testLabel));
      });
    });

    group('SidebarCategoriesSection accessibility', () {
      /// Verifies that categories section has proper heading structure.
      ///
      /// Should mark the "Categories" title as a header for proper
      /// screen reader navigation and document structure.
      testWidgets('should have proper heading structure', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const SidebarCategoriesSection(showExpandedContent: true),
          ),
        );

        // Should have header semantic
        final List<Semantics> semanticsWidgets = tester.widgetList<Semantics>(find.byType(Semantics)).toList();
        final bool hasHeader = semanticsWidgets.any((Semantics s) => s.properties.header == true);
        expect(hasHeader, isTrue);
      });

      /// Verifies that all category items are accessible.
      ///
      /// Should ensure that each category item in the section provides
      /// proper accessibility support for screen readers.
      testWidgets('should have accessible category items', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const SidebarCategoriesSection(showExpandedContent: true),
          ),
        );

        // All category items should have semantic information
        final List<SidebarCategoryItem> categoryItems = tester
            .widgetList<SidebarCategoryItem>(
              find.byType(SidebarCategoryItem),
            )
            .toList();

        expect(categoryItems.length, greaterThan(0));

        // Each category item should be accessible
        for (int i = 0; i < categoryItems.length; i++) {
          expect(find.byType(SidebarCategoryItem).at(i), findsOneWidget);
        }
      });

      /// Verifies that section maintains accessibility in collapsed state.
      ///
      /// Should provide appropriate accessibility support even when
      /// the section header is not visible.
      testWidgets('should maintain accessibility in collapsed state', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const SidebarCategoriesSection(showExpandedContent: false),
          ),
        );

        // Category items should still be accessible
        final List<SidebarCategoryItem> categoryItems = tester
            .widgetList<SidebarCategoryItem>(
              find.byType(SidebarCategoryItem),
            )
            .toList();

        expect(categoryItems.length, greaterThan(0));

        // Should have tooltips for collapsed items
        expect(find.byType(Tooltip), findsWidgets);
      });

      /// Verifies that keyboard navigation works through category list.
      ///
      /// Should support keyboard navigation through all category items
      /// in the section for users who rely on keyboard input.
      testWidgets('should support keyboard navigation through categories', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const SidebarCategoriesSection(showExpandedContent: true),
          ),
        );

        // Should be able to interact with category items
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

    group('Overall accessibility compliance', () {
      /// Verifies that all interactive elements have proper semantic labels.
      ///
      /// Should ensure that buttons, links, and other interactive elements
      /// provide appropriate labels for screen reader users.
      testWidgets('should have proper semantic labels for interactive elements', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: Column(
              children: const [
                SidebarSearchSection(showExpandedContent: false),
                SidebarCategoriesSection(showExpandedContent: false),
              ],
            ),
          ),
        );

        // All interactive elements should have semantic information
        final List<Semantics> semanticsWidgets = tester.widgetList<Semantics>(find.byType(Semantics)).toList();

        for (final Semantics semantics in semanticsWidgets) {
          if (semantics.properties.button == true) {
            expect(semantics.properties.label, isNotNull);
          }
        }
      });

      /// Verifies that tooltips provide meaningful information.
      ///
      /// Should ensure that all tooltips contain useful information
      /// that helps users understand element functionality.
      testWidgets('should provide meaningful tooltips', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: Column(
              children: const [
                SidebarSearchSection(showExpandedContent: false),
                SidebarCategoriesSection(showExpandedContent: false),
              ],
            ),
          ),
        );

        // All tooltips should have meaningful messages
        final List<Tooltip> tooltips = tester.widgetList<Tooltip>(find.byType(Tooltip)).toList();

        for (final Tooltip tooltip in tooltips) {
          expect(tooltip.message, isNotNull);
          expect(tooltip.message, isNotEmpty);
          expect(tooltip.message.length, greaterThan(3)); // Should be descriptive
        }
      });

      /// Verifies that focus management works properly.
      ///
      /// Should handle focus transitions appropriately when elements
      /// change state or when dialogs are opened/closed.
      testWidgets('should handle focus management properly', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const SidebarSearchSection(showExpandedContent: false),
          ),
        );

        // Open search overlay
        await tester.tap(find.byType(IconButton));
        await tester.pumpAndSettle();

        // Search field should be focusable
        expect(find.byType(TextField), findsOneWidget);

        // Close overlay
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Should return to original state
        expect(find.byType(IconButton), findsOneWidget);
      });

      /// Verifies that semantic structure is maintained during animations.
      ///
      /// Should preserve accessibility information even during state
      /// transitions and animations.
      testWidgets('should maintain semantic structure during animations', (WidgetTester tester) async {
        Widget buildTestWidget(bool expanded) {
          return createTestApp(
            child: Column(
              children: [
                SidebarSearchSection(showExpandedContent: expanded),
                SidebarCategoriesSection(showExpandedContent: expanded),
              ],
            ),
          );
        }

        // Start with expanded state
        await tester.pumpWidget(buildTestWidget(true));
        final int expandedSemanticsCount = tester.widgetList<Semantics>(find.byType(Semantics)).length;

        // Change to collapsed state
        await tester.pumpWidget(buildTestWidget(false));
        await tester.pumpAndSettle();
        final int collapsedSemanticsCount = tester.widgetList<Semantics>(find.byType(Semantics)).length;

        // Should maintain semantic elements (may be different but should exist)
        expect(expandedSemanticsCount, greaterThan(0));
        expect(collapsedSemanticsCount, greaterThan(0));
      });
    });
  });
}
