part of 'sidebar_categories.dart';

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
