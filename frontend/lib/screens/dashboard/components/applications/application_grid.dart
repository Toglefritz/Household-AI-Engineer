// This library groups widgets related to the grid of user applications.
library;

import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/user_application/models/user_application.dart';
import '../../../../theme/insets.dart';
import 'application_tile.dart';

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
  const ApplicationGrid({
    required this.applications,
    this.onApplicationTap,
    this.onApplicationSecondaryTap,
    this.onCreateNewApplication,
    this.selectedApplicationIds = const {},
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
  /// Receives the right-clicked application as a parameter.
  /// Used for showing context menus with management options.
  final void Function(UserApplication application)? onApplicationSecondaryTap;

  /// Callback invoked when the create new application button is tapped.
  ///
  /// Used to open the conversational interface for creating new applications.
  final VoidCallback? onCreateNewApplication;

  /// Set of application IDs that are currently selected.
  ///
  /// Selected tiles will display selection styling to indicate
  /// they are part of a multi-selection or current focus.
  final Set<String> selectedApplicationIds;

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
    final int maxColumns =
        ((availableWidth + spacing) / (minTileWidth + spacing)).floor();

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

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int crossAxisCount = _calculateCrossAxisCount(
          constraints.maxWidth,
        );

        return GridView.builder(
          padding: const EdgeInsets.all(Insets.small),
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

            return ApplicationTile(
              application: application,
              isSelected: isSelected,
              onTap: onApplicationTap != null
                  ? () => onApplicationTap!(application)
                  : null,
              onSecondaryTap: onApplicationSecondaryTap != null
                  ? () => onApplicationSecondaryTap!(application)
                  : null,
            );
          },
        );
      },
    );
  }
}
