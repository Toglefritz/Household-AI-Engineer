// This library groups widgets related to the Kiro conversation service.
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../../models/models.dart';
import 'models/kiro_command.dart';
import 'models/send_user_prompt_command.dart';
import 'sample_conversation_service.dart';

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
}
