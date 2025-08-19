import 'dart:io';

import 'package:flutter/material.dart';

import '../user_application/models/user_application.dart';
import 'models/conversation_message.dart';
import 'models/conversation_status.dart';
import 'models/conversation_thread.dart';
import 'models/message_action.dart';
import 'models/message_sender.dart';

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

  /// Waits for the Kiro Bridge REST API to become available by polling the `/api/kiro/status` endpoint.
  ///
  /// This method repeatedly attempts to connect to `http://localhost:3001/api/kiro/status` until a successful
  /// response (HTTP 200) is received or the specified [timeout] duration elapses.
  ///
  /// The polling interval between attempts is controlled by [pollInterval].
  ///
  /// Throws a [StateError] if the bridge does not become available within the timeout.
  ///
  /// Returns `true` if the bridge becomes available within the timeout.
  Future<bool> waitForKiroBridgeAvailable({
    Duration timeout = const Duration(seconds: 30),
    Duration pollInterval = const Duration(milliseconds: 500),
  }) async {
    final Uri statusUri = Uri.parse('http://localhost:3001/api/kiro/status');
    final DateTime deadline = DateTime.now().add(timeout);
    final HttpClient client = HttpClient();

    while (DateTime.now().isBefore(deadline)) {
      try {
        final HttpClientRequest request = await client.getUrl(statusUri);
        final HttpClientResponse response = await request.close();

        if (response.statusCode == 200) {
          client.close(force: true);
          return true;
        }
      } catch (_) {
        // Ignore errors and continue polling until timeout.
      }

      await Future<void>.delayed(pollInterval);
    }

    client.close(force: true);

    throw StateError('Timed out waiting for Kiro Bridge to become available.');
  }

  /// Starts a new conversation for creating an application.
  ///
  /// Creates a new conversation thread and adds the initial welcome message.
  void startNewApplicationConversation() {
    _error = null;

    // TODO(Scott): Implementation

    // TODO(Scott): _currentConversation = _currentConversation!.addMessage(welcomeMessage);
    notifyListeners();
  }

  /// Starts a new conversation for modifying an existing application.
  ///
  /// @param application The application to modify
  void startModifyApplicationConversation(UserApplication application) {
    _error = null;

    // TODO(Scott): Implementation

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

    // TODO(Scott): Implementation
  }
}
