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

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: Insets.small,
        vertical: Insets.xxSmall,
      ),
      padding: const EdgeInsets.all(Insets.small),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
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
            ),
          ),
          const SizedBox(width: Insets.small),
          Expanded(
            child: Text(
              currentPhase ?? l10n.conversationDevelopmentInProgress,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (progress > 0) ...[
            const SizedBox(width: Insets.small),
            Text(
              '${progress.round()}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
