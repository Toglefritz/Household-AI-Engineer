part of 'sidebar_navigation.dart';

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
            color: item.isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
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
