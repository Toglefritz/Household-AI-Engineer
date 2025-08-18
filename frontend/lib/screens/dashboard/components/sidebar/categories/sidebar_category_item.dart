part of 'sidebar_categories.dart';

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
