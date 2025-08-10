/// Conversation Status Enumeration
///
/// Tracks the lifecycle of conversations from initiation through completion.

/// Current status of a conversation thread.
///
/// Tracks the lifecycle of conversations from initiation through completion
/// or cancellation, enabling appropriate UI states and user actions.
enum ConversationStatus {
  /// Conversation has been started but no messages have been exchanged.
  ///
  /// Initial state when a new conversation thread is created.
  /// The system is ready to receive the user's first message.
  active,

  /// Conversation is actively ongoing with message exchange.
  ///
  /// Messages are being exchanged between the user and system.
  /// The conversation is progressing toward application creation.
  ongoing,

  /// Conversation is waiting for user input or response.
  ///
  /// The system has asked a question or provided options and
  /// is waiting for the user to respond before continuing.
  waitingForUser,

  /// Conversation is waiting for system processing.
  ///
  /// The user has provided input and the system is processing
  /// the request, generating responses, or creating the application.
  waitingForSystem,

  /// Conversation has been completed successfully.
  ///
  /// The application request has been fully specified and submitted
  /// for development. The conversation has achieved its goal.
  completed,

  /// Conversation has been cancelled by the user.
  ///
  /// The user has explicitly cancelled the conversation before
  /// completion. No application will be created from this thread.
  cancelled,

  /// Conversation has failed due to an error.
  ///
  /// An error occurred that prevents the conversation from continuing.
  /// The user may need to start a new conversation.
  failed,
}

/// Extension methods for ConversationStatus enum.
///
/// Provides utility methods for working with conversation status values,
/// including display formatting and state validation.
extension ConversationStatusExtension on ConversationStatus {
  /// Returns a human-readable display name for the conversation status.
  ///
  /// These names are suitable for display in conversation interfaces
  /// and follow consistent terminology conventions.
  String get displayName {
    switch (this) {
      case ConversationStatus.active:
        return 'Active';
      case ConversationStatus.ongoing:
        return 'Ongoing';
      case ConversationStatus.waitingForUser:
        return 'Waiting for Response';
      case ConversationStatus.waitingForSystem:
        return 'Processing';
      case ConversationStatus.completed:
        return 'Completed';
      case ConversationStatus.cancelled:
        return 'Cancelled';
      case ConversationStatus.failed:
        return 'Failed';
    }
  }

  /// Returns true if the conversation is in an active state.
  ///
  /// Active conversations can receive new messages and continue
  /// progressing toward application creation.
  bool get isActive {
    return this == ConversationStatus.active ||
        this == ConversationStatus.ongoing ||
        this == ConversationStatus.waitingForUser ||
        this == ConversationStatus.waitingForSystem;
  }

  /// Returns true if the conversation is in a terminal state.
  ///
  /// Terminal conversations have reached a final state and
  /// cannot continue without starting a new conversation.
  bool get isTerminal {
    return this == ConversationStatus.completed ||
        this == ConversationStatus.cancelled ||
        this == ConversationStatus.failed;
  }

  /// Returns true if the conversation is waiting for user input.
  ///
  /// Used to determine whether to show input fields and
  /// enable message sending in the conversation interface.
  bool get isWaitingForUser {
    return this == ConversationStatus.active ||
        this == ConversationStatus.waitingForUser;
  }

  /// Returns true if the conversation is processing.
  ///
  /// Used to show loading indicators and disable input
  /// while the system is processing user requests.
  bool get isProcessing {
    return this == ConversationStatus.waitingForSystem;
  }
}
