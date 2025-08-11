import 'package:flutter/material.dart';
import '../../../theme/insets.dart';

/// Category item widget for the sidebar categories section.
///
/// Creates a clickable category item for filtering applications.
/// Shows the category name and the number of applications in that category.
/// Only displayed when sidebar is expanded.
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
  /// Should be a recognizable icon that represents the category type.
  final IconData icon;

  /// Category name to display.
  ///
  /// Should be concise but descriptive of the category.
  final String label;

  /// Number of applications in this category.
  ///
  /// Used to show users how many items are available in each category.
  final int count;

  /// Whether to show expanded content based on actual width during animation.
  ///
  /// Only show category items when expanded to prevent overflow.
  final bool showExpandedContent;

  @override
  Widget build(BuildContext context) {
    // Only show category items when expanded
    if (!showExpandedContent) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () {
            // TODO(Toglefritz): Implement category filtering
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 32,
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
