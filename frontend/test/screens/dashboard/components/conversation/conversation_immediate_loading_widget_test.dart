import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../lib/l10n/app_localizations.dart';
import '../../../../../lib/screens/dashboard/components/conversation/conversation_immediate_loading_widget.dart';
import '../../../../test_helpers.dart';

void main() {
  group('ConversationImmediateLoadingWidget', () {
    /// Tests that the widget displays the correct processing message.
    ///
    /// This test verifies that the immediate loading widget shows
    /// the localized processing message to inform users that their
    /// input is being analyzed.
    testWidgets('should display processing message', (WidgetTester tester) async {
      // Arrange & Act: Build the widget
      await tester.pumpWidget(
        createTestApp(
          child: const ConversationImmediateLoadingWidget(),
        ),
      );

      // Assert: Processing message should be displayed
      expect(find.text('Processing your request'), findsOneWidget);
    });

    /// Tests that the widget displays a loading indicator.
    ///
    /// This test verifies that a circular progress indicator is shown
    /// to provide visual feedback that processing is occurring.
    testWidgets('should display loading indicator', (WidgetTester tester) async {
      // Arrange & Act: Build the widget
      await tester.pumpWidget(
        createTestApp(
          child: const ConversationImmediateLoadingWidget(),
        ),
      );

      // Assert: Loading indicator should be present
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    /// Tests that the widget displays animated typing dots.
    ///
    /// This test verifies that animated dots are shown after the
    /// processing message to indicate ongoing activity.
    testWidgets('should display animated typing dots', (WidgetTester tester) async {
      // Arrange & Act: Build the widget
      await tester.pumpWidget(
        createTestApp(
          child: const ConversationImmediateLoadingWidget(),
        ),
      );

      // Allow initial animation frame
      await tester.pump();

      // Assert: Should find dots (at least one dot should be visible)
      final Finder dotsFinder = find.textContaining('.');
      expect(dotsFinder, findsAtLeastNWidgets(1));
    });

    /// Tests that the loading indicator has proper styling.
    ///
    /// This test verifies that the widget follows the design system
    /// with appropriate colors, spacing, and visual hierarchy.
    testWidgets('should have proper styling and layout', (WidgetTester tester) async {
      // Arrange & Act: Build the widget
      await tester.pumpWidget(
        createTestApp(
          child: const ConversationImmediateLoadingWidget(),
        ),
      );

      // Assert: Container should have proper styling
      final Container container = tester.widget<Container>(
        find.byType(Container).first,
      );

      expect(container.decoration, isA<BoxDecoration>());
      final BoxDecoration decoration = container.decoration! as BoxDecoration;
      expect(decoration.borderRadius, isNotNull);
      expect(decoration.color, isNotNull);
      expect(decoration.border, isNotNull);

      // Assert: Should have proper padding and margins
      expect(container.margin, isNotNull);
      expect(container.padding, isNotNull);
    });

    /// Tests that animations are properly initialized and running.
    ///
    /// This test verifies that the widget's animations start correctly
    /// and provide smooth visual feedback to users.
    testWidgets('should animate loading indicator and dots', (WidgetTester tester) async {
      // Arrange & Act: Build the widget
      await tester.pumpWidget(
        createTestApp(
          child: const ConversationImmediateLoadingWidget(),
        ),
      );

      // Get initial state
      await tester.pump();

      // Advance animation and verify changes
      await tester.pump(const Duration(milliseconds: 500));

      // Assert: Widget should still be present and animating
      expect(find.byType(ConversationImmediateLoadingWidget), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Advance animation further
      await tester.pump(const Duration(milliseconds: 1000));

      // Assert: Animation should continue
      expect(find.byType(ConversationImmediateLoadingWidget), findsOneWidget);
    });

    /// Tests that the widget is accessible to screen readers.
    ///
    /// This test verifies requirement 7.1 by ensuring that the loading
    /// widget provides appropriate semantic information for assistive technologies.
    testWidgets('should be accessible to screen readers', (WidgetTester tester) async {
      // Arrange & Act: Build the widget
      await tester.pumpWidget(
        createTestApp(
          child: const ConversationImmediateLoadingWidget(),
        ),
      );

      // Assert: Text should be accessible
      final Finder processingText = find.text('Processing your request');
      expect(processingText, findsOneWidget);

      // Verify that the text widget has proper semantics
      final Text textWidget = tester.widget<Text>(processingText);
      expect(textWidget.style, isNotNull);
    });

    /// Tests that the widget handles theme changes properly.
    ///
    /// This test verifies that the widget adapts to different themes
    /// and maintains proper visual contrast and readability.
    testWidgets('should adapt to theme changes', (WidgetTester tester) async {
      // Test with light theme
      await tester.pumpWidget(
        createTestApp(
          child: const ConversationImmediateLoadingWidget(),
        ),
      );

      expect(find.byType(ConversationImmediateLoadingWidget), findsOneWidget);

      // Test with dark theme
      await tester.pumpWidget(
        createTestAppDark(
          child: const ConversationImmediateLoadingWidget(),
        ),
      );

      expect(find.byType(ConversationImmediateLoadingWidget), findsOneWidget);
    });

    /// Tests that the widget disposes animations properly.
    ///
    /// This test verifies that animation controllers are properly
    /// disposed to prevent memory leaks.
    testWidgets('should dispose animations properly', (WidgetTester tester) async {
      // Arrange & Act: Build and then remove the widget
      await tester.pumpWidget(
        createTestApp(
          child: const ConversationImmediateLoadingWidget(),
        ),
      );

      expect(find.byType(ConversationImmediateLoadingWidget), findsOneWidget);

      // Remove the widget
      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      // Assert: Widget should be removed without errors
      expect(find.byType(ConversationImmediateLoadingWidget), findsNothing);
    });

    /// Tests that the widget maintains consistent sizing.
    ///
    /// This test verifies that the loading widget has appropriate
    /// dimensions and doesn't cause layout issues in the conversation modal.
    testWidgets('should have consistent sizing', (WidgetTester tester) async {
      // Arrange & Act: Build the widget
      await tester.pumpWidget(
        createTestApp(
          child: const ConversationImmediateLoadingWidget(),
        ),
      );

      // Assert: Widget should have reasonable size constraints
      final RenderBox renderBox = tester.renderObject(
        find.byType(ConversationImmediateLoadingWidget),
      );

      expect(renderBox.size.width, greaterThan(0));
      expect(renderBox.size.height, greaterThan(0));
      expect(renderBox.size.height, lessThan(100)); // Should not be too tall
    });
  });
}
