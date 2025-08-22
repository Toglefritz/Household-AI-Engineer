part of 'application_grid.dart';

/// Empty-state widget for the application grid when no applications exist.
class ApplicationGridEmptyState extends StatelessWidget {
  /// Creates an instance of [ApplicationGridEmptyState].
  const ApplicationGridEmptyState({super.key, this.onCreateNewApplication});

  /// Callback invoked when the create new application button is tapped.
  final VoidCallback? onCreateNewApplication;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.apps_outlined,
            size: 64,
            color: colorScheme.tertiary,
          ),
          Padding(
            padding: const EdgeInsets.only(top: Insets.medium),
            child: Text(
              AppLocalizations.of(context)!.noApplications,
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: Insets.xSmall),
            child: Text(
              AppLocalizations.of(context)!.createApplicationPrompt,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.tertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: Insets.large),
            child: FilledButton.icon(
              onPressed: onCreateNewApplication,
              icon: Icon(
                Icons.add,
                color: colorScheme.onPrimary,
              ),
              label: Text(
                AppLocalizations.of(context)!.buttonCreateNewApp,
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
        ],
      ),
    );
  }
}
