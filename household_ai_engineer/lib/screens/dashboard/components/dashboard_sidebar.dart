import 'package:flutter/material.dart';
import 'sidebar_header.dart';
import 'sidebar_navigation_content.dart';

/// Sidebar component for the main dashboard interface.
///
/// Provides navigation, filtering, and organization tools for managing household applications. Supports both expanded 
/// and collapsed states for responsive design and space optimization.
///
/// Features:
/// * Application categories and filters
/// * Search functionality (placeholder)
/// * Quick actions and shortcuts
/// * Responsive collapse/expand behavior
/// * macOS-style design with proper spacing and typography
class DashboardSidebar extends StatelessWidget {
  /// Creates a dashboard sidebar widget.
  ///
  /// @param isExpanded Whether the sidebar should show full content or icons only
  /// @param onToggle Callback function when the user toggles sidebar state
  const DashboardSidebar({
    required this.isExpanded,
    required this.onToggle,
    super.key,
  });

  /// Whether the sidebar is currently expanded to show full content.
  ///
  /// When true, shows full labels and expanded interface elements. When false, shows only icons and minimal interface 
  /// for space saving.
  final bool isExpanded;

  /// Callback function invoked when the user toggles the sidebar state.
  ///
  /// Called when the user clicks the collapse/expand button or uses keyboard shortcuts to change sidebar visibility.
  final VoidCallback onToggle;

  /// Width of the sidebar when expanded to show full content.
  ///
  /// Provides enough space for navigation labels, search bar, and category listings while maintaining proper proportions.
  static const double _expandedWidth = 280.0;

  /// Width of the sidebar when collapsed to show only icons.
  ///
  /// Minimal width that still allows for recognizable icons and maintains visual hierarchy in the collapsed state.
  static const double _collapsedWidth = 88.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: isExpanded ? _expandedWidth : _collapsedWidth,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Determine if we should show expanded content based on actual width
          // during animation, not just the boolean state
          final bool showExpandedContent =
              constraints.maxWidth > (_collapsedWidth + 20);

          return Column(
            children: [
              SidebarHeader(
                onToggle: onToggle,
                isExpanded: isExpanded,
                showExpandedContent: showExpandedContent,
              ),
              const Divider(height: 1),
              Expanded(
                child: SidebarNavigationContent(
                  showExpandedContent: showExpandedContent,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
