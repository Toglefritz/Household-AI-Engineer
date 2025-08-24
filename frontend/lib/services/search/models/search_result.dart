/// Search result models for application discovery.
///
/// This module provides data structures for representing search results
/// with highlighting information, match scores, and result metadata.
/// Supports fuzzy matching results with detailed match information.

import '../../../services/user_application/models/user_application.dart';

/// Represents a text match within an application field.
///
/// Contains information about where a search query matched within
/// application text, including the matched text and its position
/// for highlighting in the UI.
class TextMatch {
  /// Creates a text match with position and content information.
  ///
  /// @param start Starting character index of the match
  /// @param end Ending character index of the match
  /// @param matchedText The actual text that matched the query
  /// @param field The application field where the match occurred
  const TextMatch({
    required this.start,
    required this.end,
    required this.matchedText,
    required this.field,
  });

  /// Starting character index of the match within the field text.
  ///
  /// Used for highlighting the matched portion of text in the UI.
  /// Zero-based index pointing to the first character of the match.
  final int start;

  /// Ending character index of the match within the field text.
  ///
  /// Used for highlighting the matched portion of text in the UI.
  /// Points to the character after the last matched character.
  final int end;

  /// The actual text that matched the search query.
  ///
  /// May differ from the original query due to fuzzy matching,
  /// case differences, or partial matches.
  final String matchedText;

  /// The application field where this match occurred.
  ///
  /// Indicates whether the match was in the title, description,
  /// or other searchable fields for context and relevance scoring.
  final String field;

  /// Length of the matched text.
  ///
  /// Convenience getter for calculating highlight spans
  /// and match quality scoring.
  int get length => end - start;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TextMatch) return false;

    return start == other.start && end == other.end && matchedText == other.matchedText && field == other.field;
  }

  @override
  int get hashCode {
    return Object.hash(start, end, matchedText, field);
  }

  @override
  String toString() {
    return 'TextMatch(field: $field, start: $start, end: $end, text: "$matchedText")';
  }
}

/// Represents a search result with match information and relevance scoring.
///
/// Contains the matched application along with detailed information about
/// how and where the search query matched, enabling rich UI feedback
/// and relevance-based result ordering.
class SearchResult {
  /// Creates a search result with match information.
  ///
  /// @param application The application that matched the search query
  /// @param matches List of text matches found in the application
  /// @param score Relevance score for this result (0.0 to 1.0)
  const SearchResult({
    required this.application,
    required this.matches,
    required this.score,
  });

  /// The application that matched the search query.
  ///
  /// Contains all the application metadata and can be used
  /// for displaying the result and handling user interactions.
  final UserApplication application;

  /// List of text matches found within the application.
  ///
  /// Each match contains position information for highlighting
  /// the matched text in the UI. Multiple matches can occur
  /// across different fields or within the same field.
  final List<TextMatch> matches;

  /// Relevance score for this search result.
  ///
  /// Ranges from 0.0 (poor match) to 1.0 (perfect match).
  /// Used for ordering search results with most relevant
  /// matches appearing first in the list.
  final double score;

  /// Whether this result has any text matches.
  ///
  /// Returns true if the search query matched text within
  /// the application fields. False indicates the result
  /// was included due to other filter criteria.
  bool get hasMatches => matches.isNotEmpty;

  /// Number of text matches found in this result.
  ///
  /// Higher match counts may indicate better relevance
  /// or more comprehensive matches across multiple fields.
  int get matchCount => matches.length;

  /// Gets all matches for a specific field.
  ///
  /// @param fieldName Name of the field to get matches for
  /// @returns List of matches found in the specified field
  List<TextMatch> getMatchesForField(String fieldName) {
    return matches.where((match) => match.field == fieldName).toList();
  }

  /// Whether this result has matches in the title field.
  ///
  /// Title matches are often considered more relevant than
  /// description matches for search result ranking.
  bool get hasTitleMatches => matches.any((match) => match.field == 'title');

