import 'package:flutter/material.dart';
import '../../../../theme/insets.dart';
import '../../models/sidebar/navigation_item_data.dart';

/// Individual navigation item widget for the sidebar.
///
/// Creates a clickable navigation item that adapts its display based on the sidebar expansion state. Includes hover
/// effects and selection states.
class SidebarNavigationItem extends StatelessWidget {
  /// Creates a sidebar navigation item widget.
  ///
  /// @param item Navigation item data including icon, label, and state
  /// @param showExpandedContent Whether to show expanded content based on actual width
  const SidebarNavigationItem({
    required this.item,
    required this.showExpandedContent,
    super.key,
  });

  /// Navigation item data including icon, label, and state.
  ///
  /// Contains all the information needed to display and handle
  /// the navigation item.
  final NavigationItemData item;

  /// Whether to show expanded content based on actual width during animation.
  ///
  /// Prevents content from appearing/disappearing abruptly during transitions.
  final bool showExpandedContent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.xSmall,
        vertical: 2,
      ),
      child: Material(
        color: item.isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            // TODO(Toglefritz): Implement navigation item selection
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 40,
            padding: EdgeInsets.symmetric(
              horizontal: showExpandedContent ? Insets.small : 4.0,
            ),
            child: showExpandedContent
                ? _ExpandedNavigationContent(item: item)
                : _CollapsedNavigationContent(item: item),
          ),
        ),
      ),
    );
  }
}

/// Expanded content for navigation items when sidebar is expanded.
///
/// Shows the full navigation item with icon, label, and optional badge.
class _ExpandedNavigationContent extends StatelessWidget {
  /// Creates expanded navigation content.
  ///
  /// @param item Navigation item data to display
  const _ExpandedNavigationContent({
    required this.item,
  });

  /// Navigation item data to display.
  final NavigationItemData item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          item.icon,
          size: 20,
          color: item.isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: Insets.small),
            child: Text(
              item.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: item.isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: item.isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),

        // Badge
        if (item.badge != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              item.badge!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

/// Collapsed content for navigation items when sidebar is collapsed.
///
/// Shows only the icon with an optional badge dot indicator.
class _CollapsedNavigationContent extends StatelessWidget {
  /// Creates collapsed navigation content.
  ///
  /// @param item Navigation item data to display
  const _CollapsedNavigationContent({
    required this.item,
  });

  /// Navigation item data to display.
  final NavigationItemData item;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            item.icon,
            size: 20,
            color: item.isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
          ),

          // Badge dot for collapsed state
          if (item.badge != null)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
