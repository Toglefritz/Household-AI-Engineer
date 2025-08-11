import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/insets.dart';

/// Header component for the dashboard sidebar.
///
/// Contains the application title (when expanded) and the sidebar toggle button. Maintains consistent spacing and 
/// follows macOS design patterns for header elements.
class SidebarHeader extends StatelessWidget {
  /// Creates a sidebar header widget.
  ///
  /// @param onToggle Callback function when the user toggles sidebar state
  /// @param isExpanded Whether the sidebar is currently expanded
  /// @param showExpandedContent Whether to show expanded content based on actual width
  const SidebarHeader({
    required this.onToggle,
    required this.isExpanded,
    required this.showExpandedContent,
    super.key,
  });

  /// Callback function invoked when the user toggles the sidebar state.
  ///
  /// Called when the user clicks the collapse/expand button or uses
  /// keyboard shortcuts to change sidebar visibility.
  final VoidCallback onToggle;

  /// Whether the sidebar is currently expanded to show full content.
  ///
  /// Used to determine the appropriate icon for the toggle button.
  final bool isExpanded;

  /// Whether to show expanded content based on actual width during animation.
  ///
  /// Prevents content from appearing/disappearing abruptly during transitions.
  final bool showExpandedContent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.0,
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.small,
        vertical: Insets.xSmall,
      ),
      child: Row(
        children: [
          // Toggle button
          IconButton(
            onPressed: onToggle,
            icon: Icon(
              isExpanded ? Icons.menu_open : Icons.menu,
              size: 20,
            ),
            tooltip: isExpanded
                ? AppLocalizations.of(context)!.sidebarToggleCollapse
                : AppLocalizations.of(context)!.sidebarToggleExpand,
            style: IconButton.styleFrom(
              minimumSize: const Size(32, 32),
              padding: const EdgeInsets.all(6),
            ),
          ),

          // Title (only shown when expanded)
          if (showExpandedContent) ...[
            const Padding(
              padding: EdgeInsets.only(left: Insets.xSmall),
            ),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.sidebarTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
