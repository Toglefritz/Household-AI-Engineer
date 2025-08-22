part of 'conversation_modal.dart';

/// Composed widget that displays the scrollable conversation messages list.
class ConversationMessagesList extends StatelessWidget {
  /// Creates an instance of [ConversationMessagesList].
  const ConversationMessagesList({
    required this.controller,
    required this.scrollController,
    required this.onActionTap,
    super.key,
  });

  /// A service responsible for managing the conversation between Kiro and the user, moderated through an orchestration
  /// layer enabling communication between these systems.
  final ConversationService controller;

  /// A scroll controller for this view.
  final ScrollController scrollController;

  /// A callback invoked when one of the action shortcuts for a message is tapped.
  final void Function(MessageAction action) onActionTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) {
        final ConversationThread? conversation = controller.currentConversation;

        if (conversation == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final List<ConversationMessage> messages = List<ConversationMessage>.from(conversation.messages);

        // Debug: Log message count
        debugPrint('ConversationMessagesList: Displaying ${messages.length} messages');

        // Add typing indicator if processing
        if (controller.isProcessing) {
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
          controller: scrollController,
          padding: const EdgeInsets.symmetric(vertical: Insets.small),
          itemCount: messages.length,
          itemBuilder: (BuildContext context, int index) {
            final ConversationMessage message = messages[index];
            return ConversationMessageWidget(
              message: message,
              onActionTap: onActionTap,
            );
          },
        );
      },
    );
  }
}
