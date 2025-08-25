part of 'application_grid.dart';

/// Empty-state widget for the application grid when no applications exist.
///
/// Displays a welcoming message and call-to-action button to encourage
/// users to create their first application. Includes full accessibility
/// support with proper semantic labeling and focus management.
class ApplicationGridEmptyState extends StatelessWidget {
  /// Creates an instance of [ApplicationGridEmptyState].
  const ApplicationGridEmptyState({super.key, this.onCreateNewApplication});

  /// Callback invoked when the create new application button is tapped.
  final VoidCallback? onCreateNewApplication;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Empty state icon - excluded from focus as it's decorative
          AccessibilityHelper.excludeFromFocus(
            Icon(
              Icons.apps_outlined,
              size: 64,
              color: colorScheme.tertiary,
            ),
          ),

          // Title with semantic header
          Padding(
            padding: const EdgeInsets.only(top: Insets.medium),
            child: AccessibilityHelper.createSemanticHeader(
              level: 2,
              child: Text(
                l10n.noApplications,
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.only(top: Insets.xSmall),
            child: Text(
              l10n.createApplicationPrompt,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.tertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Create button with accessibility support
          Padding(
            padding: const EdgeInsets.only(top: Insets.large),
            child: AccessibilityHelper.createAccessibleButton(
              label: l10n.accessibilityCreateNewAppTile,
              hint: l10n.accessibilityCreateNewAppTileHint,
              onPressed: onCreateNewApplication,
              child: FilledButton.icon(
                onPressed: onCreateNewApplication,
                icon: Icon(
                  Icons.add,
                  color: colorScheme.onPrimary,
                ),
                label: Text(
                  l10n.buttonCreateNewApp,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
                style: FilledButton.styleFrom(
                  foregroundColor: colorScheme.onPrimary,
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Insets.medium,
                    vertical: Insets.small,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
