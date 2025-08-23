import 'package:flutter/material.dart';
import '../kiro/kiro_service.dart';
import '../user_application/models/user_application.dart';
import 'models/conversation_context.dart';
import 'models/conversation_message.dart';
import 'models/conversation_status.dart';
import 'models/conversation_thread.dart';
import 'models/default_messages.dart';
import 'models/message_action.dart';
import 'models/message_sender.dart';

/// Controller for managing conversation state and interactions.
/// Controller for managing conversation state and interactions.
///
/// Handles conversation flow, message management, and user interactions
/// for the conversational interface used in application creation and modification.
class ConversationService extends ChangeNotifier {
  /// Creates a new conversation controller.
  ///
  /// @param initialConversation Optional initial conversation to load
  ConversationService({ConversationThread? initialConversation}) {
    // Start with an initial conversation if one was provided in this constructor
    if (initialConversation != null) {
      _currentConversation = initialConversation;
    }
  }

  /// A service used to communicate with the Kiro IDE via the communication bridge extension.
  final KiroService _kiroService = KiroService();

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
  Future<void> startNewApplicationConversation() async {
    _error = null;

    // Perform Kiro setup for a new application.
    await _kiroService.setupKiroForNewApplication();

    // Create a new conversation.
    _currentConversation = _createNewConversation(
      purpose: 'create_application',
    );

    // Add a default message to the conversation.
    final ConversationMessage welcomeMessage = _createWelcomeMessage(conversationId: _currentConversation!.id);
    _currentConversation = _currentConversation!.addMessage(welcomeMessage);

    // After Kiro is open and the conversation is set up, processing is complete.
    _isProcessing = false;

    notifyListeners();
  }

  /// Starts a new conversation for modifying an existing application.
  ///
  /// @param application The application to modify
  Future<void> startModifyApplicationConversation(UserApplication application) async {
    // TODO(Scott): Implementation
    /*_error = null;

    // Open a new Kiro window in the apps/ directory.
    await _kiroService.openKiroInAppsDir();

    // Create a new conversation
    _currentConversation = _createNewConversation(
      purpose: 'modify_application',
      applicationId: application.id,
    );

    // Add a welcome message to the conversation.
    _currentConversation!.addMessage(
      _createWelcomeMessage(
        conversationId: _currentConversation!.id,
        isModification: true,
        applicationName: application.title,
      ),
    );*/

    // After Kiro is open and the conversation is set up, processing is complete.
    _isProcessing = false;

    notifyListeners();
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
      return DefaultMessages.getModifyApplicationWelcomeMessage(
        messageId: messageId,
        applicationName: applicationName,
      );
    } else {
      return DefaultMessages.getNewApplicationWelcomeMessage(messageId: messageId);
    }
  }

  /// Sends a user message.
  ///
  /// Adds the user message to the conversation and triggers system processing.
  Future<void> sendMessage(String messageText) async {
    if (!canSendMessage) return;

    String messageContent = messageText.trim();
    if (messageContent.isEmpty) return;

    // Add interaction guiding instructions to the user message.
    messageContent += DefaultMessages.getInteractionGuidanceInstructions();

    // Add spec guiding instructions to the user message.
    messageContent += DefaultMessages.getSpecGuidanceInstructions();

    // Add user message to the current conversation. The system guidance information
    // is not included in this message since it will be displayed in the frontend
    // user interface.
    final ConversationMessage userMessage = ConversationMessage(
      id: 'msg_user_${DateTime.now().millisecondsSinceEpoch}',
      sender: MessageSender.user,
      content:  messageText.trim(),
      timestamp: DateTime.now(),
    );

    _currentConversation = _currentConversation!.addMessage(userMessage);
    notifyListeners();

    // Process the message and generate system response
    await _kiroService.sendMessage(messageContent);
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
    // TODO(Scott): await _processUserMessage(action.value);
  }

  /// Cancels the current conversation.
  ///
  /// Sets the conversation status to cancelled and clears the current conversation.
  Future<void> cancelConversation() async {
    if (!canCancel) return;

    // Clean up the current conversation.
    _currentConversation = _currentConversation!.updateStatus(ConversationStatus.cancelled);
    _currentConversation = null;
    _error = null;

    // Close the Kiro IDE
    await _kiroService.closeKiro();

    notifyListeners();
  }
}
