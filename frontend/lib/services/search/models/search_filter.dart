/// Search and filtering models for application discovery.
///
/// This module provides data structures for managing search queries,
/// filter criteria, and sorting options for the application grid.
/// Supports fuzzy matching, category filtering, status filtering,
/// and date-based sorting with comprehensive state management.

import '../../../services/user_application/models/application_category.dart';
import '../../../services/user_application/models/application_status.dart';

/// Enumeration of available sorting options for applications.
///
/// Provides different ways to order applications in the grid
/// based on user preferences and usage patterns.
enum SortOption {
  /// Sort by creation date with newest applications first.
  ///
  /// Default sorting option that shows recently created applications
  /// at the top of the grid for easy discovery.
  createdDateDesc('Created Date (Newest First)'),

  /// Sort by creation date with oldest applications first.
  ///
  /// Shows applications in chronological order of creation,
  /// useful for finding early applications or historical context.
  createdDateAsc('Created Date (Oldest First)'),

  /// Sort by last updated date with most recently updated first.
  ///
  /// Prioritizes applications that have been recently modified
  /// or had status changes, useful for tracking active development.
  updatedDateDesc('Last Updated (Newest First)'),

  /// Sort by last updated date with least recently updated first.
  ///
  /// Shows applications that haven't been updated recently,
  /// useful for finding stale or forgotten applications.
  updatedDateAsc('Last Updated (Oldest First)'),

  /// Sort alphabetically by application title A-Z.
  ///
  /// Provides predictable alphabetical ordering for easy
  /// navigation when users know the application name.
  titleAsc('Title (A-Z)'),

  /// Sort alphabetically by application title Z-A.
  ///
  /// Reverse alphabetical ordering for alternative browsing
  /// or when looking for applications at the end of the alphabet.
  titleDesc('Title (Z-A)'),

  /// Sort by application status with active statuses first.
  ///
  /// Groups applications by status with running and ready applications
  /// prioritized over developing or failed applications.
  statusPriority('Status (Active First)');

  /// Creates a sort option with a display name.
  ///
  /// @param displayName Human-readable name for UI display
  const SortOption(this.displayName);

  /// Human-readable display name for this sort option.
  ///
  /// Used in dropdown menus and sort controls to show
  /// user-friendly descriptions of each sorting method.
  final String displayName;
}

/// Comprehensive filter criteria for application search and discovery.
///
/// Encapsulates all filtering options including text search, category filters,
/// status filters, date ranges, and sorting preferences. Provides immutable
/// state management with copy methods for updates.
class SearchFilter {
  /// Creates a search filter with the specified criteria.
  ///
  /// All parameters are optional and default to showing all applications
  /// with no filtering applied. This provides a sensible default state
  /// for initial application loading.
  ///
  /// @param query Text search query for fuzzy matching
  /// @param selectedCategories Set of categories to include in results
  /// @param selectedStatuses Set of statuses to include in results
  /// @param sortOption How to sort the filtered results
  /// @param dateRangeStart Optional start date for date filtering
  /// @param dateRangeEnd Optional end date for date filtering
  /// @param favoritesOnly Whether to show only favorite applications
  /// @param recentOnly Whether to show only recently updated applications
  const SearchFilter({
    this.query = '',
    this.selectedCategories = const {},
    this.selectedStatuses = const {},
    this.sortOption = SortOption.createdDateDesc,
    this.dateRangeStart,
    this.dateRangeEnd,
    this.favoritesOnly = false,
    this.recentOnly = false,
  });

  /// Text search query for fuzzy matching against application titles and descriptions.
  ///
  /// Empty string means no text filtering is applied. The search implementation
  /// supports fuzzy matching to find applications even with partial or
  /// slightly misspelled queries.
  final String query;

  /// Set of application categories to include in search results.
  ///
  /// Empty set means all categories are included. When populated,
  /// only applications matching one of the selected categories
  /// will be shown in the results.
  final Set<ApplicationCategory> selectedCategories;

