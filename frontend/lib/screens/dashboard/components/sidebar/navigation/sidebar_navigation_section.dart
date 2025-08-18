import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../models/sidebar/navigation_item_data.dart';
import 'sidebar_navigation.dart';

/// Navigation section component for the dashboard sidebar.
///
/// Contains the main navigation options like "All Applications", "Recent", "Favorites", etc. Adapts display based on 
/// sidebar expansion state.
class SidebarNavigationSection extends StatelessWidget {
  /// Creates a sidebar navigation section widget.
  ///
  /// @param showExpandedContent Whether to show expanded content based on actual width
  const SidebarNavigationSection({
    required this.showExpandedContent,
    super.key,
  });

  /// Whether to show expanded content based on actual width during animation.
  ///
  /// Prevents content from appearing/disappearing abruptly during transitions.
  final bool showExpandedContent;

  @override
  Widget build(BuildContext context) {
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
        badge: '3',
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
}
