part of 'sidebar_categories.dart';

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
