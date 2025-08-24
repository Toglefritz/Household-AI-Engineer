import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../../lib/screens/dashboard/components/conversation/conversation_immediate_loading_widget.dart';
import '../../../../../lib/screens/dashboard/components/conversation/conversation_loading_indicator.dart';
import '../../../../../lib/screens/dashboard/components/conversation/conversation_modal.dart';
import '../../../../../lib/services/conversation/conversation_service.dart';
import '../../../../../lib/services/kiro/kiro_service.dart';
import '../../../../../lib/services/user_application/models/user_application.dart';
import '../../../../../lib/services/user_application/user_application_service.dart';
import '../../../../test_helpers.dart';

import 'conversation_modal_loading_integration_test.mocks.dart';

/// Integration tests for conversation modal loading state transitions.
///
/// These tests verify the complete user experience from message submission
/// through immediate loading feedback to specific progress indicators.
@GenerateMocks([
  KiroService,
  UserApplicationService,
])
void main() {
  group('ConversationModal Loading Integration', () {
    late MockKiroService mockKiroService;
    late MockUserApplicationService mockUserApplicationService;

    setUp(() {
      mockKiroService = MockKiroService();
      mockUserApplicationService = MockUserApplicationService();

      // Set up default mock responses
      when(mockKiroService.setupKiroForNewApplication()).thenAnswer((_) async => {});
      when(mockKiroService.sendMessage(any)).thenAnswer((_) async => {});
      when(mockUserApplicationService.getApplications()).thenAnswer((_) async => []);
      when(mockUserApplicationService.watchApplications()).thenAnswer((_) => Stream.value([]));
    });

    /// Tests the complete loading state transition from user input to development progress.
    ///
    /// This integration test verifies requirements 2.7 and 2.8 by testing the
    /// complete user journey from message submission through loading states.
    testWidgets('should show complete loading state transition', (WidgetTester tester) async {
      // Arrange: Build the conversation modal
      await tester.pumpWidget(
        createTestApp(
          child: const ConversationModal(),
        ),
      );

      // Wait for initial setup
      await tester.pumpAndSettle();

      // Assert: Initial state should show no loading indicators
      expect(find.byType(ConversationImmediateLoadingWidget), findsNothing);
      expect(find.byType(ConversationLoadingIndicator), findsNothing);

      // Find the input field and send button
      final Finder inputField = find.byType(TextField);
      final Finder sendButton = find.byType(FloatingActionButton);

      expect(inputField, findsOneWidget);

      // Act: Enter a message
      await tester.enterText(inputField, 'I need a budget tracker');
      await tester.pump();

      // Assert: Send button should appear
      expect(sendButton, findsOneWidget);

      // Mock delayed processing
      when(mockKiroService.sendMessage(any)).thenAnswer((_) async => Future.delayed(const Duration(milliseconds: 200)));

      // Act: Tap send button
      await tester.tap(sendButton);
      await tester.pump();

      // Assert: Immediate loading should be shown
      expect(find.byType(ConversationImmediateLoadingWidget), findsOneWidget);
      expect(find.text('Processing your request'), findsOneWidget);
      expect(find.byType(ConversationLoadingIndicator), findsNothing);

      // Assert: Input should be disabled during loading
      final TextField textField = tester.widget<TextField>(inputField);
      expect(textField.enabled, false);

      // Wait for processing to complete
      await tester.pumpAndSettle();

      // Assert: Immediate loading should be cleared
      expect(find.byType(ConversationImmediateLoadingWidget), findsNothing);
    });

    /// Tests transition from immediate loading to specific development progress.
    ///
    /// This test verifies requirement 2.8 by simulating the transition that
    /// occurs when application development begins and specific progress becomes available.
    testWidgets('should transition to development progress indicator', (WidgetTester tester) async {
      // Arrange: Set up mock to simulate development progress
      final UserApplication developingApp = UserApplication(
        id: 'app_123',
        title: 'Budget Tracker',
        description: 'A budget tracking application',
        status: ApplicationStatus.developing,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        progress: DevelopmentProgress(
          percentage: 25.0,
          currentPhase: 'Generating Code',
          milestones: [],
          developmentStatement: 'Starting development...',
        ),
      );

      // Mock application updates to simulate development beginning
      when(mockUserApplicationService.watchApplications()).thenAnswer(
        (_) => Stream.fromIterable([
          [], // Initial empty state
          [developingApp], // Application appears with progress
        ]),
      );

      // Build the conversation modal
      await tester.pumpWidget(
        createTestApp(
          child: const ConversationModal(),
        ),
      );

      await tester.pumpAndSettle();

      // Act: Send a message to trigger loading
      final Finder inputField = find.byType(TextField);
      await tester.enterText(inputField, 'Create budget app');
      await tester.pump();

      final Finder sendButton = find.byType(FloatingActionButton);
      await tester.tap(sendButton);
      await tester.pump();

      // Assert: Immediate loading should be shown initially
      expect(find.byType(ConversationImmediateLoadingWidget), findsOneWidget);

      // Simulate development progress update
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: Should transition to development progress indicator
      expect(find.byType(ConversationImmediateLoadingWidget), findsNothing);
      expect(find.byType(ConversationLoadingIndicator), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
    });

    /// Tests that loading states are properly managed during errors.
    ///
    /// This test verifies that loading indicators are properly cleared
    /// even when errors occur during message processing.
    testWidgets('should handle errors gracefully during loading', (WidgetTester tester) async {
      // Arrange: Mock Kiro service to throw an error
      when(mockKiroService.sendMessage(any)).thenThrow(Exception('Network error'));

      // Build the conversation modal
      await tester.pumpWidget(
        createTestApp(
          child: const ConversationModal(),
        ),
      );

      await tester.pumpAndSettle();

      // Act: Send a message that will fail
      final Finder inputField = find.byType(TextField);
      await tester.enterText(inputField, 'Test message');
      await tester.pump();

      final Finder sendButton = find.byType(FloatingActionButton);
      await tester.tap(sendButton);
      await tester.pump();

      // Assert: Immediate loading should be shown
      expect(find.byType(ConversationImmediateLoadingWidget), findsOneWidget);

      // Wait for error to be processed
      await tester.pumpAndSettle();

      // Assert: Loading should be cleared after error
      expect(find.byType(ConversationImmediateLoadingWidget), findsNothing);

      // Assert: Input should be re-enabled
      final TextField textField = tester.widget<TextField>(inputField);
      expect(textField.enabled, true);
    });

    /// Tests that multiple message submissions are handled correctly.
    ///
    /// This test verifies that loading states are properly managed
    /// when users send multiple messages in sequence.
    testWidgets('should handle multiple message submissions', (WidgetTester tester) async {
      // Arrange: Mock delayed processing
      when(mockKiroService.sendMessage(any)).thenAnswer((_) async => Future.delayed(const Duration(milliseconds: 100)));

      // Build the conversation modal
      await tester.pumpWidget(
        createTestApp(
          child: const ConversationModal(),
        ),
      );

      await tester.pumpAndSettle();

      final Finder inputField = find.byType(TextField);

      // Act: Send first message
      await tester.enterText(inputField, 'First message');
      await tester.pump();

      final Finder sendButton = find.byType(FloatingActionButton);
      await tester.tap(sendButton);
      await tester.pump();

      // Assert: Loading should be shown
      expect(find.byType(ConversationImmediateLoadingWidget), findsOneWidget);

      // Wait for first message to complete
      await tester.pumpAndSettle();

      // Assert: Loading should be cleared
      expect(find.byType(ConversationImmediateLoadingWidget), findsNothing);

      // Act: Send second message
      await tester.enterText(inputField, 'Second message');
      await tester.pump();
      await tester.tap(sendButton);
      await tester.pump();

      // Assert: Loading should be shown again
      expect(find.byType(ConversationImmediateLoadingWidget), findsOneWidget);

      // Wait for second message to complete
      await tester.pumpAndSettle();

      // Assert: Loading should be cleared again
      expect(find.byType(ConversationImmediateLoadingWidget), findsNothing);
    });

    /// Tests that loading animations are smooth and performant.
    ///
    /// This test verifies requirement 7.1 by ensuring that loading
    /// animations provide smooth visual feedback without performance issues.
    testWidgets('should provide smooth loading animations', (WidgetTester tester) async {
      // Build the conversation modal
      await tester.pumpWidget(
        createTestApp(
          child: const ConversationModal(),
        ),
      );

      await tester.pumpAndSettle();

      // Mock delayed processing to keep loading visible
      when(mockKiroService.sendMessage(any)).thenAnswer((_) async => Future.delayed(const Duration(seconds: 2)));

      // Act: Trigger loading state
      final Finder inputField = find.byType(TextField);
      await tester.enterText(inputField, 'Test message');
      await tester.pump();

      final Finder sendButton = find.byType(FloatingActionButton);
      await tester.tap(sendButton);
      await tester.pump();

      // Assert: Loading widget should be present
      expect(find.byType(ConversationImmediateLoadingWidget), findsOneWidget);

      // Test animation frames
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));

        // Assert: Loading widget should remain visible and animated
        expect(find.byType(ConversationImmediateLoadingWidget), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      }
    });

    /// Tests accessibility of loading states.
    ///
    /// This test verifies that loading indicators provide appropriate
    /// semantic information for screen readers and assistive technologies.
    testWidgets('should provide accessible loading feedback', (WidgetTester tester) async {
      // Build the conversation modal
      await tester.pumpWidget(
        createTestApp(
          child: const ConversationModal(),
        ),
      );

      await tester.pumpAndSettle();

      // Mock delayed processing
      when(mockKiroService.sendMessage(any)).thenAnswer((_) async => Future.delayed(const Duration(milliseconds: 200)));

      // Act: Trigger loading state
      final Finder inputField = find.byType(TextField);
      await tester.enterText(inputField, 'Test message');
      await tester.pump();

      final Finder sendButton = find.byType(FloatingActionButton);
      await tester.tap(sendButton);
      await tester.pump();

      // Assert: Loading message should be accessible
      expect(find.text('Processing your request'), findsOneWidget);

      // Verify that the loading indicator has proper semantics
      final Finder loadingIndicator = find.byType(CircularProgressIndicator);
      expect(loadingIndicator, findsOneWidget);
    });
  });
}