  /// Whether this result has matches in the description field.
  ///
  /// Description matches provide context about application
  /// functionality and purpose for search relevance.
  bool get hasDescriptionMatches => matches.any((match) => match.field == 'description');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SearchResult) return false;

    return application == other.application && matches == other.matches && score == other.score;
  }

  @override
  int get hashCode {
    return Object.hash(application, matches, score);
  }

  @override
  String toString() {
    return 'SearchResult('
        'app: "${application.title}", '
        'matches: ${matches.length}, '
        'score: ${score.toStringAsFixed(2)}'
        ')';
  }
}

/// Container for search results with metadata and statistics.
///
/// Provides comprehensive information about a search operation including
/// the filtered and sorted results, total counts, and performance metrics.
class SearchResultSet {
  /// Creates a search result set with results and metadata.
  ///
  /// @param results List of search results ordered by relevance and sort criteria
  /// @param totalCount Total number of applications before filtering
  /// @param filteredCount Number of applications after filtering but before search
  /// @param query The search query that produced these results
  /// @param searchDurationMs Time taken to perform the search in milliseconds
  const SearchResultSet({
    required this.results,
    required this.totalCount,
    required this.filteredCount,
    required this.query,
    required this.searchDurationMs,
  });

  /// List of search results ordered by relevance and sort criteria.
  ///
  /// Results are sorted first by relevance score (if search query is present)
  /// and then by the specified sort option. Empty list indicates no matches.
  final List<SearchResult> results;

  /// Total number of applications in the system before any filtering.
  ///
  /// Used for showing overall statistics and calculating filter
  /// effectiveness in the UI.
  final int totalCount;

  /// Number of applications after applying filters but before text search.
  ///
  /// Helps distinguish between applications filtered out by category/status
  /// filters versus those filtered out by text search.
  final int filteredCount;

  /// The search query that produced these results.
  ///
  /// Empty string indicates no text search was performed,
  /// and results are based only on filter criteria.
  final String query;

  /// Time taken to perform the search operation in milliseconds.
  ///
  /// Used for performance monitoring and optimization.
  /// Includes time for filtering, searching, and sorting.
  final int searchDurationMs;

  /// Number of applications in the search results.
  ///
  /// Convenience getter for the length of the results list.
  int get resultCount => results.length;

  /// Whether this result set contains any results.
  ///
  /// Returns true if at least one application matched the
  /// search and filter criteria.
  bool get hasResults => results.isNotEmpty;

  /// Whether this result set is from a text search query.
  ///
  /// Returns true if a search query was provided, even if
  /// no results were found. Used for showing search-specific UI.
  bool get isSearchQuery => query.isNotEmpty;

  /// Gets the applications from all search results.
  ///
  /// Convenience method to extract just the application objects
  /// without the search metadata for use in UI components.
  List<UserApplication> get applications {
    return results.map((result) => result.application).toList();
  }

  /// Creates an empty result set for when no applications match.
  ///
  /// @param query The search query that produced no results
  /// @param totalCount Total number of applications in the system
  /// @param filteredCount Number of applications after filtering
  /// @param searchDurationMs Time taken for the search operation
  /// @returns Empty SearchResultSet with metadata
  factory SearchResultSet.empty({
    required String query,
    required int totalCount,
    required int filteredCount,
    required int searchDurationMs,
  }) {
    return SearchResultSet(
      results: const [],
      totalCount: totalCount,
      filteredCount: filteredCount,
      query: query,
      searchDurationMs: searchDurationMs,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SearchResultSet) return false;

    return results == other.results &&
        totalCount == other.totalCount &&
        filteredCount == other.filteredCount &&
        query == other.query &&
        searchDurationMs == other.searchDurationMs;
  }

  @override
  int get hashCode {
    return Object.hash(
      results,
      totalCount,
      filteredCount,
      query,
      searchDurationMs,
    );
  }

  @override
  String toString() {
    return 'SearchResultSet('
        'results: ${results.length}, '
        'total: $totalCount, '
        'filtered: $filteredCount, '
        'query: "$query", '
        'duration: ${searchDurationMs}ms'
        ')';
  }
}
