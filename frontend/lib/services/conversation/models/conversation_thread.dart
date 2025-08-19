import 'conversation_context.dart';
import 'conversation_message.dart';
import 'conversation_status.dart';

/// Represents a complete conversation thread for application creation or modification.
///
/// Contains all messages, context, and state information for a conversation
/// between the user and the system.
class ConversationThread {
  /// Creates a new conversation thread.
  ///
  /// @param id Unique identifier for this conversation
  /// @param messages List of messages in chronological order
  /// @param context Context and metadata for this conversation
  /// @param status Current status of the conversation
  /// @param createdAt When this conversation was started
  /// @param updatedAt When this conversation was last updated
  const ConversationThread({
    required this.id,
    required this.messages,
    required this.context,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique identifier for this conversation thread.
  ///
  /// Used for tracking, persistence, and referencing the conversation
  /// across different parts of the system.
  final String id;

  /// List of messages in chronological order.
  ///
  /// Contains all messages exchanged between the user and system
  /// during this conversation.
  final List<ConversationMessage> messages;

  /// Context and metadata for this conversation.
  ///
  /// Contains information about the conversation's purpose and
  /// any relevant context that should be preserved.
  final ConversationContext context;

  /// Current status of the conversation.
  ///
  /// Indicates whether the conversation is active, processing,
  /// completed, or in another state.
  final ConversationStatus status;

  /// When this conversation was started.
  ///
  /// Used for sorting conversations and displaying creation time.
  final DateTime createdAt;

  /// When this conversation was last updated.
  ///
  /// Updated whenever a new message is added or the status changes.
  final DateTime updatedAt;

  /// Creates a ConversationThread from JSON data.
  ///
  /// @param json Map containing the conversation data
  /// @returns ConversationThread instance
  factory ConversationThread.fromJson(Map<String, dynamic> json) {
    return ConversationThread(
      id: json['id'] as String,
      messages: (json['messages'] as List<dynamic>)
          .map((dynamic message) => ConversationMessage.fromJson(message as Map<String, dynamic>))
          .toList(),
      context: ConversationContext.fromJson(json['context'] as Map<String, dynamic>),
      status: ConversationStatus.values.firstWhere(
        (ConversationStatus status) => status.name == json['status'],
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Converts this conversation thread to JSON format.
  ///
  /// @returns Map containing the conversation data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'messages': messages.map((ConversationMessage message) => message.toJson()).toList(),
      'context': context.toJson(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Creates a copy of this conversation thread with updated fields.
  ///
  /// @param id Optional new ID
  /// @param messages Optional new messages list
  /// @param context Optional new context
  /// @param status Optional new status
  /// @param createdAt Optional new creation time
  /// @param updatedAt Optional new update time
  /// @returns New ConversationThread with updated fields
  ConversationThread copyWith({
    String? id,
    List<ConversationMessage>? messages,
    ConversationContext? context,
    ConversationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationThread(
      id: id ?? this.id,
      messages: messages ?? this.messages,
      context: context ?? this.context,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Adds a new message to the conversation.
  ///
  /// @param message The message to add
  /// @returns New ConversationThread with the added message
  ConversationThread addMessage(ConversationMessage message) {
    final List<ConversationMessage> newMessages = List<ConversationMessage>.from(messages)
    ..add(message);

    return copyWith(
      messages: newMessages,
      updatedAt: DateTime.now(),
    );
  }

  /// Updates the conversation status.
  ///
  /// @param newStatus The new status to set
  /// @returns New ConversationThread with updated status
  ConversationThread updateStatus(ConversationStatus newStatus) {
    return copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
  }

  /// Updates the conversation context.
  ///
  /// @param newContext The new context to set
  /// @returns New ConversationThread with updated context
  ConversationThread updateContext(ConversationContext newContext) {
    return copyWith(
      context: newContext,
      updatedAt: DateTime.now(),
    );
  }

  /// Returns the most recent message in the conversation.
  ///
  /// @returns The last message or null if no messages exist
  ConversationMessage? get lastMessage {
    return messages.isNotEmpty ? messages.last : null;
  }

  /// Returns the most recent user message in the conversation.
  ///
  /// @returns The last user message or null if none exist
  ConversationMessage? get lastUserMessage {
    return messages.reversed.firstWhere(
      (ConversationMessage message) => message.isUserMessage,
      orElse: () => throw StateError('No user messages found'),
    );
  }

  /// Returns the most recent system message in the conversation.
  ///
  /// @returns The last system message or null if none exist
  ConversationMessage? get lastSystemMessage {
    return messages.reversed.firstWhere(
      (ConversationMessage message) => message.isSystemMessage,
      orElse: () => throw StateError('No system messages found'),
    );
  }

  /// Returns true if the conversation has any messages.
  ///
  /// Convenience method for checking if the conversation has started.
  bool get hasMessages => messages.isNotEmpty;

  /// Returns true if the conversation is empty.
  ///
  /// Convenience method for checking if no messages have been sent.
  bool get isEmpty => messages.isEmpty;

  /// Returns the number of messages in the conversation.
  ///
  /// Convenience method for getting message count.
  int get messageCount => messages.length;

  /// Returns true if the conversation can accept new messages.
  ///
  /// Based on the current conversation status.
  bool get canAcceptMessages => status.canAcceptInput;

  /// Returns true if the conversation can be cancelled.
  ///
  /// Based on the current conversation status.
  bool get canCancel => status.canCancel;

  /// Returns a formatted string describing when this conversation was created.
  ///
  /// Provides human-readable creation time information.
  String get createdTimeDescription {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Returns a formatted string describing when this conversation was last updated.
  ///
  /// Provides human-readable update time information.
  String get updatedTimeDescription {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(updatedAt);

    if (difference.inDays > 0) {
      return 'Updated ${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return 'Updated ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return 'Updated ${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just updated';
    }
  }
}
