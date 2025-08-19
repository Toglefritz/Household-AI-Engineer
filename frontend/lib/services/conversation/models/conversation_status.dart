/// Enumeration representing the current status of a conversation thread.
///
/// Used to track the conversation state and determine what actions
/// are available to the user.
enum ConversationStatus {
  /// Conversation is active and ongoing.
  ///
  /// User can send messages and the system can respond.
  active,

  /// Conversation is waiting for user input.
  ///
  /// System has asked a question or provided options and is
  /// waiting for the user to respond.
  waitingForInput,

  /// Conversation is being processed by the system.
  ///
  /// System is analyzing user input or generating a response.
  /// User input may be disabled during this state.
  processing,

  /// Conversation has been completed successfully.
  ///
  /// The application request has been finalized and submitted.
  completed,

  /// Conversation has been cancelled by the user.
  ///
  /// User chose to cancel the application creation process.
  cancelled,

  /// Conversation encountered an error.
  ///
  /// An error occurred during processing that prevents continuation.
  error,
}

/// Extension methods for [ConversationStatus] enum.
///
/// Provides utility methods for working with conversation status values.
extension ConversationStatusExtension on ConversationStatus {
  /// Returns a human-readable display name for the status.
  ///
  /// Used for debugging and accessibility purposes.
  String get displayName {
    switch (this) {
      case ConversationStatus.active:
        return 'Active';
      case ConversationStatus.waitingForInput:
        return 'Waiting for Input';
      case ConversationStatus.processing:
        return 'Processing';
      case ConversationStatus.completed:
        return 'Completed';
      case ConversationStatus.cancelled:
        return 'Cancelled';
      case ConversationStatus.error:
        return 'Error';
    }
  }

  /// Returns true if the conversation is in an active state.
  ///
  /// Active states allow user interaction and message sending.
  bool get isActive {
    return this == ConversationStatus.active || this == ConversationStatus.waitingForInput;
  }

  /// Returns true if the conversation is in a terminal state.
  ///
  /// Terminal states indicate the conversation has ended and
  /// no further interaction is expected.
  bool get isTerminal {
    return this == ConversationStatus.completed ||
        this == ConversationStatus.cancelled ||
        this == ConversationStatus.error;
  }

  /// Returns true if the conversation is currently processing.
  ///
  /// Processing state indicates the system is working and
  /// user input should be disabled.
  bool get isProcessing => this == ConversationStatus.processing;

  /// Returns true if user input should be enabled.
  ///
  /// Input is enabled for active states but disabled for
  /// processing and terminal states.
  bool get canAcceptInput => isActive;

  /// Returns true if the conversation can be cancelled.
  ///
  /// Conversations can be cancelled when they are active
  /// but not when they are already terminal.
  bool get canCancel => !isTerminal;
}
