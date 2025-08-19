// This library groups widgets related to the Kiro conversation service.
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../../models/models.dart';
import '../user_application/user_application_service.dart';
import 'models/kiro_command.dart';
import 'models/send_user_prompt_command.dart';

// Parts
part 'kiro_bridge_client.dart';

/// Controller for managing conversation state and interactions.
///
/// Handles conversation flow, message management, and user interactions
/// for the conversational interface used in application creation and modification.
class ConversationService extends ChangeNotifier {
  /// Creates a new conversation controller.
  ///
  /// @param initialConversation Optional initial conversation to load
  ConversationService({ConversationThread? initialConversation, KiroBridgeClient? kiroClient})
    : _kiro = kiroClient ?? KiroBridgeClient() {
    if (initialConversation != null) {
      _currentConversation = initialConversation;
    }
  }

  /// The current active conversation thread.
  ///
  /// Null when no conversation is active.
  ConversationThread? _currentConversation;

  /// A client responsible for handling communication with the Kiro IDE.
  final KiroBridgeClient _kiro;

  /// A service for managing the user's applications including processes for reading the user's existing applications,
  /// creating new applications, or modifying existing applications.
  final UserApplicationService _userApplicationService = UserApplicationService();

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
    // Open the Kiro IDE.
    _userApplicationService.openKiroInAppsDir();

    _error = null;
    _currentConversation = _createNewConversation(
      purpose: 'create_application',
    );

    // Add welcome message
    final ConversationMessage welcomeMessage = _createWelcomeMessage(
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
    _currentConversation = _createNewConversation(
      purpose: 'modify_application',
      applicationId: application.id,
    );

    // Add welcome message
    final ConversationMessage welcomeMessage = _createWelcomeMessage(
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
      // Optionally ping status to surface availability issues early.
      try {
        await _kiro.getStatus();
      } catch (_) {
        // Non-fatal; proceed to execute so we surface the real error if any.
      }

      // Send the user's prompt to Kiro.
      final Map<String, Object?> execResult = await _kiro.execute(
        SendUserPromptCommand(prompt: userMessage),
      );

      // Derive response text. The bridge may return different shapes; prefer 'output'.
      String responseText = '';
      if (execResult.containsKey('output') && execResult['output'] != null) {
        responseText = execResult['output'].toString();
      } else if (execResult.containsKey('message') && execResult['message'] != null) {
        responseText = execResult['message'].toString();
      } else if (execResult.containsKey('executionId')) {
        responseText = 'Request accepted. Execution ID: ${execResult['executionId']}';
      } else {
        responseText = 'Command executed.';
      }

      final ConversationMessage systemResponse = ConversationMessage(
        id: 'msg_system_${DateTime.now().millisecondsSinceEpoch}',
        sender: MessageSender.system,
        content: responseText,
        timestamp: DateTime.now(),
        // In a future enhancement, parse actionable buttons from output if your bridge encodes them.
      );

      _currentConversation = _currentConversation!.addMessage(systemResponse);
      _currentConversation = _currentConversation!.updateStatus(ConversationStatus.waitingForInput);
      _error = null;
    } catch (e) {
      _error = 'Failed to process message: $e';
      _currentConversation = _currentConversation!.updateStatus(ConversationStatus.error);
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Creates a new empty conversation thread for starting a new conversation.
  ///
  /// @param purpose The purpose of the conversation (e.g., 'create_application')
  /// @param applicationId Optional application ID for modification conversations
  /// @returns New empty ConversationThread
  ConversationThread _createNewConversation({
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
  ConversationMessage _createWelcomeMessage({
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
