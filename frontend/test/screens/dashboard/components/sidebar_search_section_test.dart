import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/l10n/app_localizations.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar/search/sidebar_search.dart';
import 'package:household_ai_engineer/screens/dashboard/models/sidebar/sidebar_spacing.dart';

/// Widget tests for the SidebarSearchSection component.
///
/// Verifies that the search section renders correctly in both expanded
/// and collapsed states, maintains consistent dimensions, and handles
/// user interactions properly.
void main() {
  group('SidebarSearchSection', () {
    /// Helper function to create a test widget with localization support.
    ///
    /// Wraps the search section in a MaterialApp with proper localization
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
          body: SidebarSearchSection(
            showExpandedContent: showExpandedContent,
          ),
        ),
      );
    }

    group('expanded state', () {
      /// Verifies that the search section renders correctly when expanded.
      ///
      /// Should show the full search text field with proper styling
      /// and maintain the correct height for layout consistency.
      testWidgets('should render expanded search field', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));

        expect(find.byType(SidebarSearchSection), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);

        // Should not show the collapsed button
        expect(find.byType(IconButton), findsNothing);
      });

      /// Verifies that the expanded search field has correct dimensions.
      ///
      /// Should maintain the standard section height to prevent layout
      /// shifts during state transitions.
      testWidgets('should have correct height in expanded state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));

        final SizedBox container = tester.widget<SizedBox>(
          find.descendant(
            of: find.byType(SidebarSearchSection),
            matching: find.byType(SizedBox),
          ),
        );

        expect(container.height, SidebarSpacing.sectionHeight);
      });

      /// Verifies that the search field accepts text input.
      ///
      /// Should allow users to type search queries and maintain
      /// proper text styling and behavior.
      testWidgets('should accept text input in expanded state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));

        final TextField textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.enabled, true);

        await tester.enterText(find.byType(TextField), 'test search');
        expect(find.text('test search'), findsOneWidget);
      });
    });

    group('collapsed state', () {
      /// Verifies that the search section renders correctly when collapsed.
      ///
      /// Should show only the search icon button with proper tooltip
      /// and maintain the same height as the expanded state.
      testWidgets('should render collapsed search button', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));

        expect(find.byType(SidebarSearchSection), findsOneWidget);
        expect(find.byType(IconButton), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);

        // Should not show the expanded text field
        expect(find.byType(TextField), findsNothing);
      });

      /// Verifies that the collapsed search button has correct dimensions.
      ///
      /// Should maintain the same height as the expanded state to prevent
      /// layout shifts during transitions.
      testWidgets('should have correct height in collapsed state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));

        final SizedBox container = tester.widget<SizedBox>(
          find.descendant(
            of: find.byType(SidebarSearchSection),
            matching: find.byType(SizedBox),
          ),
        );

        expect(container.height, SidebarSpacing.sectionHeight);
      });

      /// Verifies that the collapsed search button shows a tooltip.
      ///
      /// Should provide accessibility information and user guidance
      /// about the button's function.
      testWidgets('should show tooltip on collapsed search button', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));

        final IconButton button = tester.widget<IconButton>(find.byType(IconButton));
        expect(button.tooltip, isNotNull);
        expect(button.tooltip, isNotEmpty);
      });

      /// Verifies that tapping the collapsed search button opens the search overlay.
      ///
      /// Should show a dialog with search functionality when the user
      /// clicks the search icon in collapsed state.
      testWidgets('should open search overlay when tapped', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));

        // Tap the search button
        await tester.tap(find.byType(IconButton));
        await tester.pumpAndSettle();

        // Should show the search overlay dialog
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.text('Search'), findsOneWidget);
      });
    });

    group('search overlay', () {
      /// Verifies that the search overlay renders correctly.
      ///
      /// Should show a dialog with search field, clear button, and
      /// action buttons for search and cancel operations.
      testWidgets('should render search overlay correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));

        // Open the search overlay
        await tester.tap(find.byType(IconButton));
        await tester.pumpAndSettle();

        expect(find.byType(Dialog), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Search'), findsOneWidget);
        expect(find.byIcon(Icons.clear), findsOneWidget);
      });

      /// Verifies that the search overlay accepts text input.
      ///
      /// Should allow users to enter search queries in the overlay
      /// text field with proper focus management.
      testWidgets('should accept text input in overlay', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));

        // Open the search overlay
        await tester.tap(find.byType(IconButton));
        await tester.pumpAndSettle();

        // Enter text in the overlay search field
        await tester.enterText(find.byType(TextField), 'overlay search');
        expect(find.text('overlay search'), findsOneWidget);
      });

      /// Verifies that the clear button works in the search overlay.
      ///
      /// Should clear the search text when the clear icon is tapped
      /// and maintain focus on the search field.
      testWidgets('should clear text when clear button is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));

        // Open the search overlay
        await tester.tap(find.byType(IconButton));
        await tester.pumpAndSettle();

        // Enter text and then clear it
        await tester.enterText(find.byType(TextField), 'test text');
        expect(find.text('test text'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.clear));
        await tester.pumpAndSettle();

        // Text should be cleared
        expect(find.text('test text'), findsNothing);
      });

      /// Verifies that the cancel button closes the search overlay.
      ///
      /// Should dismiss the dialog when the cancel button is pressed
      /// without performing any search action.
      testWidgets('should close overlay when cancel is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));

        // Open the search overlay
        await tester.tap(find.byType(IconButton));
        await tester.pumpAndSettle();

        expect(find.byType(Dialog), findsOneWidget);

        // Tap cancel button
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Dialog should be closed
        expect(find.byType(Dialog), findsNothing);
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
            of: find.byType(SidebarSearchSection),
            matching: find.byType(SizedBox),
          ),
        );

        // Test collapsed state height
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));

        final SizedBox collapsedContainer = tester.widget<SizedBox>(
          find.descendant(
            of: find.byType(SidebarSearchSection),
            matching: find.byType(SizedBox),
          ),
        );

        // Heights should be identical
        expect(expandedContainer.height, collapsedContainer.height);
        expect(expandedContainer.height, SidebarSpacing.sectionHeight);
      });

      /// Verifies that the search section handles state changes gracefully.
      ///
      /// Should transition between expanded and collapsed states without
      /// errors or visual artifacts.
      testWidgets('should handle state changes gracefully', (WidgetTester tester) async {
        // Start with expanded state
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byType(IconButton), findsNothing);

        // Change to collapsed state
        await tester.pumpWidget(createTestWidget(showExpandedContent: false));
        expect(find.byType(TextField), findsNothing);
        expect(find.byType(IconButton), findsOneWidget);

        // Change back to expanded state
        await tester.pumpWidget(createTestWidget(showExpandedContent: true));
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byType(IconButton), findsNothing);
      });
    });
  });
}
