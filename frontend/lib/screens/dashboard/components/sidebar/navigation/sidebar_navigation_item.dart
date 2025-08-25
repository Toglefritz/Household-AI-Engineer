part of 'sidebar_navigation.dart';

/// Individual navigation item widget for the sidebar.
///
/// Creates a clickable navigation item that adapts its display based on the sidebar expansion state. Includes hover
/// effects and selection states.
class SidebarNavigationItem extends StatelessWidget {
  /// Creates a sidebar navigation item widget.
  ///
  /// @param item Navigation item data including icon, label, and state
  /// @param showExpandedContent Whether to show expanded content based on actual width
  /// @param onTap Callback function when the navigation item is tapped
  const SidebarNavigationItem({
    required this.item,
    required this.showExpandedContent,
    this.onTap,
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

  /// Callback function invoked when the navigation item is tapped.
  ///
  /// If null, the navigation item will not respond to taps.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 2,
      ),
      child: Material(
        color: item.isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
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
