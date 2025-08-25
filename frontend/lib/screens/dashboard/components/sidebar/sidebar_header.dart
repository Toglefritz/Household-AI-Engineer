import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/accessibility_helper.dart';
import '../../../../theme/insets.dart';

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
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    // Create semantic labels for the toggle button
    final String toggleLabel = l10n.accessibilitySidebarToggle;
    final String toggleAction = isExpanded ? l10n.collapse : l10n.expand;
    final String toggleHint = l10n.accessibilitySidebarToggleHint(toggleAction);

    return Container(
      height: 60.0,
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.small,
        vertical: Insets.xSmall,
      ),
      child: Row(
        children: [
          // Toggle button with accessibility support
          AccessibilityHelper.createAccessibleButton(
            label: toggleLabel,
            hint: toggleHint,
            onPressed: onToggle,
            child: IconButton(
              onPressed: onToggle,
              icon: Icon(
                isExpanded ? Icons.menu_open : Icons.menu,
                size: 20,
              ),
              tooltip: isExpanded ? l10n.sidebarToggleCollapse : l10n.sidebarToggleExpand,
              style: IconButton.styleFrom(
                minimumSize: const Size(32, 32),
                padding: const EdgeInsets.all(6),
              ),
            ),
          ),

          // Title (only shown when expanded) with semantic header
          if (showExpandedContent) ...[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: Insets.xSmall),
                child: AccessibilityHelper.createSemanticHeader(
                  level: 1,
                  child: Text(
                    l10n.sidebarTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
