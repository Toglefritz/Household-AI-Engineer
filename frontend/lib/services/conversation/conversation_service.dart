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

  /// Whether the system is showing immediate loading feedback after user input.
  ///
  /// This is true immediately after a user submits a message and before
  /// any specific progress information becomes available.
  bool _isShowingImmediateLoading = false;

  /// Timer for clearing immediate loading state if it persists too long.
  ///
  /// This provides a fallback to ensure the loading indicator doesn't
  /// persist indefinitely if something goes wrong with manifest detection.
  Timer? _immediateLoadingTimer;

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

  /// Whether the system is showing immediate loading feedback.
  ///
  /// This indicates that a user message has been submitted and the system
  /// is analyzing the input before specific progress information is available.
  bool get isShowingImmediateLoading => _isShowingImmediateLoading;

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
  ///
  /// @param welcomeContent Localized welcome message content
  /// @param choreTrackerLabel Localized label for chore tracker suggestion
  /// @param choreTrackerValue Localized value for chore tracker suggestion
  /// @param budgetPlannerLabel Localized label for budget planner suggestion
  /// @param budgetPlannerValue Localized value for budget planner suggestion
  /// @param recipeOrganizerLabel Localized label for recipe organizer suggestion
  /// @param recipeOrganizerValue Localized value for recipe organizer suggestion
  Future<void> startNewApplicationConversation({
    required String welcomeContent,
    required String choreTrackerLabel,
    required String choreTrackerValue,
    required String budgetPlannerLabel,
    required String budgetPlannerValue,
    required String recipeOrganizerLabel,
    required String recipeOrganizerValue,
  }) async {
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
    final ConversationMessage welcomeMessage = _createWelcomeMessage(
      conversationId: _currentConversation!.id,
      welcomeContent: welcomeContent,
      choreTrackerLabel: choreTrackerLabel,
      choreTrackerValue: choreTrackerValue,
      budgetPlannerLabel: budgetPlannerLabel,
      budgetPlannerValue: budgetPlannerValue,
      recipeOrganizerLabel: recipeOrganizerLabel,
      recipeOrganizerValue: recipeOrganizerValue,
    );
    _currentConversation = _currentConversation!.addMessage(welcomeMessage);

    // Clear any previous application tracking since this is a new conversation
    _trackedApplicationId = null;
    _lastDevelopmentStatement = null;

    // Start monitoring application progress for development statements
    _startProgressMonitoring();

    // After Kiro is open and the conversation is set up, processing is complete.
    _isProcessing = false;

    notifyListeners();
  }

  /// Starts a new conversation for modifying an existing application.
  ///
  /// Opens Kiro in the specific application directory and creates a conversation
  /// thread for handling modification requests. The conversation will track
  /// progress updates for the specified application.
  ///
  /// @param application The application to modify
  /// @param modifyContent Localized content for the modify message
  /// @param addFeaturesLabel Localized label for add features action
  /// @param addFeaturesValue Localized value for add features action
  /// @param changeDesignLabel Localized label for change design action
  /// @param changeDesignValue Localized value for change design action
  /// @param fixIssuesLabel Localized label for fix issues action
  /// @param fixIssuesValue Localized value for fix issues action
  Future<void> startModifyApplicationConversation(
    UserApplication application, {
    required String modifyContent,
    required String addFeaturesLabel,
    required String addFeaturesValue,
    required String changeDesignLabel,
    required String changeDesignValue,
    required String fixIssuesLabel,
    required String fixIssuesValue,
  }) async {
    _error = null;
    _isProcessing = true;

    try {
      // Open Kiro in the specific application directory
      await _kiroService.setupKiroForApplicationModification(application.id);

      // Create a new conversation for modification
      _currentConversation = _createNewConversation(
        purpose: 'modify_application',
        applicationId: application.id,
      );

      // Add a welcome message to the conversation
      final ConversationMessage welcomeMessage = _createWelcomeMessage(
        conversationId: _currentConversation!.id,
        isModification: true,
        applicationName: application.title,
        modifyContent: modifyContent,
        addFeaturesLabel: addFeaturesLabel,
        addFeaturesValue: addFeaturesValue,
        changeDesignLabel: changeDesignLabel,
        changeDesignValue: changeDesignValue,
        fixIssuesLabel: fixIssuesLabel,
        fixIssuesValue: fixIssuesValue,
      );
      _currentConversation = _currentConversation!.addMessage(welcomeMessage);

      // Track this specific application for progress updates
      _trackedApplicationId = application.id;

      // Clear initial application IDs since this is not a new application conversation
      _initialApplicationIds = null;

      // Initialize the last development statement to prevent the current statement
      // from appearing as a new message when starting the modification conversation
      _lastDevelopmentStatement = application.progress?.developmentStatement;

      // Start monitoring application progress for development statements
      _startProgressMonitoring();

      // After Kiro is open and the conversation is set up, processing is complete
      _isProcessing = false;

      notifyListeners();
    } catch (e) {
      _error = 'Failed to start modification conversation: $e';
      _isProcessing = false;
      notifyListeners();
      rethrow;
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
  /// @param welcomeContent Localized welcome message content
  /// @param choreTrackerLabel Localized label for chore tracker suggestion (for new apps)
  /// @param choreTrackerValue Localized value for chore tracker suggestion (for new apps)
  /// @param budgetPlannerLabel Localized label for budget planner suggestion (for new apps)
  /// @param budgetPlannerValue Localized value for budget planner suggestion (for new apps)
  /// @param recipeOrganizerLabel Localized label for recipe organizer suggestion (for new apps)
  /// @param recipeOrganizerValue Localized value for recipe organizer suggestion (for new apps)
  /// @param modifyContent Localized content for modify message (for existing apps)
  /// @param addFeaturesLabel Localized label for add features action (for existing apps)
  /// @param addFeaturesValue Localized value for add features action (for existing apps)
  /// @param changeDesignLabel Localized label for change design action (for existing apps)
  /// @param changeDesignValue Localized value for change design action (for existing apps)
  /// @param fixIssuesLabel Localized label for fix issues action (for existing apps)
  /// @param fixIssuesValue Localized value for fix issues action (for existing apps)
  /// @returns ConversationMessage with welcome content and suggestions
  ConversationMessage _createWelcomeMessage({
    required String conversationId,
    bool isModification = false,
    String? applicationName,
    String? welcomeContent,
    String? choreTrackerLabel,
    String? choreTrackerValue,
    String? budgetPlannerLabel,
    String? budgetPlannerValue,
    String? recipeOrganizerLabel,
    String? recipeOrganizerValue,
    String? modifyContent,
    String? addFeaturesLabel,
    String? addFeaturesValue,
    String? changeDesignLabel,
    String? changeDesignValue,
    String? fixIssuesLabel,
    String? fixIssuesValue,
  }) {
    final DateTime now = DateTime.now();
    final String messageId = 'msg_welcome_${now.millisecondsSinceEpoch}';

    if (isModification && applicationName != null) {
      return DefaultMessages.getModifyApplicationWelcomeMessage(
        messageId: messageId,
        applicationName: applicationName,
        modifyContent:
            modifyContent ??
            'I can help you modify your $applicationName application. What changes would you like to make?',
        addFeaturesLabel: addFeaturesLabel ?? 'Add Features',
        addFeaturesValue: addFeaturesValue ?? 'I want to add new features',
        changeDesignLabel: changeDesignLabel ?? 'Change Design',
        changeDesignValue: changeDesignValue ?? 'I want to change the design or layout',
        fixIssuesLabel: fixIssuesLabel ?? 'Fix Issues',
        fixIssuesValue: fixIssuesValue ?? 'There are some issues I want to fix',
      );
    } else {
      return DefaultMessages.getNewApplicationWelcomeMessage(
        messageId: messageId,
        welcomeContent:
            welcomeContent ??
            "Hi! I'll help you create a custom application for your household. What would you like to build?",
        choreTrackerLabel: choreTrackerLabel ?? 'Chore Tracker',
        choreTrackerValue: choreTrackerValue ?? 'I need a chore tracking app for my family',
        budgetPlannerLabel: budgetPlannerLabel ?? 'Budget Planner',
        budgetPlannerValue: budgetPlannerValue ?? 'I want to track our household budget',
        recipeOrganizerLabel: recipeOrganizerLabel ?? 'Recipe Organizer',
        recipeOrganizerValue: recipeOrganizerValue ?? 'Help me organize family recipes',
      );
    }
  }

  /// Sends a user message.
  ///
  /// Adds the user message to the conversation and triggers system processing.
  Future<void> sendMessage(String messageText) async {
    if (!canSendMessage) return;

    String messageContent = messageText.trim();
    if (messageContent.isEmpty) return;

    // Immediately show loading feedback when user submits a message
    // This will persist until we detect that a manifest.json file has been created
    debugPrint('ConversationService: Setting immediate loading state to true');
    _isShowingImmediateLoading = true;
    _isProcessing = true;

    // Set up a fallback timer to clear loading state if it persists too long
    _startImmediateLoadingTimer();

    notifyListeners();

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

    try {
      // Process the message and generate system response
      await _kiroService.sendMessage(messageContent);
    } finally {
      // Only clear the processing flag, but keep immediate loading visible
      // until we detect that an application manifest has been created
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Sends a predefined action as a user message.
  ///
  /// @param action The action to send
  Future<void> sendAction(MessageAction action) async {
    if (!canSendMessage) return;

    // Get the action value and add system guidance instructions
    String messageContent = action.value.trim();
    if (messageContent.isEmpty) return;

    // Immediately show loading feedback when user submits an action
    // This will persist until we detect that a manifest.json file has been created
    debugPrint('ConversationService: Setting immediate loading state to true for action');
    _isShowingImmediateLoading = true;
    _isProcessing = true;

    // Set up a fallback timer to clear loading state if it persists too long
    _startImmediateLoadingTimer();

    notifyListeners();

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

    try {
      // Process the action and generate system response
      await _kiroService.sendMessage(messageContent);
    } finally {
      // Only clear the processing flag, but keep immediate loading visible
      // until we detect that an application manifest has been created
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Cancels the current conversation.
  ///
  /// Sets the conversation status to cancelled and clears the current conversation.
  Future<void> cancelConversation() async {
    if (!canCancel) return;

    // Stop monitoring application progress
    _stopProgressMonitoring();

    // Clear immediate loading state if active
    if (_isShowingImmediateLoading) {
      _clearImmediateLoading();
    }

    // Clean up the current conversation.
    _currentConversation = _currentConversation!.updateStatus(
      ConversationStatus.cancelled,
    );
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

          // Clear immediate loading since we've detected the manifest.json was created
          if (_isShowingImmediateLoading) {
            debugPrint('ConversationService: New application detected (${app.id}), clearing immediate loading');
            _clearImmediateLoading();
          }

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

      // When we detect a new application (manifest.json created), transition from immediate loading
      if (_isShowingImmediateLoading) {
        debugPrint(
          'ConversationService: Application manifest detected, transitioning from immediate loading to development progress',
        );
        _clearImmediateLoading();
      }

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
        _currentConversation = _currentConversation!.addMessage(
          progressMessage,
        );
        _lastDevelopmentStatement = developmentStatement;

        notifyListeners();
      } else {
        // Still notify listeners for progress updates even without new statements
        notifyListeners();
      }
    }
  }

  /// Starts a timer to clear immediate loading state if it persists too long.
  ///
  /// This provides a fallback mechanism to ensure the loading indicator
  /// doesn't persist indefinitely if manifest detection fails.
  void _startImmediateLoadingTimer() {
    // Cancel any existing timer
    _immediateLoadingTimer?.cancel();

    // Set up a new timer for 2 minutes (reasonable timeout for Kiro to create manifest)
    _immediateLoadingTimer = Timer(const Duration(minutes: 2), () {
      if (_isShowingImmediateLoading) {
        debugPrint('ConversationService: Immediate loading timeout reached, clearing loading state');
        _clearImmediateLoading();
      }
    });
  }

  /// Clears the immediate loading state and cancels the timeout timer.
  ///
  /// This method ensures both the loading state and timer are properly cleaned up.
  void _clearImmediateLoading() {
    _isShowingImmediateLoading = false;
    _immediateLoadingTimer?.cancel();
    _immediateLoadingTimer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _immediateLoadingTimer?.cancel();
    _stopProgressMonitoring();
    super.dispose();
  }
}
