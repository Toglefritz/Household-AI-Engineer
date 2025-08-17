import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar/sidebar_category_item.dart';
import 'package:household_ai_engineer/screens/dashboard/models/sidebar/sidebar_spacing.dart';

/// Widget tests for the SidebarCategoryItem component.
///
/// Verifies that the category item renders correctly in both expanded
/// and collapsed states, maintains consistent dimensions, and handles
/// user interactions properly.
void main() {
  group('SidebarCategoryItem', () {
    /// Test data for category item testing.
    const IconData testIcon = Icons.home;
    const String testLabel = 'Test Category';
    const int testCount = 5;

    /// Helper function to create a test widget.
    ///
    /// Wraps the category item in a MaterialApp for proper testing context.
    Widget createTestWidget({required bool showExpandedContent}) {
      return MaterialApp(
        home: Scaffold(
          body: SidebarCategoryItem(
            icon: testIcon,
            label: testLabel,
            count: testCount,
            showExpandedContent: showExpandedContent,
          ),
        ),
      );
    }

    group('expanded state', () {
      /// Verifies that the category item renders correctly when expanded.
      ///
      /// Should show the icon, label, and count in a horizontal layout
      /// with proper styling and interactive behavior.
      testWidgets('should render expanded category item', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));

        expect(find.byType(SidebarCategoryItem), findsOneWidget);
        expect(find.byIcon(testIcon), findsOneWidget);
        expect(find.text(testLabel), findsOneWidget);
        expect(find.text(testCount.toString()), findsOneWidget);

        // Should show InkWell for interaction
        expect(find.byType(InkWell), findsOneWidget);
      });

      /// Verifies that the expanded category item has correct dimensions.
      ///
      /// Should maintain the standard category item height for consistent
      /// spacing and layout.
      testWidgets('should have correct height in expanded state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));

        final SizedBox container = tester.widget<SizedBox>(
          find.descendant(
            of: find.byType(SidebarCategoryItem),
            matching: find.byType(SizedBox),
          ),
        );

        expect(container.height, SidebarSpacing.categoryItemHeight);
      });

      /// Verifies that the expanded category item is interactive.
      ///
      /// Should respond to tap gestures and provide visual feedback
      /// through the InkWell ripple effect.
      testWidgets('should be interactive in expanded state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));

        final InkWell inkWell = tester.widget<InkWell>(find.byType(InkWell));
        expect(inkWell.onTap, isNotNull);

        // Should be able to tap the item
        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();
      });

      /// Verifies that the expanded category item has proper layout.
      ///
      /// Should arrange icon, label, and count in a horizontal row
      /// with appropriate spacing and alignment.
      testWidgets('should have proper layout in expanded state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));

        // Should have a Row layout
        expect(find.byType(Row), findsOneWidget);

        // Icon should be on the left
        final Row row = tester.widget<Row>(find.byType(Row));
        expect(row.children.length, greaterThanOrEqualTo(3)); // Icon, spacing, text, count
      });
    });

    group('collapsed state', () {
      /// Verifies that the category item renders correctly when collapsed.
      ///
      /// Should show only the icon with a tooltip containing the category
      /// information, maintaining the same height as expanded state.
      testWidgets('should render collapsed category item', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));

        expect(find.byType(SidebarCategoryItem), findsOneWidget);
        expect(find.byIcon(testIcon), findsOneWidget);
        expect(find.byType(Tooltip), findsOneWidget);

        // Should not show the label and count as text
        expect(find.text(testLabel), findsNothing);
        expect(find.text(testCount.toString()), findsNothing);
      });

      /// Verifies that the collapsed category item has correct dimensions.
      ///
      /// Should maintain the same height as the expanded state to prevent
      /// layout shifts during state transitions.
      testWidgets('should have correct height in collapsed state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));

        final SizedBox container = tester.widget<SizedBox>(
          find.descendant(
            of: find.byType(SidebarCategoryItem),
            matching: find.byType(SizedBox),
          ),
        );

        expect(container.height, SidebarSpacing.categoryItemHeight);
      });

      /// Verifies that the collapsed category item shows a tooltip.
      ///
      /// Should provide category information through tooltip when
      /// the user hovers or long-presses the icon.
      testWidgets('should show tooltip with category information', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));

        final Tooltip tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
        expect(tooltip.message, '$testLabel ($testCount)');
      });

      /// Verifies that the collapsed category item is interactive.
      ///
      /// Should respond to tap gestures even in collapsed state
      /// for category filtering functionality.
      testWidgets('should be interactive in collapsed state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));

        final InkWell inkWell = tester.widget<InkWell>(find.byType(InkWell));
        expect(inkWell.onTap, isNotNull);

        // Should be able to tap the item
        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();
      });

      /// Verifies that the collapsed category item has proper centering.
      ///
      /// Should center the icon within the available space for
      /// visual consistency and alignment.
      testWidgets('should center icon in collapsed state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));

        // Should have a Center widget
        expect(find.byType(Center), findsOneWidget);

        // Icon should be centered
        final Center center = tester.widget<Center>(find.byType(Center));
        expect(center.child, isA<Tooltip>());
      });
    });

    group('state consistency', () {
      /// Verifies that both states maintain the same height.
      ///
      /// Should prevent layout shifts by ensuring consistent dimensions
      /// regardless of the expansion state.
      testWidgets('should maintain consistent height across states', (WidgetTester tester) async {
        // Test expanded state height
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));

        final SizedBox expandedContainer = tester.widget<SizedBox>(
          find.descendant(
            of: find.byType(SidebarCategoryItem),
            matching: find.byType(SizedBox),
          ),
        );

        // Test collapsed state height
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));

        final SizedBox collapsedContainer = tester.widget<SizedBox>(
          find.descendant(
            of: find.byType(SidebarCategoryItem),
            matching: find.byType(SizedBox),
          ),
        );

        // Heights should be identical
        expect(expandedContainer.height, collapsedContainer.height);
        expect(expandedContainer.height, SidebarSpacing.categoryItemHeight);
      });

      /// Verifies that the category item handles state changes gracefully.
      ///
      /// Should transition between expanded and collapsed states without
      /// errors or visual artifacts.
      testWidgets('should handle state changes gracefully', (WidgetTester tester) async {
        // Start with expanded state
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));
        expect(find.text(testLabel), findsOneWidget);
        expect(find.text(testCount.toString()), findsOneWidget);
        expect(find.byType(Tooltip), findsNothing);

        // Change to collapsed state
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));
        expect(find.text(testLabel), findsNothing);
        expect(find.text(testCount.toString()), findsNothing);
        expect(find.byType(Tooltip), findsOneWidget);

        // Change back to expanded state
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));
        expect(find.text(testLabel), findsOneWidget);
        expect(find.text(testCount.toString()), findsOneWidget);
        expect(find.byType(Tooltip), findsNothing);
      });

      /// Verifies that both states maintain interactivity.
      ///
      /// Should provide tap functionality in both expanded and collapsed
      /// states for consistent user experience.
      testWidgets('should maintain interactivity across states', (WidgetTester tester) async {
        // Test expanded state interactivity
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));
        final InkWell expandedInkWell = tester.widget<InkWell>(find.byType(InkWell));
        expect(expandedInkWell.onTap, isNotNull);

        // Test collapsed state interactivity
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));
        final InkWell collapsedInkWell = tester.widget<InkWell>(find.byType(InkWell));
        expect(collapsedInkWell.onTap, isNotNull);
      });

      /// Verifies that the icon is present in both states.
      ///
      /// Should always show the category icon regardless of expansion
      /// state for visual consistency and recognition.
      testWidgets('should show icon in both states', (WidgetTester tester) async {
        // Test expanded state
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));
        expect(find.byIcon(testIcon), findsOneWidget);

        // Test collapsed state
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));
        expect(find.byIcon(testIcon), findsOneWidget);
      });
    });
  });
}
