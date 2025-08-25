/// Toolbar widget for bulk application management operations.
///
/// Appears when one or more applications are selected, providing actions
/// that can be performed on multiple applications simultaneously.
library;

import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/user_application/models/application_status.dart';
import '../../../../services/user_application/models/user_application.dart';
import '../../../../theme/insets.dart';

/// Callback type for bulk operations on applications.
///
/// Used by toolbar actions to communicate bulk operations back to
/// the parent controller for processing.
typedef BulkApplicationActionCallback = void Function(List<UserApplication> applications);

/// Toolbar widget for bulk application management.
///
/// Displays a floating toolbar with bulk actions when applications are selected.
/// The toolbar shows the selection count and provides actions like delete,
/// select all, and clear selection.
class BulkSelectionToolbar extends StatelessWidget {
  /// Creates a bulk selection toolbar.
  ///
  /// @param selectedApplications List of currently selected applications
  /// @param totalApplications Total number of applications available
  /// @param onSelectAll Callback to select all applications
  /// @param onSelectNone Callback to clear all selections
  /// @param onBulkDelete Callback to delete selected applications
  /// @param onBulkModify Callback to modify selected applications (future)
  const BulkSelectionToolbar({
    required this.selectedApplications,
    required this.totalApplications,
    this.onSelectAll,
    this.onSelectNone,
    this.onBulkDelete,
    this.onBulkModify,
    super.key,
  });

  /// List of currently selected applications.
  ///
  /// Used to determine available actions and show selection count.
  final List<UserApplication> selectedApplications;

  /// Total number of applications available for selection.
  ///
  /// Used to determine if "Select All" should be available and
  /// to show selection progress.
  final int totalApplications;

  /// Callback invoked when select all action is triggered.
  ///
  /// Should select all applications in the current view.
  final VoidCallback? onSelectAll;

  /// Callback invoked when clear selection action is triggered.
  ///
  /// Should clear all current selections.
  final VoidCallback? onSelectNone;

  /// Callback invoked when bulk delete action is triggered.
  ///
  /// Receives the list of selected applications to delete.
  final BulkApplicationActionCallback? onBulkDelete;

  /// Callback invoked when bulk modify action is triggered.
  ///
  /// Reserved for future implementation of bulk modification features.
  final BulkApplicationActionCallback? onBulkModify;

  /// Whether all applications are currently selected.
  ///
  /// Used to determine if "Select All" or "Select None" should be shown.
  bool get _allSelected => selectedApplications.length == totalApplications;

  /// Whether any applications can be deleted from the current selection.
  ///
  /// Applications can be deleted if they are not running or in development.
  bool get _canDeleteSelected {
    return selectedApplications.any(_canDelete);
  }

  /// List of selected applications that can be deleted.
  ///
  /// Filters the selection to only include applications that are safe to delete.
  List<UserApplication> get _deletableApplications {
    return selectedApplications.where(_canDelete).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.all(Insets.medium),
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.medium,
        vertical: Insets.small,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selection count
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.small,
              vertical: Insets.xSmall,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              l10n.selectedCount(selectedApplications.length),
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(width: Insets.medium),

          // Select All/None button
          if (onSelectAll != null && onSelectNone != null) ...[
            _buildToolbarButton(
              context: context,
              icon: _allSelected ? Icons.deselect : Icons.select_all,
              label: _allSelected ? l10n.selectNone : l10n.selectAll,
              onPressed: _allSelected ? onSelectNone : onSelectAll,
            ),
            const SizedBox(width: Insets.small),
          ],

          // Bulk delete button
          if (onBulkDelete != null && _canDeleteSelected) ...[
            _buildToolbarButton(
              context: context,
              icon: Icons.delete_outline,
              label: l10n.buttonDelete,
              onPressed: () => _showBulkDeleteConfirmation(context),
              color: colorScheme.error,
            ),
          ],
        ],
      ),
    );
  }

  /// Builds a toolbar button with consistent styling.
  ///
  /// Creates a button with an icon and label that follows the toolbar
  /// design patterns and provides appropriate visual feedback.
  ///
  /// @param context Build context for theming
  /// @param icon Icon to display on the button
  /// @param label Text label for the button
  /// @param onPressed Callback when button is pressed
  /// @param color Optional color override for the button
  /// @returns Styled toolbar button widget
  Widget _buildToolbarButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color effectiveColor = color ?? colorScheme.onPrimaryContainer;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.small,
            vertical: Insets.xSmall,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: effectiveColor,
              ),
              const SizedBox(width: Insets.xSmall),
              Text(
                label,
                style: TextStyle(
                  color: effectiveColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a confirmation dialog for bulk delete operation.
  ///
  /// Displays a dialog asking the user to confirm the deletion of multiple
  /// applications. Shows the count of applications that will be deleted.
  ///
  /// @param context Build context for showing the dialog
  Future<void> _showBulkDeleteConfirmation(BuildContext context) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final List<UserApplication> deletableApps = _deletableApplications;

    if (deletableApps.isEmpty) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.bulkDeleteConfirmTitle),
          content: Text(
            l10n.bulkDeleteConfirmMessage(deletableApps.length),
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

    if (confirmed ?? false) {
      onBulkDelete!(deletableApps);
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
