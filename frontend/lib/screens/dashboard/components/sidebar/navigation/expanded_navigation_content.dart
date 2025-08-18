part of 'sidebar_navigation.dart';

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
