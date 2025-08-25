/// Application search and filtering service.
///
/// This service provides comprehensive search and filtering capabilities
/// for user applications including fuzzy text matching, category filtering,
/// status filtering, date range filtering, and multiple sorting options.
/// Optimized for real-time search with efficient algorithms and caching.
library;

import 'dart:math' as math;
import 'package:flutter/foundation.dart';

import '../../services/user_application/models/application_status.dart';
import '../../services/user_application/models/user_application.dart';
import 'models/search_filter.dart';
import 'models/search_result.dart';

/// Service for searching and filtering user applications.
///
/// Provides fuzzy text search, multi-criteria filtering, and flexible sorting
/// with performance optimizations for real-time search experiences.
/// Supports highlighting of matched text and relevance scoring.
class ApplicationSearchService {
  /// Creates an application search service.
  const ApplicationSearchService();

  /// Searches and filters applications based on the provided criteria.
  ///
  /// Performs a multi-stage filtering and search process:
  /// 1. Apply category, status, and date filters
  /// 2. Perform fuzzy text search if query is provided
  /// 3. Sort results according to specified criteria
  /// 4. Return results with match information and metadata
  ///
  /// @param applications List of all applications to search
  /// @param filter Search and filter criteria to apply
  /// @returns SearchResultSet containing filtered and sorted results
  SearchResultSet searchApplications(
    List<UserApplication> applications,
    SearchFilter filter,
  ) {
    final Stopwatch stopwatch = Stopwatch()..start();

    // Stage 1: Apply non-text filters (category, status, date)
    final List<UserApplication> filteredApps = _applyFilters(applications, filter);

    // Stage 2: Apply text search if query is provided
    List<SearchResult> searchResults;
    if (filter.query.isNotEmpty) {
      searchResults = _performTextSearch(filteredApps, filter.query);
    } else {
      // No text search - convert applications to results with no matches
      searchResults = filteredApps
          .map(
            (app) => SearchResult(
              application: app,
              matches: const [],
              score: 1.0, // All results have equal relevance without search
            ),
          )
          .toList();
    }

    // Stage 3: Sort results according to specified criteria
    _sortResults(searchResults, filter.sortOption);

    stopwatch.stop();

    return SearchResultSet(
      results: searchResults,
      totalCount: applications.length,
      filteredCount: filteredApps.length,
      query: filter.query,
      searchDurationMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// Applies non-text filters to the application list.
  ///
  /// Filters applications based on category, status, and date criteria.
  /// This stage runs before text search to reduce the search space
  /// and improve performance.
  ///
  /// @param applications List of applications to filter
  /// @param filter Filter criteria to apply
  /// @returns List of applications that match the filter criteria
  List<UserApplication> _applyFilters(
    List<UserApplication> applications,
    SearchFilter filter,
  ) {
    return applications.where((app) {
      // Category filter
      if (filter.selectedCategories.isNotEmpty) {
        if (!filter.selectedCategories.contains(app.category)) {
          return false;
        }
      }

      // Status filter
      if (filter.selectedStatuses.isNotEmpty) {
        if (!filter.selectedStatuses.contains(app.status)) {
          return false;
        }
      }

      // Date range filter
      if (filter.dateRangeStart != null) {
        if (app.createdAt.isBefore(filter.dateRangeStart!)) {
          return false;
        }
      }

      if (filter.dateRangeEnd != null) {
        // Add one day to include the end date
        final DateTime endOfDay = DateTime(
          filter.dateRangeEnd!.year,
          filter.dateRangeEnd!.month,
          filter.dateRangeEnd!.day + 1,
        );
        if (app.createdAt.isAfter(endOfDay)) {
          return false;
        }
      }

      // Favorites filter
      if (filter.favoritesOnly) {
        debugPrint('Favorites filter active: checking ${app.title}, isFavorite: ${app.isFavorite}');
        if (!app.isFavorite) {
          debugPrint('Filtering out ${app.title} because it is not a favorite');
          return false;
        }
        debugPrint('Keeping ${app.title} because it is a favorite');
      }

      // Recent filter (last 7 days)
      if (filter.recentOnly) {
        final DateTime sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        debugPrint('Recent filter active: checking ${app.title}, updatedAt: ${app.updatedAt}');
        if (app.updatedAt.isBefore(sevenDaysAgo)) {
          debugPrint('Filtering out ${app.title} because it was not updated recently');
          return false;
        }
        debugPrint('Keeping ${app.title} because it was updated recently');
      }

      return true;
    }).toList();
  }

  /// Performs fuzzy text search on the filtered applications.
  ///
  /// Searches application titles and descriptions using fuzzy matching
  /// algorithms that handle typos, partial matches, and case differences.
  /// Returns results with match information and relevance scores.
  ///
  /// @param applications List of applications to search
  /// @param query Search query to match against
  /// @returns List of search results with match information
  List<SearchResult> _performTextSearch(
    List<UserApplication> applications,
    String query,
  ) {
    final String normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) {
      return applications
          .map(
            (app) => SearchResult(
              application: app,
              matches: const [],
              score: 1.0,
            ),
          )
          .toList();
    }

    final List<SearchResult> results = [];

    for (final UserApplication app in applications) {
      final List<TextMatch> matches = [];
      double totalScore = 0.0;

      // Search in title (higher weight)
      final List<TextMatch> titleMatches = _findMatches(
        app.title,
        normalizedQuery,
        'title',
      );
      matches.addAll(titleMatches);
      totalScore += _calculateFieldScore(titleMatches, app.title.length) * 2.0;

      // Search in description (lower weight)
      final List<TextMatch> descriptionMatches = _findMatches(
        app.description,
        normalizedQuery,
        'description',
      );
      matches.addAll(descriptionMatches);
      totalScore += _calculateFieldScore(descriptionMatches, app.description.length);

      // Only include results with matches
      if (matches.isNotEmpty) {
        // Normalize score to 0.0-1.0 range
        final double normalizedScore = math.min(totalScore / 3.0, 1.0);

        results.add(
          SearchResult(
            application: app,
            matches: matches,
            score: normalizedScore,
          ),
        );
      }
    }

    // Sort by relevance score (highest first)
    results.sort((a, b) => b.score.compareTo(a.score));

    return results;
  }

  /// Finds text matches within a field using fuzzy matching.
  ///
  /// Implements fuzzy string matching that handles:
  /// - Exact substring matches
  /// - Case-insensitive matching
  /// - Word boundary matching
  /// - Partial word matching
  ///
  /// @param text Text to search within
  /// @param query Search query to find
  /// @param fieldName Name of the field being searched
  /// @returns List of text matches found in the field
  List<TextMatch> _findMatches(String text, String query, String fieldName) {
    final List<TextMatch> matches = [];
    final String normalizedText = text.toLowerCase();

    // Find exact substring matches
    int startIndex = 0;
    while (true) {
      final int index = normalizedText.indexOf(query, startIndex);
      if (index == -1) break;

      matches.add(
        TextMatch(
          start: index,
          end: index + query.length,
          matchedText: text.substring(index, index + query.length),
          field: fieldName,
        ),
      );

      startIndex = index + 1;
    }

    // If no exact matches, try word-based fuzzy matching
    if (matches.isEmpty) {
      final List<String> queryWords = query.split(' ').where((w) => w.isNotEmpty).toList();
      final List<String> textWords = normalizedText.split(RegExp(r'\s+'));

      for (final String queryWord in queryWords) {
        for (int i = 0; i < textWords.length; i++) {
          final String textWord = textWords[i];

          // Check if query word is a prefix of text word
          if (textWord.startsWith(queryWord) && queryWord.length >= 2) {
            // Find the position of this word in the original text
            final int wordStart = _findWordPosition(normalizedText, textWord, i);
            if (wordStart != -1) {
              matches.add(
                TextMatch(
                  start: wordStart,
                  end: wordStart + queryWord.length,
                  matchedText: text.substring(wordStart, wordStart + queryWord.length),
                  field: fieldName,
                ),
              );
            }
          }
        }
      }
    }

    return matches;
  }

  /// Finds the position of a word in text by index.
  ///
  /// Helper method to locate the character position of a word
  /// when we know its index in the word list.
  ///
  /// @param text Text to search in
  /// @param word Word to find
  /// @param wordIndex Index of the word in the word list
  /// @returns Character position of the word, or -1 if not found
  int _findWordPosition(String text, String word, int wordIndex) {
    final List<String> words = text.split(RegExp(r'\s+'));
    if (wordIndex >= words.length) return -1;

    int position = 0;
    for (int i = 0; i < wordIndex; i++) {
      final int wordStart = text.indexOf(words[i], position);
      if (wordStart == -1) return -1;
      position = wordStart + words[i].length;
    }

    return text.indexOf(word, position);
  }

  /// Calculates relevance score for matches in a field.
  ///
  /// Considers factors like:
  /// - Number of matches
  /// - Length of matches relative to field length
  /// - Position of matches (earlier matches score higher)
  ///
  /// @param matches List of matches in the field
  /// @param fieldLength Total length of the field text
  /// @returns Relevance score for the field (0.0 to 1.0)
  double _calculateFieldScore(List<TextMatch> matches, int fieldLength) {
    if (matches.isEmpty || fieldLength == 0) return 0.0;

    double score = 0.0;

    for (final TextMatch match in matches) {
      // Base score for having a match
      double matchScore = 0.3;

      // Bonus for match length relative to field length
      final double lengthRatio = match.length / fieldLength;
      matchScore += lengthRatio * 0.4;

      // Bonus for early position in text (first 25% of text)
      if (match.start < fieldLength * 0.25) {
        matchScore += 0.3;
      }

      score += matchScore;
    }

    return math.min(score, 1.0);
  }

  /// Sorts search results according to the specified sort option.
  ///
  /// Applies the requested sorting while preserving relevance order
  /// for results with the same sort key. Modifies the results list in place.
  ///
  /// @param results List of search results to sort
  /// @param sortOption Sorting criteria to apply
  void _sortResults(List<SearchResult> results, SortOption sortOption) {
    switch (sortOption) {
      case SortOption.createdDateDesc:
        results.sort((a, b) {
          final int dateComparison = b.application.createdAt.compareTo(a.application.createdAt);
          if (dateComparison != 0) return dateComparison;
          return b.score.compareTo(a.score); // Tie-breaker: relevance
        });

      case SortOption.createdDateAsc:
        results.sort((a, b) {
          final int dateComparison = a.application.createdAt.compareTo(b.application.createdAt);
          if (dateComparison != 0) return dateComparison;
          return b.score.compareTo(a.score); // Tie-breaker: relevance
        });

      case SortOption.updatedDateDesc:
        results.sort((a, b) {
          final int dateComparison = b.application.updatedAt.compareTo(a.application.updatedAt);
          if (dateComparison != 0) return dateComparison;
          return b.score.compareTo(a.score); // Tie-breaker: relevance
        });

      case SortOption.updatedDateAsc:
        results.sort((a, b) {
          final int dateComparison = a.application.updatedAt.compareTo(b.application.updatedAt);
          if (dateComparison != 0) return dateComparison;
          return b.score.compareTo(a.score); // Tie-breaker: relevance
        });

      case SortOption.titleAsc:
        results.sort((a, b) {
          final int titleComparison = a.application.title.toLowerCase().compareTo(b.application.title.toLowerCase());
          if (titleComparison != 0) return titleComparison;
          return b.score.compareTo(a.score); // Tie-breaker: relevance
        });

      case SortOption.titleDesc:
        results.sort((a, b) {
          final int titleComparison = b.application.title.toLowerCase().compareTo(a.application.title.toLowerCase());
          if (titleComparison != 0) return titleComparison;
          return b.score.compareTo(a.score); // Tie-breaker: relevance
        });

      case SortOption.statusPriority:
        results.sort((a, b) {
          final int statusComparison = _getStatusPriority(
            a.application.status,
          ).compareTo(_getStatusPriority(b.application.status));
          if (statusComparison != 0) return statusComparison;
          return b.score.compareTo(a.score); // Tie-breaker: relevance
        });
    }
  }

  /// Gets priority value for status-based sorting.
  ///
  /// Lower values indicate higher priority (will appear first).
  /// Prioritizes active and ready applications over developing or failed ones.
  ///
  /// @param status Application status to get priority for
  /// @returns Priority value (lower = higher priority)
  int _getStatusPriority(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.running:
        return 0; // Highest priority
      case ApplicationStatus.ready:
        return 1;
      case ApplicationStatus.developing:
        return 2;
      case ApplicationStatus.testing:
        return 2; // Same priority as developing
      case ApplicationStatus.updating:
        return 2; // Same priority as developing
      case ApplicationStatus.requested:
        return 3;
      case ApplicationStatus.failed:
        return 4; // Lowest priority
    }
  }
}
