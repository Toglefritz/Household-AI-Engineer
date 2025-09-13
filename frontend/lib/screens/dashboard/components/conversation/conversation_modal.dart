//
// library;

import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/conversation/conversation_service.dart';
import '../../../../services/conversation/models/conversation_message.dart';
import '../../../../services/conversation/models/conversation_thread.dart';
import '../../../../services/conversation/models/message_action.dart';
import '../../../../services/conversation/models/message_sender.dart';
import '../../../../services/user_application/models/user_application.dart';
import '../../../../theme/accessibility_helper.dart';
import '../../../../theme/insets.dart';
import 'conversation_immediate_loading_widget.dart';
import 'conversation_input_widget.dart';
import 'conversation_loading_indicator.dart';
import 'conversation_message_widget.dart';

// Parts
part 'conversation_modal_header.dart';

part 'conversation_messages_list.dart';

/// Modal dialog for the conversational interface.
///
/// Provides a chat-like interface for creating and modifying applications
/// through natural language conversation with the system.
class ConversationModal extends StatefulWidget {
  /// Creates a conversation modal.
  ///
  /// @param initialConversation Optional initial conversation to load
  /// @param applicationToModify Optional application to modify
  /// @param onConversationComplete Callback when conversation is completed
  const ConversationModal({
    this.initialConversation,
    this.applicationToModify,
    super.key,
  });

  /// Optional initial conversation to load.
  ///
  /// If provided, the modal will load this conversation instead
  /// of starting a new one.
  final ConversationThread? initialConversation;

  /// Optional application to modify.
  ///
  /// If provided, the conversation will be set up for modifying
  /// this application instead of creating a new one.
  final UserApplication? applicationToModify;

  @override
  State<ConversationModal> createState() => _ConversationModalState();
}

/// State for the [ConversationModal] widget.
class _ConversationModalState extends State<ConversationModal> {
  /// Controller for managing conversation state.
  late final ConversationService _controller;

  /// Scroll controller for the message list.
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    // Initialize the controllers
    _controller = ConversationService(
      initialConversation: widget.initialConversation,
    );
    _scrollController = ScrollController();

    // Initialize the conversation
    _initializeConversation();

    // Listen for conversation updates to auto-scroll
    _controller.addListener(_onConversationUpdated);
  }

  /// Starts a new conversation with the Kiro IDE. The setup depends on the information provided to this modal.
  Future<void> _initializeConversation() async {
    // Start appropriate conversation type
    if (widget.initialConversation == null) {
      final AppLocalizations l10n = AppLocalizations.of(context)!;

      if (widget.applicationToModify != null) {
        await _controller.startModifyApplicationConversation(
          widget.applicationToModify!,
          modifyContent: l10n.conversationWelcomeModifyApp(widget.applicationToModify!.title),
          addFeaturesLabel: l10n.modifyActionAddFeatures,
          addFeaturesValue: l10n.modifyActionAddFeaturesValue,
          changeDesignLabel: l10n.modifyActionChangeDesign,
          changeDesignValue: l10n.modifyActionChangeDesignValue,
          fixIssuesLabel: l10n.modifyActionFixIssues,
          fixIssuesValue: l10n.modifyActionFixIssuesValue,
        );
      } else {
        await _controller.startNewApplicationConversation(
          welcomeContent: l10n.conversationWelcomeNewApp,
          choreTrackerLabel: l10n.suggestionChoreTracker,
          choreTrackerValue: l10n.suggestionChoreTrackerValue,
          budgetPlannerLabel: l10n.suggestionBudgetPlanner,
          budgetPlannerValue: l10n.suggestionBudgetPlannerValue,
          recipeOrganizerLabel: l10n.suggestionRecipeOrganizer,
          recipeOrganizerValue: l10n.suggestionRecipeOrganizerValue,
        );
      }
    }
  }

  /// Handles conversation updates and auto-scrolls to bottom.
  void _onConversationUpdated() {
    if (mounted) {
      // Auto-scroll to bottom when new messages are added
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  /// Handles sending a text message.
  void _handleSendMessage(String message) {
    _controller.sendMessage(message);
  }

  /// Handles tapping a message action.
  void _handleActionTap(MessageAction action) => _controller.sendAction(action);

  /// Handles closing the modal.
  void _handleClose() {
    if (_controller.canCancel) {
      _controller.cancelConversation();
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    // Modal display parameters
    final Size screenSize = MediaQuery.of(context).size;
    final double modalWidth = (screenSize.width * 0.8).clamp(600.0, 800.0);
    final double modalHeight = (screenSize.height * 0.8).clamp(500.0, 700.0);

    // Create semantic labels for the modal
    final String modalLabel = l10n.accessibilityConversationModal;
    final String modalHint = l10n.accessibilityConversationModalHint;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: AccessibilityHelper.createSemanticContainer(
        label: modalLabel,
        hint: modalHint,
        child: Container(
          width: modalWidth,
          height: modalHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              ConversationModalHeader(
                applicationToModify: widget.applicationToModify,
                onClose: _handleClose,
              ),

              // Messages
              Expanded(
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (BuildContext context, Widget? child) {
                    return Column(
                      children: [
                        // Messages list
                        Expanded(
                          child: ConversationMessagesList(
                            controller: _controller,
                            scrollController: _scrollController,
                            onActionTap: _handleActionTap,
                          ),
                        ),

                        // Immediate loading indicator (shown right after user input)
                        if (_controller.isShowingImmediateLoading) ...[
                          Builder(
                            builder: (context) {
                              debugPrint('ConversationModal: Showing immediate loading widget');
                              return const ConversationImmediateLoadingWidget();
                            },
                          ),
                        ]
                        // Development progress indicator (shown when specific progress is available)
                        else if (_controller.isDevelopmentInProgress) ...[
                          ConversationLoadingIndicator(
                            progress: _controller.developmentProgress,
                            currentPhase: _controller.currentApplication?.progress?.currentPhase,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),

              // Input
              ListenableBuilder(
                listenable: _controller,
                builder: (BuildContext context, Widget? child) {
                  return ConversationInputWidget(
                    onSendMessage: _handleSendMessage,
                    enabled: _controller.canAcceptInput,
                    placeholder: _controller.isProcessing
                        ? AppLocalizations.of(
                            context,
                          )!.conversationInputPlaceholderWaiting
                        : AppLocalizations.of(
                            context,
                          )!.conversationInputPlaceholder,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onConversationUpdated)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
