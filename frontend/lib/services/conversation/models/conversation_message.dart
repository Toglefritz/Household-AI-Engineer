import 'message_action.dart';
import 'message_sender.dart';

/// Represents a single message in a conversation thread.
///
/// Messages can be sent by either the user or the system, and may include
/// actions that the user can take in response to the message.
class ConversationMessage {
  /// Creates a new conversation message.
  ///
  /// @param id Unique identifier for this message
  /// @param sender Who sent this message (user or system)
  /// @param content The text content of the message
  /// @param timestamp When this message was sent
  /// @param actions Optional list of actions the user can take
  /// @param isTyping Whether this message represents a typing indicator
  const ConversationMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.actions = const [],
    this.isTyping = false,
  });

  /// Unique identifier for this message.
  ///
  /// Used for tracking, updates, and ensuring proper ordering
  /// in the conversation thread.
  final String id;

  /// Who sent this message.
  ///
  /// Determines the visual styling and positioning of the message
  /// in the conversation interface.
  final MessageSender sender;

  /// The text content of the message.
  ///
  /// Contains the actual message text that will be displayed
  /// to the user in the conversation interface.
  final String content;

  /// When this message was sent.
  ///
  /// Used for displaying timestamps and ordering messages
  /// chronologically in the conversation.
  final DateTime timestamp;

  /// Optional list of actions the user can take in response to this message.
  ///
  /// Actions are typically displayed as suggestion chips or buttons
  /// below system messages to provide quick response options.
  final List<MessageAction> actions;

  /// Whether this message represents a typing indicator.
  ///
  /// When true, this message should be displayed as a typing indicator
  /// rather than a regular message with content.
  final bool isTyping;

  /// Creates a ConversationMessage from JSON data.
  ///
  /// @param json Map containing the message data
  /// @returns ConversationMessage instance
  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      id: json['id'] as String,
      sender: MessageSender.values.firstWhere(
        (MessageSender sender) => sender.name == json['sender'],
      ),
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      actions:
          (json['actions'] as List<dynamic>?)
              ?.map((dynamic action) => MessageAction.fromJson(action as Map<String, dynamic>))
              .toList() ??
          [],
      isTyping: json['isTyping'] as bool? ?? false,
    );
  }

  /// Converts this message to JSON format.
  ///
  /// @returns Map containing the message data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'actions': actions.map((MessageAction action) => action.toJson()).toList(),
      'isTyping': isTyping,
    };
  }

  /// Creates a copy of this message with updated fields.
  ///
  /// @param id Optional new ID
  /// @param sender Optional new sender
  /// @param content Optional new content
  /// @param timestamp Optional new timestamp
  /// @param actions Optional new actions list
  /// @param isTyping Optional new typing indicator state
  /// @returns New ConversationMessage with updated fields
  ConversationMessage copyWith({
    String? id,
    MessageSender? sender,
    String? content,
    DateTime? timestamp,
    List<MessageAction>? actions,
    bool? isTyping,
  }) {
    return ConversationMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      actions: actions ?? this.actions,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  /// Returns true if this message has actions.
  ///
  /// Convenience method for checking if actions should be displayed.
  bool get hasActions => actions.isNotEmpty;

  /// Returns true if this is a user message.
  ///
  /// Convenience method for checking message origin.
  bool get isUserMessage => sender.isUser;

  /// Returns true if this is a system message.
  ///
  /// Convenience method for checking message origin.
  bool get isSystemMessage => sender.isSystem;

  /// Returns a formatted timestamp string for display.
  ///
  /// Provides a human-readable time format suitable for the UI.
  String get formattedTimestamp {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(timestamp);

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
}
