import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/models.dart';
import '../../../../theme/insets.dart';
import 'application_tile.dart';

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
  /// @param selectedApplicationIds Set of currently selected application IDs
  const ApplicationGrid({
    required this.applications,
    this.onApplicationTap,
    this.onApplicationSecondaryTap,
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

  /// Set of application IDs that are currently selected.
  ///
  /// Selected tiles will display selection styling to indicate
  /// they are part of a multi-selection or current focus.
  final Set<String> selectedApplicationIds;

  @override
  Widget build(BuildContext context) {
    // If there are no applications, build a view communicating this to the user.
    if (applications.isEmpty) {
      return _buildEmptyState(context);
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);

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
            final bool isSelected = selectedApplicationIds.contains(application.id);

            return ApplicationTile(
              application: application,
              isSelected: isSelected,
              onTap: onApplicationTap != null ? () => onApplicationTap!(application) : null,
              onSecondaryTap: onApplicationSecondaryTap != null ? () => onApplicationSecondaryTap!(application) : null,
            );
          },
        );
      },
    );
  }

  /// Builds the empty state widget when no applications are available.
  ///
  /// Displays a friendly message encouraging users to create their first
  /// application with appropriate visual styling.
  Widget _buildEmptyState(BuildContext context) {
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
              onPressed: () {
                // TODO(Scott): Implement create new application flow
                debugPrint('Create new application tapped');
              },
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.buttonCreateNewApp),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
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
}
