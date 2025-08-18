import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/insets.dart';

/// Widget for inputting and sending conversation messages.
///
/// Provides a text input field with send button and handles
/// user input validation and submission.
class ConversationInputWidget extends StatefulWidget {
  /// Creates a conversation input widget.
  ///
  /// @param onSendMessage Callback when a message should be sent
  /// @param enabled Whether input is enabled
  /// @param placeholder Optional placeholder text
  const ConversationInputWidget({
    required this.onSendMessage,
    this.enabled = true,
    this.placeholder,
    super.key,
  });

  /// Callback invoked when a message should be sent.
  ///
  /// Receives the message text as a parameter.
  final void Function(String message) onSendMessage;

  /// Whether input is enabled.
  ///
  /// When false, the input field and send button are disabled.
  final bool enabled;

  /// Optional placeholder text for the input field.
  final String? placeholder;

  @override
  State<ConversationInputWidget> createState() => _ConversationInputWidgetState();
}

/// State for the [ConversationInputWidget].
class _ConversationInputWidgetState extends State<ConversationInputWidget> {
  /// Text editing controller for the input field.
  late final TextEditingController _textController;

  /// Focus node for the input field.
  late final FocusNode _focusNode;

  /// Current text input value.
  String _currentText = '';

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();

    _textController.addListener(_onTextChanged);
  }

  /// Handles text changes in the input field.
  void _onTextChanged() {
    setState(() {
      _currentText = _textController.text;
    });
  }

  /// Handles sending the current message.
  void _handleSendMessage() {
    final String message = _currentText.trim();
    if (message.isNotEmpty && widget.enabled) {
      widget.onSendMessage(message);
      _textController.clear();
      setState(() {
        _currentText = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool canSend = _currentText.trim().isNotEmpty && widget.enabled;

    return Container(
      padding: const EdgeInsets.all(Insets.medium),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text input field
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              enabled: widget.enabled,
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: widget.placeholder ?? AppLocalizations.of(context)!.conversationInputPlaceholder,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Insets.small,
                  vertical: Insets.small,
                ),
                suffixIcon: canSend
                    ? IconButton(
                        onPressed: _handleSendMessage,
                        icon: Icon(
                          Icons.send,
                          color: colorScheme.primary,
                        ),
                        tooltip: AppLocalizations.of(context)!.tooltipSendMessage,
                      )
                    : null,
              ),
              onSubmitted: widget.enabled ? (_) => _handleSendMessage() : null,
            ),
          ),

          // Send button (alternative to suffix icon for better accessibility)
          if (canSend) ...[
            const SizedBox(width: Insets.xSmall),
            FloatingActionButton.small(
              onPressed: _handleSendMessage,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              tooltip: AppLocalizations.of(context)!.tooltipSendMessage,
              child: const Icon(Icons.send, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController
      ..removeListener(_onTextChanged)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
