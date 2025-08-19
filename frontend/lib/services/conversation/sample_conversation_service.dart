import '../../models/conversation/message_action_type.dart';
import '../../models/models.dart';

/// Service providing sample conversation data for development and testing.
///
/// This service generates realistic conversation flows to demonstrate
/// the conversational interface functionality before backend integration.
class SampleConversationService {
  /// Creates a sample conversation thread for creating a new application.
  ///
  /// Demonstrates the typical flow of creating an application through
  /// natural language conversation with clarifying questions.
  static ConversationThread createSampleNewApplicationConversation() {
    final DateTime now = DateTime.now();
    final String conversationId = 'conv_${now.millisecondsSinceEpoch}';

    return ConversationThread(
      id: conversationId,
      context: const ConversationContext(
        purpose: 'create_application',
        metadata: {
          'step': 'initial_request',
          'requirements_gathered': false,
        },
      ),
      status: ConversationStatus.active,
      createdAt: now.subtract(const Duration(minutes: 2)),
      updatedAt: now.subtract(const Duration(seconds: 30)),
      messages: [
        ConversationMessage(
          id: 'msg_001',
          sender: MessageSender.system,
          content: "Hi! I'll help you create a custom application for your household. What would you like to build?",
          timestamp: now.subtract(const Duration(minutes: 2)),
          actions: [
            const MessageAction(
              id: 'action_001',
              label: 'Chore Tracker',
              value: 'I need a chore tracking app for my family',
            ),
            const MessageAction(
              id: 'action_002',
              label: 'Budget Planner',
              value: 'I want to track our household budget',
            ),
            const MessageAction(
              id: 'action_003',
              label: 'Recipe Organizer',
              value: 'Help me organize family recipes',
            ),
          ],
        ),
        ConversationMessage(
          id: 'msg_002',
          sender: MessageSender.user,
          content: 'I need something to track which family member should do chores this week',
          timestamp: now.subtract(const Duration(minutes: 1, seconds: 30)),
        ),
        ConversationMessage(
          id: 'msg_003',
          sender: MessageSender.system,
          content:
              'Great! A chore rotation tracker sounds very useful. Let me ask a few questions to make sure I build exactly what you need:',
          timestamp: now.subtract(const Duration(minutes: 1)),
        ),
        ConversationMessage(
          id: 'msg_004',
          sender: MessageSender.system,
          content:
              '• How many family members will be using this?\n• What chores do you want to track?\n• Should it rotate weekly or on a different schedule?',
          timestamp: now.subtract(const Duration(seconds: 58)),
          actions: [
            const MessageAction(
              id: 'action_004',
              label: '4 family members',
              value: 'We have 4 family members',
            ),
            const MessageAction(
              id: 'action_005',
              label: 'Weekly rotation',
              value: 'Weekly rotation works for us',
            ),
            const MessageAction(
              id: 'action_006',
              label: 'Common chores',
              value: 'Kitchen cleanup, laundry, vacuuming, trash, bathrooms',
            ),
          ],
        ),
        ConversationMessage(
          id: 'msg_005',
          sender: MessageSender.user,
          content: '4 family members, and we have about 8 regular chores that need to be done',
          timestamp: now.subtract(const Duration(seconds: 30)),
        ),
      ],
    );
  }

  /// Creates a sample conversation thread for modifying an existing application.
  ///
  /// Demonstrates the flow of modifying an existing application with
  /// context about the current application state.
  static ConversationThread createSampleModifyApplicationConversation() {
    final DateTime now = DateTime.now();
    final String conversationId = 'conv_modify_${now.millisecondsSinceEpoch}';

    return ConversationThread(
      id: conversationId,
      context: const ConversationContext(
        purpose: 'modify_application',
        applicationId: 'app_001',
        metadata: {
          'application_name': 'Family Chore Tracker',
          'modification_type': 'feature_addition',
        },
      ),
      status: ConversationStatus.waitingForInput,
      createdAt: now.subtract(const Duration(minutes: 1)),
      updatedAt: now.subtract(const Duration(seconds: 15)),
      messages: [
        ConversationMessage(
          id: 'msg_mod_001',
          sender: MessageSender.system,
          content: 'I can help you modify your Family Chore Tracker application. What changes would you like to make?',
          timestamp: now.subtract(const Duration(minutes: 1)),
          actions: [
            const MessageAction(
              id: 'action_mod_001',
              label: 'Add Features',
              value: 'I want to add new features',
            ),
            const MessageAction(
              id: 'action_mod_002',
              label: 'Change Design',
              value: 'I want to change the design or layout',
            ),
            const MessageAction(
              id: 'action_mod_003',
              label: 'Fix Issues',
              value: 'There are some issues I want to fix',
            ),
          ],
        ),
        ConversationMessage(
          id: 'msg_mod_002',
          sender: MessageSender.user,
          content: 'I want to add a reward system where family members can earn points for completing chores',
          timestamp: now.subtract(const Duration(seconds: 30)),
        ),
        ConversationMessage(
          id: 'msg_mod_003',
          sender: MessageSender.system,
          content:
              "That's a great idea! A reward system can really motivate everyone. Let me understand what you have in mind:",
          timestamp: now.subtract(const Duration(seconds: 15)),
          actions: [
            const MessageAction(
              id: 'action_mod_004',
              label: 'Points per chore',
              value: 'Different chores should give different points',
            ),
            const MessageAction(
              id: 'action_mod_005',
              label: 'Weekly rewards',
              value: 'Rewards should be given weekly',
            ),
            const MessageAction(
              id: 'action_mod_006',
              label: 'Family leaderboard',
              value: 'Show a family leaderboard with points',
            ),
          ],
        ),
      ],
    );
  }

