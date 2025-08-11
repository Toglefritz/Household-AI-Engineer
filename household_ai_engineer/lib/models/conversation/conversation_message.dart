import 'message_action.dart';
import 'message_sender.dart';

/// Represents a single message in a conversation thread.
///
/// Messages contain the core content of conversations between users and
/// the AI system, including text content, metadata, and optional actions
/// for interactive responses.
///
/// Messages are immutable once created and form the permanent record
/// of the conversation history.
class ConversationMessage {
  /// Creates a new conversation message.
  ///
  /// All parameters except [actions] are required to ensure complete
  /// message information for proper display and processing.
  const ConversationMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.actions,
  });

  /// Unique identifier for this message.
  ///
  /// Used to track message updates, handle user interactions,
  /// and maintain conversation state across system updates.
  final String id;

  /// Who sent this message (user or system).
  ///
  /// Determines message styling, positioning, and available
  /// actions in the conversation interface.
  final MessageSender sender;

  /// Text content of the message.
  ///
  /// The main message content displayed to users. May contain
  /// markdown formatting for rich text display.
  final String content;

  /// Timestamp when this message was created.
  ///
  /// Used for chronological ordering and displaying message
  /// timing information in the conversation interface.
  final DateTime timestamp;

  /// Optional list of actions attached to this message.
  ///
  /// Actions provide interactive elements like buttons or links
  /// that users can select to respond quickly or perform tasks.
  final List<MessageAction>? actions;

  /// Creates a ConversationMessage from JSON data.
  ///
  /// Parses message data received from the backend conversation system
  /// and creates a properly typed message object with validation.
  ///
  /// Throws [FormatException] if the JSON structure is invalid or
  /// required fields are missing.
  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    try {
      return ConversationMessage(
        id: json['id'] as String? ?? (throw ArgumentError('Missing required field: id')),
        sender: _parseSender(json['sender'] as String?),
        content: json['content'] as String? ?? (throw ArgumentError('Missing required field: content')),
        timestamp: DateTime.parse(
          json['timestamp'] as String? ?? (throw ArgumentError('Missing required field: timestamp')),
        ),
        actions: (json['actions'] as List<dynamic>?)
            ?.map((action) => MessageAction.fromJson(action as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      throw FormatException('Failed to parse ConversationMessage from JSON: $e');
    }
  }

  /// Converts this message to JSON format.
  ///
  /// Creates a JSON representation suitable for API communication
  /// and local storage with proper type conversion.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'actions': actions?.map((action) => action.toJson()).toList(),
    };
  }

  /// Creates a copy of this message with updated fields.
  ///
  /// Allows updating specific fields while preserving others.
  /// Note that messages should generally be immutable, so this
  /// method should be used sparingly.
  ConversationMessage copyWith({
    String? id,
    MessageSender? sender,
    String? content,
    DateTime? timestamp,
    List<MessageAction>? actions,
  }) {
    return ConversationMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      actions: actions ?? this.actions,
    );
  }

  /// Parses a message sender string into the corresponding enum value.
  ///
  /// Handles case-insensitive parsing and provides clear error messages
  /// for invalid sender values.
  static MessageSender _parseSender(String? senderString) {
    if (senderString == null) {
      throw ArgumentError('Missing required field: sender');
    }

    switch (senderString.toLowerCase()) {
      case 'user':
        return MessageSender.user;
      case 'system':
      case 'assistant':
        return MessageSender.system;
      default:
        throw ArgumentError('Invalid message sender: $senderString');
    }
  }

  /// Returns true if this message has interactive actions.
  ///
  /// Used to determine whether to display action buttons or
  /// other interactive elements in the conversation interface.
  bool get hasActions {
    return actions != null && actions!.isNotEmpty;
  }

  /// Returns true if this message is from the user.
  ///
  /// Convenience method for checking message sender without
  /// directly accessing the sender enum.
  bool get isFromUser {
    return sender.isUser;
  }

  /// Returns true if this message is from the system.
  ///
  /// Convenience method for checking message sender without
  /// directly accessing the sender enum.
  bool get isFromSystem {
    return sender.isSystem;
  }
}
