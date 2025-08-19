import 'package:flutter/material.dart';

import '../../models/conversation/message_action_type.dart';
import '../../models/models.dart';
import 'sample_conversation_service.dart';

/// Controller for managing conversation state and interactions.
///
/// Handles conversation flow, message management, and user interactions
/// for the conversational interface used in application creation and modification.
class ConversationService extends ChangeNotifier {
  /// Creates a new conversation controller.
  ///
  /// @param initialConversation Optional initial conversation to load
  ConversationService({ConversationThread? initialConversation}) {
    if (initialConversation != null) {
      _currentConversation = initialConversation;
    }
  }

  /// The current active conversation thread.
  ///
  /// Null when no conversation is active.
  ConversationThread? _currentConversation;

  /// Whether the system is currently processing a message.
  ///
  /// Used to show typing indicators and disable input during processing.
  bool _isProcessing = false;

  /// Error message if something went wrong.
  ///
  /// Displayed to the user when an error occurs during conversation.
  String? _error;

  /// The current active conversation thread.
  ConversationThread? get currentConversation => _currentConversation;

  /// Whether the system is currently processing a message.
  bool get isProcessing => _isProcessing;

  /// Error message if something went wrong.
  String? get error => _error;

  /// Whether there is an active conversation.
  bool get hasActiveConversation => _currentConversation != null;

  /// Whether the conversation can accept new messages.
  bool get canAcceptInput => hasActiveConversation && _currentConversation!.canAcceptMessages && !_isProcessing;

  /// Whether a message can be sent (conversation can accept input).
  /// The actual text validation is handled by the input widget.
  bool get canSendMessage => canAcceptInput;

  /// Whether the conversation can be cancelled.
  bool get canCancel => hasActiveConversation && _currentConversation!.canCancel;

  /// Starts a new conversation for creating an application.
  ///
  /// Creates a new conversation thread and adds the initial welcome message.
  void startNewApplicationConversation() {
    _error = null;
    _currentConversation = SampleConversationService.createNewConversation(
      purpose: 'create_application',
    );

    // Add welcome message
    final ConversationMessage welcomeMessage = SampleConversationService.createWelcomeMessage(
      conversationId: _currentConversation!.id,
    );

    _currentConversation = _currentConversation!.addMessage(welcomeMessage);
    notifyListeners();
  }

  /// Starts a new conversation for modifying an existing application.
  ///
  /// @param application The application to modify
  void startModifyApplicationConversation(UserApplication application) {
    _error = null;
    _currentConversation = SampleConversationService.createNewConversation(
      purpose: 'modify_application',
      applicationId: application.id,
    );

    // Add welcome message
    final ConversationMessage welcomeMessage = SampleConversationService.createWelcomeMessage(
      conversationId: _currentConversation!.id,
      isModification: true,
      applicationName: application.title,
    );

    _currentConversation = _currentConversation!.addMessage(welcomeMessage);
    notifyListeners();
  }

  /// Loads an existing conversation thread.
  ///
  /// @param conversation The conversation to load
  void loadConversation(ConversationThread conversation) {
    _error = null;
    _currentConversation = conversation;
    notifyListeners();
  }

  /// Sends a user message.
  ///
  /// Adds the user message to the conversation and triggers system processing.
  Future<void> sendMessage(String messageText) async {
    if (!canSendMessage) return;

    final String messageContent = messageText.trim();
    if (messageContent.isEmpty) return;

    // Add user message
    final ConversationMessage userMessage = ConversationMessage(
      id: 'msg_user_${DateTime.now().millisecondsSinceEpoch}',
      sender: MessageSender.user,
      content: messageContent,
      timestamp: DateTime.now(),
    );

    _currentConversation = _currentConversation!.addMessage(userMessage);
    notifyListeners();

    // Process the message and generate system response
    await _processUserMessage(messageContent);
  }

  /// Sends a predefined action as a user message.
  ///
  /// @param action The action to send
  Future<void> sendAction(MessageAction action) async {
    if (!hasActiveConversation || _isProcessing) return;

    // Add user message with the action value
    final ConversationMessage userMessage = ConversationMessage(
      id: 'msg_action_${DateTime.now().millisecondsSinceEpoch}',
      sender: MessageSender.user,
      content: action.value,
      timestamp: DateTime.now(),
    );

    _currentConversation = _currentConversation!.addMessage(userMessage);
    notifyListeners();

    // Process the action and generate system response
    await _processUserMessage(action.value);
  }

  /// Cancels the current conversation.
  ///
  /// Sets the conversation status to cancelled and clears the current conversation.
  void cancelConversation() {
    if (!canCancel) return;

    _currentConversation = _currentConversation!.updateStatus(ConversationStatus.cancelled);
    _currentConversation = null;
    _error = null;
    notifyListeners();
  }

