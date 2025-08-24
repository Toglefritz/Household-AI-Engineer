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
      margin: const EdgeInsets.all(Insets.medium),
      padding: const EdgeInsets.all(Insets.large),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: progress > 0 ? progress / 100 : null,
                ),
              ),
              const SizedBox(width: Insets.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.conversationDevelopmentInProgress,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (currentPhase != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        currentPhase!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (progress > 0) ...[
                Text(
                  '${progress.round()}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: Insets.medium),

          // Progress bar
          if (progress > 0) ...[
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
            const SizedBox(height: Insets.medium),
          ],

          // Informational text
          Text(
            l10n.conversationDevelopmentTimeExpectation,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: Insets.small),

          Text(
            l10n.conversationDevelopmentBackgroundInfo,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
