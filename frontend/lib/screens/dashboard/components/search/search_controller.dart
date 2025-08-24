/// Search controller for managing search and filtering state.
///
/// This controller manages the search and filtering functionality for the
/// application grid, including text search, filter criteria, sort options,
/// and result state. Provides real-time search with debouncing and
/// comprehensive state management for the search UI.

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../../services/search/application_search_service.dart';
import '../../../../services/search/models/search_filter.dart';
import '../../../../services/search/models/search_result.dart';
import '../../../../services/user_application/models/application_category.dart';
import '../../../../services/user_application/models/application_status.dart';
import '../../../../services/user_application/models/user_application.dart';

/// Controller for managing search and filtering state.
///
/// Provides comprehensive search functionality with real-time updates,
/// debounced text search, filter management, and result state tracking.
/// Integrates with the ApplicationSearchService for search operations.
class ApplicationSearchController extends ChangeNotifier {
  /// Creates a search controller with optional initial filter.
  ///
  /// @param initialFilter Optional initial filter state
  ApplicationSearchController({SearchFilter? initialFilter})
    : _currentFilter = initialFilter ?? const SearchFilter(),
      _searchService = const ApplicationSearchService();

  /// Search service for performing search operations.
  final ApplicationSearchService _searchService;

  /// Current search and filter criteria.
  SearchFilter _currentFilter;

  /// Current search results.
  SearchResultSet? _currentResults;

  /// List of all applications available for searching.
  List<UserApplication> _allApplications = [];

  /// Timer for debouncing text search input.
  Timer? _searchDebounceTimer;

  /// Duration to wait before performing search after text input.
  static const Duration _searchDebounceDelay = Duration(milliseconds: 300);

  /// Current search and filter criteria.
  ///
  /// Immutable filter object containing all search and filter settings.
  /// Use the update methods to modify filter criteria.
  SearchFilter get currentFilter => _currentFilter;

  /// Current search results.
  ///
  /// Null if no search has been performed yet. Contains filtered and
  /// sorted applications with match information and metadata.
  SearchResultSet? get currentResults => _currentResults;

  /// List of applications from current search results.
  ///
  /// Convenience getter that extracts just the application objects
  /// from the search results for use in UI components.
  List<UserApplication> get filteredApplications {
    return _currentResults?.applications ?? _allApplications;
  }

  /// Whether a search operation is currently in progress.
  ///
  /// True when search is being performed or debounce timer is active.
  /// Used for showing loading indicators in the UI.
  bool get isSearching => _searchDebounceTimer?.isActive ?? false;

  /// Whether any filters are currently active.
  ///
  /// Returns true if any search or filter criteria are applied.
  /// Used for showing filter indicators and clear filter options.
  bool get hasActiveFilters => _currentFilter.hasActiveFilters;

  /// Current search query text.
  ///
  /// Convenience getter for the text search query from the current filter.
  String get searchQuery => _currentFilter.query;

  /// Number of results in the current search.
  ///
  /// Returns 0 if no search has been performed or no results found.
  int get resultCount => _currentResults?.resultCount ?? 0;

  /// Total number of applications before filtering.
  ///
  /// Used for showing statistics about filter effectiveness.
  int get totalApplicationCount => _allApplications.length;

  /// Updates the list of all applications and refreshes search results.
  ///
  /// Should be called whenever the application list changes to ensure
  /// search results stay current with the latest data.
  ///
  /// @param applications New list of all applications
  void updateApplications(List<UserApplication> applications) {
    _allApplications = applications;
    _performSearch();
  }

  /// Updates the search query with debouncing.
  ///
  /// Cancels any pending search and starts a new debounce timer
  /// to avoid excessive search operations during typing.
  ///
  /// @param query New search query text
  void updateSearchQuery(String query) {
    // Cancel existing timer
    _searchDebounceTimer?.cancel();

    // Update filter immediately for UI responsiveness
    _currentFilter = _currentFilter.copyWithQuery(query);
    notifyListeners();

    // Start debounce timer for actual search
    _searchDebounceTimer = Timer(_searchDebounceDelay, () {
      _performSearch();
    });
  }

