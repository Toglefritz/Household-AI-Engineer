// This library groups widgets related to the grid of user applications.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/user_application/models/user_application.dart';
import '../../../../theme/insets.dart';
import 'application_tile.dart';
import 'bulk_selection_toolbar.dart';

// Parts
part 'application_grid_empty_state.dart';

/// A responsive grid widget for displaying application tiles.
///
/// Automatically adjusts the number of columns based on available width
/// while maintaining consistent tile sizing and spacing. Supports selection,
/// hover states, and context menus for application management.
class ApplicationGrid extends StatelessWidget {
  /// Creates an application grid widget.
  ///
  /// @param applications List of applications to display
  /// @param onApplicationTap Callback when an application tile is tapped
  /// @param onApplicationSecondaryTap Callback when an application tile is right-clicked
  /// @param onCreateNewApplication Callback when the create new application button is tapped
  /// @param selectedApplicationIds Set of currently selected application IDs
  /// @param onSelectionChanged Callback when selection state changes
  /// @param onSelectAll Callback when select all is requested
  /// @param onSelectNone Callback when clear selection is requested
  /// @param onBulkDelete Callback when bulk delete is requested
  const ApplicationGrid({
    required this.applications,
    this.onApplicationTap,
    this.onApplicationSecondaryTap,
    this.onCreateNewApplication,
    this.selectedApplicationIds = const {},
    this.onSelectionChanged,
    this.onSelectAll,
    this.onSelectNone,
    this.onBulkDelete,
    super.key,
  });

  /// List of applications to display in the grid.
  ///
  /// Each application will be rendered as an individual tile
  /// with appropriate status indicators and metadata.
  final List<UserApplication> applications;

  /// Callback invoked when a user taps an application tile.
  ///
  /// Receives the tapped application as a parameter.
  /// Typically used for launching applications or showing details.
  final void Function(UserApplication application)? onApplicationTap;

  /// Callback invoked when a user right-clicks an application tile.
  ///
  /// Receives the right-clicked application as a parameter and the tap position.
  /// Used for showing context menus with management options.
  final void Function(UserApplication application, Offset position)? onApplicationSecondaryTap;

  /// Callback invoked when the create new application button is tapped.
  ///
  /// Used to open the conversational interface for creating new applications.
  final VoidCallback? onCreateNewApplication;

  /// Set of application IDs that are currently selected.
  ///
  /// Selected tiles will display selection styling to indicate
  /// they are part of a multi-selection or current focus.
  final Set<String> selectedApplicationIds;

  /// Callback invoked when an application's selection state changes.
  ///
  /// Receives the application and whether it should be selected.
  /// Used for multi-selection operations.
  final void Function(UserApplication application, {required bool isSelected})? onSelectionChanged;

  /// Callback invoked when select all is requested.
  ///
  /// Should select all applications in the current view.
  final VoidCallback? onSelectAll;

  /// Callback invoked when clear selection is requested.
  ///
  /// Should clear all current selections.
  final VoidCallback? onSelectNone;

  /// Callback invoked when bulk delete is requested.
  ///
  /// Receives the list of applications to delete.
  final void Function(List<UserApplication> applications)? onBulkDelete;

  /// Calculates the optimal number of columns based on available width.
  ///
  /// Uses responsive breakpoints to ensure tiles are appropriately sized
  /// across different screen sizes while maintaining readability.
  ///
  /// @param availableWidth Total width available for the grid
  /// @returns Optimal number of columns for the current screen size
  int _calculateCrossAxisCount(double availableWidth) {
    const double minTileWidth = 280.0; // Minimum width for readability
    const double spacing = Insets.small; // Spacing between tiles

    // Calculate how many tiles can fit with minimum width and spacing
    final int maxColumns = ((availableWidth + spacing) / (minTileWidth + spacing)).floor();

    // Apply responsive constraints for better UX
    if (availableWidth < 600) {
      return 1; // Single column on very narrow screens
    } else if (availableWidth < 900) {
      return 2; // Two columns on medium screens
    } else if (availableWidth < 1200) {
      return 3; // Three columns on larger screens
    } else {
      return maxColumns.clamp(1, 4); // Maximum 4 columns for readability
    }
  }

  @override
  Widget build(BuildContext context) {
    // If there are no applications, build a view communicating this to the user.
    if (applications.isEmpty) {
      return ApplicationGridEmptyState(
        onCreateNewApplication: onCreateNewApplication,
      );
    }

    final List<UserApplication> selectedApps = applications
        .where((app) => selectedApplicationIds.contains(app.id))
        .toList();

    return Stack(
      children: [
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int crossAxisCount = _calculateCrossAxisCount(
              constraints.maxWidth,
            );

            return GridView.builder(
              padding: EdgeInsets.only(
                left: Insets.small,
                right: Insets.small,
                top: Insets.small,
                bottom: selectedApps.isNotEmpty ? 100 : Insets.small,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: Insets.small,
                mainAxisSpacing: Insets.small,
                childAspectRatio: 1.6,
              ),
              itemCount: applications.length,
              itemBuilder: (BuildContext context, int index) {
                final UserApplication application = applications[index];
                final bool isSelected = selectedApplicationIds.contains(
                  application.id,
                );

                return GestureDetector(
                  onTap: () => _handleTileTap(application),
                  onSecondaryTapDown: (TapDownDetails details) => _handleSecondaryTap(application, details),
                  onLongPress: () => _handleLongPress(application),
                  child: ApplicationTile(
                    application: application,
                    isSelected: isSelected,
                  ),
                );
              },
            );
          },
        ),

        // Bulk selection toolbar
        if (selectedApps.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BulkSelectionToolbar(
              selectedApplications: selectedApps,
              totalApplications: applications.length,
              onSelectAll: onSelectAll,
              onSelectNone: onSelectNone,
              onBulkDelete: onBulkDelete,
            ),
          ),
      ],
    );
  }

  /// Handles tile tap events with multi-selection support.
  ///
  /// If Ctrl/Cmd is held, toggles selection. Otherwise, performs normal tap action.
  ///
  /// @param application The application that was tapped
  void _handleTileTap(UserApplication application) {
    // Check if Ctrl (Windows/Linux) or Cmd (macOS) is pressed
    final bool isMultiSelectModifier =
        HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;

    if (isMultiSelectModifier && onSelectionChanged != null) {
      // Toggle selection
      final bool isSelected = selectedApplicationIds.contains(application.id);
      onSelectionChanged!(application, isSelected: !isSelected);
    } else if (selectedApplicationIds.isNotEmpty && onSelectNone != null) {
      // Clear selection if any items are selected
      onSelectNone!();
    } else if (onApplicationTap != null) {
      // Normal tap action
      onApplicationTap?.call(application);
    }
  }

  /// Handles secondary tap (right-click) events.
  ///
  /// Shows context menu at the tap position.
  ///
  /// @param application The application that was right-clicked
  /// @param details Tap details containing position information
  void _handleSecondaryTap(UserApplication application, TapDownDetails details) {
    if (onApplicationSecondaryTap != null) {
      onApplicationSecondaryTap?.call(application, details.globalPosition);
    }
  }

  /// Handles long press events for mobile selection.
  ///
  /// Toggles selection state on long press for touch devices.
  ///
  /// @param application The application that was long-pressed
  void _handleLongPress(UserApplication application) {
    if (onSelectionChanged != null) {
      final bool isSelected = selectedApplicationIds.contains(application.id);
      onSelectionChanged!(application, isSelected: !isSelected);
    }
  }
}
