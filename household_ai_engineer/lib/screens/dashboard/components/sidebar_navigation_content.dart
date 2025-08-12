import 'package:flutter/material.dart';

import '../../../theme/insets.dart';
import 'sidebar_categories_section.dart';
import 'sidebar_navigation_section.dart';
import 'sidebar_quick_actions_section.dart';
import 'sidebar_search_section.dart';
import 'sidebar_section_spacing.dart';

/// Main navigation content component for the dashboard sidebar.
///
/// Contains navigation items, filters, and other interactive elements.
/// All sections are always present to prevent layout shifts during state
/// transitions. Each section adapts its presentation based on expansion state.
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
  /// Passed to all child sections to coordinate their presentation state.
  final bool showExpandedContent;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: Insets.small),
      children: [
        // Search section - always present, changes representation
        SidebarSearchSection(
          showExpandedContent: showExpandedContent,
        ),

        // Section spacing
        const SidebarSectionSpacing(),

        // Navigation items - already handles both states
        SidebarNavigationSection(
          showExpandedContent: showExpandedContent,
        ),

        // Section spacing
        const SidebarSectionSpacing(),

        // Categories section - always present, changes representation
        SidebarCategoriesSection(
          showExpandedContent: showExpandedContent,
        ),

        // Section spacing
        const SidebarSectionSpacing(),

        // Quick actions - already handles both states
        SidebarQuickActionsSection(
          showExpandedContent: showExpandedContent,
        ),
      ],
    );
  }
}
