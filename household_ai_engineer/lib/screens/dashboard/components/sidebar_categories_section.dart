import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/insets.dart';
import 'category_data.dart';
import 'sidebar_categories_constants.dart';
import 'sidebar_category_item.dart';
import 'sidebar_spacing.dart';

/// Categories section component for the dashboard sidebar.
///
/// Displays application categories and tags for filtering and organization.
/// Always present in both expanded and collapsed states to prevent layout shifts.
/// In expanded state, shows category labels and counts. In collapsed state,
/// shows only category icons with tooltips.
class SidebarCategoriesSection extends StatelessWidget {
  /// Creates a sidebar categories section widget.
  ///
  /// @param showExpandedContent Whether to show expanded content based on actual width
  const SidebarCategoriesSection({
    required this.showExpandedContent,
    super.key,
  });

  /// Whether to show expanded content based on actual width during animation.
  ///
  /// Prevents content from appearing/disappearing abruptly during transitions.
  /// When true, shows full category labels and counts. When false, shows
  /// only icons with spacing placeholders.
  final bool showExpandedContent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header - adaptive based on expansion state
          SizedBox(
            height: SidebarSpacing.headerHeight,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 100),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: showExpandedContent
                  ? const _CategoriesHeader(key: ValueKey('header'))
                  : const _CategoriesSpacing(key: ValueKey('spacing')),
            ),
          ),

          const Padding(padding: EdgeInsets.only(top: Insets.xSmall)),

          // Category items - always present
          ...SidebarCategoriesConstants.defaultCategories.map(
            (CategoryData category) => SidebarCategoryItem(
              icon: category.icon,
              label: category.label,
              count: category.count,
              showExpandedContent: showExpandedContent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Categories header widget for expanded sidebar state.
///
/// Shows the "Categories" section title with proper styling and typography.
/// Maintains consistent height to prevent layout shifts during transitions.
class _CategoriesHeader extends StatelessWidget {
  /// Creates a categories header widget.
  const _CategoriesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        header: true,
        child: Text(
          AppLocalizations.of(context)!.categoriesTitle,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.tertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Categories spacing widget for collapsed sidebar state.
///
/// Provides empty space with the same height as the categories header
/// to maintain consistent vertical spacing when the sidebar is collapsed.
/// Prevents layout shifts during state transitions.
class _CategoriesSpacing extends StatelessWidget {
  /// Creates a categories spacing widget.
  const _CategoriesSpacing({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