  /// Creates a sample conversation thread that has been completed.
  ///
  /// Shows what a finished conversation looks like with confirmation
  /// and next steps.
  static ConversationThread createSampleCompletedConversation() {
    final DateTime now = DateTime.now();
    final String conversationId = 'conv_completed_${now.millisecondsSinceEpoch}';

    return ConversationThread(
      id: conversationId,
      context: const ConversationContext(
        purpose: 'create_application',
        metadata: {
          'application_name': 'Garden Planning Assistant',
          'requirements_complete': true,
          'specification_generated': true,
        },
      ),
      status: ConversationStatus.completed,
      createdAt: now.subtract(const Duration(minutes: 10)),
      updatedAt: now.subtract(const Duration(minutes: 1)),
      messages: [
        ConversationMessage(
          id: 'msg_comp_001',
          sender: MessageSender.system,
          content: "Perfect! I have all the information I need. Here's what I'll create for you:",
          timestamp: now.subtract(const Duration(minutes: 2)),
        ),
        ConversationMessage(
          id: 'msg_comp_002',
          sender: MessageSender.system,
          content:
              '**Garden Planning Assistant**\n\n• Track planting schedules for vegetables and herbs\n• Set reminders for watering, fertilizing, and harvesting\n• Weather integration for optimal planting times\n• Garden layout planner with companion planting suggestions\n• Harvest tracking and yield analysis',
          timestamp: now.subtract(const Duration(minutes: 1, seconds: 45)),
        ),
        ConversationMessage(
          id: 'msg_comp_003',
          sender: MessageSender.user,
          content: 'That sounds perfect! Please go ahead and create it.',
          timestamp: now.subtract(const Duration(minutes: 1, seconds: 15)),
        ),
        ConversationMessage(
          id: 'msg_comp_004',
          sender: MessageSender.system,
          content:
              "Excellent! I'm starting development of your Garden Planning Assistant now. You can track the progress in your dashboard. I'll notify you when it's ready to use!",
          timestamp: now.subtract(const Duration(minutes: 1)),
          actions: [
            const MessageAction(
              id: 'action_comp_001',
              label: 'View Dashboard',
              value: 'Take me to the dashboard',
              type: MessageActionType.primary,
            ),
            const MessageAction(
              id: 'action_comp_002',
              label: 'Create Another',
              value: 'I want to create another application',
              type: MessageActionType.secondary,
            ),
          ],
        ),
      ],
    );
  }

  /// Returns a list of sample conversation threads for testing.
  ///
  /// Includes conversations in various states to demonstrate
  /// different UI scenarios.
  static List<ConversationThread> getSampleConversations() {
    return [
      createSampleNewApplicationConversation(),
      createSampleModifyApplicationConversation(),
      createSampleCompletedConversation(),
    ];
  }

  /// Creates a new empty conversation thread for starting a new conversation.
  ///
  /// @param purpose The purpose of the conversation (e.g., 'create_application')
  /// @param applicationId Optional application ID for modification conversations
  /// @returns New empty ConversationThread
  static ConversationThread createNewConversation({
    required String purpose,
    String? applicationId,
  }) {
    final DateTime now = DateTime.now();
    final String conversationId = 'conv_${now.millisecondsSinceEpoch}';

    return ConversationThread(
      id: conversationId,
      context: ConversationContext(
        purpose: purpose,
        applicationId: applicationId,
        metadata: const {
          'step': 'initial',
        },
      ),
      status: ConversationStatus.active,
      createdAt: now,
      updatedAt: now,
      messages: [],
    );
  }

  /// Generates a system welcome message for starting a new conversation.
  ///
  /// @param conversationId The ID of the conversation
  /// @param isModification Whether this is for modifying an existing app
  /// @param applicationName Optional name of the app being modified
  /// @returns ConversationMessage with welcome content and suggestions
  static ConversationMessage createWelcomeMessage({
    required String conversationId,
    bool isModification = false,
    String? applicationName,
  }) {
    final DateTime now = DateTime.now();
    final String messageId = 'msg_welcome_${now.millisecondsSinceEpoch}';

    if (isModification && applicationName != null) {
      return ConversationMessage(
        id: messageId,
        sender: MessageSender.system,
        content: 'I can help you modify your $applicationName application. What changes would you like to make?',
        timestamp: now,
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
    } else {
      return ConversationMessage(
        id: messageId,
        sender: MessageSender.system,
        content: "Hi! I'll help you create a custom application for your household. What would you like to build?",
        timestamp: now,
        actions: [
          const MessageAction(
            id: 'action_create_001',
            label: 'Chore Tracker',
            value: 'I need a chore tracking app for my family',
          ),
          const MessageAction(
            id: 'action_create_002',
            label: 'Budget Planner',
            value: 'I want to track our household budget',
          ),
          const MessageAction(
            id: 'action_create_003',
            label: 'Recipe Organizer',
            value: 'Help me organize family recipes',
          ),
          const MessageAction(
            id: 'action_create_004',
            label: 'Event Calendar',
            value: 'I need a family calendar for events and appointments',
          ),
        ],
      );
    }
  }
}