  /// Updates the selected categories filter.
  ///
  /// Immediately performs search with the new category criteria.
  ///
  /// @param categories Set of categories to filter by
  void updateCategoryFilter(Set<ApplicationCategory> categories) {
    _currentFilter = _currentFilter.copyWithCategories(categories);
    _performSearch();
  }

  /// Updates the selected statuses filter.
  ///
  /// Immediately performs search with the new status criteria.
  ///
  /// @param statuses Set of statuses to filter by
  void updateStatusFilter(Set<ApplicationStatus> statuses) {
    _currentFilter = _currentFilter.copyWithStatuses(statuses);
    _performSearch();
  }

  /// Updates the sort option.
  ///
  /// Immediately re-sorts current results with the new sort criteria.
  ///
  /// @param sortOption New sorting method to apply
  void updateSortOption(SortOption sortOption) {
    _currentFilter = _currentFilter.copyWithSortOption(sortOption);
    _performSearch();
  }

  /// Updates the date range filter.
  ///
  /// Immediately performs search with the new date criteria.
  ///
  /// @param startDate Optional start date for filtering
  /// @param endDate Optional end date for filtering
  void updateDateRange(DateTime? startDate, DateTime? endDate) {
    _currentFilter = _currentFilter.copyWithDateRange(startDate, endDate);
    _performSearch();
  }

  /// Toggles a category in the category filter.
  ///
  /// Adds the category if not present, removes it if already selected.
  ///
  /// @param category Category to toggle
  void toggleCategory(ApplicationCategory category) {
    final Set<ApplicationCategory> newCategories = Set.from(_currentFilter.selectedCategories);

    if (newCategories.contains(category)) {
      newCategories.remove(category);
    } else {
      newCategories.add(category);
    }

    updateCategoryFilter(newCategories);
  }

  /// Toggles a status in the status filter.
  ///
  /// Adds the status if not present, removes it if already selected.
  ///
  /// @param status Status to toggle
  void toggleStatus(ApplicationStatus status) {
    final Set<ApplicationStatus> newStatuses = Set.from(_currentFilter.selectedStatuses);

    if (newStatuses.contains(status)) {
      newStatuses.remove(status);
    } else {
      newStatuses.add(status);
    }

    updateStatusFilter(newStatuses);
  }

  /// Clears all filters and search criteria.
  ///
  /// Resets to default state showing all applications with default sorting.
  void clearAllFilters() {
    _searchDebounceTimer?.cancel();
    _currentFilter = const SearchFilter();
    _performSearch();
  }

  /// Clears only the text search query.
  ///
  /// Keeps other filter criteria but removes the search text.
  void clearSearchQuery() {
    _searchDebounceTimer?.cancel();
    _currentFilter = _currentFilter.copyWithQuery('');
    _performSearch();
  }

  /// Gets available categories from all applications.
  ///
  /// Returns a set of all categories present in the application list
  /// for use in filter UI components.
  Set<ApplicationCategory> getAvailableCategories() {
    return _allApplications.map((app) => app.category).whereType<ApplicationCategory>().toSet();
  }

  /// Gets available statuses from all applications.
  ///
  /// Returns a set of all statuses present in the application list
  /// for use in filter UI components.
  Set<ApplicationStatus> getAvailableStatuses() {
    return _allApplications.map((app) => app.status).toSet();
  }

  /// Gets the count of applications for a specific category.
  ///
  /// @param category Category to count applications for
  /// @returns Number of applications in the category
  int getCategoryCount(ApplicationCategory category) {
    return _allApplications.where((app) => app.category == category).length;
  }

  /// Gets the count of applications for a specific status.
  ///
  /// @param status Status to count applications for
  /// @returns Number of applications with the status
  int getStatusCount(ApplicationStatus status) {
    return _allApplications.where((app) => app.status == status).length;
  }

  /// Performs the search operation with current filter criteria.
  ///
  /// Executes the search using the search service and updates the
  /// current results. Notifies listeners of the state change.
  void _performSearch() {
    if (_allApplications.isEmpty) {
      _currentResults = SearchResultSet.empty(
        query: _currentFilter.query,
        totalCount: 0,
        filteredCount: 0,
        searchDurationMs: 0,
      );
    } else {
      _currentResults = _searchService.searchApplications(_allApplications, _currentFilter);
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }
}