  /// Clears any error state.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Processes a user message and generates an appropriate system response.
  ///
  /// This is a mock implementation that simulates conversation flow.
  /// In a real implementation, this would communicate with the backend.
  ///
  /// @param userMessage The user's message content
  Future<void> _processUserMessage(String userMessage) async {
    _isProcessing = true;
    _currentConversation = _currentConversation!.updateStatus(ConversationStatus.processing);
    notifyListeners();

    try {
      // Simulate processing delay
      await Future<void>.delayed(const Duration(seconds: 2));

      // Generate mock system response based on conversation context
      final ConversationMessage systemResponse = _generateSystemResponse(userMessage);

      _currentConversation = _currentConversation!.addMessage(systemResponse);
      _currentConversation = _currentConversation!.updateStatus(ConversationStatus.waitingForInput);
    } catch (e) {
      _error = 'Failed to process message: $e';
      _currentConversation = _currentConversation!.updateStatus(ConversationStatus.error);
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Generates a mock system response based on the user's message.
  ///
  /// This simulates the conversation flow for demonstration purposes.
  /// In a real implementation, this would be handled by the backend.
  ///
  /// @param userMessage The user's message content
  /// @returns Generated system response message
  ConversationMessage _generateSystemResponse(String userMessage) {
    final DateTime now = DateTime.now();
    final String messageId = 'msg_system_${now.millisecondsSinceEpoch}';

    // Simple mock logic based on message content
    if (userMessage.toLowerCase().contains('chore') || userMessage.toLowerCase().contains('track')) {
      return ConversationMessage(
        id: messageId,
        sender: MessageSender.system,
        content:
            'Great! A chore tracking system sounds very useful. Let me ask a few questions to make sure I build exactly what you need:\n\n• How many family members will be using this?\n• What chores do you want to track?\n• Should it rotate weekly or on a different schedule?',
        timestamp: now,
        actions: [
          const MessageAction(
            id: 'action_chore_001',
            label: '4 family members',
            value: 'We have 4 family members',
          ),
          const MessageAction(
            id: 'action_chore_002',
            label: 'Weekly rotation',
            value: 'Weekly rotation works for us',
          ),
          const MessageAction(
            id: 'action_chore_003',
            label: 'Common chores',
            value: 'Kitchen cleanup, laundry, vacuuming, trash, bathrooms',
          ),
        ],
      );
    } else if (userMessage.toLowerCase().contains('budget') || userMessage.toLowerCase().contains('money')) {
      return ConversationMessage(
        id: messageId,
        sender: MessageSender.system,
        content:
            'A budget tracking application is a great idea! Let me understand your needs better:\n\n• Do you want to track expenses by category?\n• Should it include income tracking?\n• Do you need spending alerts or limits?',
        timestamp: now,
        actions: [
          const MessageAction(
            id: 'action_budget_001',
            label: 'Track by category',
            value: 'Yes, track expenses by category like groceries, utilities, entertainment',
          ),
          const MessageAction(
            id: 'action_budget_002',
            label: 'Include income',
            value: 'Yes, track both income and expenses',
          ),
          const MessageAction(
            id: 'action_budget_003',
            label: 'Set spending limits',
            value: 'I want to set spending limits and get alerts',
          ),
        ],
      );
    } else if (userMessage.toLowerCase().contains('recipe') || userMessage.toLowerCase().contains('cooking')) {
      return ConversationMessage(
        id: messageId,
        sender: MessageSender.system,
        content:
            "A recipe organizer sounds wonderful! Here's what I'm thinking:\n\n• Store family recipes with ingredients and instructions\n• Organize by meal type or cuisine\n• Generate shopping lists from recipes\n• Plan weekly meals\n\nDoes this match what you had in mind?",
        timestamp: now,
        actions: [
          const MessageAction(
            id: 'action_recipe_001',
            label: 'Perfect!',
            value: 'Yes, that sounds perfect. Please create it.',
            type: MessageActionType.primary,
          ),
          const MessageAction(
            id: 'action_recipe_002',
            label: 'Add meal planning',
            value: 'Yes, and I also want meal planning for the week',
          ),
          const MessageAction(
            id: 'action_recipe_003',
            label: 'Include nutrition',
            value: 'Can you also include nutritional information?',
          ),
        ],
      );
    } else {
      // Generic response for other inputs
      return ConversationMessage(
        id: messageId,
        sender: MessageSender.system,
        content:
            'I understand you want to create an application. Could you tell me more about what specific functionality you need? For example:\n\n• What problem are you trying to solve?\n• Who will be using this application?\n• What are the main features you envision?',
        timestamp: now,
        actions: [
          const MessageAction(
            id: 'action_generic_001',
            label: 'Family organization',
            value: 'I need help organizing family activities and responsibilities',
          ),
          const MessageAction(
            id: 'action_generic_002',
            label: 'Home management',
            value: 'I want to manage household tasks and maintenance',
          ),
          const MessageAction(
            id: 'action_generic_003',
            label: 'Personal tracking',
            value: 'I need to track personal goals or habits',
          ),
        ],
      );
    }
  }
}
