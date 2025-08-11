import 'message_action_type.dart';

/// Represents an actionable button or link within a conversation message.
///
/// Message actions provide quick ways for users to respond to system
/// questions or perform common tasks without typing full responses.
///
/// Actions are typically displayed as buttons or chips below system messages.
class MessageAction {
  /// Creates a new message action.
  ///
  /// All parameters are required to ensure complete action information
  /// for proper UI rendering and event handling.
  const MessageAction({required this.id, required this.label, required this.type, this.value});

  /// Unique identifier for this action.
  ///
  /// Used to identify which action was selected when the user
  /// interacts with the conversation interface.
  final String id;

  /// Display text for the action button or link.
  ///
  /// Should be concise and clearly indicate what the action will do.
  /// Examples: "Yes", "No", "Tell me more", "Start over"
  final String label;

  /// Type of action this represents.
  ///
  /// Determines the visual styling and behavior when the action is selected.
  final MessageActionType type;

  /// Optional value associated with this action.
  ///
  /// Contains additional data that will be sent when the action is selected.
  /// For example, a predefined response text or configuration value.
  final String? value;

  /// Creates a MessageAction from JSON data.
  ///
  /// Parses action data received from the backend conversation system
  /// and creates a properly typed action object with validation.
  ///
  /// Throws [FormatException] if the JSON structure is invalid or
  /// required fields are missing.
  factory MessageAction.fromJson(Map<String, dynamic> json) {
    try {
      return MessageAction(
        id: json['id'] as String? ?? (throw ArgumentError('Missing required field: id')),
        label: json['label'] as String? ?? (throw ArgumentError('Missing required field: label')),
        type: _parseActionType(json['type'] as String?),
        value: json['value'] as String?,
      );
    } catch (e) {
      throw FormatException('Failed to parse MessageAction from JSON: $e');
    }
  }

  /// Converts this action to JSON format.
  ///
  /// Creates a JSON representation suitable for API communication
  /// and local storage with proper type conversion.
  Map<String, dynamic> toJson() {
    return {'id': id, 'label': label, 'type': type.name, 'value': value};
  }

  /// Parses an action type string into the corresponding enum value.
  ///
  /// Handles case-insensitive parsing and provides clear error messages
  /// for invalid action type values.
  static MessageActionType _parseActionType(String? typeString) {
    if (typeString == null) {
      throw ArgumentError('Missing required field: type');
    }

    switch (typeString.toLowerCase()) {
      case 'response':
        return MessageActionType.response;
      case 'suggestion':
        return MessageActionType.suggestion;
      case 'confirmation':
        return MessageActionType.confirmation;
      case 'navigation':
        return MessageActionType.navigation;
      default:
        throw ArgumentError('Invalid action type: $typeString');
    }
  }
}
