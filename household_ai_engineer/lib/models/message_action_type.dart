/// Message Action Type Enumeration
///
/// Defines types of actions that can be attached to conversation messages.

/// Types of actions that can be attached to conversation messages.
///
/// Different action types have different visual styling and behavior
/// in the conversation interface.
enum MessageActionType {
  /// Quick response action that sends a predefined message.
  ///
  /// Allows users to respond to questions with common answers
  /// without typing the full response.
  response,

  /// Suggestion action that provides helpful guidance.
  ///
  /// Offers suggestions or examples to help users formulate
  /// better requests or understand available options.
  suggestion,

  /// Confirmation action for yes/no or approval decisions.
  ///
  /// Used when the system needs explicit user confirmation
  /// before proceeding with an action.
  confirmation,

  /// Navigation action that changes the conversation flow.
  ///
  /// Allows users to restart conversations, go back to previous
  /// steps, or navigate to different conversation contexts.
  navigation,
}

/// Extension methods for MessageActionType enum.
///
/// Provides utility methods for working with action type values,
/// including display formatting and UI behavior.
extension MessageActionTypeExtension on MessageActionType {
  /// Returns a human-readable display name for the action type.
  ///
  /// These names are suitable for accessibility labels and
  /// debugging purposes.
  String get displayName {
    switch (this) {
      case MessageActionType.response:
        return 'Response';
      case MessageActionType.suggestion:
        return 'Suggestion';
      case MessageActionType.confirmation:
        return 'Confirmation';
      case MessageActionType.navigation:
        return 'Navigation';
    }
  }

  /// Returns true if this action type requires immediate processing.
  ///
  /// Some action types like confirmations should be processed
  /// immediately when selected, while others may queue responses.
  bool get requiresImmediateProcessing {
    return this == MessageActionType.confirmation ||
        this == MessageActionType.navigation;
  }
}
