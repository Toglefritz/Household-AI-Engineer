import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../services/search/models/search_filter.dart';
import '../../../../../services/user_application/models/application_status.dart';
import '../../../../../services/user_application/models/user_application.dart';
import '../../../../../theme/insets.dart';
import '../../../models/sidebar/navigation_item_data.dart';
import '../../search/search_controller.dart' as search;
import 'sidebar_navigation.dart';

/// Navigation section component for the dashboard sidebar.
///
/// Contains the main navigation options like "All Applications", "Recent", "Favorites", etc. Adapts display based on
/// sidebar expansion state and displays real-time counts for applications in development.
class SidebarNavigationSection extends StatelessWidget {
  /// Creates a sidebar navigation section widget.
  ///
  /// @param showExpandedContent Whether to show expanded content based on actual width
  /// @param applications List of applications for calculating development counts
  /// @param searchController Search controller for managing filter state
  const SidebarNavigationSection({
    required this.showExpandedContent,
    required this.applications,
    required this.searchController,
    super.key,
  });

  /// Whether to show expanded content based on actual width during animation.
  ///
  /// Prevents content from appearing/disappearing abruptly during transitions.
  final bool showExpandedContent;

  /// List of applications for calculating navigation item counts.
  ///
  /// Used to determine the number of applications in development status
  /// and display accurate badge counts in the navigation items.
  final List<UserApplication> applications;

  /// Search controller for managing filter state and operations.
  ///
  /// Provides access to search functionality and filter management.
  final search.ApplicationSearchController searchController;

