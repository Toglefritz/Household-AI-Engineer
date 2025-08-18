import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/screens/dashboard/components/conversation/conversation_input_widget.dart';

import '../../../../test_helpers.dart';

/// Test suite for [ConversationInputWidget].
///
/// Tests the input widget functionality including focus handling,
/// text input, and message sending.
void main() {
  group('ConversationInputWidget', () {
    testWidgets('displays input field with placeholder', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: ConversationInputWidget(
            onSendMessage: (_) {},
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Type your message...'), findsOneWidget);
    });

    testWidgets('can receive focus and accept text input', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: ConversationInputWidget(
            onSendMessage: (String message) {},
          ),
        ),
      );

      // Find the text field
      final Finder textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Tap to focus
      await tester.tap(textField);
      await tester.pump();

      // Enter text
      await tester.enterText(textField, 'Hello, this is a test message');
      await tester.pump();

      // Verify text was entered
      expect(find.text('Hello, this is a test message'), findsOneWidget);

      // Verify send button appears
      expect(find.byIcon(Icons.send), findsAtLeastNWidgets(1));
    });

    testWidgets('sends message when send button is tapped', (WidgetTester tester) async {
      String? sentMessage;

      await tester.pumpWidget(
        createTestApp(
          child: ConversationInputWidget(
            onSendMessage: (String message) {
              sentMessage = message;
            },
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.pump();

      // Tap send button
      await tester.tap(find.byIcon(Icons.send).first);
      await tester.pump();

      // Verify message was sent
      expect(sentMessage, equals('Test message'));

      // Verify text field was cleared
      final TextField textFieldWidget = tester.widget<TextField>(find.byType(TextField));
      expect(textFieldWidget.controller?.text, isEmpty);
    });

    testWidgets('sends message when submitted via keyboard', (WidgetTester tester) async {
      String? sentMessage;

      await tester.pumpWidget(
        createTestApp(
          child: ConversationInputWidget(
            onSendMessage: (String message) {
              sentMessage = message;
            },
          ),
        ),
      );

      // Enter text and submit
      await tester.enterText(find.byType(TextField), 'Keyboard test');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      // Verify message was sent
      expect(sentMessage, equals('Keyboard test'));
    });

    testWidgets('disables input when enabled is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: ConversationInputWidget(
            onSendMessage: (_) {},
            enabled: false,
          ),
        ),
      );

      await tester.pump(); // Ensure widget is fully built

      // Verify text field is disabled
      final TextField textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);

      // Verify no send button is visible
      expect(find.byIcon(Icons.send), findsNothing);
    });

    testWidgets('uses custom placeholder when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: ConversationInputWidget(
            onSendMessage: (_) {},
            placeholder: 'Custom placeholder text',
          ),
        ),
      );

      expect(find.text('Custom placeholder text'), findsOneWidget);
    });

    testWidgets('does not send empty messages', (WidgetTester tester) async {
      String? sentMessage;

      await tester.pumpWidget(
        createTestApp(
          child: ConversationInputWidget(
            onSendMessage: (String message) {
              sentMessage = message;
            },
          ),
        ),
      );

      // Try to send empty message
      await tester.enterText(find.byType(TextField), '   '); // Only whitespace
      await tester.pump();

      // Send button should not be visible for empty/whitespace-only text
      expect(find.byIcon(Icons.send), findsNothing);

      // Try to submit via keyboard
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      // Verify no message was sent
      expect(sentMessage, isNull);
    });
  });
}
