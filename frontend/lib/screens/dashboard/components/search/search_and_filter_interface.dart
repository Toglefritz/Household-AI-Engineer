/// Main search and filter interface component.
///
/// This component combines the search bar, filter panel, and sort controls
/// into a comprehensive search and filtering interface. Manages the search
/// controller and coordinates between all search-related components.

import 'package:flutter/material.dart';

import '../../../../services/user_application/models/user_application.dart';
import '../../../../theme/insets.dart';
import 'filter_panel.dart';
import 'search_bar.dart' as custom;
import 'search_controller.dart' as search;
import 'sort_controls.dart';

/// Main search and filter interface widget.
///
/// Provides a complete search and filtering experience with text search,
/// advanced filters, sorting options, and result management. Integrates
/// all search components with a shared SearchController for state management.
class SearchAndFilterInterface extends StatefulWidget {
  /// Creates a search and filter interface widget.
  ///
  /// @param applications List of all applications to search and filter
  /// @param onResultsChanged Callback when search results change
  /// @param showFilterPanel Whether to show the advanced filter panel
  /// @param showSortControls Whether to show the sort controls
  const SearchAndFilterInterface({
    required this.applications,
    required this.onResultsChanged,
    this.showFilterPanel = true,
    this.showSortControls = true,
    super.key,
  });

  /// List of all applications available for searching and filtering.
  ///
  /// This is the complete dataset that will be searched and filtered
  /// based on user criteria. Should be updated when applications change.
  final List<UserApplication> applications;

  /// Callback invoked when search results change.
  ///
  /// Called with the filtered list of applications whenever search
  /// criteria change or results are updated. Used to update the main
  /// application grid with filtered results.
  final void Function(List<UserApplication> results) onResultsChanged;

  /// Whether to show the advanced filter panel.
  ///
  /// When true, displays the filter panel with category, status,
  /// and date range filters. When false, only shows the search bar.
  final bool showFilterPanel;

  /// Whether to show the sort controls.
  ///
  /// When true, displays sort options for ordering results.
  /// When false, uses default sorting without user controls.
  final bool showSortControls;

  @override
  State<SearchAndFilterInterface> createState() => _SearchAndFilterInterfaceState();
}

/// State for the SearchAndFilterInterface widget.
///
/// Manages the search controller and coordinates updates between
/// search components and the parent widget.
class _SearchAndFilterInterfaceState extends State<SearchAndFilterInterface> {
  /// Search controller for managing search and filter state.
  late search.ApplicationSearchController _searchController;

  /// Whether the filter panel is currently expanded.
  bool _filterPanelExpanded = false;

  @override
  void initState() {
    super.initState();

    // Initialize search controller
    _searchController = search.ApplicationSearchController();

    // Listen to search controller changes
    _searchController.addListener(_onSearchResultsChanged);

    // Initialize with current applications
    _searchController.updateApplications(widget.applications);
  }

  @override
  void didUpdateWidget(SearchAndFilterInterface oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update applications if they changed
    if (widget.applications != oldWidget.applications) {
      _searchController.updateApplications(widget.applications);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchResultsChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// Handles changes in search results.
  ///
  /// Called whenever the search controller updates results.
  /// Notifies the parent widget of the new filtered applications.
  void _onSearchResultsChanged() {
    widget.onResultsChanged(_searchController.filteredApplications);
  }

  /// Toggles the filter panel expansion state.
  void _toggleFilterPanel() {
    setState(() {
      _filterPanelExpanded = !_filterPanelExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar with filter toggle
        Row(
          children: [
            // Main search bar
            Expanded(
              child: custom.SearchBar(
                controller: _searchController,
                onSearchChanged: (query) {
                  // Optional: Add analytics or additional handling
                },
              ),
            ),

            // Filter panel toggle button
            if (widget.showFilterPanel) ...[
              const SizedBox(width: Insets.small),
              IconButton(
                onPressed: _toggleFilterPanel,
                icon: Icon(
                  _filterPanelExpanded ? Icons.filter_list_off : Icons.filter_list,
                ),
                tooltip: _filterPanelExpanded ? 'Hide Filters' : 'Show Filters',
                style: IconButton.styleFrom(
                  backgroundColor: _searchController.hasActiveFilters
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  foregroundColor: _searchController.hasActiveFilters
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : null,
                ),
              ),
            ],
          ],
        ),

        // Sort controls
        if (widget.showSortControls) ...[
          const SizedBox(height: Insets.medium),
          SortControls(
            controller: _searchController,
            onSortChanged: (sortOption) {
              // Optional: Add analytics or additional handling
            },
          ),
        ],

        // Filter panel (expandable)
        if (widget.showFilterPanel && _filterPanelExpanded) ...[
          const SizedBox(height: Insets.medium),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: FilterPanel(
              controller: _searchController,
              onFiltersChanged: () {
                // Optional: Add analytics or additional handling
              },
            ),
          ),
        ],

        // Search results summary
        const SizedBox(height: Insets.medium),
        _buildResultsSummary(context),
      ],
    );
  }

  /// Builds the search results summary.
  ///
  /// Shows information about current search and filter state,
  /// including result counts and active filter indicators.
  ///
  /// @param context Build context for theming
  /// @returns Widget displaying results summary
  Widget _buildResultsSummary(BuildContext context) {
    return ListenableBuilder(
      listenable: _searchController,
      builder: (context, child) {
        final int resultCount = _searchController.resultCount;
        final int totalCount = _searchController.totalApplicationCount;
        final bool hasActiveFilters = _searchController.hasActiveFilters;
        final String searchQuery = _searchController.searchQuery;

        if (totalCount == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(Insets.small),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Results icon
              Icon(
                hasActiveFilters || searchQuery.isNotEmpty ? Icons.search : Icons.apps,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: Insets.small),

              // Results text
              Expanded(
                child: Text(
                  _getResultsSummaryText(context, resultCount, totalCount, searchQuery, hasActiveFilters),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              // Clear filters button
              if (hasActiveFilters)
                TextButton(
                  onPressed: () {
                    _searchController.clearAllFilters();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: Insets.small),
                    minimumSize: const Size(0, 32),
                  ),
                  child: Text(
                    'Clear',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Gets the results summary text.
  ///
  /// @param context Build context for localization
  /// @param resultCount Number of results shown
  /// @param totalCount Total number of applications
  /// @param searchQuery Current search query
  /// @param hasActiveFilters Whether filters are active
  /// @returns Summary text describing current results
  String _getResultsSummaryText(
    BuildContext context,
    int resultCount,
    int totalCount,
    String searchQuery,
    bool hasActiveFilters,
  ) {
    if (searchQuery.isNotEmpty) {
      if (resultCount == 0) {
        return 'No applications match "$searchQuery"';
      } else if (resultCount == 1) {
        return '1 application matches "$searchQuery"';
      } else {
        return '$resultCount applications match "$searchQuery"';
      }
    } else if (hasActiveFilters) {
      if (resultCount == 0) {
        return 'No applications match the current filters';
      } else if (resultCount == totalCount) {
        return 'All $totalCount applications shown';
      } else {
        return 'Showing $resultCount of $totalCount applications';
      }
    } else {
      if (totalCount == 1) {
        return '1 application';
      } else {
        return '$totalCount applications';
      }
    }
  }
}
