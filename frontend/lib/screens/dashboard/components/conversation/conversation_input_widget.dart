import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/animated_components.dart';
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
class _ConversationInputWidgetState extends State<ConversationInputWidget> with SingleTickerProviderStateMixin {
  /// Text editing controller for the input field.
  late final TextEditingController _textController;

  /// Focus node for the input field.
  late final FocusNode _focusNode;

  /// Animation controller for send button appearance.
  late final AnimationController _sendButtonController;

  /// Animation for send button scale and opacity.
  late final Animation<double> _sendButtonAnimation;

  /// Current text input value.
  String _currentText = '';

  /// Whether the send button is currently in loading state.
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();

    // Initialize send button animation
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _sendButtonAnimation =
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _sendButtonController,
            curve: Curves.easeInOut,
          ),
        );

    _textController.addListener(_onTextChanged);
  }

  /// Handles text changes in the input field.
  void _onTextChanged() {
    final String newText = _textController.text;
    final bool hadText = _currentText.trim().isNotEmpty;
    final bool hasText = newText.trim().isNotEmpty;

    setState(() {
      _currentText = newText;
    });

    // Animate send button appearance/disappearance
    if (hasText && !hadText) {
      _sendButtonController.forward();
    } else if (!hasText && hadText) {
      _sendButtonController.reverse();
    }
  }

  /// Handles sending the current message.
  Future<void> _handleSendMessage() async {
    final String message = _currentText.trim();
    if (message.isNotEmpty && widget.enabled && !_isSending) {
      setState(() {
        _isSending = true;
      });

      // Brief delay to show sending state
      await Future<void>.delayed(const Duration(milliseconds: 100));

      widget.onSendMessage(message);
      _textController.clear();

      setState(() {
        _currentText = '';
        _isSending = false;
      });

      await _sendButtonController.reverse();
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
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Insets.small,
                  vertical: Insets.small,
                ),
              ),
              onSubmitted: widget.enabled ? (_) => _handleSendMessage() : null,
            ),
          ),

          // Animated send button
          const SizedBox(width: Insets.xSmall),
          AnimatedBuilder(
            animation: _sendButtonAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _sendButtonAnimation.value,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _sendButtonAnimation.value,
                  child: AnimatedButton(
                    onPressed: canSend ? _handleSendMessage : null,
                    isLoading: _isSending,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(40, 40),
                      shape: const CircleBorder(),
                    ),
                    child: const Icon(Icons.send, size: 18),
                  ),
                ),
              );
            },
          ),
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
    _sendButtonController.dispose();
    super.dispose();
  }
}
