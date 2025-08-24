/// Unit tests for ApplicationSearchService.
///
/// Tests the search and filtering functionality including fuzzy matching,
/// category filtering, status filtering, date filtering, and sorting.
/// Ensures accurate search results and proper performance characteristics.

import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/services/search/application_search_service.dart';
import 'package:household_ai_engineer/services/search/models/search_filter.dart';

import 'package:household_ai_engineer/services/user_application/models/application_category.dart';
import 'package:household_ai_engineer/services/user_application/models/application_status.dart';
import 'package:household_ai_engineer/services/user_application/models/user_application.dart';

void main() {
  group('ApplicationSearchService', () {
    late ApplicationSearchService searchService;
    late List<UserApplication> testApplications;

    setUp(() {
      searchService = const ApplicationSearchService();

      // Create test applications with various properties
      testApplications = [
        UserApplication(
          id: 'app1',
          title: 'Budget Tracker',
          description: 'Track your household expenses and income',
          category: ApplicationCategory.finance,
          status: ApplicationStatus.ready,
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 20),
        ),
        UserApplication(
          id: 'app2',
          title: 'Chore Manager',
          description: 'Manage family chores and responsibilities',
          category: ApplicationCategory.homeManagement,
          status: ApplicationStatus.running,
          createdAt: DateTime(2024, 2, 10),
          updatedAt: DateTime(2024, 2, 15),
        ),
        UserApplication(
          id: 'app3',
          title: 'Meal Planner',
          description: 'Plan weekly meals and shopping lists',
          category: ApplicationCategory.planning,
          status: ApplicationStatus.developing,
          createdAt: DateTime(2024, 3, 5),
          updatedAt: DateTime(2024, 3, 10),
        ),
        UserApplication(
          id: 'app4',
          title: 'Exercise Tracker',
          description: 'Track workouts and fitness progress',
          category: ApplicationCategory.healthAndFitness,
          status: ApplicationStatus.failed,
          createdAt: DateTime(2024, 1, 25),
          updatedAt: DateTime(2024, 1, 30),
        ),
        UserApplication(
          id: 'app5',
          title: 'Learning Journal',
          description: 'Keep track of learning goals and progress',
          category: ApplicationCategory.education,
          status: ApplicationStatus.requested,
          createdAt: DateTime(2024, 2, 20),
          updatedAt: DateTime(2024, 2, 25),
        ),
      ];
    });

    group('Text Search', () {
      test('should return all applications when query is empty', () {
        final filter = const SearchFilter(query: '');
        final results = searchService.searchApplications(testApplications, filter);

        expect(results.results.length, equals(5));
        expect(results.query, equals(''));
        expect(results.totalCount, equals(5));
        expect(results.filteredCount, equals(5));
      });

      test('should find exact matches in title', () {
        final filter = const SearchFilter(query: 'Budget');
        final results = searchService.searchApplications(testApplications, filter);

        expect(results.results.length, equals(1));
        expect(results.results.first.application.title, equals('Budget Tracker'));
        expect(results.results.first.matches.length, greaterThan(0));
        expect(results.results.first.matches.first.field, equals('title'));
      });

      test('should find exact matches in description', () {
        final filter = const SearchFilter(query: 'expenses');
        final results = searchService.searchApplications(testApplications, filter);

        expect(results.results.length, equals(1));
        expect(results.results.first.application.title, equals('Budget Tracker'));
        expect(results.results.first.matches.length, greaterThan(0));
        expect(results.results.first.matches.first.field, equals('description'));
      });

      test('should perform case-insensitive search', () {
        final filter = const SearchFilter(query: 'BUDGET');
        final results = searchService.searchApplications(testApplications, filter);

        expect(results.results.length, equals(1));
        expect(results.results.first.application.title, equals('Budget Tracker'));
      });

      test('should find partial word matches', () {
        final filter = const SearchFilter(query: 'track');
        final results = searchService.searchApplications(testApplications, filter);

        expect(results.results.length, equals(3)); // Budget Tracker, Exercise Tracker, Learning Journal (track)

        final titles = results.results.map((r) => r.application.title).toList();
        expect(titles, containsAll(['Budget Tracker', 'Exercise Tracker', 'Learning Journal']));
      });

      test('should find multiple word matches', () {
        final filter = const SearchFilter(query: 'track progress');
        final results = searchService.searchApplications(testApplications, filter);

        expect(results.results.length, greaterThan(0));

        // Should find applications that contain both "track" and "progress"
        final hasExerciseTracker = results.results.any((r) => r.application.title == 'Exercise Tracker');
        final hasLearningJournal = results.results.any((r) => r.application.title == 'Learning Journal');
        expect(hasExerciseTracker || hasLearningJournal, isTrue);
      });

      test('should return empty results for non-matching query', () {
        final filter = const SearchFilter(query: 'nonexistent');
        final results = searchService.searchApplications(testApplications, filter);

        expect(results.results.length, equals(0));
        expect(results.query, equals('nonexistent'));
      });

      test('should score title matches higher than description matches', () {
        final filter = const SearchFilter(query: 'track');
        final results = searchService.searchApplications(testApplications, filter);

        // Find results with title matches vs description matches
        final titleMatches = results.results.where((r) => r.hasTitleMatches).toList();
        final descriptionOnlyMatches = results.results
            .where((r) => !r.hasTitleMatches && r.hasDescriptionMatches)
            .toList();

        if (titleMatches.isNotEmpty && descriptionOnlyMatches.isNotEmpty) {
          expect(titleMatches.first.score, greaterThan(descriptionOnlyMatches.first.score));
        }
      });
    });

    group('Category Filtering', () {
      test('should filter by single category', () {
        final filter = SearchFilter(
          selectedCategories: {ApplicationCategory.finance},
        );
        final results = searchService.searchApplications(testApplications, filter);

        expect(results.results.length, equals(1));
        expect(results.results.first.application.category, equals(ApplicationCategory.finance));
      });

      test('should filter by multiple categories', () {
        final filter = SearchFilter(
          selectedCategories: {ApplicationCategory.finance, ApplicationCategory.planning},
        );
        final results = searchService.searchApplications(testApplications, filter);

        expect(results.results.length, equals(2));

        final categories = results.results.map((r) => r.application.category).toSet();
        expect(categories, containsAll([ApplicationCategory.finance, ApplicationCategory.planning]));
      });

      test('should return empty results when no applications match category', () {
        // Assuming no applications have this category in our test data
        final filter = SearchFilter(
          selectedCategories: {ApplicationCategory.finance},
        );

        // Create test data without finance category
        final appsWithoutFinance = testApplications
            .where((app) => app.category != ApplicationCategory.finance)
            .toList();
        final results = searchService.searchApplications(appsWithoutFinance, filter);

        expect(results.results.length, equals(0));
      });
    });

    group('Status Filtering', () {
      test('should filter by single status', () {
        final filter = SearchFilter(
          selectedStatuses: {ApplicationStatus.ready},
        );
        final results = searchService.searchApplications(testApplications, filter);

        expect(results.results.length, equals(1));
        expect(results.results.first.application.status, equals(ApplicationStatus.ready));
      });

      test('should filter by multiple statuses', () {
        final filter = SearchFilter(
          selectedStatuses: {ApplicationStatus.ready, ApplicationStatus.running},
        );
        final results = searchService.searchApplications(testApplications, filter);

        expect(results.results.length, equals(2));

        final statuses = results.results.map((r) => r.application.status).toSet();
        expect(statuses, containsAll([ApplicationStatus.ready, ApplicationStatus.running]));
      });
    });

    group('Date Filtering', () {
      test('should filter by start date', () {
        final filter = SearchFilter(
          dateRangeStart: DateTime(2024, 2, 1),
        );
        final results = searchService.searchApplications(testApplications, filter);

        // Should include apps created on or after Feb 1, 2024
        expect(results.results.length, equals(3)); // Chore Manager, Meal Planner, Learning Journal

        for (final result in results.results) {
          expect(result.application.createdAt.isAfter(DateTime(2024, 1, 31)), isTrue);
        }
      });

      test('should filter by end date', () {
        final filter = SearchFilter(
          dateRangeEnd: DateTime(2024, 2, 1),
        );
        final results = searchService.searchApplications(testApplications, filter);

        // Should include apps created on or before Feb 1, 2024
        expect(results.results.length, equals(2)); // Budget Tracker, Exercise Tracker

        for (final result in results.results) {
          expect(result.application.createdAt.isBefore(DateTime(2024, 2, 2)), isTrue);
        }
      });

      test('should filter by date range', () {
        final filter = SearchFilter(
          dateRangeStart: DateTime(2024, 1, 20),
          dateRangeEnd: DateTime(2024, 2, 15),
        );
        final results = searchService.searchApplications(testApplications, filter);

        // Should include apps created between Jan 20 and Feb 15, 2024
        expect(results.results.length, equals(2)); // Exercise Tracker, Chore Manager

        for (final result in results.results) {
          expect(result.application.createdAt.isAfter(DateTime(2024, 1, 19)), isTrue);
          expect(result.application.createdAt.isBefore(DateTime(2024, 2, 16)), isTrue);
        }
      });
    });

    group('Combined Filtering', () {
      test('should combine text search with category filter', () {
        final filter = SearchFilter(
          query: 'track',
          selectedCategories: {ApplicationCategory.finance},
        );
        final results = searchService.searchApplications(testApplications, filter);

        expect(results.results.length, equals(1));
        expect(results.results.first.application.title, equals('Budget Tracker'));
        expect(results.results.first.application.category, equals(ApplicationCategory.finance));
        expect(results.results.first.matches.length, greaterThan(0));
      });

      test('should combine multiple filter types', () {
        final filter = SearchFilter(
          query: 'track',
          selectedCategories: {ApplicationCategory.finance, ApplicationCategory.healthAndFitness},
          selectedStatuses: {ApplicationStatus.ready, ApplicationStatus.failed},
          dateRangeStart: DateTime(2024, 1, 1),
          dateRangeEnd: DateTime(2024, 2, 1),
        );
        final results = searchService.searchApplications(testApplications, filter);

        // Should find Budget Tracker (finance, ready, created Jan 15) and Exercise Tracker (health, failed, created Jan 25)
        expect(results.results.length, equals(2));

        final titles = results.results.map((r) => r.application.title).toList();
        expect(titles, containsAll(['Budget Tracker', 'Exercise Tracker']));
      });
    });

    group('Sorting', () {
      test('should sort by creation date descending (default)', () {
        final filter = const SearchFilter(
          sortOption: SortOption.createdDateDesc,
        );
        final results = searchService.searchApplications(testApplications, filter);

        expect(results.results.length, equals(5));

        // Should be ordered: Meal Planner (Mar 5), Learning Journal (Feb 20), Chore Manager (Feb 10), Exercise Tracker (Jan 25), Budget Tracker (Jan 15)
        expect(results.results[0].application.title, equals('Meal Planner'));
        expect(results.results[1].application.title, equals('Learning Journal'));
        expect(results.results[2].application.title, equals('Chore Manager'));
        expect(results.results[3].application.title, equals('Exercise Tracker'));
        expect(results.results[4].application.title, equals('Budget Tracker'));
      });

      test('should sort by creation date ascending', () {
        final filter = const SearchFilter(
          sortOption: SortOption.createdDateAsc,
        );
        final results = searchService.searchApplications(testApplications, filter);

        expect(results.results.length, equals(5));

        // Should be ordered: Budget Tracker (Jan 15), Exercise Tracker (Jan 25), Chore Manager (Feb 10), Learning Journal (Feb 20), Meal Planner (Mar 5)
        expect(results.results[0].application.title, equals('Budget Tracker'));
        expect(results.results[4].application.title, equals('Meal Planner'));
      });

      test('should sort by title alphabetically', () {
        final filter = const SearchFilter(
          sortOption: SortOption.titleAsc,
        );
        final results = searchService.searchApplications(testApplications, filter);

        expect(results.results.length, equals(5));

        // Should be ordered alphabetically: Budget Tracker, Chore Manager, Exercise Tracker, Learning Journal, Meal Planner
        expect(results.results[0].application.title, equals('Budget Tracker'));
        expect(results.results[1].application.title, equals('Chore Manager'));
        expect(results.results[2].application.title, equals('Exercise Tracker'));
        expect(results.results[3].application.title, equals('Learning Journal'));
        expect(results.results[4].application.title, equals('Meal Planner'));
      });

      test('should sort by status priority', () {
        final filter = const SearchFilter(
          sortOption: SortOption.statusPriority,
        );
        final results = searchService.searchApplications(testApplications, filter);

        expect(results.results.length, equals(5));

        // Should prioritize: running, ready, developing, requested, failed
        final statuses = results.results.map((r) => r.application.status).toList();
        final runningIndex = statuses.indexOf(ApplicationStatus.running);
        final readyIndex = statuses.indexOf(ApplicationStatus.ready);
        final failedIndex = statuses.indexOf(ApplicationStatus.failed);

        expect(runningIndex, lessThan(readyIndex));
        expect(readyIndex, lessThan(failedIndex));
      });
    });

    group('Performance and Metadata', () {
      test('should include search duration in results', () {
        final filter = const SearchFilter(query: 'track');
        final results = searchService.searchApplications(testApplications, filter);

        expect(results.searchDurationMs, greaterThanOrEqualTo(0));
      });

      test('should include correct counts in results', () {
        final filter = SearchFilter(
          query: 'track',
          selectedCategories: {ApplicationCategory.finance},
        );
        final results = searchService.searchApplications(testApplications, filter);

        expect(results.totalCount, equals(5)); // Total applications
        expect(results.filteredCount, equals(1)); // Applications matching category filter
        expect(results.resultCount, equals(1)); // Final results after text search
      });

      test('should handle empty application list', () {
        final filter = const SearchFilter(query: 'test');
        final results = searchService.searchApplications([], filter);

        expect(results.results.length, equals(0));
        expect(results.totalCount, equals(0));
        expect(results.filteredCount, equals(0));
      });

      test('should handle special characters in search query', () {
        final filter = const SearchFilter(query: 'track & manage');
        final results = searchService.searchApplications(testApplications, filter);

        // Should not crash and should handle the query gracefully
        expect(results, isNotNull);
        expect(results.query, equals('track & manage'));
      });
    });

    group('Match Information', () {
      test('should provide accurate match positions', () {
        final filter = const SearchFilter(query: 'Budget');
        final results = searchService.searchApplications(testApplications, filter);

        expect(results.results.length, equals(1));

        final match = results.results.first.matches.first;
        expect(match.start, equals(0)); // "Budget" starts at position 0 in "Budget Tracker"
        expect(match.end, equals(6)); // "Budget" ends at position 6
        expect(match.matchedText, equals('Budget'));
        expect(match.field, equals('title'));
      });

      test('should find multiple matches in same field', () {
        // Create an app with repeated words
        final testApp = UserApplication(
          id: 'test',
          title: 'Track Track Track',
          description: 'Test description',
          category: ApplicationCategory.planning,
          status: ApplicationStatus.ready,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final filter = const SearchFilter(query: 'Track');
        final results = searchService.searchApplications([testApp], filter);

        expect(results.results.length, equals(1));
        expect(results.results.first.matches.length, equals(3)); // Three matches for "Track"
      });
    });
  });
}
