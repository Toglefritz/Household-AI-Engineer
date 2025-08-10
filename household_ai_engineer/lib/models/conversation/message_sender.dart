/// Identifies who sent a conversation message.
///
/// Used to determine message styling, positioning, and available actions
/// in the conversational interface.
enum MessageSender {
  /// Message sent by the human user.
  ///
  /// User messages contain requests, responses to questions, and
  /// clarifications about application requirements.
  user,

  /// Message sent by the AI system.
  ///
  /// System messages include questions, confirmations, progress updates,
  /// and responses to user requests.
  system,
}

/// Extension methods for MessageSender enum.
///
/// Provides utility methods for working with message sender values,
/// including display formatting and UI behavior.
extension MessageSenderExtension on MessageSender {
  /// Returns a human-readable display name for the message sender.
  ///
  /// These names are suitable for display in conversation interfaces
  /// and follow consistent terminology conventions.
  String get displayName {
    switch (this) {
      case MessageSender.user:
        return 'You';
      case MessageSender.system:
        return 'Assistant';
    }
  }

  /// Returns true if this sender represents the human user.
  ///
  /// Used for message styling and positioning in the conversation interface.
  bool get isUser {
    return this == MessageSender.user;
  }

  /// Returns true if this sender represents the AI system.
  ///
  /// Used for message styling and determining available message actions.
  bool get isSystem {
    return this == MessageSender.system;
  }
}