  /// Set of application statuses to include in search results.
  ///
  /// Empty set means all statuses are included. When populated,
  /// only applications with one of the selected statuses
  /// will be shown in the results.
  final Set<ApplicationStatus> selectedStatuses;

  /// Sorting option for ordering the filtered results.
  ///
  /// Determines how applications are ordered in the grid after
  /// filtering is applied. Defaults to newest first for discoverability.
  final SortOption sortOption;

  /// Optional start date for filtering applications by creation date.
  ///
  /// When set, only applications created on or after this date
  /// will be included in the results. Null means no start date filter.
  final DateTime? dateRangeStart;

  /// Optional end date for filtering applications by creation date.
  ///
  /// When set, only applications created on or before this date
  /// will be included in the results. Null means no end date filter.
  final DateTime? dateRangeEnd;

  /// Whether to show only applications marked as favorites.
  ///
  /// When true, only applications with isFavorite set to true
  /// will be included in the results. When false, all applications
  /// are included regardless of favorite status.
  final bool favoritesOnly;

  /// Whether to show only recently updated applications.
  ///
  /// When true, only applications updated within the last 7 days
  /// will be included in the results, sorted by most recent first.
  /// When false, all applications are included regardless of update time.
  final bool recentOnly;

  /// Whether any filters are currently active.
  ///
  /// Returns true if any filtering criteria are applied, including
  /// text search, category filters, status filters, date ranges, favorites, or recent.
  /// Used to show filter indicators and clear filter options.
  bool get hasActiveFilters {
    return query.isNotEmpty ||
        selectedCategories.isNotEmpty ||
        selectedStatuses.isNotEmpty ||
        dateRangeStart != null ||
        dateRangeEnd != null ||
        favoritesOnly ||
        recentOnly;
  }

  /// Whether only text search is active with no other filters.
  ///
  /// Returns true when only the search query is set and all other
  /// filter criteria are empty. Used for optimizing search UI states.
  bool get hasOnlyTextSearch {
    return query.isNotEmpty &&
        selectedCategories.isEmpty &&
        selectedStatuses.isEmpty &&
        dateRangeStart == null &&
        dateRangeEnd == null &&
        !favoritesOnly &&
        !recentOnly;
  }

  /// Creates a copy of this filter with updated search query.
  ///
  /// @param newQuery New text search query to apply
  /// @returns New SearchFilter instance with updated query
  SearchFilter copyWithQuery(String newQuery) {
    return SearchFilter(
      query: newQuery,
      selectedCategories: selectedCategories,
      selectedStatuses: selectedStatuses,
      sortOption: sortOption,
      dateRangeStart: dateRangeStart,
      dateRangeEnd: dateRangeEnd,
      favoritesOnly: favoritesOnly,
      recentOnly: recentOnly,
    );
  }

  /// Creates a copy of this filter with updated category selection.
  ///
  /// @param categories New set of categories to filter by
  /// @returns New SearchFilter instance with updated categories
  SearchFilter copyWithCategories(Set<ApplicationCategory> categories) {
    return SearchFilter(
      query: query,
      selectedCategories: categories,
      selectedStatuses: selectedStatuses,
      sortOption: sortOption,
      dateRangeStart: dateRangeStart,
      dateRangeEnd: dateRangeEnd,
      favoritesOnly: favoritesOnly,
      recentOnly: recentOnly,
    );
  }

  /// Creates a copy of this filter with updated status selection.
  ///
  /// @param statuses New set of statuses to filter by
  /// @returns New SearchFilter instance with updated statuses
  SearchFilter copyWithStatuses(Set<ApplicationStatus> statuses) {
    return SearchFilter(
      query: query,
      selectedCategories: selectedCategories,
      selectedStatuses: statuses,
      sortOption: sortOption,
      dateRangeStart: dateRangeStart,
      dateRangeEnd: dateRangeEnd,
      favoritesOnly: favoritesOnly,
      recentOnly: recentOnly,
    );
  }

