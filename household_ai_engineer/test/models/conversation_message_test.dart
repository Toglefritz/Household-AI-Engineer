/// Unit tests for ConversationMessage model and related classes.
///
/// Tests model creation, JSON serialization/deserialization, validation,
/// and all utility methods to ensure reliable conversation handling.

import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/models/conversation_message.dart';

void main() {
  group('MessageSender', () {
    test('should have all expected sender values', () {
      expect(MessageSender.values, hasLength(2));
      expect(MessageSender.values, contains(MessageSender.user));
      expect(MessageSender.values, contains(MessageSender.system));
    });

    test('should return correct display names', () {
      expect(MessageSender.user.displayName, equals('You'));
      expect(MessageSender.system.displayName, equals('Assistant'));
    });

    test('should identify user correctly', () {
      expect(MessageSender.user.isUser, isTrue);
      expect(MessageSender.system.isUser, isFalse);
    });

    test('should identify system correctly', () {
      expect(MessageSender.system.isSystem, isTrue);
      expect(MessageSender.user.isSystem, isFalse);
    });
  });

  group('MessageActionType', () {
    test('should have all expected action types', () {
      expect(MessageActionType.values, hasLength(4));
      expect(MessageActionType.values, contains(MessageActionType.response));
      expect(MessageActionType.values, contains(MessageActionType.suggestion));
      expect(
        MessageActionType.values,
        contains(MessageActionType.confirmation),
      );
      expect(MessageActionType.values, contains(MessageActionType.navigation));
    });

    test('should return correct display names', () {
      expect(MessageActionType.response.displayName, equals('Response'));
      expect(MessageActionType.suggestion.displayName, equals('Suggestion'));
      expect(
        MessageActionType.confirmation.displayName,
        equals('Confirmation'),
      );
      expect(MessageActionType.navigation.displayName, equals('Navigation'));
    });

    test('should identify immediate processing types', () {
      expect(
        MessageActionType.confirmation.requiresImmediateProcessing,
        isTrue,
      );
      expect(MessageActionType.navigation.requiresImmediateProcessing, isTrue);
      expect(MessageActionType.response.requiresImmediateProcessing, isFalse);
      expect(MessageActionType.suggestion.requiresImmediateProcessing, isFalse);
    });
  });

  group('MessageAction', () {
    final testAction = MessageAction(
      id: 'action_123',
      label: 'Yes, continue',
      type: MessageActionType.confirmation,
      value: 'confirm_continue',
    );

    test('should create action with all required fields', () {
      expect(testAction.id, equals('action_123'));
      expect(testAction.label, equals('Yes, continue'));
      expect(testAction.type, equals(MessageActionType.confirmation));
      expect(testAction.value, equals('confirm_continue'));
    });

    test('should create action from valid JSON', () {
      final json = {
        'id': 'action_456',
        'label': 'Tell me more',
        'type': 'suggestion',
        'value': 'request_details',
      };

      final action = MessageAction.fromJson(json);

      expect(action.id, equals('action_456'));
      expect(action.label, equals('Tell me more'));
      expect(action.type, equals(MessageActionType.suggestion));
      expect(action.value, equals('request_details'));
    });

    test('should convert action to JSON correctly', () {
      final json = testAction.toJson();

      expect(json['id'], equals('action_123'));
      expect(json['label'], equals('Yes, continue'));
      expect(json['type'], equals('confirmation'));
      expect(json['value'], equals('confirm_continue'));
    });
  });

  group('ConversationMessage', () {
    final testMessage = ConversationMessage(
      id: 'message_123',
      sender: MessageSender.system,
      content: 'Would you like to proceed?',
      timestamp: DateTime(2025, 1, 10, 14, 30),
    );

    test('should create message with required fields', () {
      expect(testMessage.id, equals('message_123'));
      expect(testMessage.sender, equals(MessageSender.system));
      expect(testMessage.content, equals('Would you like to proceed?'));
      expect(testMessage.timestamp, equals(DateTime(2025, 1, 10, 14, 30)));
    });

    test('should identify sender correctly', () {
      expect(testMessage.isFromUser, isFalse);
      expect(testMessage.isFromSystem, isTrue);

      final userMessage = ConversationMessage(
        id: 'user_message',
        sender: MessageSender.user,
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      expect(userMessage.isFromUser, isTrue);
      expect(userMessage.isFromSystem, isFalse);
    });

    test('should create message from valid JSON', () {
      final json = {
        'id': 'message_456',
        'sender': 'user',
        'content': 'I need help',
        'timestamp': '2025-01-10T14:30:00.000Z',
      };

      final message = ConversationMessage.fromJson(json);

      expect(message.id, equals('message_456'));
      expect(message.sender, equals(MessageSender.user));
      expect(message.content, equals('I need help'));
      expect(
        message.timestamp,
        equals(DateTime.parse('2025-01-10T14:30:00.000Z')),
      );
    });

    test('should convert message to JSON correctly', () {
      final json = testMessage.toJson();

      expect(json['id'], equals('message_123'));
      expect(json['sender'], equals('system'));
      expect(json['content'], equals('Would you like to proceed?'));
      expect(json['timestamp'], equals('2025-01-10T14:30:00.000'));
    });
  });
}
