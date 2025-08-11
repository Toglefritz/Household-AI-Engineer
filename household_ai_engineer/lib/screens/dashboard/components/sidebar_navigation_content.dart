import 'package:flutter/material.dart';

import '../../../theme/insets.dart';
import 'sidebar_categories_section.dart';
import 'sidebar_navigation_section.dart';
import 'sidebar_quick_actions_section.dart';
import 'sidebar_search_section.dart';

/// Main navigation content component for the dashboard sidebar.
///
/// Contains navigation items, filters, and other interactive elements.  Adapts content based on expansion state to 
/// provide appropriate level of detail and functionality.
class SidebarNavigationContent extends StatelessWidget {
  /// Creates a sidebar navigation content widget.
  ///
  /// @param showExpandedContent Whether to show expanded content based on actual width
  const SidebarNavigationContent({
    required this.showExpandedContent,
    super.key,
  });

  /// Whether to show expanded content based on actual width during animation.
  ///
  /// Prevents content from appearing/disappearing abruptly during transitions.
  final bool showExpandedContent;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: Insets.small),
      children: [
        // Search section (placeholder)
        if (showExpandedContent) const SidebarSearchSection(),

        // Navigation items
        SidebarNavigationSection(
          showExpandedContent: showExpandedContent,
        ),

        // Categories section
        if (showExpandedContent)
          SidebarCategoriesSection(
            showExpandedContent: showExpandedContent,
          ),

        // Quick actions
        SidebarQuickActionsSection(
          showExpandedContent: showExpandedContent,
        ),
      ],
    );
  }
}