  /// Creates a copy of this filter with updated sort option.
  ///
  /// @param newSortOption New sorting method to apply
  /// @returns New SearchFilter instance with updated sort option
  SearchFilter copyWithSortOption(SortOption newSortOption) {
    return SearchFilter(
      query: query,
      selectedCategories: selectedCategories,
      selectedStatuses: selectedStatuses,
      sortOption: newSortOption,
      dateRangeStart: dateRangeStart,
      dateRangeEnd: dateRangeEnd,
      favoritesOnly: favoritesOnly,
      recentOnly: recentOnly,
    );
  }

  /// Creates a copy of this filter with updated date range.
  ///
  /// @param startDate New start date for filtering (null to clear)
  /// @param endDate New end date for filtering (null to clear)
  /// @returns New SearchFilter instance with updated date range
  SearchFilter copyWithDateRange(DateTime? startDate, DateTime? endDate) {
    return SearchFilter(
      query: query,
      selectedCategories: selectedCategories,
      selectedStatuses: selectedStatuses,
      sortOption: sortOption,
      dateRangeStart: startDate,
      dateRangeEnd: endDate,
      favoritesOnly: favoritesOnly,
      recentOnly: recentOnly,
    );
  }

  /// Creates a copy of this filter with updated favorites filter.
  ///
  /// @param showFavoritesOnly Whether to show only favorite applications
  /// @returns New SearchFilter instance with updated favorites filter
  SearchFilter copyWithFavoritesOnly(bool showFavoritesOnly) {
    return SearchFilter(
      query: query,
      selectedCategories: selectedCategories,
      selectedStatuses: selectedStatuses,
      sortOption: sortOption,
      dateRangeStart: dateRangeStart,
      dateRangeEnd: dateRangeEnd,
      favoritesOnly: showFavoritesOnly,
      recentOnly: recentOnly,
    );
  }

  /// Creates a copy of this filter with updated recent filter.
  ///
  /// @param showRecentOnly Whether to show only recently updated applications
  /// @returns New SearchFilter instance with updated recent filter
  SearchFilter copyWithRecentOnly(bool showRecentOnly) {
    return SearchFilter(
      query: query,
      selectedCategories: selectedCategories,
      selectedStatuses: selectedStatuses,
      sortOption: sortOption,
      dateRangeStart: dateRangeStart,
      dateRangeEnd: dateRangeEnd,
      favoritesOnly: favoritesOnly,
      recentOnly: showRecentOnly,
    );
  }

  /// Creates a copy of this filter with all filters cleared.
  ///
  /// Resets to default state with no filtering applied and
  /// default sorting by creation date descending.
  ///
  /// @returns New SearchFilter instance with no active filters
  SearchFilter copyWithClearedFilters() {
    return const SearchFilter();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SearchFilter) return false;

    return query == other.query &&
        selectedCategories == other.selectedCategories &&
        selectedStatuses == other.selectedStatuses &&
        sortOption == other.sortOption &&
        dateRangeStart == other.dateRangeStart &&
        dateRangeEnd == other.dateRangeEnd &&
        favoritesOnly == other.favoritesOnly &&
        recentOnly == other.recentOnly;
  }

  @override
  int get hashCode {
    return Object.hash(
      query,
      selectedCategories,
      selectedStatuses,
      sortOption,
      dateRangeStart,
      dateRangeEnd,
      favoritesOnly,
      recentOnly,
    );
  }

  @override
  String toString() {
    return 'SearchFilter('
        'query: "$query", '
        'categories: ${selectedCategories.length}, '
        'statuses: ${selectedStatuses.length}, '
        'sort: ${sortOption.displayName}, '
        'dateRange: ${dateRangeStart != null || dateRangeEnd != null}'
        ')';
  }
}