  @override
  Widget build(BuildContext context) {
    // Calculate the number of applications currently in development
    final int developmentCount = _calculateDevelopmentCount();

    // Calculate the number of favorite applications
    final int favoritesCount = _calculateFavoritesCount();

    // Determine which navigation item should be selected based on current filter state
    final bool isAllApplicationsSelected = _isAllApplicationsSelected();
    final bool isRecentSelected = _isRecentSelected();
    final bool isFavoritesSelected = _isFavoritesSelected();
    final bool isInDevelopmentSelected = _isInDevelopmentSelected();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.small),
      child: Column(
        children: [
          SidebarNavigationItem(
            key: const ValueKey('all_applications'),
            item: NavigationItemData(
              icon: Icons.apps,
              label: AppLocalizations.of(context)!.navAllApplications,
              isSelected: isAllApplicationsSelected,
              badge: applications.isNotEmpty ? applications.length.toString() : null,
            ),
            showExpandedContent: showExpandedContent,
            onTap: _handleAllApplicationsTap,
          ),
          Padding(
            padding: const EdgeInsets.only(top: Insets.small),
            child: SidebarNavigationItem(
              key: const ValueKey('recent'),
              item: NavigationItemData(
                icon: Icons.history,
                label: AppLocalizations.of(context)!.navRecent,
                isSelected: isRecentSelected,
              ),
              showExpandedContent: showExpandedContent,
              onTap: _handleRecentTap,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: Insets.small),
            child: SidebarNavigationItem(
              key: const ValueKey('favorites'),
              item: NavigationItemData(
                icon: Icons.favorite,
                label: AppLocalizations.of(context)!.navFavorites,
                isSelected: isFavoritesSelected,
                badge: favoritesCount > 0 ? favoritesCount.toString() : null,
              ),
              showExpandedContent: showExpandedContent,
              onTap: _handleFavoritesTap,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: Insets.small),
            child: SidebarNavigationItem(
              key: const ValueKey('in_development'),
              item: NavigationItemData(
                icon: Icons.build,
                label: AppLocalizations.of(context)!.navInDevelopment,
                isSelected: isInDevelopmentSelected,
                badge: developmentCount > 0 ? developmentCount.toString() : null,
              ),
              showExpandedContent: showExpandedContent,
              onTap: _handleInDevelopmentTap,
            ),
          ),
        ],
      ),
    );
  }

  /// Handles the "All Applications" navigation item tap.
  ///
  /// Clears all filters to show all applications in the dashboard.
  void _handleAllApplicationsTap() {
    searchController.clearAllFilters();
  }

  /// Handles the "Recent" navigation item tap.
  ///
  /// Filters applications to show recently updated applications.
  /// Shows applications updated within the last 7 days, sorted by most recent first.
  void _handleRecentTap() {
    searchController
      ..clearAllFilters()
      ..updateRecentFilter(showRecentOnly: true)
      ..updateSortOption(SortOption.updatedDateDesc);
  }

  /// Handles the "Favorites" navigation item tap.
  ///
  /// Filters applications to show only those marked as favorites by the user.
  void _handleFavoritesTap() {
    searchController
      ..clearAllFilters()
      ..updateFavoritesFilter(showFavoritesOnly: true);
  }

  /// Handles the "In Development" navigation item tap.
  ///
  /// Filters applications to show only those currently in development states.
  /// Clears all other filters to ensure mutual exclusivity with other navigation options.
  void _handleInDevelopmentTap() {
    searchController
      ..clearAllFilters()
      ..updateStatusFilter({
        ApplicationStatus.developing,
        ApplicationStatus.testing,
        ApplicationStatus.updating,
      });
  }

  /// Calculates the number of applications currently in development.
  ///
  /// Counts applications with status of [ApplicationStatus.developing],
  /// [ApplicationStatus.testing], or [ApplicationStatus.updating] as these
  /// represent active development states that users should be aware of.
  ///
  /// Returns the count of applications in development, or 0 if none are found.
  int _calculateDevelopmentCount() {
    return applications.where((UserApplication app) {
      return app.status == ApplicationStatus.developing ||
          app.status == ApplicationStatus.testing ||
          app.status == ApplicationStatus.updating;
    }).length;
  }

  /// Calculates the number of applications marked as favorites.
  ///
  /// Counts applications with isFavorite set to true.
  ///
  /// Returns the count of favorite applications, or 0 if none are found.
  int _calculateFavoritesCount() {
    return applications.where((UserApplication app) => app.isFavorite).length;
  }

  /// Determines if "All Applications" navigation item should be selected.
  ///
  /// Returns true when no filters are active, indicating that all applications
  /// are being shown without any filtering criteria applied.
  bool _isAllApplicationsSelected() {
    return !searchController.currentFilter.hasActiveFilters;
  }

  /// Determines if "Recent" navigation item should be selected.
  ///
  /// Returns true when the recent-only filter is active, indicating
  /// that only recently updated applications are being shown.
  bool _isRecentSelected() {
    return searchController.currentFilter.recentOnly;
  }

  /// Determines if "Favorites" navigation item should be selected.
  ///
  /// Returns true when the favorites-only filter is active, indicating
  /// that only favorite applications are being shown.
  bool _isFavoritesSelected() {
    return searchController.currentFilter.favoritesOnly;
  }

  /// Determines if "In Development" navigation item should be selected.
  ///
  /// Returns true when status filters are active and contain only development
  /// statuses (developing, testing, updating), indicating that only applications
  /// in development are being shown.
  bool _isInDevelopmentSelected() {
    final Set<ApplicationStatus> selectedStatuses = searchController.currentFilter.selectedStatuses;

    // Check if status filter is active and contains only development statuses
    if (selectedStatuses.isEmpty) {
      return false;
    }

    // Define development statuses that correspond to "In Development" filter
    const Set<ApplicationStatus> developmentStatuses = {
      ApplicationStatus.developing,
      ApplicationStatus.testing,
      ApplicationStatus.updating,
    };

    // Check if selected statuses exactly match development statuses
    // This ensures the "In Development" item is selected only when that specific filter is active
    return selectedStatuses.length == developmentStatuses.length &&
        selectedStatuses.every((status) => developmentStatuses.contains(status));
  }
}
