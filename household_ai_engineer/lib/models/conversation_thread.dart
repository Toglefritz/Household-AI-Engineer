/// Conversation Thread Model
///
/// Represents a complete conversation thread between a user and the AI system
/// during application creation or modification.

import 'conversation_context.dart';
import 'conversation_message.dart';
import 'conversation_status.dart';

/// Represents a complete conversation thread for application creation.
///
/// Conversation threads maintain the complete history of interactions
/// between a user and the AI system during application development.
/// They provide context, track progress, and enable conversation
/// persistence across sessions.
///
/// Threads are the primary unit of conversation management and are
/// used throughout the conversational interface for state management.
class ConversationThread {
  /// Creates a new conversation thread.
  ///
  /// All parameters except [messages] are required to ensure complete
  /// thread information for proper conversation management.
  const ConversationThread({
    required this.id,
    required this.status,
    required this.context,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
  });

  /// Unique identifier for this conversation thread.
  ///
  /// Used to track conversations across sessions, correlate with
  /// backend processing, and manage conversation persistence.
  final String id;

  /// Current status of this conversation thread.
  ///
  /// Indicates the conversation lifecycle stage and determines
  /// available user actions and UI states.
  final ConversationStatus status;

  /// Context information for this conversation.
  ///
  /// Provides additional metadata that influences conversation
  /// behavior and system responses.
  final ConversationContext context;

  /// List of all messages in this conversation thread.
  ///
  /// Messages are ordered chronologically and form the complete
  /// conversation history. Used for display and context preservation.
  final List<ConversationMessage> messages;

  /// Timestamp when this conversation thread was created.
  ///
  /// Used for conversation sorting, cleanup, and analytics.
  /// Immutable after thread creation.
  final DateTime createdAt;

  /// Timestamp when this conversation thread was last updated.
  ///
  /// Updated whenever messages are added or thread status changes.
  /// Used for staleness detection and conversation management.
  final DateTime updatedAt;

  /// Creates a ConversationThread from JSON data.
  ///
  /// Parses thread data received from the backend conversation system
  /// and creates a properly typed thread object with validation.
  ///
  /// Throws [FormatException] if the JSON structure is invalid or
  /// required fields are missing.
  factory ConversationThread.fromJson(Map<String, dynamic> json) {
    try {
      return ConversationThread(
        id:
            json['id'] as String? ??
            (throw ArgumentError('Missing required field: id')),
        status: _parseStatus(json['status'] as String?),
        context: ConversationContext.fromJson(
          json['context'] as Map<String, dynamic>? ?? {},
        ),
        messages:
            (json['messages'] as List<dynamic>?)
                ?.map(
                  (message) => ConversationMessage.fromJson(
                    message as Map<String, dynamic>,
                  ),
                )
                .toList() ??
            [],
        createdAt: DateTime.parse(
          json['createdAt'] as String? ??
              (throw ArgumentError('Missing required field: createdAt')),
        ),
        updatedAt: DateTime.parse(
          json['updatedAt'] as String? ??
              (throw ArgumentError('Missing required field: updatedAt')),
        ),
      );
    } catch (e) {
      throw FormatException('Failed to parse ConversationThread from JSON: $e');
    }
  }

  /// Converts this thread to JSON format.
  ///
  /// Creates a JSON representation suitable for API communication
  /// and local storage with proper type conversion.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.name,
      'context': context.toJson(),
      'messages': messages.map((message) => message.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Creates a copy of this thread with updated fields.
  ///
  /// Allows updating specific fields while preserving others.
  /// Commonly used when adding messages or updating thread status.
  ConversationThread copyWith({
    String? id,
    ConversationStatus? status,
    ConversationContext? context,
    List<ConversationMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationThread(
      id: id ?? this.id,
      status: status ?? this.status,
      context: context ?? this.context,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Adds a new message to this conversation thread.
  ///
  /// Returns a new thread instance with the message added and
  /// updated timestamp. Does not modify the original thread.
  ConversationThread addMessage(ConversationMessage message) {
    final updatedMessages = List<ConversationMessage>.from(messages)
      ..add(message);

    return copyWith(messages: updatedMessages, updatedAt: DateTime.now());
  }

  /// Updates the status of this conversation thread.
  ///
  /// Returns a new thread instance with updated status and timestamp.
  /// Does not modify the original thread.
  ConversationThread updateStatus(ConversationStatus newStatus) {
    return copyWith(status: newStatus, updatedAt: DateTime.now());
  }

  /// Parses a conversation status string into the corresponding enum value.
  ///
  /// Handles case-insensitive parsing and provides clear error messages
  /// for invalid status values.
  static ConversationStatus _parseStatus(String? statusString) {
    if (statusString == null) {
      throw ArgumentError('Missing required field: status');
    }

    switch (statusString.toLowerCase()) {
      case 'active':
        return ConversationStatus.active;
      case 'ongoing':
        return ConversationStatus.ongoing;
      case 'waitingforuser':
      case 'waiting_for_user':
        return ConversationStatus.waitingForUser;
      case 'waitingforsystem':
      case 'waiting_for_system':
        return ConversationStatus.waitingForSystem;
      case 'completed':
        return ConversationStatus.completed;
      case 'cancelled':
        return ConversationStatus.cancelled;
      case 'failed':
        return ConversationStatus.failed;
      default:
        throw ArgumentError('Invalid conversation status: $statusString');
    }
  }

  /// Returns the most recent message in this conversation.
  ///
  /// Returns null if the conversation has no messages yet.
  /// Used for displaying conversation previews and determining next actions.
  ConversationMessage? get lastMessage {
    return messages.isNotEmpty ? messages.last : null;
  }

  /// Returns the number of messages in this conversation.
  ///
  /// Used for conversation analytics and UI display purposes.
  int get messageCount {
    return messages.length;
  }

  /// Returns the number of user messages in this conversation.
  ///
  /// Used for tracking user engagement and conversation complexity.
  int get userMessageCount {
    return messages.where((message) => message.isFromUser).length;
  }

  /// Returns the number of system messages in this conversation.
  ///
  /// Used for tracking system responses and conversation flow analysis.
  int get systemMessageCount {
    return messages.where((message) => message.isFromSystem).length;
  }

  /// Returns true if this conversation has any messages.
  ///
  /// Used to determine whether to show conversation history
  /// or initial conversation prompts.
  bool get hasMessages {
    return messages.isNotEmpty;
  }

  /// Returns true if this conversation is for modifying an existing application.
  ///
  /// Determined by the presence of an application ID in the conversation context.
  /// Used to customize conversation flow and system responses.
  bool get isModification {
    return context.applicationId != null;
  }

  /// Returns the duration of this conversation.
  ///
  /// Calculated as the time between creation and last update.
  /// Used for conversation analytics and timeout management.
  Duration get duration {
    return updatedAt.difference(createdAt);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConversationThread &&
        other.id == id &&
        other.status == status &&
        other.context == context &&
        other.messages.length == messages.length &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      status,
      context,
      messages.length,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'ConversationThread('
        'id: $id, '
        'status: $status, '
        'messages: ${messages.length}, '
        'createdAt: $createdAt'
        ')';
  }
}
