import 'package:flutter/material.dart';

import '../../../../../services/user_application/models/user_application.dart';
import '../../../../../theme/insets.dart';
import '../categories/sidebar_categories_section.dart';
import '../quick_actions/sidebar_quick_actions.dart';
import '../search/sidebar_search.dart';
import 'sidebar_navigation_section.dart';

/// Main navigation content component for the dashboard sidebar.
///
/// Contains navigation items, filters, and other interactive elements. All sections are always present to prevent
/// layout shifts during state transitions. Each section adapts its presentation based on expansion state.
class SidebarNavigationContent extends StatelessWidget {
  /// Creates a sidebar navigation content widget.
  ///
  /// @param showExpandedContent Whether to show expanded content based on actual width
  /// @param applications List of applications for category calculation
  /// @param openNewApplicationConversation Callback for creating new applications
  const SidebarNavigationContent({
    required this.showExpandedContent,
    required this.applications,
    required this.openNewApplicationConversation,
    super.key,
  });

  /// Whether to show expanded content based on actual width during animation.
  ///
  /// Prevents content from appearing/disappearing abruptly during transitions.
  final bool showExpandedContent;

  /// List of applications for dynamic category calculation.
  ///
  /// Used to determine which categories have applications and their counts
  /// for accurate sidebar navigation and filtering.
  final List<UserApplication> applications;

  /// A callback for when the button to create a new application is tapped.
  final VoidCallback openNewApplicationConversation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Scrollable content area containing search, navigation, and categories
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: Insets.small),
            child: Column(
              children: [
                // Search section
                Padding(
                  padding: const EdgeInsets.only(bottom: Insets.medium),
                  child: SidebarSearchSection(
                    showExpandedContent: showExpandedContent,
                  ),
                ),

                // Navigation items
                Padding(
                  padding: const EdgeInsets.only(bottom: Insets.medium),
                  child: SidebarNavigationSection(
                    showExpandedContent: showExpandedContent,
                    applications: applications,
                  ),
                ),

                // Categories section
                Padding(
                  padding: const EdgeInsets.only(bottom: Insets.medium),
                  child: SidebarCategoriesSection(
                    showExpandedContent: showExpandedContent,
                    applications: applications,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Quick actions pinned to bottom with padding
        Padding(
          padding: const EdgeInsets.only(bottom: Insets.medium),
          child: SidebarQuickActionsSection(
            showExpandedContent: showExpandedContent,
            openNewApplicationConversation: openNewApplicationConversation,
          ),
        ),
      ],
    );
  }
}
