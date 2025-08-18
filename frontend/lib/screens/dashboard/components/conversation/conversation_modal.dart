import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/models.dart';
import '../../../../theme/insets.dart';
import 'conversation_controller.dart';
import 'conversation_input_widget.dart';
import 'conversation_message_widget.dart';

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
    this.onConversationComplete,
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

  /// Callback invoked when the conversation is completed.
  ///
  /// Receives the final conversation thread as a parameter.
  final void Function(ConversationThread conversation)? onConversationComplete;

  @override
  State<ConversationModal> createState() => _ConversationModalState();
}

/// State for the [ConversationModal] widget.
class _ConversationModalState extends State<ConversationModal> {
  /// Controller for managing conversation state.
  late final ConversationController _controller;

  /// Scroll controller for the message list.
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = ConversationController(initialConversation: widget.initialConversation);
    _scrollController = ScrollController();

    // Start appropriate conversation type
    if (widget.initialConversation == null) {
      if (widget.applicationToModify != null) {
        _controller.startModifyApplicationConversation(widget.applicationToModify!);
      } else {
        _controller.startNewApplicationConversation();
      }
    }

    // Listen for conversation updates to auto-scroll
    _controller.addListener(_onConversationUpdated);
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
  void _handleSendMessage(String message) => _controller.sendMessage(message);

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
    // Modal display parameters
    final Size screenSize = MediaQuery.of(context).size;
    final double modalWidth = (screenSize.width * 0.8).clamp(600.0, 800.0);
    final double modalHeight = (screenSize.height * 0.8).clamp(500.0, 700.0);

    return Dialog(
      backgroundColor: Colors.transparent,
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
            _buildHeader(context),

            // Messages
            Expanded(
              child: _buildMessagesList(context),
            ),

            // Input
            ListenableBuilder(
              listenable: _controller,
              builder: (BuildContext context, Widget? child) {
                return ConversationInputWidget(
                  onSendMessage: _handleSendMessage,
                  enabled: _controller.canAcceptInput,
                  placeholder: _controller.isProcessing
                      ? AppLocalizations.of(context)!.conversationInputPlaceholderWaiting
                      : AppLocalizations.of(context)!.conversationInputPlaceholder,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the modal header with title and close button.
  Widget _buildHeader(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    String title;
    if (widget.applicationToModify != null) {
      title = AppLocalizations.of(context)!.modifyApplication(widget.applicationToModify!.title);
    } else {
      title = AppLocalizations.of(context)!.createNewApplication;
    }

    return Container(
      padding: const EdgeInsets.all(Insets.medium),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(right: Insets.small),
            child: Icon(
              widget.applicationToModify != null ? Icons.edit : Icons.add,
              color: colorScheme.primary,
              size: 20,
            ),
          ),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.applicationCreationDescription,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ),

          // Close button
          IconButton(
            onPressed: _handleClose,
            icon: const Icon(Icons.close),
            tooltip: AppLocalizations.of(context)!.close,
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the scrollable messages list.
  Widget _buildMessagesList(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (BuildContext context, Widget? child) {
        final ConversationThread? conversation = _controller.currentConversation;

        if (conversation == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final List<ConversationMessage> messages = List<ConversationMessage>.from(conversation.messages);

        // Add typing indicator if processing
        if (_controller.isProcessing) {
          messages.add(
            ConversationMessage(
              id: 'typing_indicator',
              sender: MessageSender.system,
              content: '',
              timestamp: DateTime.now(),
              isTyping: true,
            ),
          );
        }

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: Insets.medium),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.startConversation,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: Insets.small),
          itemCount: messages.length,
          itemBuilder: (BuildContext context, int index) {
            final ConversationMessage message = messages[index];
            return ConversationMessageWidget(
              message: message,
              onActionTap: _handleActionTap,
            );
          },
        );
      },
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
