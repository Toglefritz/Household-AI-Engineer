/// Context menu widget for application management actions.
///
/// Provides a popup menu with application-specific actions based on the
/// current application status and capabilities. Actions include launching,
/// modifying, restarting, and deleting applications.
library;

import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/user_application/models/application_status.dart';
import '../../../../services/user_application/models/user_application.dart';
import '../../../../theme/insets.dart';

/// Callback type for application management actions.
///
/// Used by context menu items to communicate user actions back to
/// the parent controller for processing.
typedef ApplicationActionCallback = void Function(UserApplication application);

/// Context menu widget for application management.
///
/// Displays a popup menu with available actions for the specified application.
/// The menu items are dynamically generated based on the application's current
/// status and capabilities.
class ApplicationContextMenu extends StatelessWidget {
  /// Creates an application context menu.
  ///
  /// @param application The application to show actions for
  /// @param onLaunch Callback when launch action is selected
  /// @param onModify Callback when modify action is selected
  /// @param onRestart Callback when restart action is selected
  /// @param onStop Callback when stop action is selected
  /// @param onDelete Callback when delete action is selected
  /// @param onViewDetails Callback when view details action is selected
  /// @param onToggleFavorite Callback when toggle favorite action is selected
  const ApplicationContextMenu({
    required this.application,
    this.onLaunch,
    this.onModify,
    this.onRestart,
    this.onStop,
    this.onDelete,
    this.onViewDetails,
    this.onToggleFavorite,
    super.key,
  });

  /// The application to show context menu actions for.
  ///
  /// Used to determine which actions are available and appropriate
  /// for the current application state.
  final UserApplication application;

  /// Callback invoked when the launch action is selected.
  ///
  /// Only available for applications that can be launched (ready or running).
  final ApplicationActionCallback? onLaunch;

  /// Callback invoked when the modify action is selected.
  ///
  /// Available for applications in stable states that can be modified.
  final ApplicationActionCallback? onModify;

  /// Callback invoked when the restart action is selected.
  ///
  /// Only available for running applications that can be restarted.
  final ApplicationActionCallback? onRestart;

  /// Callback invoked when the stop action is selected.
  ///
  /// Only available for running applications that can be stopped.
  final ApplicationActionCallback? onStop;

  /// Callback invoked when the delete action is selected.
  ///
  /// Available for applications that are not currently running or developing.
  final ApplicationActionCallback? onDelete;

  /// Callback invoked when the view details action is selected.
  ///
  /// Available for all applications to show detailed information.
  final ApplicationActionCallback? onViewDetails;

  /// Callback invoked when the toggle favorites action is selected.
  ///
  /// Available for all applications to add/remove from favorites.
  final ApplicationActionCallback? onToggleFavorite;

  /// Shows the context menu at the specified position.
  ///
  /// This static method creates and displays the context menu as a popup
  /// at the given screen coordinates. Used by application tiles when
  /// right-clicked or long-pressed.
  ///
  /// @param context Build context for showing the menu
  /// @param position Screen position where the menu should appear
  /// @param application Application to show actions for
  /// @param onLaunch Launch action callback
  /// @param onModify Modify action callback
  /// @param onRestart Restart action callback
  /// @param onStop Stop action callback
  /// @param onDelete Delete action callback
  /// @param onViewDetails View details action callback
  /// @param onToggleFavorite Toggle favorite action callback
  static Future<void> show({
    required BuildContext context,
    required Offset position,
    required UserApplication application,
    ApplicationActionCallback? onLaunch,
    ApplicationActionCallback? onModify,
    ApplicationActionCallback? onRestart,
    ApplicationActionCallback? onStop,
    ApplicationActionCallback? onDelete,
    ApplicationActionCallback? onViewDetails,
    ApplicationActionCallback? onToggleFavorite,
  }) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;

