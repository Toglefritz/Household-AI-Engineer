import 'dart:async';
import 'package:flutter/material.dart';
import '../kiro/kiro_service.dart';
import '../user_application/models/user_application.dart';
import '../user_application/user_application_service.dart';
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

  /// Service for monitoring user application progress.
  final UserApplicationService _userApplicationService = UserApplicationService();

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

  /// Subscription to application updates for monitoring progress.
  StreamSubscription<List<UserApplication>>? _applicationSubscription;

  /// The last known development statement to avoid duplicate messages.
  String? _lastDevelopmentStatement;

  /// The current application being developed, if any.
  UserApplication? _currentApplication;

  /// Whether development is currently in progress.
  bool _isDevelopmentInProgress = false;

  /// The application ID that this conversation is tracking for progress updates.
  ///
  /// When set, only progress updates for this specific application will be
  /// added to the conversation. Null when no specific application is being tracked.
  String? _trackedApplicationId;

  /// Set of application IDs that existed when the conversation started.
  ///
  /// Used to detect new applications created during this conversation.
  /// Only populated for new application conversations.
  Set<String>? _initialApplicationIds;

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

  /// Whether development is currently in progress.
  bool get isDevelopmentInProgress => _isDevelopmentInProgress;

  /// The current application being developed.
  UserApplication? get currentApplication => _currentApplication;

  /// Current development progress percentage (0-100).
  double get developmentProgress => _currentApplication?.progress?.percentage ?? 0.0;

  /// Starts a new conversation for creating an application.
  ///
  /// Creates a new conversation thread and adds the initial welcome message.
  Future<void> startNewApplicationConversation() async {
    _error = null;

    // Capture the current set of applications before starting the conversation
    // so we can detect when a new one is created
    final List<UserApplication> currentApplications = await _userApplicationService.getApplications();
    _initialApplicationIds = currentApplications.map((UserApplication app) => app.id).toSet();

    // Perform Kiro setup for a new application.
    await _kiroService.setupKiroForNewApplication();

    // Create a new conversation.
    _currentConversation = _createNewConversation(
      purpose: 'create_application',
    );

    // Add a default message to the conversation.
    final ConversationMessage welcomeMessage = _createWelcomeMessage(conversationId: _currentConversation!.id);
    _currentConversation = _currentConversation!.addMessage(welcomeMessage);

    // Clear any previous application tracking since this is a new conversation
    _trackedApplicationId = null;

    // Start monitoring application progress for development statements
    _startProgressMonitoring();

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

    // Track this specific application for progress updates
    _trackedApplicationId = application.id;

    // Clear initial application IDs since this is not a new application conversation
    _initialApplicationIds = null;

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

    // Add app architecture guiding instructions to the user message.
    messageContent += DefaultMessages.getAppTypeGuidanceInstructions();

    // Add user message to the current conversation. The system guidance information
    // is not included in this message since it will be displayed in the frontend
    // user interface.
    final ConversationMessage userMessage = ConversationMessage(
      id: 'msg_user_${DateTime.now().millisecondsSinceEpoch}',
      sender: MessageSender.user,
      content: messageText.trim(),
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
    if (!canSendMessage) return;

    // Get the action value and add system guidance instructions
    String messageContent = action.value.trim();
    if (messageContent.isEmpty) return;

    // Add interaction guiding instructions to the action message.
    messageContent += DefaultMessages.getInteractionGuidanceInstructions();

    // Add spec guiding instructions to the action message.
    messageContent += DefaultMessages.getSpecGuidanceInstructions();

    // Add user message with the action value to the conversation.
    // The system guidance information is not included in this message since it will be displayed in the frontend
    // user interface.
    final ConversationMessage userMessage = ConversationMessage(
      id: 'msg_action_${DateTime.now().millisecondsSinceEpoch}',
      sender: MessageSender.user,
      content: action.value.trim(),
      timestamp: DateTime.now(),
    );

    _currentConversation = _currentConversation!.addMessage(userMessage);
    notifyListeners();

    // Process the action and generate system response
    await _kiroService.sendMessage(messageContent);
  }

  /// Cancels the current conversation.
  ///
  /// Sets the conversation status to cancelled and clears the current conversation.
  Future<void> cancelConversation() async {
    if (!canCancel) return;

    // Stop monitoring application progress
    _stopProgressMonitoring();

    // Clean up the current conversation.
    _currentConversation = _currentConversation!.updateStatus(ConversationStatus.cancelled);
    _currentConversation = null;
    _error = null;
    _trackedApplicationId = null;
    _initialApplicationIds = null;

    // Close the Kiro IDE
    await _kiroService.closeKiro();

    notifyListeners();
  }

  /// Starts monitoring application progress to inject development statements as messages.
  ///
  /// Watches for changes in application manifests and adds development statements
  /// as system messages when they are updated.
  void _startProgressMonitoring() {
    _applicationSubscription = _userApplicationService.watchApplications().listen(
      _handleApplicationUpdates,
    );
  }

  /// Stops monitoring application progress.
  ///
  /// Cancels the subscription to application updates to prevent memory leaks
  /// and unnecessary processing when the conversation is no longer active.
  void _stopProgressMonitoring() {
    _applicationSubscription?.cancel();
    _applicationSubscription = null;
    _lastDevelopmentStatement = null;
    _trackedApplicationId = null;
    _initialApplicationIds = null;
  }

  /// Handles application updates and injects development statements as messages.
  ///
  /// Checks for new development statements in application progress and adds them
  /// as system messages to the current conversation. Only processes updates for
  /// the application currently being tracked by this conversation.
  void _handleApplicationUpdates(List<UserApplication> applications) {
    // If there is no current conversation, there is no need to process the update.
    if (_currentConversation == null) return;

    UserApplication? targetApplication;

    // If we're tracking a specific application, find it in the list
    if (_trackedApplicationId != null) {
      try {
        targetApplication = applications.firstWhere(
          (UserApplication app) => app.id == _trackedApplicationId,
        );
      } catch (e) {
        // Application not found in the list, it might not exist yet or be removed
        return;
      }
    } else if (_initialApplicationIds != null) {
      // For new application conversations, look for applications that weren't
      // in the initial set when the conversation started
      for (final UserApplication app in applications) {
        if (!_initialApplicationIds!.contains(app.id)) {
          // Found a new application that was created after this conversation started
          targetApplication = app;

          // Start tracking this application for future updates
          _trackedApplicationId = app.id;
          break;
        }
      }
    }

    // If we found a target application, process its updates
    if (targetApplication != null) {
      _currentApplication = targetApplication;

      final String? developmentStatement = targetApplication.progress?.developmentStatement;
      final double progressPercentage = targetApplication.progress?.percentage ?? 0.0;

      // Update development status based on progress
      _isDevelopmentInProgress = progressPercentage < 100.0;

      // Check if there's a new development statement
      if (developmentStatement != null &&
          developmentStatement.isNotEmpty &&
          developmentStatement != _lastDevelopmentStatement) {
        // Create a system message with the development statement
        final ConversationMessage progressMessage = ConversationMessage(
          id: 'msg_progress_${DateTime.now().millisecondsSinceEpoch}',
          sender: MessageSender.system,
          content: developmentStatement,
          timestamp: DateTime.now(),
        );

        // Add the message to the conversation
        _currentConversation = _currentConversation!.addMessage(progressMessage);
        _lastDevelopmentStatement = developmentStatement;

        notifyListeners();
      } else {
        // Still notify listeners for progress updates even without new statements
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _stopProgressMonitoring();
    super.dispose();
  }
}
