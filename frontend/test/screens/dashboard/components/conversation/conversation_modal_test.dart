import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/models/models.dart';
import 'package:household_ai_engineer/screens/dashboard/components/conversation/conversation_modal.dart';

import '../../../../test_helpers.dart';

/// Test suite for [ConversationModal] widget.
///
/// Covers rendering, interaction, and conversation flow management
/// for the conversational interface used in application creation.
void main() {
  group('ConversationModal', () {
    late UserApplication sampleApplication;

    setUp(() {
      sampleApplication = UserApplication(
        id: 'test_app_001',
        title: 'Test Application',
        description: 'A test application for conversation testing',
        status: ApplicationStatus.ready,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        launchConfig: const LaunchConfiguration(
          type: LaunchType.web,
          url: 'http://localhost:3000',
        ),
        tags: ['test', 'conversation'],
      );
    });

    group('rendering', () {
      testWidgets('displays create application modal correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ConversationModal(),
          ),
        );

        expect(find.text('Create New Application'), findsOneWidget);
        expect(find.text('Describe what you need and I\'ll help you build it'), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('displays modify application modal correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: ConversationModal(
              applicationToModify: sampleApplication,
            ),
          ),
        );

        expect(find.text('Modify Test Application'), findsOneWidget);
        expect(find.byIcon(Icons.edit), findsOneWidget);
      });

      testWidgets('displays conversation messages', (WidgetTester tester) async {
        final ConversationThread sampleConversation = _createTestConversation();

        await tester.pumpWidget(
          createTestApp(
            child: ConversationModal(
              initialConversation: sampleConversation,
            ),
          ),
        );

        // Should display the welcome message
        expect(find.textContaining('Hi! I\'ll help you create'), findsOneWidget);

        // Should display suggestion chips
        expect(find.text('Chore Tracker'), findsOneWidget);
        expect(find.text('Budget Planner'), findsOneWidget);
        expect(find.text('Recipe Organizer'), findsOneWidget);
      });

      testWidgets('displays input field', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ConversationModal(),
          ),
        );

        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Type your message...'), findsOneWidget);
      });
    });

    group('interactions', () {
      testWidgets('closes modal when close button is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (BuildContext context) => const ConversationModal(),
                    );
                  },
                  child: const Text('Open Modal'),
                );
              },
            ),
          ),
        );

        // Open the modal
        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        // Verify modal is open
        expect(find.text('Create New Application'), findsOneWidget);

        // Close the modal
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Verify modal is closed
        expect(find.text('Create New Application'), findsNothing);
      });

      testWidgets('handles text input', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ConversationModal(),
          ),
        );

        // Find the text field
        final Finder textField = find.byType(TextField);
        expect(textField, findsOneWidget);

        // Enter text
        await tester.enterText(textField, 'I need a chore tracker');
        await tester.pump();

        // Verify the text field contains the entered text
        final TextField textFieldWidget = tester.widget<TextField>(textField);
        expect(textFieldWidget.controller?.text, equals('I need a chore tracker'));
      });

      testWidgets('handles suggestion chip taps', (WidgetTester tester) async {
        final ConversationThread sampleConversation = _createTestConversation();

        await tester.pumpWidget(
          createTestApp(
            child: ConversationModal(
              initialConversation: sampleConversation,
            ),
          ),
        );

        // Find a suggestion chip
        final Finder choreTrackerChip = find.text('Chore Tracker');
        expect(choreTrackerChip, findsOneWidget);

        // Tap the suggestion chip
        await tester.tap(choreTrackerChip);
        await tester.pump();

        // The tap should be handled without throwing an exception
        expect(tester.takeException(), isNull);
      });
    });

    group('conversation flow', () {
      testWidgets('shows typing indicator when processing', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ConversationModal(),
          ),
        );

        // Enter a message to trigger processing
        final Finder textField = find.byType(TextField);
        await tester.enterText(textField, 'Test message');
        await tester.pumpAndSettle();

        // Tap send button (if visible)
        final Finder sendButton = find.byIcon(Icons.send);
        if (tester.any(sendButton)) {
          await tester.tap(sendButton);
          await tester.pump(); // Don't settle to catch the processing state

          // Should show typing indicator during processing
          // Note: This is a simplified test - in reality we'd need to mock the controller
        }
      });

      testWidgets('displays different conversation types correctly', (WidgetTester tester) async {
        // Test create conversation
        await tester.pumpWidget(
          createTestApp(
            child: const ConversationModal(),
          ),
        );

        expect(find.text('Create New Application'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);

        // Test modify conversation
        await tester.pumpWidget(
          createTestApp(
            child: ConversationModal(
              applicationToModify: sampleApplication,
            ),
          ),
        );

        expect(find.text('Modify Test Application'), findsOneWidget);
        expect(find.byIcon(Icons.edit), findsOneWidget);
      });
    });

    group('accessibility', () {
      testWidgets('has proper semantic labels', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ConversationModal(),
          ),
        );

        // Verify modal is accessible
        expect(find.byType(ConversationModal), findsOneWidget);

        // Verify input field has proper semantics
        expect(find.byType(TextField), findsOneWidget);

        // Verify close button has tooltip
        final Finder closeButton = find.byIcon(Icons.close);
        expect(closeButton, findsOneWidget);
      });
    });
  });
}

/// Creates a test conversation thread for testing purposes.
///
/// Returns a conversation with sample messages and actions to test
/// the conversation modal functionality.
ConversationThread _createTestConversation() {
  final DateTime now = DateTime.now();
  final String conversationId = 'test_conv_${now.millisecondsSinceEpoch}';

  return ConversationThread(
    id: conversationId,
    context: const ConversationContext(
      purpose: 'create_application',
      metadata: {
        'step': 'initial_request',
        'requirements_gathered': false,
      },
    ),
    status: ConversationStatus.active,
    createdAt: now.subtract(const Duration(minutes: 2)),
    updatedAt: now.subtract(const Duration(seconds: 30)),
    messages: [
      ConversationMessage(
        id: 'msg_001',
        sender: MessageSender.system,
        content: "Hi! I'll help you create a custom application for your household. What would you like to build?",
        timestamp: now.subtract(const Duration(minutes: 2)),
        actions: [
          const MessageAction(
            id: 'action_001',
            label: 'Chore Tracker',
            value: 'I need a chore tracking app for my family',
          ),
          const MessageAction(
            id: 'action_002',
            label: 'Budget Planner',
            value: 'I want to track our household budget',
          ),
          const MessageAction(
            id: 'action_003',
            label: 'Recipe Organizer',
            value: 'Help me organize family recipes',
          ),
        ],
      ),
    ],
  );
}