    await showMenu<void>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: _buildMenuItems(
        context,
        application,
        onLaunch: onLaunch,
        onModify: onModify,
        onRestart: onRestart,
        onStop: onStop,
        onDelete: onDelete,
        onViewDetails: onViewDetails,
        onToggleFavorite: onToggleFavorite,
      ),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  /// Builds the list of menu items based on application status.
  ///
  /// Dynamically creates menu items that are appropriate for the current
  /// application state. Items are ordered by frequency of use and logical grouping.
  ///
  /// @param context Build context for localization
  /// @param application Application to build menu for
  /// @param onLaunch Launch action callback
  /// @param onModify Modify action callback
  /// @param onRestart Restart action callback
  /// @param onStop Stop action callback
  /// @param onDelete Delete action callback
  /// @param onViewDetails View details action callback
  /// @param onToggleFavorite Toggle favorite action callback
  /// @returns List of popup menu items
  static List<PopupMenuEntry<void>> _buildMenuItems(
    BuildContext context,
    UserApplication application, {
    ApplicationActionCallback? onLaunch,
    ApplicationActionCallback? onModify,
    ApplicationActionCallback? onRestart,
    ApplicationActionCallback? onStop,
    ApplicationActionCallback? onDelete,
    ApplicationActionCallback? onViewDetails,
    ApplicationActionCallback? onToggleFavorite,
  }) {
    final List<PopupMenuEntry<void>> items = [];
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    // Launch action - for ready applications
    if (application.status == ApplicationStatus.ready && onLaunch != null) {
      items.add(
        PopupMenuItem<void>(
          onTap: () => onLaunch(application),
          child: _buildMenuItem(
            icon: Icons.play_arrow,
            title: l10n.buttonLaunchApplication,
            color: Colors.green,
          ),
        ),
      );
    }

    // Bring to foreground action - for running applications
    if (application.status == ApplicationStatus.running && onLaunch != null) {
      items.add(
        PopupMenuItem<void>(
          onTap: () => onLaunch(application),
          child: _buildMenuItem(
            icon: Icons.open_in_new,
            title: l10n.buttonBringToForeground,
            color: Colors.blue,
          ),
        ),
      );
    }

    // Restart action - for running applications
    if (application.status == ApplicationStatus.running && onRestart != null) {
      items.add(
        PopupMenuItem<void>(
          onTap: () => onRestart(application),
          child: _buildMenuItem(
            icon: Icons.restart_alt,
            title: l10n.buttonRestartApplication,
            color: Colors.orange,
          ),
        ),
      );
    }

    // Stop action - for running applications
    if (application.status == ApplicationStatus.running && onStop != null) {
      items.add(
        PopupMenuItem<void>(
          onTap: () => onStop(application),
          child: _buildMenuItem(
            icon: Icons.stop,
            title: l10n.buttonStopApplication,
            color: Colors.red,
          ),
        ),
      );
    }

    // Add divider if we have primary actions
    if (items.isNotEmpty) {
      items.add(const PopupMenuDivider());
    }

    // Modify action - for applications that can be modified
    if (application.canModify && onModify != null) {
      items.add(
        PopupMenuItem<void>(
          onTap: () => onModify(application),
          child: _buildMenuItem(
            icon: Icons.edit,
            title: l10n.buttonModifyApplication,
          ),
        ),
      );
    }

    // View details action - always available
    if (onViewDetails != null) {
      items.add(
        PopupMenuItem<void>(
          onTap: () => onViewDetails(application),
          child: _buildMenuItem(
            icon: Icons.info_outline,
            title: l10n.buttonViewDetails,
          ),
        ),
      );
    }

    // Toggle favorite action - always available
    if (onToggleFavorite != null) {
      items.add(
        PopupMenuItem<void>(
          onTap: () => onToggleFavorite(application),
          child: _buildMenuItem(
            icon: application.isFavorite ? Icons.favorite : Icons.favorite_border,
            title: application.isFavorite ? l10n.buttonRemoveFromFavorites : l10n.buttonAddToFavorites,
            color: application.isFavorite ? Colors.red : null,
          ),
        ),
      );
    }

    // Retry action - for failed applications
    if (application.status == ApplicationStatus.failed && onModify != null) {
      items.add(
        PopupMenuItem<void>(
          onTap: () => onModify(application),
          child: _buildMenuItem(
            icon: Icons.refresh,
            title: l10n.buttonRetryApplication,
            color: Colors.orange,
          ),
        ),
      );
    }

    // Add divider before destructive actions
    if (onDelete != null && _canDelete(application)) {
      items..add(const PopupMenuDivider())

      // Delete action - for applications that can be deleted
      ..add(
        PopupMenuItem<void>(
          onTap: () => onDelete(application),
          child: _buildMenuItem(
            icon: Icons.delete_outline,
            title: l10n.buttonDeleteApplication,
            color: Colors.red,
          ),
        ),
      );
    }

    return items;
  }

  /// Builds a menu item widget with consistent styling.
  ///
  /// Creates a menu item with an icon, title, and optional color styling.
  /// All menu items use consistent padding and typography.
  ///
  /// @param icon Icon to display for the menu item
  /// @param title Text to display for the menu item
  /// @param color Optional color for the icon and text
  /// @returns Styled menu item widget
  static Widget _buildMenuItem({
    required IconData icon,
    required String title,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.xxSmall),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(width: Insets.small),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    // This widget is not meant to be built directly.
    // Use the static show method instead.
    throw UnsupportedError(
      'ApplicationContextMenu should be shown using the static show method',
    );
  }
}
