import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/insets.dart';

/// Widget that displays immediate loading feedback when user submits a message.
///
/// Shows a generic processing indicator with animated dots while the system
/// analyzes user input before specific progress information becomes available.
class ConversationImmediateLoadingWidget extends StatefulWidget {
  /// Creates a conversation immediate loading widget.
  const ConversationImmediateLoadingWidget({super.key});

  @override
  State<ConversationImmediateLoadingWidget> createState() => _ConversationImmediateLoadingWidgetState();
}

/// State for the [ConversationImmediateLoadingWidget].
class _ConversationImmediateLoadingWidgetState extends State<ConversationImmediateLoadingWidget>
    with TickerProviderStateMixin {
  /// Animation controller for the pulsing loading indicator.
  late final AnimationController _pulseController;

  /// Animation for the pulsing effect.
  late final Animation<double> _pulseAnimation;

  /// Animation controller for the typing dots.
  late final AnimationController _dotsController;

  /// Animation for the typing dots.
  late final Animation<double> _dotsAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize pulse animation for the loading indicator
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation =
        Tween<double>(
          begin: 0.6,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _pulseController,
            curve: Curves.easeInOut,
          ),
        );

    // Initialize dots animation for typing indicator
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _dotsAnimation =
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _dotsController,
            curve: Curves.easeInOut,
          ),
        );

    // Start animations
    _pulseController.repeat(reverse: true);
    _dotsController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: Insets.small,
        vertical: Insets.xxSmall,
      ),
      padding: const EdgeInsets.all(Insets.small),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated loading indicator
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (BuildContext context, Widget? child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: Insets.small),

          // Processing message with animated dots
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n?.conversationProcessingMessage ?? 'Processing your request',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                AnimatedBuilder(
                  animation: _dotsAnimation,
                  builder: (BuildContext context, Widget? child) {
                    final int dotCount = (_dotsAnimation.value * 3).floor() + 1;
                    return Text(
                      '.' * dotCount.clamp(1, 3),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _dotsController.dispose();
    super.dispose();
  }
}
