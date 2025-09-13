/// Dialog widget for displaying detailed application information.
///
/// Shows comprehensive information about an application including metadata,
/// development progress, status history, and available actions.
library;

import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/user_application/models/application_status.dart';
import '../../../../services/user_application/models/user_application.dart';
import '../../../../theme/insets.dart';

/// Callback type for application actions from the details dialog.
typedef ApplicationDetailsActionCallback = void Function(UserApplication application);

/// Dialog widget for displaying application details.
///
/// Provides a comprehensive view of application information including
/// metadata, current status, development progress, and available actions.
/// The dialog adapts its content based on the application's current state.
class ApplicationDetailsDialog extends StatelessWidget {
  /// Creates an application details dialog.
  ///
  /// @param application The application to show details for
  /// @param onLaunch Callback when launch action is selected
  /// @param onModify Callback when modify action is selected
  /// @param onRestart Callback when restart action is selected
  /// @param onStop Callback when stop action is selected
  /// @param onDelete Callback when delete action is selected
  /// @param onToggleFavorite Callback when toggle favorite action is selected
  const ApplicationDetailsDialog({
    required this.application,
    this.onLaunch,
    this.onModify,
    this.onRestart,
    this.onStop,
    this.onDelete,
    this.onToggleFavorite,
    super.key,
  });

  /// The application to show details for.
  final UserApplication application;

  /// Callback invoked when the launch action is selected.
  final ApplicationDetailsActionCallback? onLaunch;

  /// Callback invoked when the modify action is selected.
  final ApplicationDetailsActionCallback? onModify;

  /// Callback invoked when the restart action is selected.
  final ApplicationDetailsActionCallback? onRestart;

  /// Callback invoked when the stop action is selected.
  final ApplicationDetailsActionCallback? onStop;

  /// Callback invoked when the delete action is selected.
  final ApplicationDetailsActionCallback? onDelete;

  /// Callback invoked when the toggle favorite action is selected.
  final ApplicationDetailsActionCallback? onToggleFavorite;

