/// Types of message actions available in conversations.
///
/// Different action types may have different visual styling
/// and interaction behaviors.
enum MessageActionType {
  /// Suggestion chip for quick responses.
  ///
  /// Displayed as small chips below system messages to provide
  /// common response options.
  suggestion,

  /// Primary action button.
  ///
  /// Displayed as a prominent button for important actions
  /// like confirming or proceeding.
  primary,

  /// Secondary action button.
  ///
  /// Displayed as a less prominent button for alternative actions
  /// like canceling or going back.
  secondary,
}
