import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../services/user_application/models/application_category.dart';
import '../../../../../services/user_application/models/user_application.dart';
import '../../../../../theme/insets.dart';
import '../../../models/sidebar/category_data.dart';
import '../../../models/sidebar/sidebar_spacing.dart';
import '../../search/search_controller.dart' as search;
import 'sidebar_categories.dart';

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
  /// @param applications List of applications for dynamic category calculation
  /// @param searchController Search controller for managing filter state
  const SidebarCategoriesSection({
    required this.showExpandedContent,
    required this.applications,
    required this.searchController,
    super.key,
  });

  /// Whether to show expanded content based on actual width during animation.
  ///
  /// Prevents content from appearing/disappearing abruptly during transitions.
  /// When true, shows full category labels and counts. When false, shows
  /// only icons with spacing placeholders.
  final bool showExpandedContent;

  /// List of applications for dynamic category calculation.
  ///
  /// Used to determine which categories have applications and their counts
  /// for accurate sidebar navigation and filtering.
  final List<UserApplication> applications;

  /// Search controller for managing filter state and operations.
  ///
  /// Provides access to search functionality and filter management.
  final search.ApplicationSearchController searchController;

  /// Calculates dynamic categories based on the current applications.
  ///
  /// Creates category data with accurate counts based on applications that
  /// actually have categories assigned. Only shows categories that have
  /// at least one application. Uses the ApplicationCategory enum for
  /// type-safe category handling with consistent icons and labels.
  List<CategoryData> _calculateDynamicCategories() {
    debugPrint(
      'Calculating dynamic categories for ${applications.length} applications',
    );

    // Count applications by category enum
    final Map<ApplicationCategory, int> categoryCounts = <ApplicationCategory, int>{};

    for (final UserApplication app in applications) {
      debugPrint(
        'App: ${app.title}, hasCategory: ${app.hasCategory}, category: ${app.category?.displayName}',
      );

      // Assign category - use app's category if it has one, otherwise "Other"
      final ApplicationCategory category = app.hasCategory ? app.category! : ApplicationCategory.other;
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      debugPrint(
        'Added to category "${category.displayName}", count now: ${categoryCounts[category]}',
      );
    }

    debugPrint(
      'Category counts: ${categoryCounts.map((k, v) => MapEntry(k.displayName, v))}',
    );

    // Create category data for categories that have applications
    final List<CategoryData> dynamicCategories = <CategoryData>[];

    for (final MapEntry<ApplicationCategory, int> entry in categoryCounts.entries) {
      final ApplicationCategory categoryEnum = entry.key;
      final int count = entry.value;

      if (count > 0) {
        dynamicCategories.add(
          CategoryData(
            icon: categoryEnum.icon,
            label: categoryEnum.displayName,
            count: count,
          ),
        );
      }
    }

    debugPrint(
      'Generated ${dynamicCategories.length} dynamic categories: ${dynamicCategories.map((c) => '${c.label} (${c.count})').join(', ')}',
    );
    return dynamicCategories;
  }

  @override
  Widget build(BuildContext context) {
    final List<CategoryData> categories = _calculateDynamicCategories();
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

          // Category items - dynamically calculated based on applications
          ...categories.map(
            (CategoryData category) => SidebarCategoryItem(
              icon: category.icon,
              label: category.label,
              count: category.count,
              showExpandedContent: showExpandedContent,
              searchController: searchController,
            ),
          ),
        ],
      ),
    );
  }
}
