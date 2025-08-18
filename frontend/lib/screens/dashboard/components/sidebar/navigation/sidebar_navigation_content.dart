import 'package:flutter/material.dart';

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
  const SidebarNavigationContent({
    required this.showExpandedContent,
    required this.openNewApplicationConversation,
    super.key,
  });

  /// Whether to show expanded content based on actual width during animation.
  ///
  /// Prevents content from appearing/disappearing abruptly during transitions.
  final bool showExpandedContent;

  /// A callback for when the button to create a new application is tapped.
  final VoidCallback openNewApplicationConversation;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: Insets.small),
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
          ),
        ),

        // Categories section
        Padding(
          padding: const EdgeInsets.only(bottom: Insets.medium),
          child: SidebarCategoriesSection(
            showExpandedContent: showExpandedContent,
          ),
        ),

        // Quick actions
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
