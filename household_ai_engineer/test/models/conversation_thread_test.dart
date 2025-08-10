/// Unit tests for ConversationThread model and related classes.
///
/// Tests model creation, JSON serialization/deserialization, validation,
/// and all utility methods to ensure reliable conversation thread management.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/models/models.dart';

void main() {
  group('ConversationStatus', () {
    test('should have all expected status values', () {
      expect(ConversationStatus.values, hasLength(7));
      expect(ConversationStatus.values, contains(ConversationStatus.active));
      expect(ConversationStatus.values, contains(ConversationStatus.ongoing));
      expect(ConversationStatus.values, contains(ConversationStatus.waitingForUser));
      expect(ConversationStatus.values, contains(ConversationStatus.waitingForSystem));
      expect(ConversationStatus.values, contains(ConversationStatus.completed));
      expect(ConversationStatus.values, contains(ConversationStatus.cancelled));
      expect(ConversationStatus.values, contains(ConversationStatus.failed));
    });

    test('should return correct display names', () {
      expect(ConversationStatus.active.displayName, equals('Active'));
      expect(ConversationStatus.ongoing.displayName, equals('Ongoing'));
      expect(ConversationStatus.waitingForUser.displayName, equals('Waiting for Response'));
      expect(ConversationStatus.waitingForSystem.displayName, equals('Processing'));
      expect(ConversationStatus.completed.displayName, equals('Completed'));
      expect(ConversationStatus.cancelled.displayName, equals('Cancelled'));
      expect(ConversationStatus.failed.displayName, equals('Failed'));
    });

    test('should identify active states correctly', () {
      expect(ConversationStatus.active.isActive, isTrue);
      expect(ConversationStatus.ongoing.isActive, isTrue);
      expect(ConversationStatus.waitingForUser.isActive, isTrue);
      expect(ConversationStatus.waitingForSystem.isActive, isTrue);
      expect(ConversationStatus.completed.isActive, isFalse);
      expect(ConversationStatus.cancelled.isActive, isFalse);
      expect(ConversationStatus.failed.isActive, isFalse);
    });

    test('should identify terminal states correctly', () {
      expect(ConversationStatus.completed.isTerminal, isTrue);
      expect(ConversationStatus.cancelled.isTerminal, isTrue);
      expect(ConversationStatus.failed.isTerminal, isTrue);
      expect(ConversationStatus.active.isTerminal, isFalse);
      expect(ConversationStatus.ongoing.isTerminal, isFalse);
      expect(ConversationStatus.waitingForUser.isTerminal, isFalse);
      expect(ConversationStatus.waitingForSystem.isTerminal, isFalse);
    });

    test('should identify waiting for user states correctly', () {
      expect(ConversationStatus.active.isWaitingForUser, isTrue);
      expect(ConversationStatus.waitingForUser.isWaitingForUser, isTrue);
      expect(ConversationStatus.ongoing.isWaitingForUser, isFalse);
      expect(ConversationStatus.waitingForSystem.isWaitingForUser, isFalse);
    });

    test('should identify processing state correctly', () {
      expect(ConversationStatus.waitingForSystem.isProcessing, isTrue);
      expect(ConversationStatus.active.isProcessing, isFalse);
      expect(ConversationStatus.ongoing.isProcessing, isFalse);
      expect(ConversationStatus.waitingForUser.isProcessing, isFalse);
    });
  });

  group('ConversationContext', () {
    final testContext = ConversationContext(
      applicationId: 'app_123',
      userId: 'user_456',
      sessionId: 'session_789',
      metadata: {'key': 'value'},
    );

    test('should create context with all optional fields', () {
      expect(testContext.applicationId, equals('app_123'));
      expect(testContext.userId, equals('user_456'));
      expect(testContext.sessionId, equals('session_789'));
      expect(testContext.metadata, equals({'key': 'value'}));
    });

    test('should create context with null fields', () {
      const emptyContext = ConversationContext();
      expect(emptyContext.applicationId, isNull);
      expect(emptyContext.userId, isNull);
      expect(emptyContext.sessionId, isNull);
      expect(emptyContext.metadata, isNull);
    });

    test('should create context from JSON', () {
      final json = {
        'applicationId': 'app_test',
        'userId': 'user_test',
        'sessionId': 'session_test',
        'metadata': {'test': 'data'},
      };

      final context = ConversationContext.fromJson(json);

      expect(context.applicationId, equals('app_test'));
      expect(context.userId, equals('user_test'));
      expect(context.sessionId, equals('session_test'));
      expect(context.metadata, equals({'test': 'data'}));
    });

    test('should convert context to JSON correctly', () {
      final json = testContext.toJson();

      expect(json['applicationId'], equals('app_123'));
      expect(json['userId'], equals('user_456'));
      expect(json['sessionId'], equals('session_789'));
      expect(json['metadata'], equals({'key': 'value'}));
    });
  });

  group('ConversationThread', () {
    final testMessages = [
      ConversationMessage(
        id: 'message_1',
        sender: MessageSender.user,
        content: 'I want to create a chore tracker',
        timestamp: DateTime(2025, 1, 10, 14, 0),
      ),
      ConversationMessage(
        id: 'message_2',
        sender: MessageSender.system,
        content: 'Great! Let me ask you a few questions.',
        timestamp: DateTime(2025, 1, 10, 14, 1),
      ),
    ];

    final testContext = ConversationContext(userId: 'user_123', sessionId: 'session_456');

    final testThread = ConversationThread(
      id: 'thread_123',
      status: ConversationStatus.ongoing,
      context: testContext,
      messages: testMessages,
      createdAt: DateTime(2025, 1, 10, 14, 0),
      updatedAt: DateTime(2025, 1, 10, 14, 1),
    );

    test('should create thread with all required fields', () {
      expect(testThread.id, equals('thread_123'));
      expect(testThread.status, equals(ConversationStatus.ongoing));
      expect(testThread.context, equals(testContext));
      expect(testThread.messages, hasLength(2));
      expect(testThread.createdAt, equals(DateTime(2025, 1, 10, 14, 0)));
      expect(testThread.updatedAt, equals(DateTime(2025, 1, 10, 14, 1)));
    });

    test('should return last message correctly', () {
      final lastMessage = testThread.lastMessage;
      expect(lastMessage, isNotNull);
      expect(lastMessage!.id, equals('message_2'));
      expect(lastMessage.sender, equals(MessageSender.system));
    });

    test('should return null for empty thread', () {
      final emptyThread = testThread.copyWith(messages: []);
      expect(emptyThread.lastMessage, isNull);
    });

    test('should count messages correctly', () {
      expect(testThread.messageCount, equals(2));
      expect(testThread.userMessageCount, equals(1));
      expect(testThread.systemMessageCount, equals(1));
    });

    test('should detect messages correctly', () {
      expect(testThread.hasMessages, isTrue);

      final emptyThread = testThread.copyWith(messages: []);
      expect(emptyThread.hasMessages, isFalse);
    });

    test('should detect modification correctly', () {
      expect(testThread.isModification, isFalse);

      final modificationThread = testThread.copyWith(context: testContext.copyWith(applicationId: 'existing_app'));
      expect(modificationThread.isModification, isTrue);
    });

    test('should calculate duration correctly', () {
      final duration = testThread.duration;
      expect(duration, equals(Duration(minutes: 1)));
    });

    test('should add message correctly', () {
      final newMessage = ConversationMessage(
        id: 'message_3',
        sender: MessageSender.user,
        content: 'Yes, please continue',
        timestamp: DateTime(2025, 1, 10, 14, 2),
      );

      final updatedThread = testThread.addMessage(newMessage);

      expect(updatedThread.messages, hasLength(3));
      expect(updatedThread.messages.last, equals(newMessage));
      expect(updatedThread.updatedAt.isAfter(testThread.updatedAt), isTrue);
    });

    test('should update status correctly', () {
      final updatedThread = testThread.updateStatus(ConversationStatus.completed);

      expect(updatedThread.status, equals(ConversationStatus.completed));
      expect(updatedThread.updatedAt.isAfter(testThread.updatedAt), isTrue);
    });

    test('should create thread from JSON', () {
      final json = {
        'id': 'thread_456',
        'status': 'active',
        'context': {'userId': 'user_test', 'sessionId': 'session_test'},
        'messages': [
          {'id': 'message_test', 'sender': 'user', 'content': 'Test message', 'timestamp': '2025-01-10T14:00:00.000Z'},
        ],
        'createdAt': '2025-01-10T14:00:00.000Z',
        'updatedAt': '2025-01-10T14:01:00.000Z',
      };

      final thread = ConversationThread.fromJson(json);

      expect(thread.id, equals('thread_456'));
      expect(thread.status, equals(ConversationStatus.active));
      expect(thread.messages, hasLength(1));
    });

    test('should convert thread to JSON correctly', () {
      final json = testThread.toJson();

      expect(json['id'], equals('thread_123'));
      expect(json['status'], equals('ongoing'));
      expect(json['context'], isA<Map<String, dynamic>>());
      expect(json['messages'], hasLength(2));
      expect(json['createdAt'], equals('2025-01-10T14:00:00.000'));
      expect(json['updatedAt'], equals('2025-01-10T14:01:00.000'));
    });
  });
}
