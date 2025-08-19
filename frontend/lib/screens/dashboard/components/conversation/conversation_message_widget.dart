import 'package:flutter/material.dart';

import '../../../../services/conversation/models/conversation_message.dart';
import '../../../../services/conversation/models/message_action.dart';
import '../../../../services/conversation/models/message_action_type.dart';
import '../../../../theme/insets.dart';

/// Widget for displaying a single conversation message.
///
/// Handles both user and system messages with appropriate styling,
/// positioning, and action buttons for interactive messages.
class ConversationMessageWidget extends StatelessWidget {
  /// Creates a conversation message widget.
  ///
  /// @param message The message to display
  /// @param onActionTap Callback when an action is tapped
  const ConversationMessageWidget({
    required this.message,
    this.onActionTap,
    super.key,
  });

  /// The message to display.
  final ConversationMessage message;

  /// Callback invoked when a message action is tapped.
  ///
  /// Receives the tapped action as a parameter.
  final void Function(MessageAction action)? onActionTap;

  @override
  Widget build(BuildContext context) {
    if (message.isTyping) {
      return _buildTypingIndicator(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.medium,
        vertical: Insets.xSmall,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isSystemMessage) ...[
            _buildAvatar(context, isSystem: true),
            Expanded(child: _buildMessageBubble(context)),
          ] else ...[
            Expanded(child: _buildMessageBubble(context)),
            _buildAvatar(context, isSystem: false),
          ],
        ],
      ),
    );
  }

  /// Builds the avatar for the message sender.
  ///
  /// @param context Build context
  /// @param isSystem Whether this is a system message
  /// @returns Avatar widget
  Widget _buildAvatar(BuildContext context, {required bool isSystem}) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isSystem ? colorScheme.primary : colorScheme.secondary,
        shape: BoxShape.circle,
      ),
      margin: const EdgeInsets.symmetric(horizontal: Insets.small),
      child: Icon(
        isSystem ? Icons.smart_toy : Icons.person,
        color: isSystem ? colorScheme.onPrimary : colorScheme.onSecondary,
        size: 18,
      ),
    );
  }

  /// Builds the message bubble with content and actions.
  ///
  /// @param context Build context
  /// @returns Message bubble widget
  Widget _buildMessageBubble(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: message.isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(Insets.small),
          decoration: BoxDecoration(
            color: message.isUserMessage ? colorScheme.primary : colorScheme.surface,
            borderRadius: BorderRadius.circular(16).copyWith(
              topLeft: message.isSystemMessage ? Radius.zero : const Radius.circular(16),
              topRight: message.isUserMessage ? Radius.zero : const Radius.circular(16),
            ),
            border: message.isSystemMessage ? Border.all(color: colorScheme.outline.withValues(alpha: 0.3)) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.content,
                style: textTheme.bodyMedium?.copyWith(
                  color: message.isUserMessage ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
              ),

              // Timestamp
              Padding(
                padding: const EdgeInsets.only(top: Insets.xxSmall),
                child: Text(
                  message.formattedTimestamp,
                  style: textTheme.bodySmall?.copyWith(
                    color: message.isUserMessage ? colorScheme.onPrimary.withValues(alpha: 0.7) : colorScheme.tertiary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Actions (only for system messages)
        if (message.hasActions && message.isSystemMessage) ...[
          const SizedBox(height: Insets.xSmall),
          _buildMessageActions(context),
        ],
      ],
    );
  }

  /// Builds the action chips for interactive messages.
  ///
  /// @param context Build context
  /// @returns Actions widget
  Widget _buildMessageActions(BuildContext context) {
    return Wrap(
      spacing: Insets.xSmall,
      runSpacing: Insets.xSmall,
      children: message.actions.map((MessageAction action) {
        return _buildActionChip(context, action);
      }).toList(),
    );
  }

  /// Builds a single action chip.
  ///
  /// @param context Build context
  /// @param action The action to build
  /// @returns Action chip widget
  Widget _buildActionChip(BuildContext context, MessageAction action) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    switch (action.type) {
      case MessageActionType.primary:
        return FilledButton(
          onPressed: onActionTap != null ? () => onActionTap!(action) : null,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.small,
              vertical: Insets.xSmall,
            ),
          ),
          child: Text(action.label),
        );

      case MessageActionType.secondary:
        return OutlinedButton(
          onPressed: onActionTap != null ? () => onActionTap!(action) : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.onSurface,
            side: BorderSide(color: colorScheme.outline),
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.small,
              vertical: Insets.xSmall,
            ),
          ),
          child: Text(action.label),
        );

      case MessageActionType.suggestion:
        return ActionChip(
          onPressed: onActionTap != null ? () => onActionTap!(action) : null,
          label: Text(action.label),
          backgroundColor: colorScheme.surface,
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
          labelStyle: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 13,
          ),
          padding: const EdgeInsets.symmetric(horizontal: Insets.xSmall),
        );
    }
  }

  /// Builds a typing indicator for when the system is processing.
  ///
  /// @param context Build context
  /// @returns Typing indicator widget
  Widget _buildTypingIndicator(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.medium,
        vertical: Insets.xSmall,
      ),
      child: Row(
        children: [
          _buildAvatar(context, isSystem: true),
          const SizedBox(width: Insets.small),
          Container(
            padding: const EdgeInsets.all(Insets.small),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16).copyWith(
                topLeft: Radius.zero,
              ),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(context, delay: 0),
                _buildTypingDot(context, delay: 200),
                _buildTypingDot(context, delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single animated dot for the typing indicator.
  ///
  /// @param context Build context
  /// @param delay Animation delay in milliseconds
  /// @returns Animated dot widget
  Widget _buildTypingDot(BuildContext context, {required int delay}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (BuildContext context, double opacity, Widget? child) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 100 + delay),
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: Insets.xxSmall),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiary.withValues(alpha: opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
