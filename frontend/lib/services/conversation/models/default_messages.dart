import 'conversation_message.dart';
import 'message_action.dart';
import 'message_sender.dart';

/// Contains a collection of pre-written messages used to populate conversations with Kiro.
///
/// In some situations, it is useful to have some hard-coded, default messages that can be quickly displayed in
/// Kiro conversations without actually interacting with Kiro. For example, when the user initiates a conversation,
/// a default welcome message can be displayed.
class DefaultMessages {
  /// A message displayed when the user first initializes a conversation with Kiro to create a new application.
  ///
  /// @param messageId Unique identifier for this welcome message
  /// @returns ConversationMessage with welcome content and action suggestions
  static ConversationMessage getNewApplicationWelcomeMessage({
    required String messageId,
  }) {
    return ConversationMessage(
      id: messageId,
      sender: MessageSender.system,
      content: "Hi! I'll help you create a custom application for your household. What would you like to build?",
      timestamp: DateTime.now(),
      actions: [
        const MessageAction(
          id: 'welcome_action_001',
          label: 'Chore Tracker',
          value: 'I need a chore tracking app for my family',
        ),
        const MessageAction(
          id: 'welcome_action_002',
          label: 'Budget Planner',
          value: 'I want to track our household budget',
        ),
        const MessageAction(
          id: 'welcome_action_003',
          label: 'Recipe Organizer',
          value: 'Help me organize family recipes',
        ),
      ],
    );
  }

  /// A message displayed when the user first initializes a conversation with Kiro to modify an existing application.
  static ConversationMessage getModifyApplicationWelcomeMessage({
    required String messageId,
    required String applicationName,
  }) {
    return ConversationMessage(
      id: messageId,
      sender: MessageSender.system,
      content: 'I can help you modify your $applicationName application. What changes would you like to make?',
      timestamp: DateTime.now(),
      actions: [
        const MessageAction(
          id: 'action_modify_001',
          label: 'Add Features',
          value: 'I want to add new features',
        ),
        const MessageAction(
          id: 'action_modify_002',
          label: 'Change Design',
          value: 'I want to change the design or layout',
        ),
        const MessageAction(
          id: 'action_modify_003',
          label: 'Fix Issues',
          value: 'There are some issues I want to fix',
        ),
      ],
    );
  }
}
