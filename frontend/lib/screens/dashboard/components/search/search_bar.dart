/// Search bar component with real-time filtering and result display.
///
/// This component provides a comprehensive search interface with text input,
/// result count display, clear functionality, and integration with the
/// search controller for real-time filtering and fuzzy matching.
library;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/insets.dart';
import 'search_controller.dart' as search;

/// Search bar widget with real-time filtering capabilities.
///
/// Provides text input for search queries with immediate visual feedback,
/// result count display, and clear functionality. Integrates with the
/// SearchController for debounced search operations and state management.
class SearchBar extends StatefulWidget {
  /// Creates a search bar widget.
  ///
  /// @param controller Search controller for managing search state
  /// @param onSearchChanged Optional callback when search query changes
  const SearchBar({
    required this.controller,
    this.onSearchChanged,
    super.key,
  });

  /// Search controller for managing search state and operations.
  ///
  /// Provides access to current search query, results, and methods
  /// for updating search criteria and clearing filters.
  final search.ApplicationSearchController controller;

  /// Optional callback invoked when the search query changes.
  ///
  /// Called with the new search query text whenever the user
  /// types in the search field. Useful for additional UI updates.
  final void Function(String query)? onSearchChanged;

  @override
  State<SearchBar> createState() => _SearchBarState();
}

/// State for the SearchBar widget.
///
/// Manages the text editing controller and handles user input
/// with proper cleanup and state synchronization.
class _SearchBarState extends State<SearchBar> {
  /// Text editing controller for the search input field.
  ///
  /// Manages the text input state and cursor position.
  /// Synchronized with the search controller's query state.
  late TextEditingController _textController;

  /// Focus node for the search input field.
  ///
  /// Manages focus state and keyboard interactions.
  /// Used for programmatic focus control and styling.
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with current search state
    _textController = TextEditingController(text: widget.controller.searchQuery);
    _focusNode = FocusNode();

    // Listen to search controller changes
    widget.controller.addListener(_onSearchControllerChanged);
  }

  @override
  void dispose() {
    // Clean up resources
    widget.controller.removeListener(_onSearchControllerChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Handles changes from the search controller.
  ///
  /// Updates the text controller when the search query changes
  /// from external sources (e.g., clear filters button).
  void _onSearchControllerChanged() {
    if (_textController.text != widget.controller.searchQuery) {
      _textController.text = widget.controller.searchQuery;
    }
  }

  /// Handles text input changes from the user.
  ///
  /// Updates the search controller with the new query and
  /// calls the optional callback if provided.
  ///
  /// @param query New search query text
  void _onTextChanged(String query) {
    widget.controller.updateSearchQuery(query);
    widget.onSearchChanged?.call(query);
  }

  /// Clears the search query and focuses the input field.
  ///
  /// Provides a quick way for users to clear their search
  /// and start a new query.
  void _clearSearch() {
    _textController.clear();
    widget.controller.clearSearchQuery();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final bool hasQuery = widget.controller.searchQuery.isNotEmpty;
        final bool isSearching = widget.controller.isSearching;
        final int resultCount = widget.controller.resultCount;
        final int totalCount = widget.controller.totalApplicationCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search input field
            TextField(
              controller: _textController,
              focusNode: _focusNode,
              onChanged: _onTextChanged,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchApplicationsHint,
                prefixIcon: isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : const Icon(Icons.search, size: 20),
                suffixIcon: hasQuery
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: _clearSearch,
                        tooltip: AppLocalizations.of(context)!.clearSearch,
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Insets.medium,
                  vertical: Insets.small,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            // Result count and status
            if (hasQuery || widget.controller.hasActiveFilters)
              Padding(
                padding: const EdgeInsets.only(top: Insets.small),
                child: _buildResultStatus(context, hasQuery, resultCount, totalCount),
              ),
          ],
        );
      },
    );
  }

  /// Builds the result status display.
  ///
  /// Shows result count, total count, and search status information
  /// to provide feedback about the current search and filter state.
  ///
  /// @param context Build context for theming
  /// @param hasQuery Whether a search query is active
  /// @param resultCount Number of results found
  /// @param totalCount Total number of applications
  /// @returns Widget displaying result status
  Widget _buildResultStatus(
    BuildContext context,
    bool hasQuery,
    int resultCount,
    int totalCount,
  ) {
    final TextStyle? statusStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    String statusText;
    if (hasQuery) {
      if (resultCount == 0) {
        statusText = AppLocalizations.of(context)!.noSearchResults;
      } else if (resultCount == 1) {
        statusText = AppLocalizations.of(context)!.oneSearchResult;
      } else {
        statusText = AppLocalizations.of(context)!.multipleSearchResults(resultCount);
      }
    } else {
      // Only filters active, no search query
      if (resultCount == 0) {
        statusText = AppLocalizations.of(context)!.noFilterResults;
      } else if (resultCount == totalCount) {
        statusText = AppLocalizations.of(context)!.allApplicationsShown(totalCount);
      } else {
        statusText = AppLocalizations.of(context)!.filteredApplicationsShown(resultCount, totalCount);
      }
    }

    return Row(
      children: [
        Icon(
          hasQuery ? Icons.search : Icons.filter_list,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        Padding(
          padding: const EdgeInsets.only(left: Insets.xSmall),
          child: Expanded(
            child: Text(
              statusText,
              style: statusStyle,
            ),
          ),
        ),
      ],
    );
  }
}
