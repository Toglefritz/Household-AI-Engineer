import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/insets.dart';
import '../../models/sidebar/sidebar_spacing.dart';

/// Category item widget for the sidebar categories section.
///
/// Creates a clickable category item for filtering applications. Adapts its presentation based on sidebar expansion
/// state. In expanded state, shows the category name and count. In collapsed state, shows only the icon with a tooltip
/// containing the category information.
class SidebarCategoryItem extends StatelessWidget {
  /// Creates a sidebar category item widget.
  ///
  /// @param icon Icon representing the category
  /// @param label Category name to display
  /// @param count Number of applications in this category
  /// @param showExpandedContent Whether to show expanded content based on actual width
  const SidebarCategoryItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.showExpandedContent,
    super.key,
  });

  /// Icon representing the category.
  ///
  /// Should be a recognizable icon that represents the category type. Used in both expanded and collapsed states.
  final IconData icon;

  /// Category name to display.
  ///
  /// Shown as text in expanded state and in tooltip for collapsed state. Should be concise but descriptive of the
  /// category.
  final String label;

  /// Number of applications in this category.
  ///
  /// Used to show users how many items are available in each category. Displayed as text in expanded state and in
  /// tooltip for collapsed state.
  final int count;

  /// Whether to show expanded content based on actual width during animation.
  ///
  /// When true, shows full category item with icon, label, and count. When false, shows only icon with tooltip
  /// containing category information.
  final bool showExpandedContent;

  /// Handles category selection when the item is tapped.
  ///
  /// Triggers category filtering functionality. In a full implementation, this would filter the applications list to
  /// show only items in this category.
  void _handleCategoryTap() {
    // TODO(Toglefritz): Implement category filtering
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: SizedBox(
        height: SidebarSpacing.categoryItemHeight,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 100),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: showExpandedContent
              ? _ExpandedCategoryItem(
                  key: ValueKey('expanded_$label'),
                  icon: icon,
                  label: label,
                  count: count,
                  onTap: _handleCategoryTap,
                )
              : _CollapsedCategoryItem(
                  key: ValueKey('collapsed_$label'),
                  icon: icon,
                  label: label,
                  count: count,
                  onTap: _handleCategoryTap,
                ),
        ),
      ),
    );
  }
}

/// Expanded category item widget for when sidebar is expanded.
///
/// Shows the full category information including icon, label, and count
/// in a horizontal layout with proper spacing and typography.
class _ExpandedCategoryItem extends StatelessWidget {
  /// Creates an expanded category item widget.
  ///
  /// @param icon Icon representing the category
  /// @param label Category name to display
  /// @param count Number of applications in this category
  /// @param onTap Callback function when the item is tapped
  const _ExpandedCategoryItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
    super.key,
  });

  /// Icon representing the category.
  final IconData icon;

  /// Category name to display.
  final String label;

  /// Number of applications in this category.
  final int count;

  /// Callback function when the item is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label category',
      hint: '$count applications. Double tap to filter by this category.',
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: Insets.xSmall),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: Insets.xSmall),
                ),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Collapsed category item widget for when sidebar is collapsed.
///
/// Shows only the category icon with a tooltip containing the category
/// name and count. Maintains the same height as the expanded version
/// to prevent layout shifts during state transitions.
class _CollapsedCategoryItem extends StatelessWidget {
  /// Creates a collapsed category item widget.
  ///
  /// @param icon Icon representing the category
  /// @param label Category name for tooltip
  /// @param count Number of applications for tooltip
  /// @param onTap Callback function when the item is tapped
  const _CollapsedCategoryItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
    super.key,
  });

  /// Icon representing the category.
  final IconData icon;

  /// Category name for tooltip.
  final String label;

  /// Number of applications for tooltip.
  final int count;

  /// Callback function when the item is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Tooltip(
        message: '$label ($count)',
        child: Semantics(
          label: AppLocalizations.of(context)!.sidebarCategoryLabel(label),
          hint: AppLocalizations.of(context)!.sidebarCategoryHint(count),
          button: true,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 32,
                height: 32,
                padding: const EdgeInsets.all(8),
                child: Icon(
                  icon,
                  size: 16,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
