/// Enumeration representing who sent a conversation message.
///
/// Used to distinguish between user messages and system responses
/// in the conversational interface for application creation.
enum MessageSender {
  /// Message sent by the user.
  ///
  /// Represents user input, requests, and responses to system questions.
  user,

  /// Message sent by the system/assistant.
  ///
  /// Represents system responses, clarifying questions, and guidance.
  system,
}

/// Extension methods for [MessageSender] enum.
///
/// Provides utility methods for working with message sender values.
extension MessageSenderExtension on MessageSender {
  /// Returns a human-readable display name for the sender.
  ///
  /// Used for accessibility and debugging purposes.
  String get displayName {
    switch (this) {
      case MessageSender.user:
        return 'User';
      case MessageSender.system:
        return 'System';
    }
  }

  /// Returns true if this is a user message.
  ///
  /// Convenience method for checking message origin.
  bool get isUser => this == MessageSender.user;

  /// Returns true if this is a system message.
  ///
  /// Convenience method for checking message origin.
  bool get isSystem => this == MessageSender.system;
}
