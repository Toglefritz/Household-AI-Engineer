import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/insets.dart';
import '../../models/sidebar/category_data.dart';
import '../../models/sidebar/sidebar_categories_constants.dart';
import '../../models/sidebar/sidebar_spacing.dart';
import 'sidebar_category_item.dart';

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
          Padding(
            padding: const EdgeInsets.only(top: Insets.xSmall),
            child: SizedBox(
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
                    ? Align(
                        key: const ValueKey('header'),
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
                      )
                    : const SizedBox.shrink(key: ValueKey('spacing')),
              ),
            ),
          ),

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
