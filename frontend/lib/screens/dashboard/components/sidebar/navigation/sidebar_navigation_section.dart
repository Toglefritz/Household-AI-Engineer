import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../services/user_application/models/application_status.dart';
import '../../../../../services/user_application/models/user_application.dart';
import '../../../../../theme/insets.dart';
import '../../../models/sidebar/navigation_item_data.dart';
import '../../../models/sidebar/sidebar_spacing.dart';
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.small),
      child: Column(
        children: [
          GestureDetector(
            onTap: _handleAllApplicationsTap,
            child: SidebarNavigationItem(
              key: const ValueKey('all_applications'),
              item: NavigationItemData(
                icon: Icons.apps,
                label: AppLocalizations.of(context)!.navAllApplications,
                isSelected: true, // TODO: Track actual selection state
                badge: applications.isNotEmpty ? applications.length.toString() : null,
              ),
              showExpandedContent: showExpandedContent,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: Insets.small),
            child: GestureDetector(
              onTap: _handleRecentTap,
              child: SidebarNavigationItem(
                key: const ValueKey('recent'),
                item: NavigationItemData(
                  icon: Icons.history,
                  label: AppLocalizations.of(context)!.navRecent,
                  isSelected: false, // TODO: Track actual selection state
                ),
                showExpandedContent: showExpandedContent,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: Insets.small),
            child: GestureDetector(
              onTap: _handleFavoritesTap,
              child: SidebarNavigationItem(
                key: const ValueKey('favorites'),
                item: NavigationItemData(
                  icon: Icons.favorite,
                  label: AppLocalizations.of(context)!.navFavorites,
                  isSelected: false, // TODO: Track actual selection state
                ),
                showExpandedContent: showExpandedContent,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: Insets.small),
            child: GestureDetector(
              onTap: _handleInDevelopmentTap,
              child: SidebarNavigationItem(
                key: const ValueKey('in_development'),
                item: NavigationItemData(
                  icon: Icons.build,
                  label: AppLocalizations.of(context)!.navInDevelopment,
                  isSelected: false, // TODO: Track actual selection state
                  badge: developmentCount > 0 ? developmentCount.toString() : null,
                ),
                showExpandedContent: showExpandedContent,
              ),
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
  /// Filters applications to show recently created or updated applications.
  /// Shows applications from the last 7 days, sorted by most recent first.
  void _handleRecentTap() {
    // TODO: Implement recent applications filter
    // For now, clear filters and sort by newest
    searchController.clearAllFilters();
    // Future implementation: Add date range filter for last 7 days
  }

  /// Handles the "Favorites" navigation item tap.
  ///
  /// Filters applications to show only those marked as favorites by the user.
  void _handleFavoritesTap() {
    // TODO: Implement favorites filter
    // This requires adding a favorites field to UserApplication model
    searchController.clearAllFilters();
    // Future implementation: Filter by isFavorite field
  }

  /// Handles the "In Development" navigation item tap.
  ///
  /// Filters applications to show only those currently in development states.
  void _handleInDevelopmentTap() {
    searchController.updateStatusFilter({
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
}