  /// Shows the application details dialog.
  ///
  /// This static method creates and displays the details dialog as a modal.
  /// The dialog is dismissible and includes a close button.
  ///
  /// @param context Build context for showing the dialog
  /// @param application Application to show details for
  /// @param onLaunch Launch action callback
  /// @param onModify Modify action callback
  /// @param onRestart Restart action callback
  /// @param onStop Stop action callback
  /// @param onDelete Delete action callback
  /// @param onToggleFavorite Toggle favorite action callback
  static Future<void> show({
    required BuildContext context,
    required UserApplication application,
    ApplicationDetailsActionCallback? onLaunch,
    ApplicationDetailsActionCallback? onModify,
    ApplicationDetailsActionCallback? onRestart,
    ApplicationDetailsActionCallback? onStop,
    ApplicationDetailsActionCallback? onDelete,
    ApplicationDetailsActionCallback? onToggleFavorite,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return ApplicationDetailsDialog(
          application: application,
          onLaunch: onLaunch,
          onModify: onModify,
          onRestart: onRestart,
          onStop: onStop,
          onDelete: onDelete,
          onToggleFavorite: onToggleFavorite,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(Insets.medium),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // Application icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getApplicationIcon(),
                      color: colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: Insets.medium),

                  // Title and status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.title,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: Insets.xxSmall),
                        _buildStatusChip(context),
                      ],
                    ),
                  ),

                  // Close button
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: l10n.close,
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Insets.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    _buildSection(
                      context: context,
                      title: l10n.detailsDescription,
                      child: Text(
                        application.description,
                        style: textTheme.bodyMedium,
                      ),
                    ),

                    const SizedBox(height: Insets.medium),

                    // Progress (if in development)
                    if (application.isInDevelopment && application.progress != null) ...[
                      _buildSection(
                        context: context,
                        title: l10n.detailsDevelopmentProgress,
                        child: Text(
                          '${application.progress!.percentage}% • ${application.progress!.currentPhase}',
                          style: textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: Insets.medium),
                    ],

                    // Metadata
                    _buildSection(
                      context: context,
                      title: l10n.detailsInformation,
                      child: Column(
                        children: [
                          _buildInfoRow(
                            context: context,
                            label: l10n.detailsCreated,
                            value: application.createdTimeDescription,
                          ),
                          _buildInfoRow(
                            context: context,
                            label: l10n.detailsLastUpdated,
                            value: application.updatedTimeDescription,
                          ),
                          if (application.hasCategory)
                            _buildInfoRow(
                              context: context,
                              label: l10n.detailsCategory,
                              value: application.category!.displayName,
                            ),
                          if (application.hasTags)
                            _buildInfoRow(
                              context: context,
                              label: l10n.detailsTags,
                              value: application.tags.join(', '),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(Insets.medium),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _buildActionButtons(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a section with a title and content.
  ///
  /// Creates a consistently styled section with a title and child content.
  /// Used for organizing information in the details dialog.
  ///
  /// @param context Build context for theming
  /// @param title Section title
  /// @param child Section content widget
  /// @returns Styled section widget
  Widget _buildSection({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: Insets.small),
        child,
      ],
    );
  }

  /// Builds an information row with label and value.
  ///
  /// Creates a row displaying a label and its corresponding value
  /// with consistent styling and spacing.
  ///
  /// @param context Build context for theming
  /// @param label Information label
  /// @param value Information value
  /// @returns Styled information row widget
  Widget _buildInfoRow({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.xSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the status chip for the application.
  ///
  /// Creates a styled chip showing the current application status
  /// with appropriate colors and icons.
  ///
  /// @param context Build context for theming
  /// @returns Status chip widget
  Widget _buildStatusChip(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    Color chipColor;
    Color textColor;
    IconData icon;

    switch (application.status) {
      case ApplicationStatus.requested:
        chipColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        icon = Icons.schedule;
      case ApplicationStatus.developing:
      case ApplicationStatus.testing:
      case ApplicationStatus.updating:
        chipColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        icon = Icons.build;
      case ApplicationStatus.ready:
        chipColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        icon = Icons.check_circle;
      case ApplicationStatus.running:
        chipColor = colorScheme.primary.withValues(alpha: 0.1);
        textColor = colorScheme.primary;
        icon = Icons.play_circle_filled;
      case ApplicationStatus.failed:
        chipColor = colorScheme.error.withValues(alpha: 0.1);
        textColor = colorScheme.error;
        icon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.small,
        vertical: Insets.xxSmall,
      ),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: Insets.xxSmall),
          Text(
            application.status.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the action buttons for the dialog.
  ///
  /// Creates a list of action buttons based on the application's current
  /// status and available operations.
  ///
  /// @param context Build context for theming and localization
  /// @returns List of action button widgets
  List<Widget> _buildActionButtons(BuildContext context) {
    final List<Widget> buttons = [];
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    // Launch/Bring to foreground button
    if (application.canLaunch && onLaunch != null) {
      final String buttonText = application.status == ApplicationStatus.running
          ? l10n.buttonBringToForeground
          : l10n.buttonLaunchApplication;

      buttons.add(
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onLaunch!(application);
          },
          icon: Icon(
            application.status == ApplicationStatus.running ? Icons.open_in_new : Icons.play_arrow,
          ),
          label: Text(buttonText),
        ),
      );
    }

    // Restart button (for running applications)
    if (application.status == ApplicationStatus.running && onRestart != null) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(width: Insets.small));
      }
      buttons.add(
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onRestart!(application);
          },
          icon: const Icon(Icons.restart_alt),
          label: Text(l10n.buttonRestartApplication),
        ),
      );
    }

    // Stop button (for running applications)
    if (application.status == ApplicationStatus.running && onStop != null) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(width: Insets.small));
      }
      buttons.add(
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onStop!(application);
          },
          icon: const Icon(Icons.stop),
          label: Text(l10n.buttonStopApplication),
        ),
      );
    }

    // Modify button
    if (application.canModify && onModify != null) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(width: Insets.small));
      }
      buttons.add(
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onModify!(application);
          },
          icon: const Icon(Icons.edit),
          label: Text(l10n.buttonModifyApplication),
        ),
      );
    }

    // Retry button (for failed applications)
    if (application.status == ApplicationStatus.failed && onModify != null) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(width: Insets.small));
      }
      buttons.add(
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onModify!(application);
          },
          icon: const Icon(Icons.refresh),
          label: Text(l10n.buttonRetryApplication),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
        ),
      );
    }

    // Delete button
    if (onDelete != null && _canDelete(application)) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(width: Insets.small));
      }
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _showDeleteConfirmation(context),
          icon: const Icon(Icons.delete_outline),
          label: Text(l10n.buttonDeleteApplication),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
      );
    }

    return buttons;
  }

  /// Shows a confirmation dialog for deleting the application.
  ///
  /// Displays a dialog asking the user to confirm the deletion of the
  /// application. Shows the application title in the confirmation message.
  ///
  /// @param context Build context for showing the dialog
  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.deleteConfirmTitle),
          content: Text(
            l10n.deleteConfirmMessage(application.title),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.buttonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(l10n.buttonDelete),
            ),
          ],
        );
      },
    );

    if ((confirmed ?? false) && context.mounted) {
      Navigator.of(context).pop(); // Close details dialog
      onDelete!(application);
    }
  }

  /// Returns the appropriate icon for the application.
  ///
  /// Uses different icons based on the application status to provide
  /// visual context in the dialog header.
  ///
  /// @returns Icon data for the application
  IconData _getApplicationIcon() {
    switch (application.status) {
      case ApplicationStatus.failed:
        return Icons.error_outline;
      case ApplicationStatus.running:
        return Icons.play_circle_filled;
      case ApplicationStatus.ready:
        return Icons.check_circle_outline;
      case ApplicationStatus.developing:
      case ApplicationStatus.testing:
      case ApplicationStatus.updating:
        return Icons.build;
      default:
        return Icons.apps;
    }
  }

  /// Determines if an application can be deleted.
  ///
  /// Applications can be deleted if they are not currently running
  /// or in an active development state.
  ///
  /// @param application Application to check
  /// @returns True if the application can be deleted
  static bool _canDelete(UserApplication application) {
    switch (application.status) {
      case ApplicationStatus.running:
      case ApplicationStatus.developing:
      case ApplicationStatus.testing:
      case ApplicationStatus.updating:
        return false;
      case ApplicationStatus.requested:
      case ApplicationStatus.ready:
      case ApplicationStatus.failed:
        return true;
    }
  }
}
