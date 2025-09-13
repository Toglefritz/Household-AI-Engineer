import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/insets.dart';

/// Loading indicator widget for ongoing development processes.
///
/// Displays a progress indicator with informative messaging about the
/// development process, including time expectations and background processing.
class ConversationLoadingIndicator extends StatelessWidget {
  /// Creates a conversation loading indicator.
  ///
  /// @param progress Development progress percentage (0.0 to 100.0)
  /// @param currentPhase Optional current development phase description
  const ConversationLoadingIndicator({
    required this.progress,
    this.currentPhase,
    super.key,
  });

  /// Development progress percentage (0.0 to 100.0).
  final double progress;

  /// Optional current development phase description.
  final String? currentPhase;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(
        horizontal: Insets.small,
        vertical: Insets.xxSmall,
      ),
      padding: const EdgeInsets.all(Insets.small),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: progress > 0 ? progress / 100 : null,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: Insets.small),
            child: Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  currentPhase ?? l10n.conversationDevelopmentInProgress,
                  key: ValueKey(currentPhase ?? l10n.conversationDevelopmentInProgress),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          if (progress > 0) ...[
            Padding(
              padding: const EdgeInsets.only(left: Insets.small),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  '${progress.round()}%',
                  key: ValueKey(progress.round()),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
