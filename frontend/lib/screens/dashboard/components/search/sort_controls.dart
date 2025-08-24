/// Sort controls component for application ordering.
///
/// This component provides sorting options for the application grid
/// including multiple sort criteria and visual indicators for the
/// current sort state. Integrates with the search controller for
/// real-time sort updates and state management.

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/search/models/search_filter.dart';
import '../../../../theme/insets.dart';
import 'search_controller.dart' as search;

/// Sort controls widget with multiple sorting options.
///
/// Provides a dropdown menu for selecting sort criteria and visual
/// indicators for the current sort state. Integrates with SearchController
/// for real-time sort updates and result reordering.
class SortControls extends StatelessWidget {
  /// Creates a sort controls widget.
  ///
  /// @param controller Search controller for managing sort state
  /// @param onSortChanged Optional callback when sort option changes
  const SortControls({
    required this.controller,
    this.onSortChanged,
    super.key,
  });

  /// Search controller for managing sort state and operations.
  ///
  /// Provides access to current sort option and methods
  /// for updating sort criteria and triggering result reordering.
  final search.ApplicationSearchController controller;

  /// Optional callback invoked when the sort option changes.
  ///
  /// Called with the new sort option whenever the user
  /// selects a different sorting method. Useful for analytics.
  final void Function(SortOption sortOption)? onSortChanged;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final SortOption currentSort = controller.currentFilter.sortOption;
        final int resultCount = controller.resultCount;

        return Row(
          children: [
            // Sort label
            Icon(
              Icons.sort,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: Insets.small),
            Text(
              AppLocalizations.of(context)!.sortBy,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: Insets.small),

            // Sort dropdown
            Expanded(
              child: DropdownButton<SortOption>(
                value: currentSort,
                onChanged: (SortOption? newSort) {
                  if (newSort != null) {
                    controller.updateSortOption(newSort);
                    onSortChanged?.call(newSort);
                  }
                },
                items: SortOption.values.map((SortOption option) {
                  return DropdownMenuItem<SortOption>(
                    value: option,
                    child: Text(
                      option.displayName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }).toList(),
                isExpanded: true,
                underline: Container(), // Remove default underline
                icon: const Icon(Icons.arrow_drop_down),
                style: Theme.of(context).textTheme.bodyMedium,
                dropdownColor: Theme.of(context).colorScheme.surface,
              ),
            ),

            // Result count indicator
            if (resultCount > 0) ...[
              const SizedBox(width: Insets.medium),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Insets.small,
                  vertical: Insets.xSmall,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getResultCountText(context, resultCount),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /// Gets the result count text for display.
  ///
  /// @param context Build context for localization
  /// @param count Number of results
  /// @returns Formatted result count text
  String _getResultCountText(BuildContext context, int count) {
    if (count == 1) {
      return AppLocalizations.of(context)!.oneResult;
    } else {
      return AppLocalizations.of(context)!.multipleResults(count);
    }
  }
}

/// Compact sort controls widget for smaller spaces.
///
/// Provides a more compact version of the sort controls with just
/// the dropdown and minimal labeling. Suitable for toolbar use.
class CompactSortControls extends StatelessWidget {
  /// Creates compact sort controls widget.
  ///
  /// @param controller Search controller for managing sort state
  /// @param onSortChanged Optional callback when sort option changes
  const CompactSortControls({
    required this.controller,
    this.onSortChanged,
    super.key,
  });

  /// Search controller for managing sort state and operations.
  final search.ApplicationSearchController controller;

  /// Optional callback invoked when the sort option changes.
  final void Function(SortOption sortOption)? onSortChanged;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final SortOption currentSort = controller.currentFilter.sortOption;

        return PopupMenuButton<SortOption>(
          initialValue: currentSort,
          onSelected: (SortOption newSort) {
            controller.updateSortOption(newSort);
            onSortChanged?.call(newSort);
          },
          itemBuilder: (BuildContext context) {
            return SortOption.values.map((SortOption option) {
              return PopupMenuItem<SortOption>(
                value: option,
                child: Row(
                  children: [
                    if (option == currentSort)
                      Icon(
                        Icons.check,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: Insets.small),
                    Expanded(
                      child: Text(
                        option.displayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: option == currentSort ? Theme.of(context).colorScheme.primary : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.small,
              vertical: Insets.xSmall,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sort,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: Insets.xSmall),
                Text(
                  _getSortDisplayName(context, currentSort),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: Insets.xSmall),
                Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Gets a shortened display name for the sort option.
  ///
  /// @param context Build context for localization
  /// @param sortOption Sort option to get display name for
  /// @returns Shortened display name
  String _getSortDisplayName(BuildContext context, SortOption sortOption) {
    switch (sortOption) {
      case SortOption.createdDateDesc:
        return AppLocalizations.of(context)!.newest;
      case SortOption.createdDateAsc:
        return AppLocalizations.of(context)!.oldest;
      case SortOption.updatedDateDesc:
        return AppLocalizations.of(context)!.recentlyUpdated;
      case SortOption.updatedDateAsc:
        return AppLocalizations.of(context)!.leastRecentlyUpdated;
      case SortOption.titleAsc:
        return AppLocalizations.of(context)!.titleAZ;
      case SortOption.titleDesc:
        return AppLocalizations.of(context)!.titleZA;
      case SortOption.statusPriority:
        return AppLocalizations.of(context)!.statusPriority;
    }
  }
}
