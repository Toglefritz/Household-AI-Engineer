import 'message_action_type.dart';

/// Represents an action that can be taken in response to a conversation message.
///
/// Actions provide quick response options for users, such as suggestion chips
/// or buttons that can be clicked to provide common responses.
class MessageAction {
  /// Creates a new message action.
  ///
  /// @param id Unique identifier for this action
  /// @param label Display text for the action button/chip
  /// @param value The value to send when this action is selected
  /// @param type The type of action for styling and behavior
  const MessageAction({
    required this.id,
    required this.label,
    required this.value,
    this.type = MessageActionType.suggestion,
  });

  /// Unique identifier for this action.
  ///
  /// Used to track which action was selected and for deduplication.
  final String id;

  /// Display text shown on the action button or chip.
  ///
  /// Should be concise and clearly indicate what the action does.
  final String label;

  /// The value that will be sent as a message when this action is selected.
  ///
  /// This becomes the user's message content when the action is triggered.
  final String value;

  /// The type of action, affecting its visual presentation and behavior.
  ///
  /// Different types may have different styling or interaction patterns.
  final MessageActionType type;

  /// Creates a MessageAction from JSON data.
  ///
  /// @param json Map containing the action data
  /// @returns MessageAction instance
  factory MessageAction.fromJson(Map<String, dynamic> json) {
    return MessageAction(
      id: json['id'] as String,
      label: json['label'] as String,
      value: json['value'] as String,
      type: MessageActionType.values.firstWhere(
        (MessageActionType type) => type.name == json['type'],
        orElse: () => MessageActionType.suggestion,
      ),
    );
  }

  /// Converts this action to JSON format.
  ///
  /// @returns Map containing the action data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'value': value,
      'type': type.name,
    };
  }
}

/// Extension methods for [MessageActionType] enum.
extension MessageActionTypeExtension on MessageActionType {
  /// Returns a human-readable display name for the action type.
  String get displayName {
    switch (this) {
      case MessageActionType.suggestion:
        return 'Suggestion';
      case MessageActionType.primary:
        return 'Primary';
      case MessageActionType.secondary:
        return 'Secondary';
    }
  }

  /// Returns true if this is a suggestion action.
  bool get isSuggestion => this == MessageActionType.suggestion;

  /// Returns true if this is a primary action.
  bool get isPrimary => this == MessageActionType.primary;

  /// Returns true if this is a secondary action.
  bool get isSecondary => this == MessageActionType.secondary;
}
