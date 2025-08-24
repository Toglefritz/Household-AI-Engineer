import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../services/user_application/models/application_status.dart';
import '../../../../../services/user_application/models/user_application.dart';
import '../../../models/sidebar/navigation_item_data.dart';
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
  const SidebarNavigationSection({
    required this.showExpandedContent,
    required this.applications,
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

  @override
  Widget build(BuildContext context) {
    // Calculate the number of applications currently in development
    final int developmentCount = _calculateDevelopmentCount();

    final List<NavigationItemData> items = [
      NavigationItemData(
        icon: Icons.apps,
        label: AppLocalizations.of(context)!.navAllApplications,
        isSelected: true,
      ),
      NavigationItemData(
        icon: Icons.access_time,
        label: AppLocalizations.of(context)!.navRecent,
        isSelected: false,
      ),
      NavigationItemData(
        icon: Icons.favorite_outline,
        label: AppLocalizations.of(context)!.navFavorites,
        isSelected: false,
      ),
      NavigationItemData(
        icon: Icons.build,
        label: AppLocalizations.of(context)!.navInDevelopment,
        isSelected: false,
        badge: developmentCount > 0 ? developmentCount.toString() : null,
      ),
    ];

    return Column(
      children: items
          .map(
            (NavigationItemData item) => SidebarNavigationItem(
              item: item,
              showExpandedContent: showExpandedContent,
            ),
          )
          .toList(),
    );
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
